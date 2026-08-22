BlCopNet = BlCopNet or {}

local dutyState = {} -- [src] = { onDuty = bool, job = string }
local clientSyncMeta = {} -- [src] = { lastAt = ms, changes = {t1,t2,...} }
local lastPosition = {} -- [src] = { x, y, at }
local clockOutToken = {} -- [src] = number, bricht verzögertes Ausstempeln ab

local function isDutyJob(jobName)
  if not jobName then return false end
  if Config.DutyJobs[jobName] == false then return false end
  if Config.DutyJobs[jobName] == true then return true end
  local n = tostring(jobName):lower()
  return n:find('police', 1, true)
    or n:find('sheriff', 1, true)
    or n:find('lspd', 1, true)
    or n:find('lssd', 1, true)
    or n:find('bcso', 1, true)
    or n:find('fib', 1, true)
    or n:find('doj', 1, true)
    or n:find('usms', 1, true)
    or n:find('ambulance', 1, true)
    or n:find('medic', 1, true)
    or n:find('lsmd', 1, true)
    or n:find('ems', 1, true)
    or n:find('fire', 1, true)
end

local function setTracked(src, onDuty, jobName)
  dutyState[src] = { onDuty = onDuty and true or false, job = jobName or '' }
end

local function getServerDutyFlag(job)
  if type(job) ~= 'table' then return nil end
  local flag = job.onDuty
  if flag == nil then flag = job.onduty end
  if flag == false or flag == 0 then return false end
  if flag == true or flag == 1 then return true end
  return nil
end

--- explicit false/0 → false; explicit true/1 → true;
--- nil + job in DutyJobs → true (ESX/lunar without flag); else false
local function resolveOnDuty(job)
  if type(job) ~= 'table' then return false end
  local flag = getServerDutyFlag(job)
  if flag ~= nil then return flag end
  -- nil / missing flag: ESX/lunar often omit onDuty even when on duty
  if isDutyJob(job.name) then return true end
  return false
end

