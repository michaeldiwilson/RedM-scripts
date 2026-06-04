fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name 'mike-exchange'
description 'Player-driven buy/sell stockpile shops for RSGCore'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

dependencies { 'rsg-core', 'rsg-inventory', 'ox_lib', 'ox_target', 'oxmysql' }
lua54 'yes'
