RegisterNetEvent('bl_copnet:requestTablet', function()
  local src = source
  if Config.Tablet and Config.Tablet.enabled == false then
    TriggerClientEvent('bl_copnet:tabletError', src, 'CopNet-Tablet ist deaktiviert.')
    return
  end

  -- Nur on-duty Officers (DutyJobs + Tracking)
  if not BlCopNet.IsPlayerTrackedOnDuty or not BlCopNet.IsPlayerTrackedOnDuty(src) then
    TriggerClientEvent('bl_copnet:tabletError', src, 'CopNet-Tablet nur im Dienst verfügbar.')
    return
  end

  local discordId = BlCopNet.GetDiscordId(src)
  if not discordId then
    TriggerClientEvent('bl_copnet:tabletError', src, 'Keine Discord-ID verknüpft.')
    return
  end

  local redirect = (Config.Tablet and Config.Tablet.redirect) or '/dashboard'
  BlCopNet.CreateAuthTicket(discordId, redirect, function(ok, data)
    if not ok or not data or not data.path then
      local err = (data and (data.error or data.raw)) or 'Ticket fehlgeschlagen'
      TriggerClientEvent('bl_copnet:tabletError', src, tostring(err))
      return
    end
    local base = BlCopNet.GetApiBaseUrl()
    if base == '' then
      TriggerClientEvent('bl_copnet:tabletError', src, 'BL_CopNet_API_url nicht gesetzt.')
      return
    end
    local url = base .. tostring(data.path)
    TriggerClientEvent('bl_copnet:tabletOpen', src, url, 'CopNet')
  end)
end)
