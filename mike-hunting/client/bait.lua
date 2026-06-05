-- ──────────────────────────────────────────────────────────────────────────
-- Bait placement + animal attraction
-- ──────────────────────────────────────────────────────────────────────────
local activeBaits = {}  -- { prop, animals = {}, thread }
local baitCount = 0

-- Reverse lookup: typeKey -> model name (for spawning animals)
local animalModelForType = {}
for modelName, typeKey in pairs(Config.AnimalModels) do
    if not animalModelForType[typeKey] then
        animalModelForType[typeKey] = modelName
    end
end

local function loadModel(hash)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 5000 do Wait(10) end
    return HasModelLoaded(hash)
end

local function cleanupBait(baitId)
    local bait = activeBaits[baitId]
    if not bait then return end

    -- Delete prop
    if bait.prop and DoesEntityExist(bait.prop) then
        SetEntityAsMissionEntity(bait.prop, true, true)
        DeleteEntity(bait.prop)
    end

    -- Delete spawned animals (only if still alive — dead ones stay for skinning)
    for _, animal in ipairs(bait.animals or {}) do
        if DoesEntityExist(animal) and not IsPedDeadOrDying(animal, true) then
            SetEntityAsMissionEntity(animal, true, true)
            DeleteEntity(animal)
        end
    end

    activeBaits[baitId] = nil
    baitCount = baitCount - 1
end

RegisterNetEvent('mike-hunting:client:placeBait', function(baitType)
    local baitConfig = Config.Bait[baitType]
    if not baitConfig then return end

    if baitCount >= Config.MaxActiveBaits then
        lib.notify({ type = 'error', description = 'You already have the maximum baits placed' })
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local fwd = GetEntityForwardVector(ped)
    local placeCoords = coords + fwd * 1.5

    -- Place bait prop
    local propHash = GetHashKey(baitConfig.prop)
    if not loadModel(propHash) then
        lib.notify({ type = 'error', description = 'Failed to place bait' })
        return
    end

    local prop = CreateObject(propHash, placeCoords.x, placeCoords.y, placeCoords.z, false, false, false, true, true)
    PlaceObjectOnGroundProperly(prop)
    FreezeEntityPosition(prop, true)
    SetEntityAsMissionEntity(prop, true, true)
    SetModelAsNoLongerNeeded(propHash)

    local baitId = GetGameTimer()
    baitCount = baitCount + 1
    activeBaits[baitId] = { prop = prop, animals = {}, coords = placeCoords }

    lib.notify({ type = 'success', description = baitConfig.label .. ' placed. Wait for animals...', duration = 3000 })

    -- Attraction thread
    CreateThread(function()
        -- Wait for animals to be attracted
        local delay = math.random(baitConfig.delay.min, baitConfig.delay.max) * 1000
        Wait(delay)

        if not activeBaits[baitId] then return end

        -- Spawn animals
        local spawnCount = math.random(baitConfig.spawnCount.min, baitConfig.spawnCount.max)
        local baitCoords = activeBaits[baitId].coords

        for i = 1, spawnCount do
            local typeKey = baitConfig.attracts[math.random(#baitConfig.attracts)]
            local modelName = animalModelForType[typeKey]
            if not modelName then goto nextAnimal end

            local hash = GetHashKey(modelName)
            if not loadModel(hash) then goto nextAnimal end

            -- Spawn at random angle + distance from bait
            local angle = math.random() * math.pi * 2
            local dist = math.random(baitConfig.spawnDist.min, baitConfig.spawnDist.max) + 0.0
            local spawnX = baitCoords.x + math.cos(angle) * dist
            local spawnY = baitCoords.y + math.sin(angle) * dist
            local spawnZ = baitCoords.z

            -- Get ground Z
            local found, groundZ = GetGroundZFor_3dCoord(spawnX, spawnY, spawnZ + 50.0, false)
            if found then spawnZ = groundZ end

            local animal = CreatePed(hash, spawnX, spawnY, spawnZ, 0.0, true, false, false, false)
            if animal and animal ~= 0 then
                SetModelAsNoLongerNeeded(hash)
                -- Walk toward bait
                TaskGoToCoordAnyMeans(animal, baitCoords.x, baitCoords.y, baitCoords.z, 1.0, 0, false, 786603, 0.0)
                activeBaits[baitId].animals[#activeBaits[baitId].animals + 1] = animal
            end

            ::nextAnimal::
        end

        if #activeBaits[baitId].animals > 0 then
            lib.notify({ type = 'inform', description = 'Animals are approaching the bait...', duration = 3000 })
        end

        -- Wait for lifetime then cleanup
        Wait(baitConfig.lifetime * 1000)
        cleanupBait(baitId)
    end)
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        for baitId in pairs(activeBaits) do
            cleanupBait(baitId)
        end
    end
end)
