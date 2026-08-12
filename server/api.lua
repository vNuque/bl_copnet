BlCopNet = BlCopNet or {}

local API = 'BL_CopNet_API'

local function api()
  return exports[API]
end

function BlCopNet.Debug(msg, ...)
  if not Config.Debug then return end
  print(('[bl_copnet] ' .. tostring(msg)):format(...))
end

function BlCopNet.Warn(msg, ...)
  print(('[bl_copnet] WARN ' .. tostring(msg)):format(...))
end

function BlCopNet.GetApiBaseUrl()
  return (GetConvar('BL_CopNet_API_url', '') or ''):gsub('/+$', '')
end

function BlCopNet.SendEvent(eventType, discordId, payload, cb)
  api():sendEvent(eventType, discordId, payload, function(ok, data)
    if cb then cb(ok, data) end
  end)
end

function BlCopNet.SyncCharacter(character, cb)
  api():syncPerson(character, function(ok, data)
    if cb then cb(ok, data) end
  end)
end

function BlCopNet.SyncCharacters(characters, cb)
  api():syncPersonsBulk(characters, function(ok, data)
    if cb then cb(ok, data) end
  end)
end

function BlCopNet.LookupVehicles(opts, cb)
  api():lookupVehicles(opts, function(ok, data)
    if cb then cb(ok, data) end
  end)
end

function BlCopNet.LookupVehicle(plate, cb)
  BlCopNet.LookupVehicles({ plate = plate }, function(ok, data)
    local vehicle = ok and data and data.vehicles and data.vehicles[1] or nil
    if cb then cb(ok and vehicle ~= nil, vehicle or data) end
  end)
end

function BlCopNet.LookupWeapons(opts, cb)
  api():lookupWeapons(opts, function(ok, data)
    if cb then cb(ok, data) end
  end)
end

function BlCopNet.LookupWeapon(serial, cb)
  BlCopNet.LookupWeapons({ serial = serial }, function(ok, data)
    local weapon = ok and data and data.weapons and data.weapons[1] or nil
    if cb then cb(ok and weapon ~= nil, weapon or data) end
  end)
end

function BlCopNet.LookupPerson(opts, cb)
  api():lookupPerson(opts, function(ok, data)
    if cb then cb(ok, data) end
  end)
end

function BlCopNet.GetAssignedDispatch(discordId, cb)
  api():getAssignedDispatch(discordId, function(ok, data)
    if cb then cb(ok, data) end
  end)
end

function BlCopNet.AckDispatchCall(callId, discordId, action, cb)
  api():ackDispatchCall(callId, discordId, action, function(ok, data)
    if cb then cb(ok, data) end
  end)
end

function BlCopNet.SendCadAlert(body, cb)
  api():sendCadAlert(body, function(ok, data)
    if cb then cb(ok, data) end
  end)
end

function BlCopNet.UploadLivemapApi(body, cb)
  api():uploadLivemap(body, function(ok, data)
    if cb then cb(ok, data) end
  end)
end

function BlCopNet.CreateAuthTicket(discordId, redirect, cb)
  api():createAuthTicket(discordId, redirect, function(ok, data)
    if cb then cb(ok, data) end
  end)
end
