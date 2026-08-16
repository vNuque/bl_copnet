-- GTA/ESX Farbindizes → deutsche Anzeigenamen (Fahrzeugregister).
BlCopNet = BlCopNet or {}

local COLOR_NAMES = {
  [0] = 'Schwarz',
  [1] = 'Graphit',
  [2] = 'Schwarzstahl',
  [3] = 'Dunkelstahl',
  [4] = 'Silber',
  [5] = 'Blausilber',
  [6] = 'Stahlgrau',
  [7] = 'Schattensilber',
  [8] = 'Steinsilber',
  [9] = 'Mitternachtssilber',
  [10] = 'Gusseisen',
  [11] = 'Anthrazit',
  [12] = 'Matt Schwarz',
  [13] = 'Matt Grau',
  [14] = 'Matt Hellgrau',
  [15] = 'Util Schwarz',
  [16] = 'Util Schwarz',
  [17] = 'Util Dunkelsilber',
  [18] = 'Util Silber',
  [19] = 'Util Gunmetal',
  [20] = 'Util Schattensilber',
  [21] = 'Abgenutzt Schwarz',
  [22] = 'Abgenutzt Graphit',
  [23] = 'Abgenutzt Silbergrau',
  [24] = 'Abgenutzt Silber',
  [25] = 'Abgenutzt Blausilber',
  [26] = 'Abgenutzt Schattensilber',
  [27] = 'Rot',
  [28] = 'Torino Rot',
  [29] = 'Formel Rot',
  [30] = 'Blaze Rot',
  [31] = 'Grace Rot',
  [32] = 'Granatrot',
  [33] = 'Sonnenuntergang Rot',
  [34] = 'Cabernet Rot',
  [35] = 'Candy Rot',
  [36] = 'Sonnenaufgang Orange',
  [37] = 'Classic Gold',
  [38] = 'Orange',
  [39] = 'Matt Rot',
  [40] = 'Matt Dunkelrot',
  [41] = 'Matt Orange',
  [42] = 'Matt Gelb',
  [43] = 'Util Rot',
  [44] = 'Util Hellrot',
  [45] = 'Util Granatrot',
  [46] = 'Abgenutzt Rot',
  [47] = 'Abgenutzt Goldenrot',
  [48] = 'Abgenutzt Dunkelrot',
  [49] = 'Dunkelgrün',
  [50] = 'Racing Grün',
  [51] = 'Seegrün',
  [52] = 'Olivgrün',
  [53] = 'Hellgrün',
  [54] = 'Benzin Grün',
  [55] = 'Matt Limette',
  [56] = 'Util Dunkelgrün',
  [57] = 'Util Grün',
  [58] = 'Abgenutzt Dunkelgrün',
  [59] = 'Abgenutzt Grün',
  [60] = 'Abgenutzt Meeresgrün',
  [61] = 'Galaxy Blau',
  [62] = 'Dunkelblau',
  [63] = 'Saxony Blau',
  [64] = 'Blau',
  [65] = 'Mariner Blau',
  [66] = 'Hafenblau',
  [67] = 'Diamantblau',
  [68] = 'Surfblau',
  [69] = 'Nautikblau',
  [70] = 'Ultrablau',
  [71] = 'Schafter Lila',
  [72] = 'Spinnaker Lila',
  [73] = 'Racing Blau',
  [74] = 'Hellblau',
  [75] = 'Util Dunkelblau',
  [76] = 'Util Mitternachtsblau',
  [77] = 'Util Blau',
  [78] = 'Util Seeblau',
  [79] = 'Util Lightning Blau',
  [80] = 'Util Maui Blau',
  [81] = 'Util Hellblau',
  [82] = 'Matt Dunkelblau',
  [83] = 'Matt Blau',
  [84] = 'Matt Mitternachtsblau',
  [85] = 'Abgenutzt Dunkelblau',
  [86] = 'Abgenutzt Blau',
  [87] = 'Abgenutzt Hellblau',
  [88] = 'Gelb',
  [89] = 'Racing Gelb',
  [90] = 'Bronze',
  [91] = 'Taugelb',
  [92] = 'Limettengrün',
  [93] = 'Util Champagner',
  [94] = 'Feltzer Braun',
  [95] = 'Creek Braun',
  [96] = 'Schokobraun',
  [97] = 'Ahornbraun',
  [98] = 'Sattelbraun',
  [99] = 'Strohbraun',
  [100] = 'Moosbraun',
  [101] = 'Bisonbraun',
  [102] = 'Woodbeech Braun',
  [103] = 'Buchenbraun',
  [104] = 'Sienna Braun',
  [105] = 'Sandbraun',
  [106] = 'Gebleicht Braun',
  [107] = 'Creme',
  [108] = 'Util Braun',
  [109] = 'Util Mittelbraun',
  [110] = 'Util Hellbraun',
  [111] = 'Eisweiß',
  [112] = 'Frostweiß',
  [113] = 'Abgenutzt Honigbeige',
  [114] = 'Abgenutzt Braun',
  [115] = 'Abgenutzt Dunkelbraun',
  [116] = 'Abgenutzt Strohbeige',
  [117] = 'Gebürsteter Stahl',
  [118] = 'Gebürsteter Schwarzstahl',
  [119] = 'Gebürstetes Aluminium',
  [120] = 'Chrom',
  [121] = 'Abgenutzt Off-White',
  [122] = 'Util Off-White',
  [123] = 'Abgenutzt Orange',
  [124] = 'Abgenutzt Hellorange',
  [125] = 'Securicor Grün',
  [126] = 'Abgenutzt Taxi Gelb',
  [127] = 'Polizei Blau',
  [128] = 'Matt Grün',
  [129] = 'Matt Braun',
  [130] = 'Abgenutzt Orange',
  [131] = 'Matt Weiß',
  [132] = 'Abgenutzt Weiß',
  [133] = 'Abgenutzt Olivgrün',
  [134] = 'Reinweiß',
  [135] = 'Hot Pink',
  [136] = 'Lachsrosa',
  [137] = 'Pfister Pink',
  [138] = 'Hellorange',
  [139] = 'Grün',
  [140] = 'Blau',
  [141] = 'Mitternachtsblau',
  [142] = 'Mitternachtlila',
  [143] = 'Weinrot',
  [144] = 'Huntergrün',
  [145] = 'Helllila',
  [146] = 'Dunkelblau',
  [147] = 'Carbon Schwarz',
  [148] = 'Matt Schafter Lila',
  [149] = 'Matt Mitternachtlila',
  [150] = 'Lava Rot',
  [151] = 'Matt Waldgrün',
  [152] = 'Matt Oliv',
  [153] = 'Matt Wüstenbraun',
  [154] = 'Matt Wüstentan',
  [155] = 'Matt Laubgrün',
  [156] = 'Default Alloy',
  [157] = 'Epsilon Blau',
  [158] = 'Reines Gold',
  [159] = 'Gebürstetes Gold',
  [160] = 'MP Gold',
}

