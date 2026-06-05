-- ──────────────────────────────────────────────────────────────────────────
-- Legendary Animals: proximity-based spawning of rare unique animals
-- ──────────────────────────────────────────────────────────────────────────
local spawnedLegendaries = {}  -- legendaryKey -> { entity, spawned = true }
local notifiedLegendaries = {} -- legendaryKey -> true (prevent spam notifications)

local function loadModel(hash)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 5000 do Wait(10) end
    return HasModelLoaded(hash)
end

local function spawnLegendary(key, def)
    local hash = GetHashKey(def.model)
    if not loadModel(hash) then return end

    local animal = CreatePed(hash, def.coords.x, def.coords.y, def.coords.z, def.heading, true, false, false, false)
    if not animal or animal == 0 then return end

    SetModelAsNoLongerNeeded(hash)

    -- Give it extra health to make it a tougher fight
    SetEntityMaxHealth(animal, 800)
    SetEntityHealth(animal, 800)

    -- Let it wander near its spawn point
    TaskWanderInArea(animal, def.coords.x, def.coords.y, def.coords.z, def.wanderRadius, 0, 0)

    -- Track it
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
-- Proximity check: every 10 seconds, check if player is near spawn points
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    Wait(5000) -- Wait for game to settle

    while true do
        Wait(10000)
        local pCoords = GetEntityCoords(PlayerPedId())

        -- Get available legendaries from server
        local available = lib.callback.await('mike-hunting:server:checkLegendaries', false)
        if not available then goto continue end

        for key, def in pairs(Config.LegendaryAnimals) do
            local dist = #(pCoords - def.coords)
            local isSpawned = spawnedLegendaries[key] ~= nil

            if isSpawned then
                -- Check if player left the area — despawn
                if dist > Config.LegendarySpawnRadius * 1.5 then
                    despawnLegendary(key, true)
                end
            else
                -- Check if close enough to spawn
                if available[key] and dist <= Config.LegendarySpawnRadius then
                    local claimed = lib.callback.await('mike-hunting:server:claimLegendarySpawn', false, key)
                    if claimed then
                        spawnLegendary(key, def)
                    end
                elseif available[key] and dist <= Config.LegendaryNotifyRadius and not notifiedLegendaries[key] then
                    notifiedLegendaries[key] = true
                    lib.notify({
                        type = 'inform',
                        description = 'You sense something legendary in this area...',
                        duration = 4000,
                    })
                end
            end
        end

        ::continue::
    end
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Check spawned legendaries for death (every 2 seconds)
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(2000)
        for key, data in pairs(spawnedLegendaries) do
            if data.entity and DoesEntityExist(data.entity) then
                if IsPedDeadOrDying(data.entity, true) then
                    -- The EVENT_LOOT_COMPLETE handler in main.lua will handle
                    -- the actual skinning via LegendaryEntityLookup.
                    -- We just stop tracking spawn state here.
                    spawnedLegendaries[key] = nil
                    notifiedLegendaries[key] = nil
                    -- Don't remove from LegendaryEntityLookup yet —
                    -- main.lua needs it when EVENT_LOOT_COMPLETE fires
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
    end
end)
