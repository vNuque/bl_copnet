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
  local payload = body and json.encode(body) or ''
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
