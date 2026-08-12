BlCopNet = BlCopNet or {}

local dutyState = {} -- [src] = { onDuty = bool, job = string }

local function isDutyJob(jobName)
  if not jobName then return false end
  return Config.DutyJobs[jobName] == true
end

local function setTracked(src, onDuty, jobName)
  dutyState[src] = { onDuty = onDuty and true or false, job = jobName or '' }
end

--- explicit false/0 → false; explicit true/1 → true;
--- nil + job in DutyJobs → true (ESX/lunar without flag); else false
local function resolveOnDuty(job)
  if type(job) ~= 'table' then return false end
  local flag = job.onDuty
  if flag == nil then flag = job.onduty end
  if flag == false or flag == 0 then return false end
  if flag == true or flag == 1 then return true end
  -- nil / missing flag: ESX/lunar often omit onDuty even when on duty
  if isDutyJob(job.name) then return true end
  return false
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
  TriggerClientEvent('bl_copnet:setTracking', src, onDuty and true or false)
end

function BlCopNet.HandleDutyChange(src, job, lastJob)
  local discordId = BlCopNet.GetDiscordId(src)
  local jobName = job and job.name or nil
  local onDuty = resolveOnDuty(job)
  local tracked = isDutyJob(jobName)
  local prev = dutyState[src]

  if tracked and onDuty then
    if not prev or not prev.onDuty or prev.job ~= jobName then
      setTracked(src, true, jobName)
      BlCopNet.SendEvent('clock_in', discordId, {
        job = jobName,
        grade = job and job.grade or 0,
      })
      TriggerClientEvent('bl_copnet:setTracking', src, true)
      if Config.Debug then
        BlCopNet.Debug('Duty ON src=%s job=%s', src, tostring(jobName))
      end
    end
    return
  end

  if prev and prev.onDuty then
    setTracked(src, false, jobName)
    BlCopNet.SendEvent('clock_out', discordId, {
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
  TriggerClientEvent('bl_copnet:setTracking', src, false)
end

function BlCopNet.SendPosition(src, x, y)
  if not BlCopNet.IsPlayerTrackedOnDuty(src) then return end
  local discordId = BlCopNet.GetDiscordId(src)
  if not discordId then return end
  BlCopNet.SendEvent('unit_position', discordId, {
    x = x,
    y = y,
  })
end

function BlCopNet.ClearPlayer(src)
  local prev = dutyState[src]
  if prev and prev.onDuty then
    local discordId = BlCopNet.GetDiscordId(src)
    BlCopNet.SendEvent('clock_out', discordId, { reason = 'disconnect' })
  end
  dutyState[src] = nil
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

  -- Kein Server-Duty-Flag → Client/LB Phone steuert via clientDutySync
  local flag = job.onDuty
  if flag == nil then flag = job.onduty end
  if flag == nil then return end

  BlCopNet.HandleDutyChange(src, job)
end)

--- Client-side duty sync (LB Phone / sky_jobs_base toggles onDuty without esx:setJob).
--- Client-Boolean ist maßgeblich (LB Phone updated oft nur PlayerData clientseitig).
RegisterNetEvent('bl_copnet:clientDutySync', function(clientDuty)
  local src = source
  local xPlayer = ESX.GetPlayerFromId(src)
  if not xPlayer then return end

  local job = xPlayer.getJob and xPlayer.getJob() or xPlayer.job
  if type(job) ~= 'table' or not isDutyJob(job.name) then
    BlCopNet.SetDutyTracking(src, false, job and job.name or '')
    return
  end

  local onDuty = clientDuty == true
  local wasOnDuty = BlCopNet.IsPlayerTrackedOnDuty(src)
  if onDuty == wasOnDuty then return end

  local discordId = BlCopNet.GetDiscordId(src)
  if onDuty then
    BlCopNet.SendEvent('clock_in', discordId, {
      job = job.name,
      grade = job.grade or 0,
    })
    BlCopNet.SetDutyTracking(src, true, job.name)
    if Config.Debug then
      BlCopNet.Debug('clientDutySync ON src=%s job=%s', src, tostring(job.name))
    end
  else
    BlCopNet.SendEvent('clock_out', discordId, {
      job = job.name,
      reason = 'off_duty',
    })
    BlCopNet.SetDutyTracking(src, false, job.name)
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
