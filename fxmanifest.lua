fx_version 'cerulean'
games { 'gta5' }
lua54 'yes'

name 'Printer Script'
author 'PulseScripts - pulsescripts.com'
version '1.0.7'

ui_page 'web/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/locale.lua'
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
    'locales/*.json'
}
