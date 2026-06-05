local skinnedAnimals = {}  -- netId -> true

-- Build hash lookup from config (shared with eagleeye.lua)
AnimalHashLookup = {}
for modelName, typeKey in pairs(Config.AnimalModels) do
    AnimalHashLookup[joaat(modelName)] = typeKey
end

-- Legendary entity tracking (populated by legendary.lua)
LegendaryEntityLookup = {}  -- entity -> legendaryKey

-- ──────────────────────────────────────────────────────────────────────────
-- Track the nearest dead animal the player is standing next to.
-- Updated every 500ms so we know which animal is being skinned when
-- EVENT_LOOT_COMPLETE fires. Also snapshots weapon on first death detection.
-- ──────────────────────────────────────────────────────────────────────────
local nearestDeadAnimal = nil   -- { entity, typeKey, netId }

CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        local p = GetEntityCoords(ped)
        local currentWeapon = GetCurrentWeapon(ped)
        local best, bestDist, bestType = nil, Config.SkinRadius, nil

        for _, animal in pairs(GetGamePool('CPed') or {}) do
            if DoesEntityExist(animal) and IsPedDeadOrDying(animal, true) and not IsPedAPlayer(animal) then
                local model = GetEntityModel(animal)
                local typeKey = AnimalHashLookup[model]
                if typeKey then
                    local netId = NetworkGetNetworkIdFromEntity(animal)
                    if not skinnedAnimals[netId] then
                        -- Snapshot weapon on first time seeing this animal dead
                        if not SeenDeadAnimals[netId] then
                            SeenDeadAnimals[netId] = true
                            AnimalKillWeapon[netId] = currentWeapon
                        end

                        local d = #(GetEntityCoords(animal) - p)
                        if d <= bestDist then
                            best = animal
                            bestDist = d
                            bestType = typeKey
                        end
                    end
                end
            end
        end

        if best then
            nearestDeadAnimal = {
                entity  = best,
                typeKey = bestType,
                netId   = NetworkGetNetworkIdFromEntity(best),
            }
        else
            nearestDeadAnimal = nil
        end
    end
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Native event polling: detect EVENT_LOOT_COMPLETE
-- The game handles the skinning animation + prompt. We just catch the
-- completion event, delete the native pelt, and give custom items.
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    local EVENT_LOOT_COMPLETE = joaat('EVENT_LOOT_COMPLETE')

    while true do
        Wait(0)
        local eventCount = GetNumberOfEvents(0)
        for i = 0, eventCount - 1 do
            local event = GetEventAtIndex(0, i)
            if event == EVENT_LOOT_COMPLETE and nearestDeadAnimal then
                local animal = nearestDeadAnimal
                skinnedAnimals[animal.netId] = true
                nearestDeadAnimal = nil

                -- Wait for game to spawn the native pelt in player's hands, then delete it
                CreateThread(function()
                    Wait(1500)
                    local holding = Citizen.InvokeNative(0xD806CD2A4F2C2996, PlayerPedId())
                    if holding and holding ~= 0 and DoesEntityExist(holding) then
                        SetEntityAsMissionEntity(holding, true, true)
                        DeleteEntity(holding)
                    end
                end)

                -- Check if this is a legendary animal
                local legKey = LegendaryEntityLookup[animal.entity]
                if legKey then
                    TriggerServerEvent('mike-hunting:server:legendaryKilled', legKey)
                    LegendaryEntityLookup[animal.entity] = nil
                else
                    -- Determine pelt quality from weapon used
                    local weaponHash = AnimalKillWeapon[animal.netId] or 0
                    local quality = DetermineQuality(animal.typeKey, weaponHash)
                    TriggerServerEvent('mike-hunting:server:skin', animal.netId, animal.typeKey, quality)
                end

                -- Cleanup tracking tables
                AnimalKillWeapon[animal.netId] = nil
                SeenDeadAnimals[animal.netId] = nil
            end
        end
    end
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Butcher shops: sell meat, pelts, carcasses, parts from inventory
-- ──────────────────────────────────────────────────────────────────────────
local butcherZones = {}

