local tracking = false

RegisterNetEvent('bl_copnet:setTracking', function(enabled)
  tracking = enabled and true or false
  TriggerEvent('bl_copnet:refreshRadial')
  TriggerEvent('bl_copnet:dutyState', tracking)
end)

CreateThread(function()
  local interval = tonumber(Config.PositionIntervalMs) or 15000
  if interval < 5000 then interval = 5000 end

  while true do
    Wait(interval)
    if tracking then
      local ped = PlayerPedId()
      if ped and ped ~= 0 then
        local coords = GetEntityCoords(ped)
        TriggerServerEvent('bl_copnet:position', coords.x, coords.y)
      end
    end
  end
end)

local function currentCoords()
  local ped = PlayerPedId()
  if not ped or ped == 0 then return nil end
  local c = GetEntityCoords(ped)
  return c.x + 0.0, c.y + 0.0, c.z + 0.0
end

local function notify(msg)
  lib.notify({ description = msg, type = 'inform' })
end

local function resolvePostal()
  local cfg = Config.Panic and Config.Panic.postal
  if type(cfg) ~= 'table' then return '' end
  local resource = tostring(cfg.resource or 'hex_finalhud')
  if resource == '' or GetResourceState(resource) ~= 'started' then return '' end

  local names = cfg.exports
  if type(names) ~= 'table' or #names == 0 then
    names = { 'GetPostal', 'getPostal', 'GetNearestPostal', 'getNearestPostal' }
  end

  for _, exportName in ipairs(names) do
    local ok, result = pcall(function()
      return exports[resource][exportName](exports[resource])
    end)
    if ok and result ~= nil then
      if type(result) == 'table' then
        local code = result.code or result.postal or result.Postal or result[1]
        if code ~= nil and tostring(code) ~= '' then
          return tostring(code)
        end
      else
        local text = tostring(result)
        if text ~= '' and text ~= 'nil' then
          return text
        end
      end
    end
  end
  return ''
end

