BlCopNet = BlCopNet or {}

local function trimSlash(url)
  return (tostring(url or ''):gsub('/+$', ''))
end

function BlCopNet.Debug(msg, ...)
  if not Config.Debug then return end
  print(('[bl_copnet] ' .. tostring(msg)):format(...))
end

function BlCopNet.Warn(msg, ...)
  print(('[bl_copnet] WARN ' .. tostring(msg)):format(...))
end

function BlCopNet.Request(method, path, body, cb)
  local token = tostring(Config.ApiToken or ''):gsub('%s+', '')
  local base = trimSlash(Config.ApiBaseUrl)
  if token == '' or base == '' then
    BlCopNet.Warn('ApiBaseUrl / ApiToken nicht gesetzt – Request übersprungen (%s)', path)
    if cb then cb(false, { error = 'not_configured' }) end
    return
  end

  local url = base .. path
  local payload = ''
  if method ~= 'GET' and method ~= 'HEAD' then
    payload = body and json.encode(body) or ''
  elseif type(body) == 'table' then
    local parts = {}
    for k, v in pairs(body) do
      parts[#parts + 1] = ('%s=%s'):format(tostring(k), tostring(v):gsub('([^%w%-_%.~])', function(c)
        return ('%%%02X'):format(string.byte(c))
      end))
    end
    if #parts > 0 then
      url = url .. (url:find('?', 1, true) and '&' or '?') .. table.concat(parts, '&')
    end
  end

  local headers = {
    ['Content-Type'] = 'application/json',
    ['x-copnet-fivem-token'] = token,
  }

  PerformHttpRequest(url, function(status, responseText, _)
    local ok = status >= 200 and status < 300
    local decoded = nil
    if responseText and responseText ~= '' then
      local success, data = pcall(json.decode, responseText)
      if success then decoded = data end
    end
    if not ok then
      BlCopNet.Warn('%s %s → HTTP %s %s', method, path, tostring(status), tostring(responseText):sub(1, 240))
    else
      BlCopNet.Debug('%s %s → HTTP %s', method, path, tostring(status))
    end
    if cb then cb(ok, decoded or { raw = responseText, status = status }) end
  end, method, payload, headers)
end

function BlCopNet.SendEvent(eventType, discordId, payload, cb)
  if not discordId or tostring(discordId) == '' then
    if cb then cb(false, { error = 'missing_discord' }) end
    return
  end
  BlCopNet.Request('POST', '/api/fivem/events', {
    eventType = eventType,
    discordId = tostring(discordId),
    payload = payload or {},
    process = true,
  }, cb)
end

function BlCopNet.SyncCharacter(character, cb)
  BlCopNet.Request('POST', '/api/fivem/persons/sync', character, cb)
end

function BlCopNet.SyncCharacters(characters, cb)
  BlCopNet.Request('POST', '/api/fivem/persons/sync/bulk', {
    characters = characters,
  }, cb)
end

--- Register-Lookups (Fahrzeug / Waffe / Person)

function BlCopNet.LookupVehicles(opts, cb)
  opts = type(opts) == 'table' and opts or { plate = opts }
  BlCopNet.Request('GET', '/api/fivem/vehicles', {
    plate = opts.plate,
    q = opts.q or opts.search,
    personId = opts.personId or opts.person_id,
    limit = opts.limit,
    includeAkte = opts.includeAkte == false and '0' or nil,
  }, function(ok, data)
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
  opts = type(opts) == 'table' and opts or { serial = opts }
  BlCopNet.Request('GET', '/api/fivem/weapons', {
    serial = opts.serial or opts.serialNumber,
    q = opts.q or opts.search,
    personId = opts.personId or opts.person_id,
    limit = opts.limit,
  }, function(ok, data)
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
  opts = type(opts) == 'table' and opts or { externalIdentifier = opts }
  BlCopNet.Request('GET', '/api/fivem/persons/lookup', {
    externalIdentifier = opts.externalIdentifier or opts.identifier or opts.external_id,
    personId = opts.personId or opts.person_id,
  }, function(ok, data)
    if cb then cb(ok, data) end
  end)
end
