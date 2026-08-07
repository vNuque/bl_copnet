Config = {}

-- CopNet API
Config.ApiBaseUrl = 'https://copnet.blackleaf.pro'
Config.ApiToken = 'DfYWz0dujiHAWwl3ec7ExGuWQW9Wk-ZMQ-Fj9yS5jNM'

-- Jobs, die Stempeluhr + Live-Position an CopNet melden
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
Config.Debug = false

-- Manuelle Commands (ACE: command.blcopnet)
Config.Commands = {
  syncMe = 'copnet_syncme',       -- eigenen Charakter syncen
  syncAll = 'copnet_syncall',     -- komplette users-Tabelle
  dutyTest = 'copnet_duty',       -- clock_in/out testen: /copnet_duty on|off
}
