BlCopNet = BlCopNet or {}

local DATA = BlCopNetVehicleLabelData or {}

local function asU32(n)
  n = math.floor(tonumber(n) or 0)
  if n < 0 then n = n + 4294967296 end
  return n % 4294967296
end

local function asI32(n)
  n = asU32(n)
  if n > 2147483647 then return n - 4294967296 end
  return n
end

--- Hash / Spawn-Name → Anzeige-Label (serverseitig, ohne Online-Spieler).
--- Addon-Fahrzeuge: Config.VehicleLabels = { [`myaddon`] = 'Mein Auto', ['123456'] = '…' }
function BlCopNet.LookupVehicleLabel(model)
  if model == nil then return '' end

  local overrides = Config and Config.VehicleLabels
  if type(overrides) == 'table' then
    local key = tostring(model)
    if overrides[key] and tostring(overrides[key]) ~= '' then
      return tostring(overrides[key])
    end
    local num = tonumber(model)
    if num then
      local u, s = tostring(asU32(num)), tostring(asI32(num))
      if overrides[u] and tostring(overrides[u]) ~= '' then return tostring(overrides[u]) end
      if overrides[s] and tostring(overrides[s]) ~= '' then return tostring(overrides[s]) end
    elseif type(model) == 'string' and model ~= '' then
      local lower = model:lower()
      if overrides[lower] then return tostring(overrides[lower]) end
      local h = joaat(model)
      local u, s = tostring(asU32(h)), tostring(asI32(h))
      if overrides[u] then return tostring(overrides[u]) end
      if overrides[s] then return tostring(overrides[s]) end
    end
  end

  local key = tostring(model)
  if DATA[key] then return DATA[key] end

  local num = tonumber(model)
  if num then
    local hit = DATA[tostring(asU32(num))] or DATA[tostring(asI32(num))]
    if hit then return hit end
  elseif type(model) == 'string' and model ~= '' and not key:match('^-?%d+$') then
    local lower = model:lower()
    if DATA[lower] then return DATA[lower] end
    local h = joaat(model)
    local hit = DATA[tostring(asU32(h))] or DATA[tostring(asI32(h))]
    if hit then return hit end
    return (model:gsub('^%l', string.upper))
  end

  return key
end
