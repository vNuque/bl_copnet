BlCopNet = BlCopNet or {}

local cachedMap = { bytes = nil, contentType = 'image/png', path = nil }

local function contentTypeForPath(filePath)
  local lower = tostring(filePath or ''):lower()
  if lower:match('%.jpe?g$') then return 'image/jpeg' end
  if lower:match('%.webp$') then return 'image/webp' end
  if lower:match('%.gif$') then return 'image/gif' end
  return 'image/png'
end

local function b64encode(data)
  if not data or data == '' then return nil end
  if type(base64) == 'table' and base64.encode then
    return base64.encode(data)
  end
  local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  return ((data:gsub('.', function(x)
    local r, byte = '', x:byte()
    for i = 8, 1, -1 do
      r = r .. (byte % 2 ^ i - byte % 2 ^ (i - 1) > 0 and '1' or '0')
    end
    return r
  end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
    if #x < 6 then return '' end
    local c = 0
    for i = 1, 6 do
      c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0)
    end
    return b:sub(c + 1, c + 1)
  end) .. ({ '', '==', '=' })[#data % 3 + 1])
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
  -- häufige Map-Resources auf dem Server (falls vorhanden)
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
          if raw and #raw > 512 then -- Platzhalter (<512B) ignorieren
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

--- Karte vom Gameserver greifen und nach CopNet laden.
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

  local mode = tostring(cfg.mode or 'auto'):lower()
  local publicBase = tostring(cfg.publicBaseUrl or ''):gsub('/+$', '')

  -- Mode fetch: CopNet holt die Karte selbst vom öffentlichen FiveM-HTTP
  if (mode == 'fetch' or (mode == 'auto' and publicBase ~= '')) and publicBase ~= '' then
    local fetchUrl = publicBase .. '/' .. GetCurrentResourceName() .. '/livemap-map'
    body.fetchUrl = fetchUrl
    BlCopNet.Debug('LiveMap: CopNet soll Karte von %s laden', fetchUrl)
    return pushBodyToCopNet(body, function(ok, data)
      if ok then
        BlCopNet.Debug('LiveMap: CopNet-Fetch ok (image=%s)', tostring(data and data.map and data.map.hasImage))
      else
        BlCopNet.Warn('LiveMap-Fetch fehlgeschlagen: %s – versuche lokalen Upload', tostring(data and (data.error or data.raw) or '?'))
        -- Fallback: lokale Datei hochladen
        BlCopNet.UploadLiveMapLocal(cb)
        return
      end
      if cb then cb(ok, data) end
    end)
  end

  return BlCopNet.UploadLiveMapLocal(cb)
end

function BlCopNet.UploadLiveMapLocal(cb)
  local cfg = Config.LiveMap or {}
  local body = {
    source = 'bl_copnet',
    bounds = boundsFromConfig(cfg),
  }

  local function finishWithBytes(raw, contentType, label)
    if not raw or #raw == 0 then
      BlCopNet.Warn('LiveMap: keine Kartendaten (%s)', tostring(label))
      if cb then cb(false, { error = 'no_map_data' }) end
      return
    end
    if #raw < 512 then
      BlCopNet.Warn('LiveMap: Datei zu klein (%d B) – echte Satmap setzen (sourceResource/imagePath/sourceUrl)', #raw)
      if cb then cb(false, { error = 'map_too_small' }) end
      return
    end
    cacheMap(raw, contentType, label)
    local encoded = b64encode(raw)
    if not encoded then
      if cb then cb(false, { error = 'b64_failed' }) end
      return
    end
    body.imageBase64 = encoded
    body.contentType = contentType
    BlCopNet.Debug('LiveMap: lade %s (%d Bytes) nach CopNet', tostring(label), #raw)
    pushBodyToCopNet(body, function(ok, data)
      if ok then
        BlCopNet.Debug('LiveMap: CopNet-Karte aktualisiert (image=%s)', tostring(data and data.map and data.map.hasImage))
      else
        BlCopNet.Warn('LiveMap-Upload fehlgeschlagen: %s', tostring(data and (data.error or data.raw) or 'unknown'))
      end
      if cb then cb(ok, data) end
    end)
  end

  -- 1) Direkt vom Gameserver-Dateisystem (andere Resource / Pfad)
  local path, raw, resName = BlCopNet.ResolveLiveMapPath()
  if raw then
    return finishWithBytes(raw, cfg.contentType or contentTypeForPath(path), path or resName)
  end

  -- 2) Optional: Script lädt echte Karte von URL und pusht sie
  local sourceUrl = tostring(cfg.sourceUrl or ''):gsub('%s+', '')
  if sourceUrl ~= '' then
    BlCopNet.Debug('LiveMap: lade Karte von URL %s', sourceUrl)
    PerformHttpRequest(sourceUrl, function(status, data, headers)
      if status < 200 or status >= 300 or not data or data == '' then
        BlCopNet.Warn('LiveMap: sourceUrl HTTP %s', tostring(status))
        if cb then cb(false, { error = 'source_url_failed', status = status }) end
        return
      end
      local ct = cfg.contentType
      if not ct and type(headers) == 'table' then
        ct = headers['Content-Type'] or headers['content-type']
      end
      finishWithBytes(data, ct or contentTypeForPath(sourceUrl), sourceUrl)
    end, 'GET', '', {})
    return
  end

  BlCopNet.Warn('LiveMap: keine echte Karte auf dem Server gefunden. Config.LiveMap.sourceResource / imagePath / sourceUrl setzen.')
  -- Bounds trotzdem senden
  pushBodyToCopNet(body, cb)
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
      local mode = tostring(cfg.mode or 'auto'):lower()
      if mode ~= 'fetch' and mode ~= 'auto' then
        res.writeHead(404, { ['Content-Type'] = 'text/plain' })
        res.send('livemap http disabled')
        return
      end

      local expected = tostring(GetConvar('BL_CopNet_API_token', '') or ''):gsub('%s+', '')
      local headers = req.headers or {}
      local provided = tostring(
        headers['x-copnet-fivem-token']
        or headers['X-CopNet-Fivem-Token']
        or ''
      ):gsub('%s+', '')
      -- Query ?token= als Fallback für manuelle Checks
      if provided == '' and req.path then
        local q = tostring(req.path)
        -- FiveM liefert Query oft in req.path? Einige Builds: req.qs / separate
      end
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
  -- Karte cachen (für HTTP-Handler) und nach CopNet pushen
  local path, raw = BlCopNet.ResolveLiveMapPath()
  if raw then
    cacheMap(raw, (Config.LiveMap or {}).contentType or contentTypeForPath(path), path)
  end
  BlCopNet.UploadLiveMap()
end)
