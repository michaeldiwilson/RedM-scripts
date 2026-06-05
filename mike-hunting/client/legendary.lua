-- ──────────────────────────────────────────────────────────────────────────
-- Legendary Animals: buy a rumor at the butcher to reveal territory on map
-- Server picks a random location for multi-location legendaries
-- ──────────────────────────────────────────────────────────────────────────
local spawnedLegendaries = {}    -- legendaryKey -> { entity }
local notifiedLegendaries = {}   -- legendaryKey -> true
local legendaryBlips = {}        -- legendaryKey -> blip handle
local discoveredLegendaries = {} -- legendaryKey -> { coords = vec3 } (from server)

local function loadModel(hash)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 5000 do Wait(10) end
    return HasModelLoaded(hash)
end

-- ──────────────────────────────────────────────────────────────────────────
-- Area blip: rough circle on the map (offset slightly so it's not exact)
-- ──────────────────────────────────────────────────────────────────────────
local function addLegendaryBlip(key, label, coords)
    if legendaryBlips[key] then return end

    -- Offset the blip slightly so the circle isn't centered exactly on the spawn
    local ox = math.random(-50, 50) + 0.0
    local oy = math.random(-50, 50) + 0.0
    local bx = coords.x + ox
    local by = coords.y + oy
    local bz = coords.z

    -- Create an area blip (circle on the map) using _BLIP_ADD_FOR_AREA
    local areaSize = 200.0
    local blip = Citizen.InvokeNative(0xEC174ADBCB611ECC, 1664425300, bx + 0.0, by + 0.0, bz + 0.0, areaSize, areaSize, 0.0, 0)
    if blip and blip ~= 0 then
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, label .. ' Territory')
        legendaryBlips[key] = blip
    end

    -- Also add a small icon blip at the rough center
    local iconBlip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, bx + 0.0, by + 0.0, bz + 0.0)
    if iconBlip and iconBlip ~= 0 then
        SetBlipSprite(iconBlip, joaat('blip_hunt_animal_clue'), true)
        Citizen.InvokeNative(0x9CB1A1623062F402, iconBlip, label)
        legendaryBlips[key .. '_icon'] = iconBlip
    end
end

local function removeLegendaryBlip(key)
    for _, suffix in ipairs({'', '_icon'}) do
        local blipKey = key .. suffix
        if legendaryBlips[blipKey] and DoesBlipExist(legendaryBlips[blipKey]) then
            RemoveBlip(legendaryBlips[blipKey])
        end
        legendaryBlips[blipKey] = nil
    end
end

-- ──────────────────────────────────────────────────────────────────────────
-- Rumor: server tells client the active coords for this legendary
-- ──────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mike-hunting:client:revealLegendary', function(legendaryKey, activeCoords)
    local def = Config.LegendaryAnimals[legendaryKey]
    if not def then return end

    discoveredLegendaries[legendaryKey] = { coords = activeCoords }
    addLegendaryBlip(legendaryKey, def.label, activeCoords)

    lib.notify({
        type = 'success',
        title = 'Legendary Rumor',
        description = 'The butcher told you about a ' .. def.label .. '. The area has been marked on your map.',
        duration = 6000,
    })
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Spawn / despawn — uses coords from server (not config)
-- ──────────────────────────────────────────────────────────────────────────
local function spawnLegendary(key, def, coords, heading)
    local hash = GetHashKey(def.model)
    if not loadModel(hash) then return end

    local animal = CreatePed(hash, coords.x, coords.y, coords.z, heading, true, false, false, false)
    if not animal or animal == 0 then return end

    SetModelAsNoLongerNeeded(hash)
    SetEntityMaxHealth(animal, 800)
    SetEntityHealth(animal, 800)
    TaskWanderInArea(animal, coords.x, coords.y, coords.z, def.wanderRadius, 0, 0)

    spawnedLegendaries[key] = { entity = animal }
    LegendaryEntityLookup[animal] = key

    lib.notify({
        type = 'inform',
        title = 'Legendary Animal',
        description = 'You sense a ' .. def.label .. ' nearby...',
        duration = 5000,
    })
end

local function despawnLegendary(key, notifyServer)
    local data = spawnedLegendaries[key]
    if not data then return end

    local entity = data.entity
    if entity then
        LegendaryEntityLookup[entity] = nil
        if DoesEntityExist(entity) then
            SetEntityAsMissionEntity(entity, true, true)
            DeleteEntity(entity)
        end
    end

    spawnedLegendaries[key] = nil
    notifiedLegendaries[key] = nil

    if notifyServer then
        TriggerServerEvent('mike-hunting:server:legendaryDespawned', key)
    end
end

-- ──────────────────────────────────────────────────────────────────────────
-- Proximity check: uses active coords from server
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    Wait(5000)

    while true do
        Wait(10000)
        local pCoords = GetEntityCoords(PlayerPedId())

        local available = lib.callback.await('mike-hunting:server:checkLegendaries', false)
        if not available then goto continue end

        for key, def in pairs(Config.LegendaryAnimals) do
            if not discoveredLegendaries[key] then goto nextLeg end

            -- Use server-provided coords for proximity
            local info = available[key]
            if not info then goto nextLeg end

            local activeCoords = info.coords
            local activeHeading = info.heading
            local dist = #(pCoords - activeCoords)
            local isSpawned = spawnedLegendaries[key] ~= nil

            if isSpawned then
                if dist > Config.LegendarySpawnRadius * 1.5 then
                    despawnLegendary(key, true)
                end
            else
                if dist <= Config.LegendarySpawnRadius then
                    local claimed = lib.callback.await('mike-hunting:server:claimLegendarySpawn', false, key)
                    if claimed then
                        spawnLegendary(key, def, activeCoords, activeHeading)
                    end
                elseif dist <= Config.LegendaryNotifyRadius and not notifiedLegendaries[key] then
                    notifiedLegendaries[key] = true
                    lib.notify({
                        type = 'inform',
                        description = 'You sense something legendary in this area...',
                        duration = 4000,
                    })
                end
            end

            ::nextLeg::
        end

        ::continue::
    end
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Check spawned legendaries for death
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(2000)
        for key, data in pairs(spawnedLegendaries) do
            if data.entity and DoesEntityExist(data.entity) then
                if IsPedDeadOrDying(data.entity, true) then
                    spawnedLegendaries[key] = nil
                    notifiedLegendaries[key] = nil
                    removeLegendaryBlip(key)
                    discoveredLegendaries[key] = nil
                end
            end
        end
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        for key in pairs(spawnedLegendaries) do
            despawnLegendary(key, true)
        end
        for blipKey, blip in pairs(legendaryBlips) do
            if DoesBlipExist(blip) then RemoveBlip(blip) end
        end
        legendaryBlips = {}
    end
end)
