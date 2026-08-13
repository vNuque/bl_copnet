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
}

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua',
}

client_scripts {
  'client/keybinds.lua',
  'client/main.lua',
  'client/panic_sound.lua',
  'client/dispatch.lua',
  'client/tablet.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/api.lua',
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
  -- BL_CopNet_API: weiche Abhängigkeit (siehe server/api.lua).
  -- Hartes ensure würde bl_copnet komplett blockieren, wenn die API fehlt.
}

