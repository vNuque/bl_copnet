Config = {}

-- CopNet-Website-URL / Token liegen NUR in BL_CopNet_API (server.cfg Convars):
--   set BL_CopNet_API_url "https://copnet.blackleaf.pro"
--   set BL_CopNet_API_token "…"
-- bl_copnet spricht die Website nie direkt an – nur via exports['BL_CopNet_API'].

-- Jobs, die Stempeluhr + Live-Position + Radialmenü an CopNet melden
Config.DutyJobs = {
  police = true,
  -- sheriff = true,
  -- fib = true,
}

-- Position alle X ms an CopNet senden (nur on-duty)
Config.PositionIntervalMs = 15000

--[[
  Live-Map Anti-Teleport (server/duty.lua)
  - Server-Ped-Koordinaten (OneSync) haben Vorrang vor Client-Werten
  - minIntervalMs: Mindestabstand zwischen akzeptierten Updates
  - maxSpeedMps: max. plausibel m/s (~150 ≈ 540 km/h, inkl. Heli-Spielraum)
  - graceMeters: Toleranz (Lag / kurze Warps)
  - resetAfterMs: nach längerer Lücke Position neu annehmen (kein Dauer-Lock)
]]
Config.PositionAntiTeleport = {
  enabled = true,
  minIntervalMs = 4000,
  maxSpeedMps = 150,
  graceMeters = 80,
  resetAfterMs = 120000,
}

-- Client-Duty-Hint (LB Phone ohne Server-onDuty): Rate-Limits gegen Spam
Config.ClientDutySyncMinIntervalMs = 3000
Config.ClientDutySyncMaxPerMinute = 12

-- Charakter + Fahrzeuge nach Login syncen
Config.SyncOnPlayerLoad = true

-- Online-Spieler periodisch nachsyncen (0 = aus)
Config.OnlineResyncIntervalMs = 10 * 60 * 1000

-- Beim Resource-Start alle Charaktere aus der DB syncen (kann dauern)
Config.FullDbSyncOnStart = false
Config.FullDbSyncBatchSize = 40
Config.FullDbSyncDelayMs = 750

-- Debug-Logs in der Server-Konsole
Config.Debug = false

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
  statusCooldownMs = 2000,
  callsignCooldownMs = 3000,
}

--[[
  Panic-Button

  requiredItem: Inventar-Item-Name (ESX / ox_inventory).
  - Keybind / Radial / Command lösen Panic nur aus, wenn das Item im Inventar ist.
  - Item verwenden (usable) löst ebenfalls Panic aus.
  - Leerlassen ('') = kein Item nötig.

  postal: PLZ über hex_finalhud (oder anderes Resource mit Export).

  proximitySound: hörbar für ALLE Spieler in der Nähe (auch Civilisten / Crime),
  nicht nur für on-duty Cops. 3D am Auslöseort.
]]
Config.Panic = {
  requiredItem = 'panicbutton',
  missingMessage = '',           -- leer = still scheitern; sonst z.B. 'Kein Panic-Gerät dabei.'
  registerUsable = true,         -- Item-Nutzung → Panic
  postal = {
    resource = 'hex_finalhud',
    -- Export-Namen der Reihe nach versuchen (pcall)
    exports = { 'GetPostal', 'getPostal', 'GetNearestPostal', 'getNearestPostal', 'postal' },
  },
  proximitySound = {
    enabled = true,
    radius = 5.0,        -- Meter Hörweite
    durationMs = 5500,   -- wie lange der Alarm wiederholt wird
    intervalMs = 750,    -- Pause zwischen Beeps
    -- GTA-Sound (3D an den Koordinaten des Officers)
    name = 'TIMER_STOP',
    set = 'HUD_MINI_GAME_SOUNDSET',
  },
}


-- CAD-Alerts von anderen Resources (Hausraub, Schüsse, …)
-- agencyId: CopNet-Behörden-Schlüssel (z.B. 'lspd'). Leer = Config.CadAlerts.defaultAgencyId
Config.CadAlerts = {
  enabled = true,
  defaultAgencyId = 'lspd',
  defaultPriority = 2, -- 1=P1 … 5=P5
  -- Leer = alle Resources dürfen CreateCadAlert; sonst nur gelistete Namen
  allowedResources = {
    -- 'qs-housing',
    -- 'my_robbery',
  },
  -- Min. Abstand zwischen Alerts derselben Source-Resource (ms)
  minIntervalMs = 5000,
}

--[[
  Live-Karte für CopNet Dispatch

  Das Script greift die echte Karte vom FiveM-Server und lädt sie nach CopNet.

  Quellen (Reihenfolge):
  1) imagePath – absoluter Pfad auf dem Gameserver
  2) sourceResource + imageFile – Datei in einer anderen Resource (z.B. eure Satmap-Web-PNG)
  3) sourceUrl – HTTP(S)-URL, die das Script selbst lädt und weitergibt
  4) publicBaseUrl + mode=fetch – CopNet holt die Karte über FiveM-HTTP
     (http://IP:30120/bl_copnet/livemap-map)
]]
Config.LiveMap = {
  enabled = true,
  uploadOnStart = true,
  uploadDelayMs = 4000,
  mode = 'auto', -- auto | upload | fetch

  -- Resource auf dem Server, die die echte Map-PNG/JPG enthält:
  sourceResource = '', -- z.B. 'my_webmap' oder 'oulsen_satmap_web'
  imageFile = 'html/livemap-map.png', -- relativ zur sourceResource
  -- imagePath = '/home/fivem/server-data/maps/satmap.png',

  -- Optional: Karte von URL laden (Script greift → CopNet)
  -- sourceUrl = 'https://cdn.example.com/gta-satmap.jpg',

  -- Optional: öffentlicher FiveM-Endpoint, damit CopNet die Karte selbst pullen kann
  -- publicBaseUrl = 'http://DEINE-SERVER-IP:30120',

  sourceResourceFallbacks = {
    -- 'my_livemap',
  },

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
