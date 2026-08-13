BlCopNet = BlCopNet or {}

-- Einzige erlaubte HTTP-Schicht zur Website
local API = 'BL_CopNet_API'

local function apiStarted()
  return GetResourceState(API) == 'started'
end

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

--- Öffentliche CopNet-URL nur für Browser/Tablet-Iframe (kein Token).
--- Kommt aus Convar der API-Resource – bl_copnet speichert kein Secret.
function BlCopNet.GetApiBaseUrl()
  return (GetConvar('BL_CopNet_API_url', '') or ''):gsub('/+$', '')
end

local function requireApi(cb, label)
  if apiStarted() then return true end
  BlCopNet.Warn('%s: %s nicht gestartet – keine Direkt-Kommunikation zur Website.', tostring(label or 'API'), API)
  if cb then cb(false, { error = 'api_resource_missing', resource = API }) end
  return false
end

--- Generischer Call nur über BL_CopNet_API (nie PerformHttpRequest → CopNet).
function BlCopNet.Request(method, path, body, cb)
  if not requireApi(cb, 'Request') then return end
  local ok, err = pcall(function()
    api():request(method, path, body, cb)
  end)
  if not ok then
    BlCopNet.Warn('BL_CopNet_API:request fehlgeschlagen: %s', tostring(err))
    if cb then cb(false, { error = 'api_call_failed', detail = tostring(err) }) end
  end
end

local function call(exportName, cb, invoker)
  if not requireApi(cb, exportName) then return end
  local ok, err = pcall(invoker)
  if not ok then
    BlCopNet.Warn('BL_CopNet_API:%s fehlgeschlagen: %s', tostring(exportName), tostring(err))
    if cb then cb(false, { error = 'api_call_failed', export = exportName, detail = tostring(err) }) end
  end
end

function BlCopNet.SendEvent(eventType, discordId, payload, cb)
  call('sendEvent', cb, function()
    api():sendEvent(eventType, discordId, payload, cb)
  end)
end

function BlCopNet.SyncCharacter(character, cb)
  call('syncPerson', cb, function()
    api():syncPerson(character, cb)
  end)
end

function BlCopNet.SyncCharacters(characters, cb)
  call('syncPersonsBulk', cb, function()
    api():syncPersonsBulk(characters, cb)
  end)
end

function BlCopNet.LookupVehicles(opts, cb)
  call('lookupVehicles', cb, function()
    api():lookupVehicles(opts, cb)
  end)
end

function BlCopNet.LookupVehicle(plate, cb)
  BlCopNet.LookupVehicles({ plate = plate }, function(ok, data)
    local vehicle = ok and data and data.vehicles and data.vehicles[1] or nil
    if cb then cb(ok and vehicle ~= nil, vehicle or data) end
  end)
end

function BlCopNet.LookupWeapons(opts, cb)
  call('lookupWeapons', cb, function()
    api():lookupWeapons(opts, cb)
  end)
end

function BlCopNet.LookupWeapon(serial, cb)
  BlCopNet.LookupWeapons({ serial = serial }, function(ok, data)
    local weapon = ok and data and data.weapons and data.weapons[1] or nil
    if cb then cb(ok and weapon ~= nil, weapon or data) end
  end)
end

function BlCopNet.LookupPerson(opts, cb)
  call('lookupPerson', cb, function()
    api():lookupPerson(opts, cb)
  end)
end

function BlCopNet.GetAssignedDispatch(discordId, cb)
  call('getAssignedDispatch', cb, function()
    api():getAssignedDispatch(discordId, cb)
  end)
end

function BlCopNet.AckDispatchCall(callId, discordId, action, cb)
  call('ackDispatchCall', cb, function()
    api():ackDispatchCall(callId, discordId, action, cb)
  end)
end

function BlCopNet.SendCadAlert(body, cb)
  call('sendCadAlert', cb, function()
    api():sendCadAlert(body, cb)
  end)
end

function BlCopNet.UploadLivemapApi(body, cb)
  call('uploadLivemap', cb, function()
    api():uploadLivemap(body, cb)
  end)
end

function BlCopNet.GetLivemapMeta(cb)
  call('getLivemap', cb, function()
    api():getLivemap(cb)
  end)
end

function BlCopNet.CreateAuthTicket(discordId, redirect, cb)
  call('createAuthTicket', cb, function()
    api():createAuthTicket(discordId, redirect, cb)
  end)
end
