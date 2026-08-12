# Livemap-Bild

Lege hier deine GTA-V-Karte ab als **`livemap-map.png`** (oder `.jpg` und `Config.LiveMap.imageFile` anpassen).

Anforderungen:
- Gleiche Projektion wie `Config.LiveMap.bounds` (Default: X −4000…4500, Y −4000…8000)
- Empfohlen: max. ~8 MB (PNG/JPEG)
- Datei muss in `fxmanifest.lua` unter `files` stehen (Standard: `html/livemap-map.png`)

Beim Resource-Start lädt `bl_copnet` das Bild nach CopNet (`POST /api/fivem/livemap/map`); die CAD-Live-Karte nutzt es als Hintergrund.
