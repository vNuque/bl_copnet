local tracking = false

RegisterNetEvent('bl_copnet:setTracking', function(enabled)
  tracking = enabled and true or false
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
