local RSGCore = exports['rsg-core']:GetCoreObject()
local animalData = {}    -- id -> data from server
local animalPeds = {}    -- id -> entity
local animalZones = {}   -- id -> zoneId
local traderPed = nil
local traderZone = nil

local function loadModel(hash)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 5000 do Wait(10) end
    return HasModelLoaded(hash)
end

-- ──────────────────────────────────────────────────────────────────────────
-- Spawn/despawn animals based on proximity
-- ──────────────────────────────────────────────────────────────────────────
local function spawnAnimal(a)
    if animalPeds[a.id] and DoesEntityExist(animalPeds[a.id]) then return end
    local typeDef = Config.AnimalTypes[a.type]; if not typeDef then return end

    local hash = GetHashKey(typeDef.model)
    if not loadModel(hash) then return end

    local ped = CreatePed(hash, a.x + 0.0, a.y + 0.0, a.z + 0.0, a.heading + 0.0, false, false, false, false)
    if not ped or ped == 0 then return end

    SetModelAsNoLongerNeeded(hash)
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true) -- SetRandomOutfitVariation
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskWanderInArea(ped, a.x + 0.0, a.y + 0.0, a.z + 0.0, 8.0, 0, 0)

    animalPeds[a.id] = ped

    -- Determine status icon
    local statusIcon = 'fa-solid fa-heart'
    if a.hunger <= 20 then statusIcon = 'fa-solid fa-triangle-exclamation' end

    local zid = exports.ox_target:addSphereZone({
        coords = vector3(a.x, a.y, a.z),
        radius = 4.0,
        debug  = false,
        options = {
            {
                name     = 'mike_ranch_' .. a.id,
                label    = a.name or 'Animal',
                icon     = statusIcon,
                onSelect = function() openAnimalMenu(a.id) end,
            },
        },
    })
    animalZones[a.id] = zid
end

local function removeAnimal(id)
    if animalZones[id] then exports.ox_target:removeZone(animalZones[id]); animalZones[id] = nil end
    if animalPeds[id] and DoesEntityExist(animalPeds[id]) then
        SetEntityAsMissionEntity(animalPeds[id], true, true)
        DeleteEntity(animalPeds[id])
    end
    animalPeds[id] = nil
end

-- ──────────────────────────────────────────────────────────────────────────
-- Sync from server
-- ──────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mike-ranching:client:syncAnimals', function(data)
    animalData = data or {}
    -- Remove animals no longer in data
    for id in pairs(animalPeds) do
        if not animalData[id] then removeAnimal(id) end
    end
end)