local function decodeJson(raw)
  if type(raw) == 'table' then return raw end
  if type(raw) ~= 'string' or raw == '' then return {} end
  local ok, data = pcall(json.decode, raw)
  if ok and type(data) == 'table' then return data end
  return {}
end

local function rgbChannel(v)
  local n = tonumber(v)
  if not n then return nil end
  if n >= 0 and n <= 1 then n = n * 255 end
  return math.floor(math.max(0, math.min(255, n)) + 0.5)
end

--- RGB → grober deutscher Farbname (Custom-Lackierung).
local function nameFromRgb(r, g, b)
  r, g, b = rgbChannel(r), rgbChannel(g), rgbChannel(b)
  if not r or not g or not b then return '' end

  local maxv = math.max(r, g, b)
  local minv = math.min(r, g, b)
  local delta = maxv - minv

  if maxv < 28 then return 'Schwarz' end
  if minv > 230 and delta < 25 then return 'Weiß' end
  if delta < 18 then
    if maxv < 70 then return 'Schwarz' end
    if maxv < 120 then return 'Dunkelgrau' end
    if maxv < 180 then return 'Grau' end
    if maxv < 220 then return 'Hellgrau' end
    return 'Silber'
  end

  local h
  if delta == 0 then
    h = 0
  elseif maxv == r then
    h = 60 * (((g - b) / delta) % 6)
  elseif maxv == g then
    h = 60 * (((b - r) / delta) + 2)
  else
    h = 60 * (((r - g) / delta) + 4)
  end
  if h < 0 then h = h + 360 end

  local s = maxv == 0 and 0 or (delta / maxv)
  local l = (maxv + minv) / (2 * 255)

  if s < 0.18 then
    if l < 0.25 then return 'Dunkelgrau' end
    if l < 0.55 then return 'Grau' end
    return 'Hellgrau'
  end

  if h < 15 or h >= 345 then
    return l < 0.35 and 'Dunkelrot' or 'Rot'
  elseif h < 40 then
    return 'Orange'
  elseif h < 70 then
    return l > 0.55 and 'Gelb' or 'Gold'
  elseif h < 160 then
    return l < 0.35 and 'Dunkelgrün' or 'Grün'
  elseif h < 200 then
    return 'Türkis'
  elseif h < 255 then
    return l < 0.35 and 'Dunkelblau' or 'Blau'
  elseif h < 290 then
    return 'Lila'
  elseif h < 330 then
    return 'Pink'
  end
  return 'Rot'
