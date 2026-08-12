ESX = exports['es_extended']:getSharedObject()

CreateThread(function()
  Wait(1500)
  if Config.FullDbSyncOnStart then
    BlCopNet.SyncAllUsers()
  end

  local resync = tonumber(Config.OnlineResyncIntervalMs) or 0
  if resync > 0 then
    while true do
      Wait(resync)
      for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if src then
          BlCopNet.SyncPlayer(src)
          Wait(250)
        end
      end
    end
  end
end)

RegisterCommand(Config.Commands.syncMe, function(src)
  if src == 0 then
    print('[bl_copnet] syncMe nur ingame')
    return
  end
  BlCopNet.SyncPlayer(src, function(ok, data)
    if ok then
      TriggerClientEvent('esx:showNotification', src, 'CopNet: Charakter synchronisiert.')
    else
      TriggerClientEvent('esx:showNotification', src, 'CopNet: Sync fehlgeschlagen.')
      BlCopNet.Warn('syncMe failed for %s: %s', src, json.encode(data or {}))
    end
  end)
end, true)

RegisterCommand(Config.Commands.syncAll, function(src)
  if src ~= 0 then
    TriggerClientEvent('esx:showNotification', src, 'Full-Sync gestartet (Server-Konsole prüfen).')
  end
  BlCopNet.SyncAllUsers()
end, true)

RegisterCommand(Config.Commands.dutyTest, function(src, args)
  if src == 0 then return end
  local mode = tostring(args[1] or ''):lower()
  local discordId = BlCopNet.GetDiscordId(src)
  if mode == 'on' then
    BlCopNet.SendEvent('clock_in', discordId, { manual = true })
    BlCopNet.SetDutyTracking(src, true)
    TriggerClientEvent('esx:showNotification', src, 'CopNet: clock_in gesendet.')
  elseif mode == 'off' then
    BlCopNet.SendEvent('clock_out', discordId, { manual = true })
    BlCopNet.SetDutyTracking(src, false)
    TriggerClientEvent('esx:showNotification', src, 'CopNet: clock_out gesendet.')
  else
    TriggerClientEvent('esx:showNotification', src, 'Usage: /' .. Config.Commands.dutyTest .. ' on|off')
  end
end, true)

print('[bl_copnet] gestartet → ' .. tostring(BlCopNet.GetApiBaseUrl()))
