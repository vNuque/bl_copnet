fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'bl_copnet'
author 'bl_james and bl_michael'
description 'CopNet Bridge – Duty, GPS, Sync, Radial, Dispatch-UI, Tablet'
version '1.3.0'

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
  'server/main.lua',
}

dependencies {
  'es_extended',
  'oxmysql',
  'ox_lib',
}
