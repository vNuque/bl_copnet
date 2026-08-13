# bl_copnet – FiveM ↔ CopNet Bridge

Game-Bridge (Duty, GPS, Radial, Tablet, CAD-Alerts, LiveMap) für [CopNet](https://copnet.blackleaf.pro/).

**Kommunikation zur Website läuft ausschließlich über [`BL_CopNet_API`](../BL_CopNeT_API)** – `bl_copnet` enthält keinen Token und spricht CopNet nicht direkt an.

```
bl_copnet ──exports──► BL_CopNet_API ──HTTP+Token──► CopNet /api/fivem/*
```

## Voraussetzungen

- ESX Legacy + oxmysql + **ox_lib**
- Resource **`BL_CopNet_API`** (vorher starten)
- `owned_vehicles`, `users` (mit Identity-Spalten), optional `phone_phones` / `phone_last_phone` (lb-phone)
- In CopNet: `COPNET_FIVEM_TOKEN` = gleicher Wert wie `BL_CopNet_API_token`
- Officer in CopNet mit **gleicher Discord-ID** wie im FiveM-Client (für Duty/Live-Map/Radial)

## Installation

1. `BL_CopNet_API` + `bl_copnet` nach `resources/[blackleaf]/` kopieren
2. `Config.DutyJobs` in `bl_copnet/config.lua` anpassen
3. `server.cfg`:
   ```
   set BL_CopNet_API_debug "false"
   set BL_CopNet_API_url "https://copnet.blackleaf.pro"
   set BL_CopNet_API_token "dein-token"   # = COPNET_FIVEM_TOKEN

   ensure ox_lib
   ensure es_extended
   ensure oxmysql
   ensure BL_CopNet_API
   ensure bl_copnet
   ```
4. CopNet deployen/neu starten (`COPNET_FIVEM_TOKEN`, optional `COPNET_FIVEM_ALLOWED_IPS`)

Token **nur** in `BL_CopNet_API` / server.cfg – nicht in `bl_copnet`.

## Was wird gesynct / gesteuert

| Feature | Trigger |
|---|---|
| Person + Fahrzeuge + Telefon | Login, periodischer Resync, `/copnet_syncme`, `/copnet_syncall` |
| Fahrzeug-/Waffen-Lookup | `/copnet_plate`, `/copnet_serial` + Exports |
| Duty clock_in / clock_out | `esx:setJob` (Server-Job/`onDuty`); Client-Hint nur wenn Server kein Flag hat + Rate-Limit |
| Live-Position | alle `PositionIntervalMs`, nur on-duty; Server-Coords + Anti-Teleport (`Config.PositionAntiTeleport`) |
| CAD-Status | Radial / F6-Menü / `/copnet_status <status>` (Cooldown `Radial.statusCooldownMs`) |
| Streifencode | Radial / Menü / `/copnet_callsign L-21` (Cooldown `Radial.callsignCooldownMs`) |
| Panic | Radial / F7 / `/copnet_panic` / Item nutzen → P1-CAD-Einsatz `PANIC` (Cooldown + Item); **Proximity-Sound** in `Config.Panic.proximitySound.radius` für alle in der Nähe (auch Crime) |
| CopNet-Tablet | F9 / `/copnet_tablet` → volle CopNet-UI (Dashboard + Navigation) |
| CAD-Alerts (Export) | `CreateCadAlert` / `CreateCadAlertAtPlayer` von anderen Resources |
| Live-Karte | Greift echte Map vom Gameserver → CopNet; offene Calls als Marker |

## Dispatch-UI (zugeteilte Einsätze)

On-duty erscheinen links Call-Cards (wie CAD-Alarmierungen):

- Polling der zugeteilten offenen Einsätze
- **G** – annehmen + GPS-Wegpunkt (wenn Koordinaten vorhanden)
- **H** – nächsten Einsatz fokussieren
- Optional: Ausblenden-Keybind in `Config.Keybinds.dismissCall`

Panic alarmiert alle on-duty Officers der Behörde und enthält GPS für den Wegpunkt.

## CopNet-Tablet (volle UI)

On-duty (Keybind **F9** / `/copnet_tablet`): NUI-Vollbild mit Login-Ticket → **gesamtes CopNet** (Dashboard, Personen, Akten, Register, …) im iframe – nicht nur CAD.

- Startseite nach Login: `Config.Tablet.redirect` (Default `/dashboard`; z. B. `/persons` oder `/patrol` möglich)
- Schließen: ESC oder Button in der Tablet-Leiste

**Nicht** enthalten: Sky-MDT-Daten (eigenes System).

## Radialmenü (on-duty)

- ox_lib-Radial: Eintrag **CopNet**
  - Status (AVL / ENR / ONS / BUSY / UNAV)
  - Streifencode setzen
  - PANIC
- **F6** – Kontextmenü (gleiche Aktionen) · Default in `Config.Keybinds.menu`
- **F7** – Panic-Hotkey · Default in `Config.Keybinds.panic` (Cooldown: `Config.Radial.panicCooldownMs`)

Keybinds in `config.lua` unter `Config.Keybinds` = **Server-Default**.
Spieler können sie jederzeit selbst umbelegen: **Esc → Einstellungen → Tastatur → FiveM → „CopNet: …“**.


## Upsert-Key

`users.identifier` (z. B. `char1:license…`) → CopNet `external_identifier`

## Commands

| Command | Wirkung |
|---|---|
| `/copnet_syncme` | eigenen Charakter syncen (ACE) |
| `/copnet_syncall` | komplette DB (ACE) |
| `/copnet_duty on\|off` | Duty-Event manuell testen (ACE) |
| `/copnet_status available` | CAD-Status setzen |
| `/copnet_callsign L-21` | Streifencode |
| `/copnet_panic` | Panic |
| `/copnet_menu` | Einsatzmenü |
| `/copnet_plate ABC123` | Fahrzeugregister-Lookup |
| `/copnet_serial SN-1` | Waffenregister-Lookup |

### Exports (andere Resources)

```lua
exports['bl_copnet']:LookupVehicle('ABC123', function(ok, vehicle)
  -- vehicle.plate, vehicleType, ownerLabel, statusLabel, source ('register'|'person_akte')
end)

exports['bl_copnet']:LookupVehicles({ plate = 'ABC123' }, function(ok, data)
  -- data.vehicles = { ... }
end)

exports['bl_copnet']:LookupWeapon('SN-1', function(ok, weapon) end)

exports['bl_copnet']:LookupPerson({ identifier = 'char1:license:...' }, function(ok, data)
  -- data.person, data.vehicles, data.weapons
end)

exports['bl_copnet']:CreateCadAlert({
  title = 'Schüsse gemeldet',
  code = 'SHOTS',
  kind = 'shots_fired',
  priority = 1,
  x = 100.0, y = 200.0, z = 30.0,
}, function(ok, data) end)
```

ACE für Admin-Commands: `command.blcopnet` (wie zuvor für sync/duty).

## CAD-Alerts von anderen Scripts

Andere Resources können Einsätze direkt ans CAD schicken (Hausraub, Schüsse, Alarmierungen, …):

```lua
exports['bl_copnet']:CreateCadAlert({
  title = 'Hausraub',
  code = '10-90',
  kind = 'house_robbery',
  priority = 2,          -- 1=P1 … 5=P5
  agencyId = 'lspd',     -- optional; sonst Config.CadAlerts.defaultAgencyId
  x = coords.x, y = coords.y, z = coords.z,
  street = 'Forum Drive',
  postal = '123',
  notes = 'Einbruchmeldung',
  source = 'qs-housing', -- optional; Default = aufrufende Resource
}, function(ok, data)
  if ok then
    print('CAD Call', data.call.id)
  end
end)

-- Variante: Koordinaten vom Spieler
exports['bl_copnet']:CreateCadAlertAtPlayer(src, {
  title = 'Schüsse gemeldet',
  code = 'SHOTS',
  kind = 'shots_fired',
  priority = 1,
}, cb)
```

Config: `Config.CadAlerts` (`enabled`, `defaultAgencyId`, `defaultPriority`).
CopNet muss die Route `/api/fivem/cad/alerts` deployen.

## Live-Karte (Dispatch)

Beim Start greift `bl_copnet` die **echte Karte vom FiveM-Server** und lädt sie nach CopNet. Offene CAD-Calls mit Koordinaten erscheinen als Marker.

Quellen in `Config.LiveMap` (eine reicht):

| Option | Beispiel |
|---|---|
| `sourceResource` + `imageFile` | Resource auf dem Gameserver mit PNG/JPG |
| `imagePath` | Absoluter Server-Pfad zur Map-Datei |
| `sourceUrl` | Script lädt von URL und pusht nach CopNet |
| `publicBaseUrl` + `mode='fetch'` | CopNet holt `http://IP:30120/bl_copnet/livemap-map` |

Details: [`html/LIVEMAP.md`](html/LIVEMAP.md)

Manuell: `exports['bl_copnet']:UploadLiveMap(cb)`
