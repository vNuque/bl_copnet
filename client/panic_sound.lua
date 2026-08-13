--- Proximity-Panic-Sound (BLACK-14): hörbar für alle in der Nähe, auch Civilisten.
RegisterNetEvent('bl_copnet:panicProximitySound', function(x, y, z)
  local cfg = Config.Panic and Config.Panic.proximitySound
  if type(cfg) == 'table' and cfg.enabled == false then return end

  x = tonumber(x)
  y = tonumber(y)
  z = tonumber(z) or 0.0
  if not x or not y then return end

  local radius = tonumber(cfg and cfg.radius) or 5.0
  if radius < 1.0 then radius = 1.0 end
  local durationMs = tonumber(cfg and cfg.durationMs) or 5500
  local intervalMs = tonumber(cfg and cfg.intervalMs) or 750
  if intervalMs < 300 then intervalMs = 300 end

  local ped = PlayerPedId()
  if not ped or ped == 0 then return end
  local my = GetEntityCoords(ped)
  local dist = #(my - vector3(x + 0.0, y + 0.0, z + 0.0))
  if dist > radius then return end

  local soundName = tostring((cfg and cfg.name) or 'TIMER_STOP')
  local soundSet = tostring((cfg and cfg.set) or 'HUD_MINI_GAME_SOUNDSET')

  CreateThread(function()
    local endsAt = GetGameTimer() + durationMs
    while GetGameTimer() < endsAt do
      -- Distanz erneut prüfen (Spieler kann weglaufen)
      ped = PlayerPedId()
      if ped and ped ~= 0 then
        my = GetEntityCoords(ped)
        dist = #(my - vector3(x + 0.0, y + 0.0, z + 0.0))
        if dist <= radius then
          local soundId = GetSoundId()
          PlaySoundFromCoord(soundId, soundName, x + 0.0, y + 0.0, z + 0.0, soundSet, false, radius + 0.0, false)
          ReleaseSoundId(soundId)
        end
      end
      Wait(intervalMs)
    end
  end)
end)
