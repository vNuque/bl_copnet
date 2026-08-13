# Livemap – echte Karte vom Gameserver

`bl_copnet` liest die Karte **direkt vom FiveM-Server** und lädt sie nach CopNet (CAD-Hintergrund).

## Einrichtung

In `config.lua` → `Config.LiveMap` eine Quelle setzen:

### A) Datei in einer Resource auf dem Server (empfohlen)

```lua
sourceResource = 'meine_webmap',  -- Resource-Name auf dem Gameserver
imageFile = 'map.png',            -- PNG/JPG relativ zu dieser Resource
```

Die Datei muss eine **Web-Karte** sein (PNG/JPG), keine `.ytd`-Minimap-Textures.

### B) Absoluter Pfad auf dem Gameserver

```lua
imagePath = '/home/fivem/server-data/maps/satmap.png',
```

### C) URL (Script lädt und pusht nach CopNet)

```lua
sourceUrl = 'https://cdn.example.com/gta-satmap.jpg',
```

### D) CopNet pullt vom FiveM-HTTP

```lua
mode = 'fetch',
publicBaseUrl = 'http://DEINE-SERVER-IP:30120',
```

Dann erreichbar unter: `http://IP:30120/bl_copnet/livemap-map`

## Bounds

`Config.LiveMap.bounds` muss zur Bild-Kalibrierung passen (Default GTA-Welt: X −4000…4500, Y −4000…8000).

## Hinweis zu Satmap-Resources (`oulsen_satmap` etc.)

Ingame-Satmaps streamen meist `.ytd`/DDS – die sind **nicht** direkt im Browser nutzbar.  
Lege zusätzlich eine exportierte PNG/JPG der gleichen Karte auf den Server (eigene kleine Resource oder `imagePath`).
