# bl_copnet – FiveM ↔ CopNet Bridge

Synchronisiert ESX-Charaktere, Fahrzeuge, Telefonnummern sowie Police-Duty/GPS mit [CopNet](https://copnet.blackleaf.pro/) und bietet ein **Radialmenü** für CAD-Status, Streifencode und Panic.

## Voraussetzungen

- ESX Legacy + oxmysql + **ox_lib**
- `owned_vehicles`, `users` (mit Identity-Spalten), optional `phone_phones` / `phone_last_phone` (lb-phone)
- In CopNet: `COPNET_FIVEM_TOKEN` gesetzt
- Officer in CopNet mit **gleicher Discord-ID** wie im FiveM-Client (für Duty/Live-Map/Radial)

## Installation

1. Ordner nach `resources/[blackleaf]/bl_copnet` kopieren
2. In `config.lua`:
   - `Config.ApiToken` = CopNet-Token
   - `Config.DutyJobs` an eure Police-Jobs anpassen
3. `server.cfg` (Reihenfolge):
   ```
   ensure ox_lib
   ensure es_extended
   ensure oxmysql
   ensure bl_copnet
   ```
4. CopNet deployen/neu starten (Events `unit_callsign`, `unit_panic`)

## Was wird gesynct / gesteuert

| Feature | Trigger |
|---|---|
| Person + Fahrzeuge + Telefon | Login, periodischer Resync, `/copnet_syncme`, `/copnet_syncall` |
| Fahrzeug-/Waffen-Lookup | `/copnet_plate`, `/copnet_serial` + Exports |
| Duty clock_in / clock_out | `esx:setJob` wenn Job in `Config.DutyJobs` und `onDuty` |
| Live-Position | alle `PositionIntervalMs`, nur on-duty |
| CAD-Status | Radial / F6-Menü / `/copnet_status <status>` |
| Streifencode | Radial / Menü / `/copnet_callsign L-21` |
| Panic | Radial / F7 / `/copnet_panic` / Item nutzen → P1-CAD-Einsatz `PANIC` (nur mit Item, siehe `Config.Panic`) |
| CopNet-Tablet | F9 / `/copnet_tablet` → volle CopNet-UI (Dashboard + Navigation) |
| CAD-Alerts (Export) | `CreateCadAlert` / `CreateCadAlertAtPlayer` von anderen Resources |
| Live-Karte | Start-Upload `html/livemap-map.png` + Bounds → CAD-Hintergrund; offene Calls als Marker |

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
  -- vehicle.plate, model, ownerLabel, statusLabel, source ('register'|'person_akte')
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

Beim Start pusht `bl_copnet` Kartenbild + Bounds an CopNet. Offene CAD-Calls mit Koordinaten erscheinen als Marker auf der Karte (Units = Kreise, Calls = Dreiecke).

1. Eigene GTA-Karte nach `html/livemap-map.png` legen (siehe `html/LIVEMAP.md`)
2. Bounds in `Config.LiveMap.bounds` an die Bild-Kalibrierung anpassen
3. CopNet + Resource neu starten → Upload automatisch (`uploadOnStart`)

Manuell: `exports['bl_copnet']:UploadLiveMap(cb)`

API: `POST /api/fivem/livemap/map` mit `imageBase64` + `bounds`.
