BlCopNet = BlCopNet or {}

--- Exports für andere Resources
--- exports['bl_copnet']:LookupVehicle('ABC123', function(ok, vehicle) ... end)
--- exports['bl_copnet']:LookupVehicles({ plate = 'ABC123' }, cb)
--- exports['bl_copnet']:LookupWeapon('SN-1', cb)
--- exports['bl_copnet']:LookupPerson({ identifier = 'char1:license:...' }, cb)

exports('LookupVehicles', function(opts, cb)
  BlCopNet.LookupVehicles(opts, cb)
end)

exports('LookupVehicle', function(plate, cb)
  BlCopNet.LookupVehicle(plate, cb)
end)

exports('LookupWeapons', function(opts, cb)
  BlCopNet.LookupWeapons(opts, cb)
end)

exports('LookupWeapon', function(serial, cb)
  BlCopNet.LookupWeapon(serial, cb)
end)

exports('LookupPerson', function(opts, cb)
  BlCopNet.LookupPerson(opts, cb)
end)

local function notify(src, msg)
  if src == 0 then
    print('[bl_copnet] ' .. tostring(msg))
    return
  end
  TriggerClientEvent('esx:showNotification', src, msg)
end

RegisterCommand('copnet_plate', function(src, args)
  local plate = table.concat(args or {}, ' '):gsub('^%s+', ''):gsub('%s+$', '')
  if plate == '' then
    notify(src, 'Usage: /copnet_plate <kennzeichen>')
    return
  end
  BlCopNet.LookupVehicles({ plate = plate }, function(ok, data)
    if not ok then
      notify(src, 'CopNet: Fahrzeug-Lookup fehlgeschlagen.')
      return
    end
    local list = data and data.vehicles or {}
    if #list == 0 then
      notify(src, ('CopNet: Kein Fahrzeug für %s'):format(plate))
      return
    end
    local v = list[1]
    local line = ('%s · %s %s · %s'):format(
      tostring(v.plate or plate),
      tostring(v.vehicleType or ''),
      tostring(v.model or ''),
      tostring(v.ownerLabel or v.statusLabel or v.status or '')
    )
    notify(src, 'CopNet: ' .. line)
    if #list > 1 then
      notify(src, ('(+%s weitere Treffer)'):format(#list - 1))
    end
    BlCopNet.Debug('plate lookup %s → %s', plate, json.encode(list))
  end)
end, false)

RegisterCommand('copnet_serial', function(src, args)
  local serial = table.concat(args or {}, ' '):gsub('^%s+', ''):gsub('%s+$', '')
  if serial == '' then
    notify(src, 'Usage: /copnet_serial <seriennummer>')
    return
  end
  BlCopNet.LookupWeapons({ serial = serial }, function(ok, data)
    if not ok then
      notify(src, 'CopNet: Waffen-Lookup fehlgeschlagen.')
      return
    end
    local list = data and data.weapons or {}
    if #list == 0 then
      notify(src, ('CopNet: Keine Waffe für %s'):format(serial))
      return
    end
    local w = list[1]
    notify(src, ('CopNet: %s · %s · %s'):format(
      tostring(w.serialNumber or serial),
      tostring(w.weaponType or ''),
      tostring(w.ownerLabel or w.statusLabel or '')
    ))
  end)
end, false)
