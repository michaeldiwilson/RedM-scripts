function StartMine(idx)
    if lib.progressBar({
        duration = Config.MineTime,
        label = 'Mining...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    }) then
        TriggerServerEvent('mike-mining:server:mine', idx)
    end
end

function PlaceTNT(idx, node)
    local ped = PlayerPedId()
    local p = GetEntityCoords(ped)

    -- Crouch/kneel scenario while placing
    TaskStartScenarioInPlace(ped, joaat('MP_LOBBY_WORLD_HUMAN_CROUCH_INSPECT'), -1, true, false, false, false)
    if lib.progressBar({
        duration = 3000,
        label = 'Placing TNT...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    }) then
        ClearPedTasks(ped)
        TriggerServerEvent('mike-mining:server:tntPlaced', idx, { x = p.x, y = p.y, z = p.z })
        lib.notify({ type = 'warning', title = 'Fuse lit!', description = ('Run! %ds fuse!'):format(Config.TNT.fuseSeconds), duration = 4000 })
    else
        ClearPedTasks(ped)
        lib.notify({ type = 'error', description = 'Placement cancelled' })
    end
end

local fuseProps = {}  -- idx -> prop entity

RegisterNetEvent('mike-mining:client:armTNT', function(idx, pos)
    if fuseProps[idx] then return end
    pos = pos or Config.Nodes[idx]; if not pos then return end

    local hash = GetHashKey(Config.TNT.propPlaced)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 2000 do Wait(10) end
    if HasModelLoaded(hash) then
        local prop = CreateObject(hash, pos.x, pos.y, pos.z + 0.5, false, false, false, true, true)
        PlaceObjectOnGroundProperly(prop)
        SetEntityAsMissionEntity(prop, true, true)
        SetModelAsNoLongerNeeded(hash)
        fuseProps[idx] = prop
    end
end)

RegisterNetEvent('mike-mining:client:tntBoom', function(idx, pos)
    local node = Config.Nodes[idx]
    local prop = fuseProps[idx]
    local coords = (prop and DoesEntityExist(prop)) and GetEntityCoords(prop)
                    or (pos and vector3(pos.x, pos.y, pos.z))
                    or (node and vector3(node.x, node.y, node.z))
    if not coords then return end

    -- Delete prop before explosion
    if prop and DoesEntityExist(prop) then
        SetEntityAsMissionEntity(prop, true, true)
        DeleteEntity(prop)
    end
    fuseProps[idx] = nil

    -- Real RDR2 explosion at the blast site (type 27 = dynamite, lower power)
    AddExplosion(coords.x, coords.y, coords.z, 27, 5.0, true, false, 0.5)

    -- Screen shake based on distance
    local ped = PlayerPedId()
    local d = #(GetEntityCoords(ped) - coords)
    if d <= Config.TNT.blastRadius * 3 then
        local intensity = math.max(0.1, 1.0 - (d / (Config.TNT.blastRadius * 3)))
        ShakeGameplayCam('DRUNK_SHAKE', intensity)
        Wait(1500)
        StopGameplayCamShaking(true)
    end

    -- Damage/kill player if within blast radius
    if d <= Config.TNT.blastRadius then
        local dmg = math.floor((1 - d / Config.TNT.blastRadius) * 500)
        local hp  = GetEntityHealth(ped)
        SetEntityHealth(ped, math.max(hp - dmg, 0))
        if dmg >= hp then
            lib.notify({ type = 'error', title = 'BOOM!', description = 'You were too close!', duration = 5000 })
        else
            lib.notify({ type = 'error', title = 'BOOM!', description = ('Caught in the blast! -%d HP'):format(dmg), duration = 5000 })
        end
    else
        lib.notify({ type = 'inform', title = 'BOOM!', description = ('The charge goes off (you were %dm away).'):format(math.floor(d)), duration = 4000 })
    end
end)