local function allowClientDutyHint(src)
  local minMs = tonumber(Config.ClientDutySyncMinIntervalMs) or 3000
  if minMs < 1000 then minMs = 1000 end
  local maxPerMin = tonumber(Config.ClientDutySyncMaxPerMinute) or 12
  if maxPerMin < 2 then maxPerMin = 2 end

  local now = GetGameTimer()
  local meta = clientSyncMeta[src]
  if not meta then
    meta = { lastAt = 0, changes = {} }
    clientSyncMeta[src] = meta
  end

  if (now - (meta.lastAt or 0)) < minMs then
    return false, 'interval'
  end

  local window = {}
  for _, t in ipairs(meta.changes or {}) do
    if (now - t) < 60000 then
      window[#window + 1] = t
    end
  end
  if #window >= maxPerMin then
    return false, 'rate'
  end

  window[#window + 1] = now
  meta.changes = window
  meta.lastAt = now
  return true
end

local function nextClockOutToken(src)
  local token = (clockOutToken[src] or 0) + 1
  clockOutToken[src] = token
  return token
end

local function scheduleClockOut(src, discordId, payload)
  local token = nextClockOutToken(src)
  -- Kurzes Duty-Flackern (esx:setJob) nicht sofort ausstempeln.
  SetTimeout(3000, function()
    if clockOutToken[src] ~= token then return end
    if BlCopNet.IsPlayerTrackedOnDuty(src) then return end
    clockOutToken[src] = nil
    BlCopNet.SendEvent('clock_out', discordId, payload)
  end)
end

function BlCopNet.IsPlayerTrackedOnDuty(src)
  local state = dutyState[src]
  return state and state.onDuty == true
end

function BlCopNet.SetDutyTracking(src, onDuty, jobName)
  local name = jobName
  if not name or name == '' then
    local xPlayer = ESX.GetPlayerFromId(src)
    name = xPlayer and xPlayer.job and xPlayer.job.name or ''
  end
  setTracked(src, onDuty and true or false, name)
  if not onDuty then
    lastPosition[src] = nil
  end
  TriggerClientEvent('bl_copnet:setTracking', src, onDuty and true or false)
  if onDuty then
    TriggerClientEvent('bl_copnet:requestPosition', src)
  end
end

function BlCopNet.HandleDutyChange(src, job, lastJob)
  local discordId = BlCopNet.GetDiscordId(src)
  local jobName = job and job.name or nil
  local tracked = isDutyJob(jobName)
  local prev = dutyState[src]
  local serverFlag = getServerDutyFlag(job)
  local onDuty
  if serverFlag ~= nil then
    onDuty = serverFlag == true and tracked
  elseif prev then
    -- Ohne ESX-Flag gilt der letzte Stand (Client-Hint). Job-Name allein stempelt nicht wieder ein.
    onDuty = prev.onDuty == true and tracked
  else
    onDuty = resolveOnDuty(job)
  end

  if tracked and onDuty then
    nextClockOutToken(src)
    if not prev or not prev.onDuty or prev.job ~= jobName then
      setTracked(src, true, jobName)
      BlCopNet.SendEvent('clock_in', discordId, {
        job = jobName,
        grade = job and job.grade or 0,
      })
      if Config.Debug then
        BlCopNet.Debug('Duty ON src=%s job=%s', src, tostring(jobName))
      end
    end
    -- Client nach Restart/Reconnect immer wieder scharf schalten, sonst bleibt GPS aus.
    TriggerClientEvent('bl_copnet:setTracking', src, true)
    TriggerClientEvent('bl_copnet:requestPosition', src)
    return
  end

  if prev and prev.onDuty then
    setTracked(src, false, jobName)
    lastPosition[src] = nil
    scheduleClockOut(src, discordId, {
      job = prev.job,
      reason = tracked and 'off_duty' or 'job_change',
    })
    TriggerClientEvent('bl_copnet:setTracking', src, false)
    if Config.Debug then
      BlCopNet.Debug('Duty OFF src=%s reason=%s', src, tracked and 'off_duty' or 'job_change')
    end
    return
  end

  setTracked(src, false, jobName or '')
  lastPosition[src] = nil
  TriggerClientEvent('bl_copnet:setTracking', src, false)
end

local function resolvePositionCoords(src, clientX, clientY)
  local ped = GetPlayerPed(src)
  if ped and ped ~= 0 then
    local c = GetEntityCoords(ped)
    if c and c.x and c.y then
      return c.x + 0.0, c.y + 0.0, true
    end
  end
  return clientX + 0.0, clientY + 0.0, false
end

--- Anti-Teleport: Intervall + max. Distanz aus Geschwindigkeit seit letztem akzeptierten Punkt.
local function acceptPositionUpdate(src, x, y)
  local cfg = Config.PositionAntiTeleport
  if type(cfg) ~= 'table' or cfg.enabled == false then
    return true
  end

  local now = GetGameTimer()
  local prev = lastPosition[src]
  local minInterval = tonumber(cfg.minIntervalMs) or 4000
  if minInterval < 1000 then minInterval = 1000 end
  local resetAfter = tonumber(cfg.resetAfterMs) or 120000
  local maxSpeed = tonumber(cfg.maxSpeedMps) or 150
  local grace = tonumber(cfg.graceMeters) or 80

  if not prev then
    lastPosition[src] = { x = x, y = y, at = now }
    return true
  end

  local elapsed = now - (prev.at or 0)
  if elapsed < minInterval then
    return false, 'interval'
  end

  if elapsed >= resetAfter then
    lastPosition[src] = { x = x, y = y, at = now }
    return true
  end

  local dx = x - (prev.x or x)
  local dy = y - (prev.y or y)
  local dist = math.sqrt(dx * dx + dy * dy)
  local maxDist = (maxSpeed * (elapsed / 1000.0)) + grace
  if dist > maxDist then
    if Config.Debug then
      BlCopNet.Debug('position reject src=%s dist=%.1f max=%.1f elapsed=%dms', src, dist, maxDist, elapsed)
    end
    return false, 'teleport'
  end

  lastPosition[src] = { x = x, y = y, at = now }
  return true
end

function BlCopNet.SendPosition(src, x, y)
  if not BlCopNet.IsPlayerTrackedOnDuty(src) then return end
  if type(x) ~= 'number' or type(y) ~= 'number' then return end
  if x ~= x or y ~= y then return end -- NaN

  local sx, sy = resolvePositionCoords(src, x, y)
  local ok = acceptPositionUpdate(src, sx, sy)
  if not ok then return end

  local discordId = BlCopNet.GetDiscordId(src)
  if not discordId then return end
  BlCopNet.SendEvent('unit_position', discordId, {
    x = sx,
    y = sy,
  })
end

function BlCopNet.ClearPlayer(src)
  nextClockOutToken(src)
  local prev = dutyState[src]
  if prev and prev.onDuty then
    local discordId = BlCopNet.GetDiscordId(src)
    BlCopNet.SendEvent('clock_out', discordId, { reason = 'disconnect' })
  end
  dutyState[src] = nil
  clientSyncMeta[src] = nil
  lastPosition[src] = nil
  clockOutToken[src] = nil
end

AddEventHandler('esx:setJob', function(playerId, job, lastJob)
  BlCopNet.HandleDutyChange(playerId, job, lastJob)
end)

RegisterNetEvent('bl_copnet:refreshDuty', function()
  local src = source
  local xPlayer = ESX.GetPlayerFromId(src)
  if not xPlayer then return end
  local job = xPlayer.getJob and xPlayer.getJob() or xPlayer.job
  if type(job) ~= 'table' then return end

  -- Ohne Duty-Job → immer raus
  if not isDutyJob(job.name) then
    BlCopNet.HandleDutyChange(src, job)
    return
  end

  -- Serverseitiges Duty-Flag vorhanden → nur Server-Wahrheit
  if getServerDutyFlag(job) ~= nil then
    BlCopNet.HandleDutyChange(src, job)
    return
  end

  -- Kein Server-Flag (LB Phone / Client-only Duty): Client-Hint darf nachziehen
end)

--- Client-Hint für Duty (LB Phone / sky_jobs_base ohne esx:setJob).
--- Server-Job-Flag hat Vorrang; Client-Boolean nur wenn Server kein Flag hat.
--- Rate-Limit gegen Spam / Cheat-Clock-In.
RegisterNetEvent('bl_copnet:clientDutySync', function(clientDuty)
  local src = source
  if type(clientDuty) ~= 'boolean' then return end

  local xPlayer = ESX.GetPlayerFromId(src)
  if not xPlayer then return end

  local job = xPlayer.getJob and xPlayer.getJob() or xPlayer.job
  if type(job) ~= 'table' or not isDutyJob(job.name) then
    local wasOn = BlCopNet.IsPlayerTrackedOnDuty(src)
    local discordId = BlCopNet.GetDiscordId(src)
    BlCopNet.SetDutyTracking(src, false, job and job.name or '')
    if wasOn then
      scheduleClockOut(src, discordId, {
        job = job and job.name or '',
        reason = 'job_change',
        source = 'client_hint',
      })
    end
    return
  end

  local serverFlag = getServerDutyFlag(job)
  if serverFlag ~= nil then
    -- Server kennt Duty → Client-Boolean ignorieren
    BlCopNet.HandleDutyChange(src, job)
    return
  end

  local allowed, reason = allowClientDutyHint(src)
  if not allowed then
    if Config.Debug then
      BlCopNet.Debug('clientDutySync blocked src=%s reason=%s', src, tostring(reason))
    end
    return
  end

  local onDuty = clientDuty == true
  local wasOnDuty = BlCopNet.IsPlayerTrackedOnDuty(src)
  if onDuty == wasOnDuty then return end

  local discordId = BlCopNet.GetDiscordId(src)
  if onDuty then
    nextClockOutToken(src)
    BlCopNet.SendEvent('clock_in', discordId, {
      job = job.name,
      grade = job.grade or 0,
      source = 'client_hint',
    })
    BlCopNet.SetDutyTracking(src, true, job.name)
    if Config.Debug then
      BlCopNet.Debug('clientDutySync ON src=%s job=%s', src, tostring(job.name))
    end
  else
    BlCopNet.SetDutyTracking(src, false, job.name)
    scheduleClockOut(src, discordId, {
      job = job.name,
      reason = 'off_duty',
      source = 'client_hint',
    })
    if Config.Debug then
      BlCopNet.Debug('clientDutySync OFF src=%s job=%s', src, tostring(job.name))
    end
  end
end)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
  if not xPlayer then return end
  SetTimeout(2500, function()
    if Config.SyncOnPlayerLoad then
      BlCopNet.SyncPlayer(playerId)
    end
    BlCopNet.HandleDutyChange(playerId, xPlayer.getJob and xPlayer.getJob() or xPlayer.job)
  end)
end)

AddEventHandler('playerDropped', function()
  BlCopNet.ClearPlayer(source)
end)

RegisterNetEvent('bl_copnet:position', function(x, y)
  local src = source
  if type(x) ~= 'number' or type(y) ~= 'number' then return end
  BlCopNet.SendPosition(src, x + 0.0, y + 0.0)
end)

-- Nach Resource-Start: alle Online-Officer erneut an CopNet melden
-- (sonst bleiben sie unsichtbar, wenn clock_in vorher 403 war).
CreateThread(function()
  Wait(6000)
  if not ESX then return end
  for _, sid in ipairs(GetPlayers()) do
    local src = tonumber(sid)
    if src then
      local xPlayer = ESX.GetPlayerFromId(src)
      if xPlayer then
        BlCopNet.HandleDutyChange(src, xPlayer.getJob and xPlayer.getJob() or xPlayer.job)
      end
    end
  end
end)

-- Heartbeat: Stempeluhr offen halten, solange FiveM sie on-duty trackt
CreateThread(function()
  while true do
    Wait(90000)
    for src, state in pairs(dutyState) do
      if state and state.onDuty then
        local discordId = BlCopNet.GetDiscordId(src)
        if discordId then
          BlCopNet.SendEvent('clock_in', discordId, {
            job = state.job,
            source = 'heartbeat',
          })
        end
      end
    end
  end
end)
