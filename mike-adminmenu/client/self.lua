local godmode  = false
local invisible = false

function OpenSelfMenu()
    local ped = PlayerPedId()
    local hp  = GetEntityHealth(ped)
    local max = GetEntityMaxHealth(ped)
    local coords = GetEntityCoords(ped)

    lib.registerContext({
        id = 'mike_admin_self',
        title = 'Self',
        menu = 'mike_admin_root',
        options = {
            { title = ('Health: %d / %d'):format(hp, max), disabled = true },
            { title = IsNoclipOn() and 'Noclip: ON' or 'Noclip: OFF', icon = 'ghost',       onSelect = ToggleNoclip },
            { title = godmode  and 'Godmode: ON'  or 'Godmode: OFF',  icon = 'shield',      onSelect = function()
                godmode = not godmode
                SetEntityInvincible(PlayerPedId(), godmode)
                SetPlayerInvincible(PlayerId(), godmode)
                lib.notify({ description = 'Godmode ' .. (godmode and 'ON' or 'OFF') })
                OpenSelfMenu()
            end },
            { title = invisible and 'Invisible: ON' or 'Invisible: OFF', icon = 'eye-slash', onSelect = function()
                invisible = not invisible
                SetEntityVisible(PlayerPedId(), not invisible)
                lib.notify({ description = 'Invisible ' .. (invisible and 'ON' or 'OFF') })
                OpenSelfMenu()
            end },
            { title = 'Heal',   icon = 'heart',   onSelect = function() TriggerServerEvent('mike-adminmenu:server:selfAction', 'heal')   end },
            { title = 'Revive', icon = 'syringe', onSelect = function() TriggerServerEvent('mike-adminmenu:server:selfAction', 'revive') end },
            { title = 'Teleport to Waypoint', icon = 'map-pin', onSelect = TeleportToWaypoint },
            { title = 'Appearance Menu', icon = 'user-edit', onSelect = function() TriggerServerEvent('mike-adminmenu:server:openAppearance') end },
            { title = 'Copy my coords',       icon = 'copy',    onSelect = function()
                lib.setClipboard(Utils.FormatCoords4(coords, GetEntityHeading(ped)))
                lib.notify({ description = 'Coords copied' })
            end },
        },
    })
    lib.showContext('mike_admin_self')
end

function TeleportToWaypoint()
    if not IsWaypointActive() then
        lib.notify({ type = 'error', description = 'No waypoint set on the map' })
        return
    end
    local c = GetWaypointCoords()
    local groundZ = GetHeightmapBottomZForPosition(c.x, c.y)
    local ped = PlayerPedId()
    SetEntityCoords(ped, c.x, c.y, (groundZ or 0.0) + 3.0, false, false, false, false)
    lib.notify({ type = 'success', description = 'Teleported to waypoint' })
end

RegisterNetEvent('mike-adminmenu:client:tpWaypoint', TeleportToWaypoint)
