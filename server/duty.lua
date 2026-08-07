BlCopNet = BlCopNet or {}

local dutyState = {} -- [src] = { onDuty = bool, job = string }

local function isDutyJob(jobName)
  if not jobName then return false end
  return Config.DutyJobs[jobName] == true
end

local function setTracked(src, onDuty, jobName)
  dutyState[src] = { onDuty = onDuty and true or false, job = jobName or '' }
end

function BlCopNet.IsPlayerTrackedOnDuty(src)
  local state = dutyState[src]
  return state and state.onDuty == true
end

function BlCopNet.HandleDutyChange(src, job, lastJob)
  local discordId = BlCopNet.GetDiscordId(src)
  local jobName = job and job.name or nil
  local onDuty = job and job.onDuty == true
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
