local tracking = false
local lastLocalDuty = nil

local function readLocalOnDuty()
  local esxDuty = nil
  local ok, ESX = pcall(function()
    return exports['es_extended']:getSharedObject()
  end)
  if ok and ESX and ESX.PlayerData and ESX.PlayerData.job then
    local job = ESX.PlayerData.job
    local flag = job.onDuty
    if flag == nil then flag = job.onduty end
    if flag ~= nil then
      esxDuty = flag == true or flag == 1
    end
  end

  -- sky_jobs_base: nur true ist autoritativ; false darf ESX/LB Phone nicht blockieren
  if GetResourceState('sky_jobs_base') == 'started' then
    local skyOk, result = pcall(function()
      return exports['sky_jobs_base']:isOnDuty()
    end)
    if skyOk and result == true then
      return true
    end
  end

  -- State-Bag: nur true oder wenn ESX kein Flag hat
  local state = LocalPlayer and LocalPlayer.state
  if state then
    local flag = state.onDuty
    if flag == nil then flag = state.onduty end
    if flag ~= nil then
      local stateDuty = flag == true or flag == 1
      if stateDuty then return true end
      if esxDuty == nil then return false end
    end
  end

  return esxDuty
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

local function openCallsignDialog()
  if not tracking then
    notify('Streifencode nur on-duty.')
    return
  end
  CreateThread(function()
    Wait(250)
    if not tracking then return end
    local input = lib.inputDialog('Streifencode', {
      { type = 'input', label = 'Code', placeholder = 'L-21', required = true, max = 32 },
    })
    if not input or not input[1] then return end
    TriggerServerEvent('bl_copnet:setCallsign', input[1])
  end)
end

local function openTabletFromRadial()
  if not tracking then
    notify('Tablet nur on-duty.')
    return
  end
  CreateThread(function()
    Wait(200)
    if BlCopNetOpenTablet then BlCopNetOpenTablet() end
  end)
end

AddEventHandler('bl_copnet:openCallsignDialog', openCallsignDialog)
RegisterNetEvent('bl_copnet:openCallsignDialog', openCallsignDialog)
AddEventHandler('bl_copnet:radialTablet', openTabletFromRadial)

local RADIAL_IDS = {
  'copnet',
  'bl_copnet_root',
  'bl_copnet_status',
  'bl_copnet_callsign',
  'bl_copnet_tablet',
  'bl_copnet_panic',
  'copnet_status',
  'copnet_status_available',
  'copnet_status_enroute',
  'copnet_status_on_scene',
  'copnet_status_busy',
  'copnet_status_unavailable',
  'bl_copnet_status_available',
  'bl_copnet_status_enroute',
  'bl_copnet_status_on_scene',
  'bl_copnet_status_busy',
  'bl_copnet_status_unavailable',
}

local function buildStatusRadialSubmenu()
  local items = {}
  for _, entry in ipairs(Config.Statuses or {}) do
    local value = entry.value
    items[#items + 1] = {
      id = 'bl_copnet_status_' .. tostring(value),
      label = entry.label,
      description = 'CAD-Status setzen',
      icon = 'fa-solid fa-' .. tostring(entry.icon or 'circle'),
      action = function()
        TriggerServerEvent('bl_copnet:setStatus', value)
      end,
    }
  end
  return items
end

