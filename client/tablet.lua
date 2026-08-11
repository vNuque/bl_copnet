local tabletOpen = false

local function notify(msg, typ)
  lib.notify({ description = msg, type = typ or 'inform' })
end

local function closeTablet()
  if not tabletOpen then return end
  tabletOpen = false
  SetNuiFocus(false, false)
  SendNUIMessage({ action = 'closeTablet' })
end

RegisterNUICallback('tabletClose', function(_, cb)
  tabletOpen = false
  SetNuiFocus(false, false)
  cb({ ok = true })
end)

RegisterNetEvent('bl_copnet:tabletOpen', function(url, label)
  if type(url) ~= 'string' or url == '' then
    notify('CopNet-Tablet: keine URL.', 'error')
    return
  end
  tabletOpen = true
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
      Wait(0)
    else
      Wait(400)
    end
  end
end)

function BlCopNetOpenTablet()
  if tabletOpen then
    closeTablet()
    return
  end
  TriggerServerEvent('bl_copnet:requestTablet')
end

exports('OpenTablet', BlCopNetOpenTablet)
