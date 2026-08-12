Config = {}

-- Jobs, die Stempeluhr + Live-Position + Radialmenü an CopNet melden
Config.DutyJobs = {
  police = true,
  -- sheriff = true,
  -- fib = true,
}

-- Position alle X ms an CopNet senden (nur on-duty)
Config.PositionIntervalMs = 15000

-- Charakter + Fahrzeuge nach Login syncen
Config.SyncOnPlayerLoad = true

-- Online-Spieler periodisch nachsyncen (0 = aus)
Config.OnlineResyncIntervalMs = 10 * 60 * 1000

-- Beim Resource-Start alle Charaktere aus der DB syncen (kann dauern)
Config.FullDbSyncOnStart = false
Config.FullDbSyncBatchSize = 40
Config.FullDbSyncDelayMs = 750

-- Debug-Logs (auch per Convar: setr bl_copnet_debug "true")
Config.Debug = GetConvar('bl_copnet_debug', 'false') == 'true'

-- Manuelle Commands (ACE: command.blcopnet für sync/duty)
Config.Commands = {
  syncMe = 'copnet_syncme',
  syncAll = 'copnet_syncall',
  dutyTest = 'copnet_duty',
  status = 'copnet_status',
  callsign = 'copnet_callsign',
  panic = 'copnet_panic',
  tablet = 'copnet_tablet',
}

--[[
  Keybinds (Einsatzmenü läuft über stg-radialmenu)

  `default` = Startbelegung für neue Spieler (Server-Default).
  Spieler umbelegen: Esc → Einstellungen → Tastatur → FiveM → „CopNet: …“

  https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
]]
Config.Keybinds = {
  panic = {
    default = 'F7',
    description = 'CopNet: Panic Button',
  },
  acceptCall = {
    default = 'G',
    description = 'CopNet: Einsatz annehmen + Wegpunkt',
  },
  cycleCall = {
    default = 'H',
    description = 'CopNet: Nächsten Einsatz wählen',
  },
  dismissCall = {
    default = 'J',
    description = 'CopNet: Einsatzmeldung ausblenden',
  },
  tablet = {
    default = 'F9',
    description = 'CopNet: Tablet öffnen/schließen',
  },
}

Config.Tablet = {
  enabled = true,
  redirect = '/dashboard',
}

Config.DispatchUI = {
  enabled = true,
  pollIntervalMs = 3000,
}

Config.Radial = {
  enabled = true,
  panicCooldownMs = 60000,
}

Config.Panic = {
  requiredItem = 'panicbutton',
  missingMessage = 'Kein Panicbutton dabei',
  registerUsable = true,
  postal = {
    resource = 'hex_finalhud',
    exports = { 'GetPostal', 'getPostal', 'GetNearestPostal', 'getNearestPostal', 'Postal' },
  },
}

Config.CadAlerts = {
  enabled = true,
  defaultAgencyId = 'lspd',
  defaultPriority = 2,
}

Config.LiveMap = {
  enabled = true,
  uploadOnStart = true,
  uploadDelayMs = 4000,
  imageFile = 'html/livemap-map.png',
  bounds = {
    xMin = -4000,
    xMax = 4500,
    yMin = -4000,
    yMax = 8000,
  },
}

Config.Statuses = {
  { value = 'available',   label = 'Verfügbar (AVL)',     icon = 'check' },
  { value = 'enroute',     label = 'Anfahrt (ENR)',       icon = 'car' },
  { value = 'on_scene',    label = 'Vor Ort (ONS)',       icon = 'location-dot' },
  { value = 'busy',        label = 'Beschäftigt (BUSY)',  icon = 'hourglass' },
  { value = 'unavailable', label = 'Nicht verfügbar',     icon = 'ban' },
}
