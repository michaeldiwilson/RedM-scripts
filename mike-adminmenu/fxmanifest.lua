fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name 'mike-adminmenu'
description 'Interactive admin menu for RedM / RSGCore'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/main.lua',
    'client/noclip.lua',
    'client/self.lua',
    'client/players.lua',
    'client/server_mgmt.lua',
    'client/dev.lua',
    'client/spawner.lua',
    'client/zones.lua',
    'client/events.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/players.lua',
    'server/bans.lua',
    'server/inventory.lua',
    'server/appearance.lua',
    'server/zones.lua',
    'server/commands.lua',
}

dependencies {
    'rsg-core',
    'ox_lib',
    'oxmysql',
}

lua54 'yes'
