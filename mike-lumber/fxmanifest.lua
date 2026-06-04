fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name 'mike-lumber'
description 'Tree chopping and sawmill for RSGCore'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/sawmill.lua',
}

server_scripts {
    'server/main.lua',
    'server/sawmill.lua',
}

dependencies { 'rsg-core', 'rsg-inventory', 'ox_lib', 'ox_target' }
lua54 'yes'
