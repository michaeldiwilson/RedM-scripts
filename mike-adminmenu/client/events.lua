RegisterNetEvent('mike-adminmenu:client:revive', function()
    TriggerEvent('rsg-medic:client:playerRevive')
    lib.notify({ type = 'success', description = 'Revived' })
end)

RegisterNetEvent('mike-adminmenu:client:heal', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    lib.notify({ type = 'success', description = 'Healed' })
end)

RegisterNetEvent('mike-adminmenu:client:freeze', function(state)
    FreezeEntityPosition(PlayerPedId(), state == true)
    lib.notify({ description = state and 'You are frozen' or 'You are unfrozen' })
end)

RegisterNetEvent('mike-adminmenu:client:teleport', function(c)
    if not c then return end
    SetEntityCoords(PlayerPedId(), c.x + 0.0, c.y + 0.0, c.z + 0.5, false, false, false, false)
end)

RegisterNetEvent('mike-adminmenu:client:setWeather', function(weather)
    Citizen.InvokeNative(0x59174F1AFE095B5A, GetHashKey(weather), true, true, true, 0.0, false)
    lib.notify({ description = 'Weather: ' .. weather })
end)

RegisterNetEvent('mike-adminmenu:client:setTime', function(h, m)
    NetworkOverrideClockTime(h, m, 0)
end)

RegisterNetEvent('mike-adminmenu:client:cleanup', function(kind)
    local ped = PlayerPedId()
    local myCoords = GetEntityCoords(ped)
    if kind == 'horses' or kind == 'peds' then
        local handle, entity = FindFirstPed()
        local success
        repeat
            if entity ~= ped and not IsPedAPlayer(entity) then
                local isHorse = IsPedModel(entity, GetHashKey('a_c_horse_americanstandard_black')) or
                                Citizen.InvokeNative(0x772A1969F649E902, entity) -- IS_PED_HORSE (rough)
                if kind == 'horses' and isHorse then
                    SetEntityAsMissionEntity(entity, true, true)
                    DeleteEntity(entity)
                elseif kind == 'peds' and not isHorse then
                    SetEntityAsMissionEntity(entity, true, true)
                    DeleteEntity(entity)
                end
            end
            success, entity = FindNextPed(handle)
        until not success
        EndFindPed(handle)
    elseif kind == 'wagons' then
        local handle, v = FindFirstVehicle()
        local success
        repeat
            SetEntityAsMissionEntity(v, true, true)
            DeleteEntity(v)
            success, v = FindNextVehicle(handle)
        until not success
        EndFindVehicle(handle)
    elseif kind == 'objects' then
        local handle, o = FindFirstObject()
        local success
        repeat
            SetEntityAsMissionEntity(o, true, true)
            DeleteEntity(o)
            success, o = FindNextObject(handle)
        until not success
        EndFindObject(handle)
    end
end)

local spectating = false
local spectateTarget = nil
RegisterNetEvent('mike-adminmenu:client:spectate', function(targetServerId)
    local targetPlayer = GetPlayerFromServerId(targetServerId)
    if targetPlayer == -1 then
        lib.notify({ type = 'error', description = 'Target not in scope' })
        return
    end
    spectating = not spectating
    if spectating then
        spectateTarget = targetPlayer
        local targetPed = GetPlayerPed(targetPlayer)
        NetworkSetInSpectatorMode(true, targetPed)
        lib.notify({ description = 'Spectating ' .. GetPlayerName(targetPlayer) })
    else
        NetworkSetInSpectatorMode(false, 0)
        lib.notify({ description = 'Spectate stopped' })
    end
end)
