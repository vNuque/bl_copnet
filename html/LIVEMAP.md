# Livemap – echte Karte vom Gameserver

`bl_copnet` liest die Karte **direkt vom FiveM-Server** und lädt sie nach CopNet (CAD-Hintergrund).

## Einrichtung

In `config.lua` → `Config.LiveMap` eine Quelle setzen:

### A) Datei in einer Resource auf dem Server

```lua
sourceResource = 'meine_webmap',
imageFile = 'map.png',
publicBaseUrl = 'http://DEINE-SERVER-IP:30120',
```

CopNet holt die Datei über `http://IP:30120/bl_copnet/livemap-map`. Kein Base64-Upload.

### B) Absoluter Pfad auf dem Gameserver

```lua
imagePath = '/home/fivem/server-data/maps/satmap.png',
publicBaseUrl = 'http://DEINE-SERVER-IP:30120',
```

## Bounds

`Config.LiveMap.bounds` muss zur Bild-Kalibrierung passen (Default GTA-Welt: X −4000…4500, Y −4000…8000).

## Hinweis zu Satmap-Resources (`oulsen_satmap` etc.)

Ingame-Satmaps streamen meist `.ytd`/DDS – die sind **nicht** direkt im Browser nutzbar.  
Lege zusätzlich eine exportierte PNG/JPG der gleichen Karte auf den Server (eigene kleine Resource oder `imagePath`).