end

local function nameFromColorValue(value)
  if value == nil then return '' end
  if type(value) == 'table' then
    local r = value.r or value[1] or value.R
    local g = value.g or value[2] or value.G
    local b = value.b or value[3] or value.B
    return nameFromRgb(r, g, b)
  end
  if type(value) == 'number' or tostring(value):match('^-?%d+$') then
    local idx = tonumber(value)
    if idx == nil then return '' end
    return COLOR_NAMES[idx] or ('Farbe ' .. tostring(idx))
  end
  local text = tostring(value):gsub('^%s+', ''):gsub('%s+$', '')
  if text == '' then return '' end
  return text:sub(1, 40)
end

local function firstColor(props, keys)
  for _, key in ipairs(keys) do
    local val = props[key]
    if val ~= nil then
      local name = nameFromColorValue(val)
      if name ~= '' then return name end
    end
  end
  return ''
end

--- Farbe aus owned_vehicles-Zeile / ESX vehicle-JSON lesen.
function BlCopNet.LookupVehicleColor(row)
  if type(row) ~= 'table' then return '' end

  for _, key in ipairs({ 'color', 'colour', 'color_name', 'vehicle_color' }) do
    local direct = row[key]
    if direct ~= nil and tostring(direct) ~= '' and not tostring(direct):match('^[%[{]') then
      local name = nameFromColorValue(direct)
      if name ~= '' then return name end
    end
  end

  local props = decodeJson(row.vehicle or row.mods or row.props or {})
  local primary = firstColor(props, {
    'customPrimaryColour', 'customPrimaryColor',
    'color1', 'colour1', 'primaryColor', 'primaryColour',
  })
  local secondary = firstColor(props, {
    'customSecondaryColour', 'customSecondaryColor',
    'color2', 'colour2', 'secondaryColor', 'secondaryColour',
  })

  if primary == '' and secondary == '' then
    -- Manche Garagen legen Farben flach ab
    primary = firstColor(row, { 'color1', 'colour1' })
    secondary = firstColor(row, { 'color2', 'colour2' })
  end

  if primary ~= '' and secondary ~= '' and primary ~= secondary then
    local combined = primary .. ' / ' .. secondary
    return combined:sub(1, 40)
  end
  return (primary ~= '' and primary or secondary):sub(1, 40)
end