local function syncStgRadial()
  if GetResourceState('stg-radialmenu') ~= 'started' then return end

  for _, id in ipairs(RADIAL_IDS) do
    pcall(function()
      exports['stg-radialmenu']:removeRadialItem(id)
    end)
  end

  if not tracking then return end

  local submenuOk = pcall(function()
    exports['stg-radialmenu']:addRadialItem({
      id = 'copnet',
      label = 'CopNet',
      description = 'CAD-Status, Streifencode, Tablet und Panic',
      icon = 'fa-solid fa-shield-halved',
      submenu = {
        {
          id = 'bl_copnet_status',
          label = 'CAD-Status',
          description = 'AVL / ENR / ONS / BUSY / UNAV',
          icon = 'fa-solid fa-signal',
          submenu = buildStatusRadialSubmenu(),
        },
        {
          id = 'bl_copnet_callsign',
          label = 'Streifencode',
          description = 'Anzeige auf Live-Map / Dispatch',
          icon = 'fa-solid fa-hashtag',
          action = function()
            TriggerEvent('bl_copnet:openCallsignDialog')
          end,
        },
        {
          id = 'bl_copnet_tablet',
          label = 'CopNet-Tablet',
          description = 'Officer-CAD / volles CopNet',
          icon = 'fa-solid fa-tablet-screen-button',
          action = function()
            TriggerEvent('bl_copnet:radialTablet')
          end,
        },
        {
          id = 'bl_copnet_panic',
          label = 'PANIC',
          description = 'P1-Alarm an Dispatch',
          icon = 'fa-solid fa-triangle-exclamation',
          action = function()
            TriggerEvent('bl_copnet:requestPanic')
          end,
        },
      },
    })
  end)

  if submenuOk then return end

  -- Fallback ohne verschachteltes Submenü: Status-Einträge flach + Rest
  pcall(function()
    exports['stg-radialmenu']:addRadialItem({
      id = 'bl_copnet_root',
      label = 'CopNet',
      description = 'CAD-Status, Streifencode, Tablet und Panic',
      icon = 'fa-solid fa-shield-halved',
      submenu = (function()
        local items = buildStatusRadialSubmenu()
        items[#items + 1] = {
          id = 'bl_copnet_callsign',
          label = 'Streifencode',
          icon = 'fa-solid fa-hashtag',
          action = function()
            TriggerEvent('bl_copnet:openCallsignDialog')
          end,
        }
        items[#items + 1] = {
          id = 'bl_copnet_tablet',
          label = 'CopNet-Tablet',
          icon = 'fa-solid fa-tablet-screen-button',
          action = function()
            TriggerEvent('bl_copnet:radialTablet')
          end,
        }
        items[#items + 1] = {
          id = 'bl_copnet_panic',
          label = 'PANIC',
          icon = 'fa-solid fa-triangle-exclamation',
          action = function()
            TriggerEvent('bl_copnet:requestPanic')
          end,
        }
        return items
      end)(),
    })
  end)
end

RegisterNetEvent('bl_copnet:setTracking', function(enabled)
  tracking = enabled and true or false
  TriggerEvent('bl_copnet:dutyState', tracking)
  syncStgRadial()
end)

-- Client meldet nur einen Duty-Hint; Server entscheidet (Flag-Vorrang + Rate-Limit).
CreateThread(function()
  while true do
    Wait(1000)
    local duty = readLocalOnDuty()
    if type(duty) == 'boolean' and (duty ~= lastLocalDuty or duty ~= tracking) then
      lastLocalDuty = duty
      TriggerServerEvent('bl_copnet:clientDutySync', duty)
    end
  end
end)

RegisterNetEvent('esx:setJob', function(job)
  -- LB Phone / ESX schickt Job-Update inkl. onDuty oft nur clientseitig
  if type(job) == 'table' then
    local flag = job.onDuty
    if flag == nil then flag = job.onduty end
    if flag ~= nil then
      local duty = flag == true or flag == 1
      lastLocalDuty = duty
      TriggerServerEvent('bl_copnet:clientDutySync', duty)
      return
    end
  end
  TriggerServerEvent('bl_copnet:refreshDuty')
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

local function bootRadialAndDuty()
  Wait(800)
  syncStgRadial()
  TriggerServerEvent('bl_copnet:refreshDuty')
  local duty = readLocalOnDuty()
  if type(duty) == 'boolean' then
    lastLocalDuty = duty
    TriggerServerEvent('bl_copnet:clientDutySync', duty)
  end
end

CreateThread(function()
  bootRadialAndDuty()
end)

AddEventHandler('onClientResourceStart', function(resourceName)
  if resourceName == GetCurrentResourceName() or resourceName == 'stg-radialmenu' then
    CreateThread(bootRadialAndDuty)
  end
end)

exports('IsOnDuty', function()
  return tracking == true
end)

local keybinds = Config.Keybinds or {}

BlCopNetKeybinds.Register(keybinds.panic, 'bl_copnet_panic', function()
  sendPanic()
end, { button = true })

BlCopNetKeybinds.Register(keybinds.tablet, Config.Commands.tablet, function()
  if BlCopNetOpenTablet then BlCopNetOpenTablet() end
end)
