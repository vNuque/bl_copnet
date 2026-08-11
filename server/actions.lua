BlCopNet = BlCopNet or {}

local panicCooldownUntil = {} -- [src] = gameTimer ms

local VALID_STATUS = {
  available = true,
  busy = true,
  enroute = true,
  on_scene = true,
  unavailable = true,
}

local function notify(src, msg)
  TriggerClientEvent('esx:showNotification', src, msg)
end

local function panicItemName()
  local cfg = Config.Panic or {}
  local name = tostring(cfg.requiredItem or ''):gsub('^%s+', ''):gsub('%s+$', '')
  return name ~= '' and name or nil
end

function BlCopNet.HasPanicItem(src)
  local itemName = panicItemName()
  if not itemName then return true end

  if GetResourceState('ox_inventory') == 'started' then
    local count = exports.ox_inventory:Search(src, 'count', itemName)
    return (tonumber(count) or 0) > 0
  end

  local xPlayer = ESX.GetPlayerFromId(src)
  if not xPlayer then return false end
  local item = xPlayer.getInventoryItem and xPlayer.getInventoryItem(itemName)
  if not item then return false end
  return (tonumber(item.count) or tonumber(item.amount) or 0) > 0
end

local function requireDutyDiscord(src)
  if not BlCopNet.IsPlayerTrackedOnDuty(src) then
    notify(src, 'CopNet: Nur on-duty verfügbar.')
    return nil
  end
  local discordId = BlCopNet.GetDiscordId(src)
  if not discordId then
    notify(src, 'CopNet: Keine Discord-ID am Client.')
    return nil
  end
  return discordId
end

function BlCopNet.SetUnitStatus(src, status, cb)
  local discordId = requireDutyDiscord(src)
  if not discordId then
    if cb then cb(false) end
    return
  end
  local value = tostring(status or ''):lower():gsub('%s+', '_')
  if not VALID_STATUS[value] then
    notify(src, 'CopNet: Ungültiger Status.')
    if cb then cb(false) end
    return
  end
  BlCopNet.SendEvent('unit_status', discordId, { status = value }, function(ok)
    if ok then
      notify(src, ('CopNet: Status → %s'):format(value))
      TriggerClientEvent('bl_copnet:statusChanged', src, value)
    else
      notify(src, 'CopNet: Status konnte nicht gesetzt werden.')
    end
    if cb then cb(ok) end
  end)
end

function BlCopNet.SetCallsign(src, callsign, cb)
  local discordId = requireDutyDiscord(src)
  if not discordId then
    if cb then cb(false) end
    return
  end
  local code = tostring(callsign or ''):gsub('^%s+', ''):gsub('%s+$', '')
  if code == '' or #code > 32 then
    notify(src, 'CopNet: Streifencode 1–32 Zeichen.')
    if cb then cb(false) end
    return
  end
  BlCopNet.SendEvent('unit_callsign', discordId, { callsign = code }, function(ok)
    if ok then
      notify(src, ('CopNet: Streifencode → %s'):format(code))
      TriggerClientEvent('bl_copnet:callsignChanged', src, code)
    else
      notify(src, 'CopNet: Streifencode fehlgeschlagen.')
    end
    if cb then cb(ok) end
  end)
end

function BlCopNet.TriggerPanic(src, payload, cb)
  if not BlCopNet.HasPanicItem(src) then
    local msg = tostring((Config.Panic and Config.Panic.missingMessage) or '')
    if msg ~= '' then
      notify(src, msg)
    end
    if cb then cb(false) end
    return
  end

  local discordId = requireDutyDiscord(src)
  if not discordId then
    if cb then cb(false) end
    return
  end

  local cooldown = tonumber(Config.Radial and Config.Radial.panicCooldownMs) or 60000
  local now = GetGameTimer()
  local untilTs = panicCooldownUntil[src] or 0
  if now < untilTs then
    local left = math.ceil((untilTs - now) / 1000)
    notify(src, ('CopNet: Panic-Cooldown (%ss)'):format(left))
    if cb then cb(false) end
    return
  end

  local body = type(payload) == 'table' and payload or {}
  BlCopNet.SendEvent('unit_panic', discordId, {
    x = body.x,
    y = body.y,
    locationText = body.locationText,
    note = body.note,
  }, function(ok)
    if ok then
      panicCooldownUntil[src] = now + cooldown
      notify(src, 'CopNet: PANIC ausgelöst – Dispatch alarmiert.')
      TriggerClientEvent('bl_copnet:panicSent', src)
    else
      notify(src, 'CopNet: Panic fehlgeschlagen.')
    end
    if cb then cb(ok) end
  end)
end

RegisterNetEvent('bl_copnet:setStatus', function(status)
  BlCopNet.SetUnitStatus(source, status)
end)

RegisterNetEvent('bl_copnet:setCallsign', function(callsign)
  BlCopNet.SetCallsign(source, callsign)
end)

RegisterNetEvent('bl_copnet:panic', function(payload)
  BlCopNet.TriggerPanic(source, payload)
end)

AddEventHandler('playerDropped', function()
  panicCooldownUntil[source] = nil
end)

RegisterCommand(Config.Commands.status, function(src, args)
  if src == 0 then return end
  BlCopNet.SetUnitStatus(src, args[1])
end, false)

RegisterCommand(Config.Commands.callsign, function(src, args)
  if src == 0 then return end
  BlCopNet.SetCallsign(src, table.concat(args or {}, ' '))
end, false)

RegisterCommand(Config.Commands.panic, function(src)
  if src == 0 then return end
  TriggerClientEvent('bl_copnet:requestPanic', src)
end, false)

CreateThread(function()
  local itemName = panicItemName()
  local cfg = Config.Panic or {}
  if not itemName or cfg.registerUsable == false then return end

  Wait(1500)
  ESX.RegisterUsableItem(itemName, function(source)
    TriggerClientEvent('bl_copnet:usePanicItem', source)
  end)
  BlCopNet.Debug('Panic usable Item registriert: %s', itemName)
end)