local function openButcherMenu()
    lib.registerContext({
        id = 'mike_butcher_main',
        title = 'Butcher',
        options = {
            {
                title       = 'Sell Goods',
                description = 'Sell meat, pelts, carcasses and parts',
                icon        = 'fa-solid fa-coins',
                onSelect    = function()
                    TriggerServerEvent('mike-hunting:server:getButcherStock')
                end,
            },
            {
                title       = 'Legendary Rumors',
                description = 'Buy information about legendary animals in the area',
                icon        = 'fa-solid fa-map',
                onSelect    = function() openLegendaryRumors() end,
            },
        },
    })
    lib.showContext('mike_butcher_main')
end

function openLegendaryRumors()
    local opts = {}
    for key, def in pairs(Config.LegendaryAnimals) do
        local price = def.rumorPrice or 25
        if discoveredLegendaries and discoveredLegendaries[key] then
            opts[#opts + 1] = {
                title       = def.label,
                description = 'Already discovered',
                icon        = 'fa-solid fa-check',
                disabled    = true,
            }
        else
            opts[#opts + 1] = {
                title       = def.label .. ' — $' .. price,
                description = 'Buy a rumor about this legendary animal',
                icon        = 'fa-solid fa-scroll',
                onSelect    = function()
                    lib.callback.await('mike-hunting:server:buyRumor', false, key)
                end,
            }
        end
    end

    lib.registerContext({ id = 'mike_butcher_rumors', title = 'Legendary Rumors', menu = 'mike_butcher_main', options = opts })
    lib.showContext('mike_butcher_rumors')
end

RegisterNetEvent('mike-hunting:client:showButcher', function(sellableItems)
    if not sellableItems or #sellableItems == 0 then
        return lib.notify({ type = 'inform', description = 'You have nothing to sell.' })
    end

    local opts = {}
    for _, si in ipairs(sellableItems) do
        opts[#opts + 1] = {
            title       = ('Sell %s — $%d each'):format(si.label, si.price),
            description = ('You have: %d'):format(si.amount),
            icon        = 'fa-solid fa-coins',
            onSelect    = function()
                local res = lib.inputDialog('Sell ' .. si.label, {
                    { type = 'number', label = 'How many?', default = si.amount, min = 1, max = si.amount, required = true },
                })
                if not res then return end
                TriggerServerEvent('mike-hunting:server:sellToButcher', si.item, res[1])
            end,
        }
    end

    lib.registerContext({ id = 'mike_butcher', title = 'Sell Goods', menu = 'mike_butcher_main', options = opts })
    lib.showContext('mike_butcher')
end)

RegisterNetEvent('mike-hunting:client:carcassReady', function(typeKey, animalNetId)
    lib.notify({
        type = 'inform',
        title = 'Carcass',
        description = 'Load onto a hunting wagon to sell whole at a butcher.',
        duration = 5000,
    })
end)

local butcherPeds = {}

CreateThread(function()
    Wait(2500)
    for idx, b in ipairs(Config.Butchers) do
        -- Spawn NPC if model defined
        if b.npcmodel then
            local hash = GetHashKey(b.npcmodel)
            RequestModel(hash)
            local t = GetGameTimer()
            while not HasModelLoaded(hash) and GetGameTimer() - t < 5000 do Wait(10) end
            if HasModelLoaded(hash) then
                local npc = CreatePed(hash, b.coords.x, b.coords.y, b.coords.z - 1.0, 0.0, false, false, false, false)
                Citizen.InvokeNative(0x283978A15512B2FE, npc, true) -- SetRandomOutfitVariation
                SetEntityInvincible(npc, true)
                SetBlockingOfNonTemporaryEvents(npc, true)
                FreezeEntityPosition(npc, true)
                SetModelAsNoLongerNeeded(hash)
                butcherPeds[#butcherPeds + 1] = npc
            end
        end

        local zid = exports.ox_target:addSphereZone({
            coords = b.coords,
            radius = Config.ButcherRadius,
            debug  = false,
            options = {
                {
                    name  = 'mike_butcher_' .. idx,
                    label = b.name,
                    icon  = 'fa-solid fa-drumstick-bite',
                    onSelect = function() openButcherMenu() end,
                },
            },
        })
        butcherZones[#butcherZones + 1] = zid
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        for _, id in ipairs(butcherZones) do exports.ox_target:removeZone(id) end
        for _, ped in ipairs(butcherPeds) do
            if DoesEntityExist(ped) then
                SetEntityAsMissionEntity(ped, true, true)
                DeleteEntity(ped)
            end
        end
    end
end)
