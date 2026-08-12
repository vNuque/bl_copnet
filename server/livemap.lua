BlCopNet = BlCopNet or {}

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
  -- Fallback ohne native base64-Lib
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

--- Karte + Bounds an CopNet pushen (Resource-Start / manuell).
function BlCopNet.UploadLiveMap(cb)
  local cfg = Config.LiveMap or {}
  if cfg.enabled == false then
    if cb then cb(false, { error = 'disabled' }) end
    return
  end

  local bounds = cfg.bounds or {
    xMin = -4000,
    xMax = 4500,
    yMin = -4000,
    yMax = 8000,
  }

  local body = {
    source = 'bl_copnet',
    bounds = {
      xMin = tonumber(bounds.xMin) or -4000,
      xMax = tonumber(bounds.xMax) or 4500,
      yMin = tonumber(bounds.yMin) or -4000,
      yMax = tonumber(bounds.yMax) or 8000,
    },
  }

  local fileName = tostring(cfg.imageFile or 'html/livemap-map.png')
  local raw = LoadResourceFile(GetCurrentResourceName(), fileName)
  if raw and #raw > 0 then
    local encoded = b64encode(raw)
    if not encoded then
      BlCopNet.Warn('LiveMap: Base64-Encode fehlgeschlagen')
      if cb then cb(false, { error = 'b64_failed' }) end
      return
    end
    body.imageBase64 = encoded
    body.contentType = cfg.contentType or contentTypeForPath(fileName)
    BlCopNet.Debug('LiveMap: lade %s (%d Bytes) hoch', fileName, #raw)
  else
    BlCopNet.Warn('LiveMap: Datei %s nicht gefunden – nur Bounds werden gesendet', fileName)
  end

  BlCopNet.UploadLivemapApi(body, function(ok, data)
    if ok then
      BlCopNet.Debug('LiveMap: CopNet-Karte aktualisiert (image=%s)', tostring(data and data.map and data.map.hasImage))
    else
      BlCopNet.Warn('LiveMap-Upload fehlgeschlagen: %s', tostring(data and (data.error or data.raw) or 'unknown'))
    end
    if cb then cb(ok, data) end
  end)
end

exports('UploadLiveMap', function(cb)
  return BlCopNet.UploadLiveMap(cb)
end)

CreateThread(function()
  local cfg = Config.LiveMap or {}
  if cfg.enabled == false or cfg.uploadOnStart == false then return end
  local delay = tonumber(cfg.uploadDelayMs) or 4000
  Wait(math.max(500, delay))
  BlCopNet.UploadLiveMap()
end)
