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
| Duty clock_in / clock_out | `esx:setJob` wenn Job in `Config.DutyJobs` und `onDuty` |
| Live-Position | alle `PositionIntervalMs`, nur on-duty |
| CAD-Status | Radial / F6-Menü / `/copnet_status <status>` |
| Streifencode | Radial / Menü / `/copnet_callsign L-21` |
| Panic | Radial / F7 / `/copnet_panic` / Item nutzen → P1-CAD-Einsatz `PANIC` (nur mit Item, siehe `Config.Panic`) |

## Dispatch-UI (zugeteilte Einsätze)

On-duty erscheinen links Call-Cards (wie CAD-Alarmierungen):

- Polling der zugeteilten offenen Einsätze
- **G** – annehmen + GPS-Wegpunkt (wenn Koordinaten vorhanden)
- **H** – nächsten Einsatz fokussieren
- Optional: Ausblenden-Keybind in `Config.Keybinds.dismissCall`

Panic alarmiert alle on-duty Officers der Behörde und enthält GPS für den Wegpunkt.


**Nicht** enthalten: Sky-MDT-Daten / volle Akten-UI.

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

ACE für Admin-Commands: `command.blcopnet` (wie zuvor für sync/duty).
