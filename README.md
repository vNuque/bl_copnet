# bl_copnet – FiveM ↔ CopNet Bridge

Synchronisiert ESX-Charaktere, Fahrzeuge, Telefonnummern sowie Police-Duty/GPS mit [CopNet](https://copnet.blackleaf.pro/).

## Voraussetzungen

- ESX Legacy + oxmysql
- `owned_vehicles`, `users` (mit Identity-Spalten), optional `phone_phones` / `phone_last_phone` (lb-phone)
- In CopNet: `COPNET_FIVEM_TOKEN` gesetzt
- Officer in CopNet mit **gleicher Discord-ID** wie im FiveM-Client (für Duty/Live-Map)

## Installation

1. Ordner nach `resources/[blackleaf]/bl_copnet` kopieren
2. In `config.lua`:
   - `Config.ApiToken` = CopNet-Token
   - `Config.DutyJobs` an eure Police-Jobs anpassen
3. `server.cfg`: `ensure bl_copnet` (nach `es_extended` / `oxmysql`)
4. CopNet deployen/neu starten (neue API-Routen)

## Was wird gesynct

| Feature | Trigger |
|---|---|
| Person + Fahrzeuge + Telefon | Login, periodischer Resync, `/copnet_syncme`, `/copnet_syncall` |
| Duty clock_in / clock_out | `esx:setJob` wenn Job in `Config.DutyJobs` und `onDuty` |
| Live-Position | alle `PositionIntervalMs`, nur on-duty |

**Nicht** enthalten: Sky-MDT-Daten.

## Upsert-Key

`users.identifier` (z. B. `char1:license…`) → CopNet `external_identifier`

## Commands (ACE)

- `/copnet_syncme` – eigenen Charakter syncen
- `/copnet_syncall` – komplette DB (Batches)
- `/copnet_duty on|off` – Duty-Event manuell testen