-- Proximity spawning
CreateThread(function()
    while true do
        Wait(3000)
        local pc = GetEntityCoords(PlayerPedId())
        for id, a in pairs(animalData) do
            local d = #(pc - vector3(a.x + 0.0, a.y + 0.0, a.z + 0.0))
            if d <= 120.0 then
                spawnAnimal(a)
            else
                removeAnimal(id)
            end
        end
    end
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Animal interaction menu
-- ──────────────────────────────────────────────────────────────────────────
function openAnimalMenu(animalId)
    local info = lib.callback.await('mike-ranching:server:getAnimalInfo', false, animalId)
    if not info then return end

    local typeDef = Config.AnimalTypes[info.type]
    if not typeDef then return end

    local hungerBar = string.rep('█', math.floor(info.hunger / 10)) .. string.rep('░', 10 - math.floor(info.hunger / 10))
    local thirstBar = string.rep('█', math.floor(info.thirst / 10)) .. string.rep('░', 10 - math.floor(info.thirst / 10))

    local opts = {}

    -- Status
    opts[#opts + 1] = {
        title       = info.name .. ' (' .. typeDef.label .. ')',
        description = ('Hunger: %s %d%%\nThirst: %s %d%%'):format(hungerBar, info.hunger, thirstBar, info.thirst),
        icon        = 'fa-solid fa-heart',
        disabled    = true,
    }

    -- Feed
    opts[#opts + 1] = {
        title       = 'Feed (' .. typeDef.feedQty .. 'x ' .. typeDef.feedItem:gsub('_', ' ') .. ')',
        icon        = 'fa-solid fa-wheat-awn',
        onSelect    = function()
            if lib.progressBar({
                duration = 3000,
                label = 'Feeding ' .. info.name .. '...',
                useWhileDead = false, canCancel = true,
                disable = { move = true, car = true, combat = true },
            }) then
                lib.callback.await('mike-ranching:server:feedAnimal', false, animalId)
            end
        end,
    }

    -- Water
    opts[#opts + 1] = {
        title       = 'Water',
        icon        = 'fa-solid fa-droplet',
        onSelect    = function()
            if lib.progressBar({
                duration = 3000,
                label = 'Watering ' .. info.name .. '...',
                useWhileDead = false, canCancel = true,
                disable = { move = true, car = true, combat = true },
            }) then
                lib.callback.await('mike-ranching:server:waterAnimal', false, animalId)
            end
        end,
    }

    -- Collect produce
    if info.produceReady then
        opts[#opts + 1] = {
            title       = 'Collect ' .. info.produceLabel,
            icon        = 'fa-solid fa-basket-shopping',
            onSelect    = function()
                if lib.progressBar({
                    duration = 4000,
                    label = 'Collecting ' .. info.produceLabel .. '...',
                    useWhileDead = false, canCancel = true,
                    disable = { move = true, car = true, combat = true },
                }) then
                    lib.callback.await('mike-ranching:server:collectProduce', false, animalId)
                end
            end,
        }
    else
        local mins = math.ceil(info.produceRemaining / 60)
        opts[#opts + 1] = {
            title       = info.produceLabel .. ' — ' .. mins .. ' min remaining',
            icon        = 'fa-solid fa-hourglass-half',
            disabled    = true,
        }
    end

    -- Sell
    opts[#opts + 1] = {
        title       = 'Sell Animal ($' .. math.floor((typeDef.price or 10) * 0.5) .. ')',
        icon        = 'fa-solid fa-coins',
        onSelect    = function()
            local ok = lib.callback.await('mike-ranching:server:sellAnimal', false, animalId)
            if ok then removeAnimal(animalId); animalData[animalId] = nil end
        end,
    }

    lib.registerContext({ id = 'mike_ranch_animal_' .. animalId, title = info.name, options = opts })
    lib.showContext('mike_ranch_animal_' .. animalId)
end

-- ──────────────────────────────────────────────────────────────────────────
-- Livestock trader NPC
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    Wait(3000)

    local hash = GetHashKey(Config.Trader.model)
    if not loadModel(hash) then return end

    traderPed = CreatePed(hash, Config.Trader.coords.x, Config.Trader.coords.y, Config.Trader.coords.z - 1.0, Config.Trader.heading, false, false, false, false)
    Citizen.InvokeNative(0x283978A15512B2FE, traderPed, true)
    SetEntityInvincible(traderPed, true)
    SetBlockingOfNonTemporaryEvents(traderPed, true)
    FreezeEntityPosition(traderPed, true)
    SetModelAsNoLongerNeeded(hash)

    -- Blip
    local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, Config.Trader.coords.x + 0.0, Config.Trader.coords.y + 0.0, Config.Trader.coords.z + 0.0)
    SetBlipSprite(blip, joaat('blip_shop_horse'), true)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, Config.Trader.name)

    traderZone = exports.ox_target:addSphereZone({
        coords = Config.Trader.coords,
        radius = 3.0,
        debug  = false,
        options = {
            {
                name     = 'mike_ranch_trader',
                label    = Config.Trader.name,
                icon     = 'fa-solid fa-cow',
                onSelect = function() openTraderMenu() end,
            },
        },
    })
end)

function openTraderMenu()
    local opts = {}
    for typeKey, typeDef in pairs(Config.AnimalTypes) do
        opts[#opts + 1] = {
            title       = ('Buy %s — $%d'):format(typeDef.label, typeDef.price),
            description = ('Produces: %s'):format(typeDef.produce.label),
            icon        = 'fa-solid fa-paw',
            onSelect    = function()
                lib.callback.await('mike-ranching:server:buyAnimal', false, typeKey)
            end,
        }
    end

    lib.registerContext({ id = 'mike_ranch_trader', title = Config.Trader.name, options = opts })
    lib.showContext('mike_ranch_trader')
end

-- Cleanup
AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        for id in pairs(animalPeds) do removeAnimal(id) end
        if traderPed and DoesEntityExist(traderPed) then
            SetEntityAsMissionEntity(traderPed, true, true)
            DeleteEntity(traderPed)
        end
        if traderZone then exports.ox_target:removeZone(traderZone) end
    end
end)
