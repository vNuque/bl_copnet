local tabletOpen = false
local tabletProp = nil
local tabletAnimActive = false

local function notify(msg, typ)
  lib.notify({ description = msg, type = typ or 'inform' })
end

local function tabletCfg()
  return Config.Tablet or {}
end

local function loadAnimDict(dict)
  if not dict or dict == '' or HasAnimDictLoaded(dict) then return true end
  RequestAnimDict(dict)
  local timeout = GetGameTimer() + 5000
  while not HasAnimDictLoaded(dict) do
    if GetGameTimer() > timeout then return false end
    Wait(10)
  end
  return true
end

local function loadModel(model)
  if type(model) == 'string' then model = joaat(model) end
  if not model or model == 0 then return nil end
  if not IsModelInCdimage(model) then return nil end
  if HasModelLoaded(model) then return model end
  RequestModel(model)
  local timeout = GetGameTimer() + 5000
  while not HasModelLoaded(model) do
    if GetGameTimer() > timeout then return nil end
    Wait(10)
  end
  return model
end

local function clearTabletProp()
  if tabletProp and DoesEntityExist(tabletProp) then
    DetachEntity(tabletProp, true, true)
    DeleteEntity(tabletProp)
  end
  tabletProp = nil
end

local function stopTabletAnim()
  local ped = PlayerPedId()
  local anim = tabletCfg().anim or {}
  if tabletAnimActive and anim.dict and anim.name then
    StopAnimTask(ped, anim.dict, anim.name, 1.0)
  end
  tabletAnimActive = false
  clearTabletProp()
end

local function startTabletAnim()
  local cfg = tabletCfg()
  local anim = cfg.anim or {}
  local prop = cfg.prop or {}

  stopTabletAnim()

  local ped = PlayerPedId()
  if anim.dict and anim.name and loadAnimDict(anim.dict) then
    TaskPlayAnim(ped, anim.dict, anim.name, 3.0, 3.0, -1, tonumber(anim.flag) or 49, 0.0, false, false, false)
    tabletAnimActive = true
  end

  if prop.enabled == false then return end
  local model = loadModel(prop.model or `prop_cs_tablet`)
  if not model then return end

  local coords = GetEntityCoords(ped)
  local obj = CreateObject(model, coords.x, coords.y, coords.z + 0.2, true, true, false)
  SetModelAsNoLongerNeeded(model)
  if not obj or obj == 0 then return end

  local bone = tonumber(prop.bone) or 28422
  local pos = prop.pos or {}
  local rot = prop.rot or {}
  AttachEntityToEntity(
    obj,
    ped,
    GetPedBoneIndex(ped, bone),
    tonumber(pos.x) or 0.0,
    tonumber(pos.y) or 0.0,
    tonumber(pos.z) or 0.03,
    tonumber(rot.x) or 0.0,
    tonumber(rot.y) or 0.0,
    tonumber(rot.z) or 0.0,
    true,
    true,
    false,
    true,
    1,
    true
  )
  tabletProp = obj
end

local function closeTablet()
  if not tabletOpen then return end
  tabletOpen = false
  SetNuiFocus(false, false)
  SendNUIMessage({ action = 'closeTablet' })
  stopTabletAnim()
end

RegisterNUICallback('tabletClose', function(_, cb)
  tabletOpen = false
  SetNuiFocus(false, false)
  stopTabletAnim()
  cb({ ok = true })
end)

RegisterNetEvent('bl_copnet:tabletOpen', function(url, label)
  if type(url) ~= 'string' or url == '' then
    notify('CopNet-Tablet: keine URL.', 'error')
    return
  end
  tabletOpen = true
  startTabletAnim()
  SetNuiFocus(true, true)
  SendNUIMessage({
    action = 'openTablet',
    url = url,
    label = label or 'CopNet',
  })
end)

RegisterNetEvent('bl_copnet:tabletClose', closeTablet)

RegisterNetEvent('bl_copnet:tabletError', function(msg)
  notify(tostring(msg or 'Tablet konnte nicht geöffnet werden.'), 'error')
end)

CreateThread(function()
  while true do
    if tabletOpen then
      DisableControlAction(0, 1, true)
      DisableControlAction(0, 2, true)
      DisableControlAction(0, 24, true)
      DisableControlAction(0, 25, true)
      DisableControlAction(0, 257, true)

      local ped = PlayerPedId()
      local anim = tabletCfg().anim or {}
      if tabletAnimActive and anim.dict and anim.name and not IsEntityPlayingAnim(ped, anim.dict, anim.name, 3) then
        TaskPlayAnim(ped, anim.dict, anim.name, 3.0, 3.0, -1, tonumber(anim.flag) or 49, 0.0, false, false, false)
      end

      if IsEntityDead(ped) or IsPedRagdoll(ped) or IsPedFatallyInjured(ped) then
        closeTablet()
      end
      Wait(0)
    else
      Wait(400)
    end
  end
end)

AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  if tabletOpen then
    SetNuiFocus(false, false)
  end
  stopTabletAnim()
end)

function BlCopNetOpenTablet()
  if tabletOpen then
    closeTablet()
    return
  end
  TriggerServerEvent('bl_copnet:requestTablet')
end

exports('OpenTablet', BlCopNetOpenTablet)
