fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'bl_copnet'
author 'bl_james and bl_michael'
version '1.5.0'
description 'CopNet Bridge – Duty, GPS, Sync, Radial, Dispatch-UI, Tablet, CAD-Alerts, LiveMap'

ui_page 'html/dispatch.html'

files {
  'html/dispatch.html',
  'html/livemap-map.png',
}

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua',
}

client_scripts {
  'client/keybinds.lua',
  'client/main.lua',
  'client/dispatch.lua',
  'client/tablet.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/http.lua',
  'server/sync.lua',
  'server/duty.lua',
  'server/actions.lua',
  'server/dispatch.lua',
  'server/tablet.lua',
  'server/lookup.lua',
  'server/alerts.lua',
  'server/livemap.lua',
  'server/main.lua',
}

dependencies {
  'es_extended',
  'oxmysql',
  'ox_lib',
}
