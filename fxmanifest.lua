fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'bl_copnet'
author 'bl_james and bl_michael'
description 'CopNet Bridge – Duty, GPS, Personen- & Fahrzeug-Sync'
version '1.0.0'

shared_scripts {
  'config.lua',
}

client_scripts {
  'client/main.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/http.lua',
  'server/sync.lua',
  'server/duty.lua',
  'server/main.lua',
}

dependencies {
  'es_extended',
  'oxmysql',
}
