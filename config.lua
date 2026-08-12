Config = {}

-- CopNet API
Config.ApiBaseUrl = 'https://copnet.blackleaf.pro'
Config.ApiToken = 'DfYWz0dujiHAWwl3ec7ExGuWQW9Wk-ZMQ-Fj9yS5jNM'

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

-- Debug-Logs in der Server-Konsole
Config.Debug = true

-- Manuelle Commands (ACE: command.blcopnet für sync/duty)
Config.Commands = {
  syncMe = 'copnet_syncme',       -- eigenen Charakter syncen
  syncAll = 'copnet_syncall',     -- komplette users-Tabelle
  dutyTest = 'copnet_duty',       -- clock_in/out testen: /copnet_duty on|off
  status = 'copnet_status',       -- CAD-Status: /copnet_status available
  callsign = 'copnet_callsign',   -- Streifencode: /copnet_callsign L-21
  panic = 'copnet_panic',         -- Panic Button (Command)
  menu = 'copnet_menu',           -- Einsatzmenü (Command)
  tablet = 'copnet_tablet',       -- CopNet-Tablet (NUI)
}

--[[
  Keybinds

  `default` = Startbelegung für neue Spieler (Server-Default).
  Jeder Spieler kann die Tasten selbst umbelegen:
    Esc → Einstellungen → Tastatur → FiveM → Einträge „CopNet: …“

  Gültige Tasten:
  https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
]]
Config.Keybinds = {
  menu = {
    default = 'F6',
    description = 'CopNet: Einsatzmenü',
  },
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

-- CopNet-Vollbild-Tablet (NUI → Login-Ticket → volle CopNet-UI)
Config.Tablet = {
  enabled = true,
  redirect = '/dashboard', -- Startseite nach Login (z.B. /dashboard, /persons, /patrol)
}

-- Zugeteilte CAD-Einsätze (Ingame-Cards)
Config.DispatchUI = {
  enabled = true,
  pollIntervalMs = 3000,
}

-- Radialmenü / Schnellaktionen (ox_lib)
Config.Radial = {
  enabled = true,
  panicCooldownMs = 60000,
}

--[[
  Panic-Button

  requiredItem: Inventar-Item-Name (ESX / ox_inventory).
  - Keybind / Radial / Command lösen Panic nur aus, wenn das Item im Inventar ist.
  - Item verwenden (usable) löst ebenfalls Panic aus.
  - Leerlassen ('') = kein Item nötig.

  postal: PLZ über hex_finalhud (oder anderes Resource mit Export).
]]
Config.Panic = {
  requiredItem = 'panicbutton',
  missingMessage = 'Kein Panicbutton dabei',           -- leer = still scheitern; sonst z.B. 'Kein Panic-Gerät dabei.'
  registerUsable = true,         -- Item-Nutzung → Panic
  postal = {
    resource = 'hex_finalhud',
    -- Export-Namen der Reihe nach versuchen (pcall)
    exports = { 'GetPostal', 'getPostal', 'GetNearestPostal', 'getNearestPostal', 'postal' },
  },
}


-- CAD-Alerts von anderen Resources (Hausraub, Schüsse, …)
-- agencyId: CopNet-Behörden-Schlüssel (z.B. 'lspd'). Leer = Config.CadAlerts.defaultAgencyId
Config.CadAlerts = {
  enabled = true,
  defaultAgencyId = 'lspd',
  defaultPriority = 2, -- 1=P1 … 5=P5
}

--[[
  Live-Karte für CopNet Dispatch

  imageFile: Pfad relativ zur Resource (muss in fxmanifest `files` stehen).
  Beim Start (uploadOnStart) wird Bild + Bounds an CopNet gepusht und dort
  als Hintergrund der CAD-Live-Karte genutzt.
]]
Config.LiveMap = {
  enabled = true,
  uploadOnStart = true,
  uploadDelayMs = 4000,
  imageFile = 'html/livemap-map.png', -- PNG/JPG hier ablegen
  -- contentType = 'image/png', -- optional, sonst aus Dateiendung
  bounds = {
    xMin = -4000,
    xMax = 4500,
    yMin = -4000,
    yMax = 8000,
  },
}

-- CAD-Status-Optionen (Werte = CopNet unit_status)
Config.Statuses = {
  { value = 'available',   label = 'Verfügbar (AVL)',     icon = 'check' },
  { value = 'enroute',     label = 'Anfahrt (ENR)',       icon = 'car' },
  { value = 'on_scene',    label = 'Vor Ort (ONS)',       icon = 'location-dot' },
  { value = 'busy',        label = 'Beschäftigt (BUSY)',  icon = 'hourglass' },
  { value = 'unavailable', label = 'Nicht verfügbar',     icon = 'ban' },
}