local function buildPanicPayload()
  local ped = PlayerPedId()
  if not ped or ped == 0 then return nil end

  local coords = GetEntityCoords(ped)
  local x, y, z = coords.x + 0.0, coords.y + 0.0, coords.z + 0.0
  local streetHash, crossingHash = GetStreetNameAtCoord(x, y, z)
  local street = GetStreetNameFromHashKey(streetHash) or ''
  local crossing = GetStreetNameFromHashKey(crossingHash) or ''
  local zoneCode = GetNameOfZone(x, y, z) or ''
  local district = GetLabelText(zoneCode) or ''
  if district == 'NULL' or district == 'NULL_NULL' then district = zoneCode end

  local postal = resolvePostal()
  local heading = GetEntityHeading(ped) + 0.0
  local inVehicle = IsPedInAnyVehicle(ped, false)
  local vehicleLabel = ''
  local plate = ''
  if inVehicle then
    local veh = GetVehiclePedIsIn(ped, false)
    if veh and veh ~= 0 then
      plate = GetVehicleNumberPlateText(veh) or ''
      local model = GetEntityModel(veh)
      vehicleLabel = GetLabelText(GetDisplayNameFromVehicleModel(model)) or ''
      if vehicleLabel == 'NULL' then
        vehicleLabel = GetDisplayNameFromVehicleModel(model) or ''
      end
    end
  end

  local locationParts = {}
  if postal ~= '' then locationParts[#locationParts + 1] = ('PLZ %s'):format(postal) end
  if street ~= '' then locationParts[#locationParts + 1] = street end
  if crossing ~= '' and crossing ~= street then
    locationParts[#locationParts + 1] = ('Ecke %s'):format(crossing)
  end
  if district ~= '' then locationParts[#locationParts + 1] = district end

  return {
    x = x,
    y = y,
    z = z,
    heading = heading,
    street = street,
    crossing = crossing,
    district = district,
    zone = zoneCode,
    postal = postal,
    inVehicle = inVehicle and true or false,
    vehicle = vehicleLabel,
    plate = plate,
    locationText = table.concat(locationParts, ' · '),
  }
end

local function sendPanic()
  if not tracking then
    notify('Panic nur on-duty.')
    return
  end
  local payload = buildPanicPayload()
  if not payload then return end
  TriggerServerEvent('bl_copnet:panic', payload)
end

RegisterNetEvent('bl_copnet:requestPanic', sendPanic)
RegisterNetEvent('bl_copnet:usePanicItem', sendPanic)


local function openStatusMenu()
  local options = {}
  for _, entry in ipairs(Config.Statuses or {}) do
    options[#options + 1] = {
      title = entry.label,
      icon = entry.icon or 'circle',
      onSelect = function()
        TriggerServerEvent('bl_copnet:setStatus', entry.value)
      end,
    }
  end
  lib.registerContext({
    id = 'bl_copnet_status',
    title = 'CAD-Status',
    menu = 'bl_copnet_main',
    options = options,
  })
  lib.showContext('bl_copnet_status')
end

local function openCallsignDialog()
  local input = lib.inputDialog('Streifencode', {
    { type = 'input', label = 'Code', placeholder = 'L-21', required = true, max = 32 },
  })
  if not input or not input[1] then return end
  TriggerServerEvent('bl_copnet:setCallsign', input[1])
end

local function openMainMenu()
  if not tracking then
    notify('Einsatzmenü nur on-duty.')
    return
  end
  lib.registerContext({
    id = 'bl_copnet_main',
    title = 'CopNet Einsatz',
    options = {
      {
        title = 'CAD-Status',
        description = 'AVL / ENR / ONS / BUSY / UNAV',
        icon = 'signal',
        onSelect = openStatusMenu,
      },
      {
        title = 'Streifencode setzen',
        description = 'Anzeige auf Live-Map / Dispatch',
        icon = 'hashtag',
        onSelect = openCallsignDialog,
      },
      {
        title = 'CopNet-Tablet',
        description = 'Officer-CAD / volles CopNet',
        icon = 'tablet-screen-button',
        onSelect = function()
          if BlCopNetOpenTablet then BlCopNetOpenTablet() end
        end,
      },
      {
        title = 'PANIC',
        description = 'P1-Alarm an Dispatch',
        icon = 'triangle-exclamation',
        onSelect = sendPanic,
      },
    },
  })
  lib.showContext('bl_copnet_main')
end

local function registerRadial()
  if Config.Radial and Config.Radial.enabled == false then
    lib.removeRadialItem('bl_copnet_root')
    return
  end

  lib.removeRadialItem('bl_copnet_root')
  if not tracking then return end

  local statusItems = {}
  for _, entry in ipairs(Config.Statuses or {}) do
    statusItems[#statusItems + 1] = {
      label = entry.label,
      icon = entry.icon or 'circle',
      onSelect = function()
        TriggerServerEvent('bl_copnet:setStatus', entry.value)
      end,
    }
  end

  lib.registerRadial({
    id = 'bl_copnet_status_radial',
    items = statusItems,
  })

  lib.registerRadial({
    id = 'bl_copnet_main_radial',
    items = {
      {
        label = 'Status',
        icon = 'signal',
        menu = 'bl_copnet_status_radial',
      },
      {
        label = 'Streifencode',
        icon = 'hashtag',
        onSelect = openCallsignDialog,
      },
      {
        label = 'Tablet',
        icon = 'tablet-screen-button',
        onSelect = function()
          if BlCopNetOpenTablet then BlCopNetOpenTablet() end
        end,
      },
      {
        label = 'PANIC',
        icon = 'triangle-exclamation',
        onSelect = sendPanic,
      },
    },
  })

  lib.addRadialItem({
    id = 'bl_copnet_root',
    label = 'CopNet',
    icon = 'shield-halved',
    menu = 'bl_copnet_main_radial',
  })
end

AddEventHandler('bl_copnet:refreshRadial', registerRadial)

CreateThread(function()
  Wait(500)
  registerRadial()
end)

local keybinds = Config.Keybinds or {}

BlCopNetKeybinds.Register(keybinds.menu, Config.Commands.menu, function()
  openMainMenu()
end)

BlCopNetKeybinds.Register(keybinds.panic, 'bl_copnet_panic', function()
  sendPanic()
end, { button = true })

BlCopNetKeybinds.Register(keybinds.tablet, Config.Commands.tablet, function()
  if BlCopNetOpenTablet then BlCopNetOpenTablet() end
end)

