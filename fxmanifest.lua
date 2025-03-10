fx_version 'cerulean'
games { 'gta5' }
lua54 'yes'

name 'Printers'
author 'PulseScripts'
version '1.0.2'

ui_page 'web/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/bridge/*'
}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/bridge/*'
}

dependencies {
    'ox_lib',
}

files {
    'web/index.html',
    'locales/en.json'
}
