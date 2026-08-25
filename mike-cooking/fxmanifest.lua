fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name 'mike-cooking'
description 'Campfire cooking for fish and hunting meat'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
    'server/filleting.lua',
}

dependencies { 'rsg-core', 'rsg-inventory', 'ox_lib', 'ox_target' }
lua54 'yes'
