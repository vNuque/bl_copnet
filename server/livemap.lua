BlCopNet = BlCopNet or {}

local cachedMap = { bytes = nil, contentType = 'image/png', path = nil }

local function contentTypeForPath(filePath)
  local lower = tostring(filePath or ''):lower()
  if lower:match('%.jpe?g$') then return 'image/jpeg' end
  if lower:match('%.webp$') then return 'image/webp' end
  if lower:match('%.gif$') then return 'image/gif' end
  return 'image/png'
end

local function readBinaryFile(absPath)
  if not absPath or absPath == '' then return nil end
  local f = io.open(absPath, 'rb')
  if not f then return nil end
  local data = f:read('*a')
  f:close()
  if not data or #data == 0 then return nil end
  return data
end

--- Echte Karte vom Gameserver auflösen (andere Resource / Pfad / eigene Datei).
function BlCopNet.ResolveLiveMapPath()
  local cfg = Config.LiveMap or {}
  if cfg.imagePath and tostring(cfg.imagePath) ~= '' then
    return tostring(cfg.imagePath)
  end

  local rel = tostring(cfg.imageFile or 'html/livemap-map.png'):gsub('^[/\\]+', '')
  local sources = {}

  local srcRes = tostring(cfg.sourceResource or ''):gsub('%s+', '')
  if srcRes ~= '' then
    sources[#sources + 1] = srcRes
  end
  if type(cfg.sourceResourceFallbacks) == 'table' then
    for _, name in ipairs(cfg.sourceResourceFallbacks) do
      sources[#sources + 1] = tostring(name)
    end
  end
  sources[#sources + 1] = GetCurrentResourceName()

  local seen = {}
  for _, resName in ipairs(sources) do
    if resName and resName ~= '' and not seen[resName] then
      seen[resName] = true
      if GetResourceState(resName) == 'started' or GetResourceState(resName) == 'stopped' or resName == GetCurrentResourceName() then
        local base = GetResourcePath(resName)
        if base and base ~= '' then
          local full = (base:gsub('[/\\]+$', '') .. '/' .. rel):gsub('\\', '/')
          local raw = readBinaryFile(full)
          if raw and #raw > 512 then
            return full, raw, resName
          end
        end
      end
    end
  end
  return nil, nil, nil
end

local function cacheMap(bytes, contentType, path)
  cachedMap.bytes = bytes
  cachedMap.contentType = contentType or 'image/png'
  cachedMap.path = path
end

local function pushBodyToCopNet(body, cb)
  if not BlCopNet.UploadLivemapApi then
    BlCopNet.Warn('LiveMap: UploadLivemapApi fehlt')
    if cb then cb(false, { error = 'no_api' }) end
    return
  end
  return BlCopNet.UploadLivemapApi(body, cb)
end

local function boundsFromConfig(cfg)
  local bounds = (cfg and cfg.bounds) or {}
  return {
    xMin = tonumber(bounds.xMin) or -4000,
    xMax = tonumber(bounds.xMax) or 4500,
    yMin = tonumber(bounds.yMin) or -4000,
    yMax = tonumber(bounds.yMax) or 8000,
  }
end

local function resolvePublicBase(cfg)
  local publicBase = tostring(cfg.publicBaseUrl or GetConvar('BL_CopNet_livemap_public_url', '') or ''):gsub('/+$', '')
  if publicBase ~= '' then return publicBase end
  local listingIp = tostring(GetConvar('sv_listingIPOverride', '') or ''):gsub('%s+', '')
  if listingIp ~= '' and listingIp ~= '0.0.0.0' and listingIp ~= '::' then
    local port = tostring(GetConvar('netPort', '') or '')
    if port == '' then port = '30120' end
    return ('http://%s:%s'):format(listingIp, port)
  end
  return ''
end

--- Nur Fetch/Bounds an CopNet. Kein Base64-Upload (HTTP 413).
function BlCopNet.UploadLiveMap(cb)
  local cfg = Config.LiveMap or {}
  if cfg.enabled == false then
    if cb then cb(false, { error = 'disabled' }) end
    return
  end

  local body = {
    source = 'bl_copnet',
    bounds = boundsFromConfig(cfg),
  }

  local publicBase = resolvePublicBase(cfg)
  if publicBase ~= '' then
    body.fetchUrl = publicBase .. '/' .. GetCurrentResourceName() .. '/livemap-map'
    BlCopNet.Debug('LiveMap: CopNet soll Karte von %s laden', body.fetchUrl)
  else
    BlCopNet.Warn('LiveMap: kein publicBaseUrl – nur Bounds, kein Kartenbild')
  end

  return pushBodyToCopNet(body, function(ok, data)
    if ok then
      BlCopNet.Debug('LiveMap: CopNet-Fetch ok (image=%s)', tostring(data and data.map and data.map.hasImage))
    else
      BlCopNet.Warn('LiveMap-Fetch fehlgeschlagen: %s', tostring(data and (data.error or data.raw) or '?'))
    end
    if cb then cb(ok, data) end
  end)
end

exports('UploadLiveMap', function(cb)
  return BlCopNet.UploadLiveMap(cb)
end)

-- FiveM-HTTP: CopNet holt die Server-Karte unter /bl_copnet/livemap-map (Token Pflicht)
CreateThread(function()
  SetHttpHandler(function(req, res)
    local p = tostring(req.path or '')
    if p == '/livemap-map' or p == '/livemap-map.png' or p == '/livemap-map.jpg' then
      local cfg = Config.LiveMap or {}
      local expected = tostring(GetConvar('BL_CopNet_API_token', '') or ''):gsub('%s+', '')
      local headers = req.headers or {}
      local provided = tostring(
        headers['x-copnet-fivem-token']
        or headers['X-CopNet-Fivem-Token']
        or ''
      ):gsub('%s+', '')
      if type(req.query) == 'table' and req.query.token then
        provided = tostring(req.query.token):gsub('%s+', '')
      end
      if expected == '' or provided == '' or provided ~= expected then
        res.writeHead(401, { ['Content-Type'] = 'text/plain' })
        res.send('unauthorized')
        return
      end

      if not cachedMap.bytes then
        local _, raw = BlCopNet.ResolveLiveMapPath()
        if raw then
          cacheMap(raw, cfg.contentType or contentTypeForPath(cfg.imageFile or cfg.imagePath), 'http-resolve')
        end
      end
      if not cachedMap.bytes then
        res.writeHead(404, { ['Content-Type'] = 'text/plain' })
        res.send('livemap not found')
        return
      end
      res.writeHead(200, {
        ['Content-Type'] = cachedMap.contentType or 'image/png',
        ['Cache-Control'] = 'private, max-age=60',
      })
      res.send(cachedMap.bytes)
      return
    end
    res.writeHead(404)
    res.send('')
  end)
end)

CreateThread(function()
  local cfg = Config.LiveMap or {}
  if cfg.enabled == false or cfg.uploadOnStart == false then return end
  local delay = tonumber(cfg.uploadDelayMs) or 4000
  Wait(math.max(500, delay))
  local path, raw = BlCopNet.ResolveLiveMapPath()
  if raw then
    cacheMap(raw, (Config.LiveMap or {}).contentType or contentTypeForPath(path), path)
  end
  BlCopNet.UploadLiveMap()
end)
