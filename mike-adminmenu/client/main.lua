RSGCore = exports['rsg-core']:GetCoreObject()

IsAdminCached = false

local function refreshAdmin()
    RSGCore.Functions.TriggerCallback('mike-adminmenu:server:isAdmin', function(isAdmin)
        IsAdminCached = isAdmin
    end)
end

AddEventHandler('RSGCore:Client:OnPlayerLoaded', refreshAdmin)
AddEventHandler('onResourceStart', function(r)
    if r == GetCurrentResourceName() then
        Wait(1000)
        refreshAdmin()
    end
end)

function OpenAdminMenu()
    if not IsAdminCached then
        lib.notify({ type = 'error', description = 'No admin permission' })
        return
    end
    lib.registerContext({
        id = 'mike_admin_root',
        title = 'Admin Menu',
        options = {
            { title = 'Self',             description = 'Noclip, godmode, invisible, heal, teleport', icon = 'user',       onSelect = OpenSelfMenu },
            { title = 'Players',          description = 'Online player list + actions',                icon = 'users',      onSelect = OpenPlayersMenu },
            { title = 'Server',           description = 'Weather, time, announce, cleanup',            icon = 'server',     onSelect = OpenServerMenu },
            { title = 'Bans',             description = 'View and lift active bans',                   icon = 'ban',        onSelect = OpenBansMenu },
            { title = 'Spawner',          description = 'Horses, wagons, carts',                       icon = 'horse',      onSelect = OpenSpawnerMenu },
            { title = 'Admin Zones',      description = 'Create / manage restricted zones',            icon = 'map',        onSelect = OpenZonesMenu },
            { title = 'Developer',        description = 'Copy coords, entity info',                    icon = 'code',       onSelect = OpenDevMenu },
        },
    })
    lib.showContext('mike_admin_root')
end

RegisterCommand(Config.OpenCommand, function() OpenAdminMenu() end, false)

-- F6 key to open admin menu (F9 not in RSGCore keybinds)
CreateThread(function()
    local ADMIN_KEY = 0x3C0A40F2  -- F6
    while true do
        Wait(0)
        if IsControlJustReleased(0, ADMIN_KEY) then
            OpenAdminMenu()
        end
    end
end)
