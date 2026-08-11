RegisterNetEvent('bl_copnet:requestTablet', function()
  local src = source
  if Config.Tablet and Config.Tablet.enabled == false then
    TriggerClientEvent('bl_copnet:tabletError', src, 'CopNet-Tablet ist deaktiviert.')
    return
  end
  local discordId = BlCopNet.GetDiscordId(src)
  if not discordId then
    TriggerClientEvent('bl_copnet:tabletError', src, 'Keine Discord-ID verknüpft.')
    return
  end

  local redirect = (Config.Tablet and Config.Tablet.redirect) or '/patrol'
  BlCopNet.Request('POST', '/api/fivem/auth/ticket', {
    discordId = tostring(discordId),
    redirect = redirect,
  }, function(ok, data)
    if not ok or not data or not data.path then
      local err = (data and (data.error or data.raw)) or 'Ticket fehlgeschlagen'
      TriggerClientEvent('bl_copnet:tabletError', src, tostring(err))
      return
    end
    local base = tostring(Config.ApiBaseUrl or ''):gsub('/+$', '')
    local url = base .. tostring(data.path)
    TriggerClientEvent('bl_copnet:tabletOpen', src, url, 'CopNet')
  end)
end)
