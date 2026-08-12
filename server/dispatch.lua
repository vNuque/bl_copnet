BlCopNet = BlCopNet or {}

local dismissed = {} -- [src] = { [callId] = true }

function BlCopNet.FetchAssignedCalls(src, cb)
  local discordId = BlCopNet.GetDiscordId(src)
  if not discordId then
    if cb then cb(false, { calls = {} }) end
    return
  end
  BlCopNet.GetAssignedDispatch(discordId, function(ok, data)
    if not ok or type(data) ~= 'table' then
      if cb then cb(false, { calls = {} }) end
      return
    end
    local hide = dismissed[src] or {}
    local filtered = {}
    for _, call in ipairs(data.calls or {}) do
      if call and call.id and not hide[tostring(call.id)] then
        filtered[#filtered + 1] = call
      end
    end
    data.calls = filtered
    if cb then cb(true, data) end
  end)
end

function BlCopNet.AckCall(src, callId, action, cb)
  local discordId = BlCopNet.GetDiscordId(src)
  if not discordId then
    if cb then cb(false, { error = 'missing_discord' }) end
    return
  end
  action = tostring(action or 'accept'):lower()
  BlCopNet.AckDispatchCall(callId, discordId, action, function(ok, data)
    if ok and action == 'dismiss' then
      dismissed[src] = dismissed[src] or {}
      dismissed[src][tostring(callId)] = true
    end
    if cb then cb(ok, data) end
  end)
end

RegisterNetEvent('bl_copnet:dispatchPoll', function()
  local src = source
  if not BlCopNet.IsPlayerTrackedOnDuty(src) then
    TriggerClientEvent('bl_copnet:dispatchCalls', src, {})
    return
  end
  BlCopNet.FetchAssignedCalls(src, function(_, data)
    TriggerClientEvent('bl_copnet:dispatchCalls', src, (data and data.calls) or {})
  end)
end)

RegisterNetEvent('bl_copnet:dispatchAccept', function(callId)
  local src = source
  callId = tostring(callId or '')
  if callId == '' then return end
  BlCopNet.AckCall(src, callId, 'accept', function(ok)
    if ok then
      TriggerClientEvent('esx:showNotification', src, 'CopNet: Einsatz angenommen – Wegpunkt gesetzt.')
      BlCopNet.FetchAssignedCalls(src, function(_, data)
        TriggerClientEvent('bl_copnet:dispatchCalls', src, (data and data.calls) or {})
      end)
    else
      TriggerClientEvent('esx:showNotification', src, 'CopNet: Annehmen fehlgeschlagen.')
    end
  end)
end)

RegisterNetEvent('bl_copnet:dispatchDismiss', function(callId)
  local src = source
  callId = tostring(callId or '')
  if callId == '' then return end
  BlCopNet.AckCall(src, callId, 'dismiss', function()
    BlCopNet.FetchAssignedCalls(src, function(_, data)
      TriggerClientEvent('bl_copnet:dispatchCalls', src, (data and data.calls) or {})
    end)
  end)
end)

AddEventHandler('playerDropped', function()
  dismissed[source] = nil
end)
