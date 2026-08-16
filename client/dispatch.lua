local tracking = false
local calls = {}
local focusIndex = 1
local lastKeySignature = ''

local function dispatchKeys()
  return {
    accept = BlCopNetKeybinds.GetLabel('bl_copnet_accept_call', (Config.Keybinds and Config.Keybinds.acceptCall and Config.Keybinds.acceptCall.default) or 'G'),
    cycle = BlCopNetKeybinds.GetLabel('bl_copnet_cycle_call', (Config.Keybinds and Config.Keybinds.cycleCall and Config.Keybinds.cycleCall.default) or 'H'),
    dismiss = BlCopNetKeybinds.GetLabel('bl_copnet_dismiss_call', (Config.Keybinds and Config.Keybinds.dismissCall and Config.Keybinds.dismissCall.default) or 'J'),
  }
end

local function keysSignature(keys)
  return table.concat({ keys.accept or '', keys.cycle or '', keys.dismiss or '' }, '|')
end

AddEventHandler('bl_copnet:dutyState', function(enabled)
  tracking = enabled and true or false
  if not tracking then
    calls = {}
    focusIndex = 1
    lastKeySignature = ''
    SendNUIMessage({ action = 'setCalls', calls = {}, keys = dispatchKeys() })
  end
end)

local function pushUi(force)
  local keys = dispatchKeys()
  local sig = keysSignature(keys)
  local keysChanged = sig ~= lastKeySignature
  lastKeySignature = sig

  local payload = {}
  local ped = PlayerPedId()
  local coords = ped and ped ~= 0 and GetEntityCoords(ped) or nil
  for i, call in ipairs(calls) do
    local row = {}
    for k, v in pairs(call) do row[k] = v end
    row.focused = (i == focusIndex)
    if coords and call.posX and call.posY then
      local dx = coords.x - call.posX
      local dy = coords.y - call.posY
      row.distance = math.floor(math.sqrt(dx * dx + dy * dy) + 0.5)
    else
      row.distance = nil
    end
    payload[#payload + 1] = row
  end

  -- Immer pushen wenn Calls da / force; Key-Wechsel auch bei leerer Liste irrelevant
  if force or keysChanged or #payload > 0 then
    SendNUIMessage({ action = 'setCalls', calls = payload, keys = keys })
  end
end

local function removeCallLocally(callId)
  callId = tostring(callId or '')
  if callId == '' then return false end
  local nextCalls = {}
  for _, call in ipairs(calls) do
    if tostring(call.id) ~= callId then
      nextCalls[#nextCalls + 1] = call
    end
  end
  if #nextCalls == #calls then return false end
  calls = nextCalls
  if focusIndex > #calls then focusIndex = math.max(1, #calls) end
  if focusIndex < 1 then focusIndex = 1 end
  pushUi(true)
  return true
end

RegisterNetEvent('bl_copnet:dispatchCalls', function(list)
  calls = type(list) == 'table' and list or {}
  if focusIndex > #calls then focusIndex = math.max(1, #calls) end
  if focusIndex < 1 then focusIndex = 1 end
  pushUi(true)
end)

CreateThread(function()
  local interval = tonumber(Config.DispatchUI and Config.DispatchUI.pollIntervalMs) or 3000
  if interval < 1500 then interval = 1500 end
  while true do
    Wait(interval)
    if tracking and Config.DispatchUI and Config.DispatchUI.enabled ~= false then
      TriggerServerEvent('bl_copnet:dispatchPoll')
    end
  end
end)

CreateThread(function()
  while true do
    Wait(1000)
    if #calls > 0 then
      pushUi(false)
    else
      -- Auch ohne Callouts Keybinds prüfen (nach Umlegen aktualisieren beim nächsten Call)
      local keys = dispatchKeys()
      local sig = keysSignature(keys)
      if sig ~= lastKeySignature then
        lastKeySignature = sig
      end
    end
  end
end)

local function focusedCall()
  return calls[focusIndex]
end

local function acceptFocused()
  local call = focusedCall()
  if not call then return end
  local callId = call.id
  if call.posX and call.posY then
    SetNewWaypoint(call.posX + 0.0, call.posY + 0.0)
  end
  -- Sofort vom Bildschirm nehmen; Server hält das über dismissed+Poll
  removeCallLocally(callId)
  TriggerServerEvent('bl_copnet:dispatchAccept', callId)
  local claim = call.claimable and ' – zugeteilt.' or ''
  lib.notify({
    description = (call.posX and ('Einsatz angenommen' .. claim .. ' Wegpunkt gesetzt.') or ('Einsatz angenommen' .. claim)),
    type = 'success',
  })
end

local function cycleFocus(delta)
  if #calls == 0 then return end
  focusIndex = focusIndex + (delta or 1)
  if focusIndex > #calls then focusIndex = 1 end
  if focusIndex < 1 then focusIndex = #calls end
  pushUi(true)
end

local function dismissFocused()
  local call = focusedCall()
  if not call then return end
  local callId = call.id
  removeCallLocally(callId)
  TriggerServerEvent('bl_copnet:dispatchDismiss', callId)
end

local keybinds = Config.Keybinds or {}

BlCopNetKeybinds.Register(keybinds.acceptCall, 'bl_copnet_accept_call', function()
  if not tracking then return end
  acceptFocused()
end)

BlCopNetKeybinds.Register(keybinds.cycleCall, 'bl_copnet_cycle_call', function()
  if not tracking then return end
  cycleFocus(1)
end)

BlCopNetKeybinds.Register(keybinds.dismissCall, 'bl_copnet_dismiss_call', function()
  if not tracking then return end
  dismissFocused()
end)
