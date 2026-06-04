local RSGCore = exports['rsg-core']:GetCoreObject()
local placedBenches = {}  -- benchId -> { prop, zoneId }

-- ──────────────────────────────────────────────────────────────────────────
-- Place bench: server tells us where to spawn prop + add target
-- ──────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mike-crafting:client:spawnBench', function(benchId, x, y, z, heading)
    local hash = GetHashKey(Config.BenchProp)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 3000 do Wait(10) end
    if not HasModelLoaded(hash) then return end

    local prop = CreateObject(hash, x, y, z, false, false, false, true, true)
    SetEntityHeading(prop, heading)
    PlaceObjectOnGroundProperly(prop)
    FreezeEntityPosition(prop, true)
    SetEntityAsMissionEntity(prop, true, true)
    SetModelAsNoLongerNeeded(hash)

    local zid = exports.ox_target:addSphereZone({
        coords = vector3(x, y, z),
        radius = 2.5,
        debug  = false,
        options = {
            {
                name     = 'mike_craft_use_' .. benchId,
                label    = 'Use Crafting Bench',
                icon     = 'fa-solid fa-hammer',
                onSelect = function() openCraftMenu(benchId) end,
            },
            {
                name     = 'mike_craft_pack_' .. benchId,
                label    = 'Pack up Bench',
                icon     = 'fa-solid fa-box',
                onSelect = function()
                    TriggerServerEvent('mike-crafting:server:packBench', benchId)
                end,
            },
        },
    })

    placedBenches[benchId] = { prop = prop, zoneId = zid }
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Remove bench (packed up or resource stop)
-- ──────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mike-crafting:client:removeBench', function(benchId)
    local data = placedBenches[benchId]
    if not data then return end
    if data.zoneId then exports.ox_target:removeZone(data.zoneId) end
    if data.prop and DoesEntityExist(data.prop) then
        SetEntityAsMissionEntity(data.prop, true, true)
        DeleteEntity(data.prop)
    end
    placedBenches[benchId] = nil
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Craft menu
-- ──────────────────────────────────────────────────────────────────────────
function openCraftMenu(bid)
    -- Build recipe list (filter by blueprints)
    local visibleRecipes = {}
    for key, r in pairs(Config.Recipes) do
        if r.blueprint then
            local has = exports['rsg-inventory']:HasItem(r.blueprint, 1)
            if not has then goto continue end
        end
        visibleRecipes[key] = {
            label   = r.label or ('Craft ' .. r.output),
            inputs  = r.inputs,
            output  = r.output,
            qty     = r.qty or 1,
            time    = r.time,
        }
        ::continue::
    end

    -- Get player inventory counts
    local inv = getInventoryCounts(visibleRecipes)

    -- Open NUI
    SetNuiFocus(true, true)
    SendNUIMessage({
        action  = 'open',
        recipes = visibleRecipes,
        inventory = inv,
        benchId = bid,
    })
end

function getInventoryCounts(recipeList)
    local items = {}
    local pd = RSGCore.Functions.GetPlayerData()
    if not pd or not pd.items then return items end

    for _, r in pairs(recipeList) do
        for item, _ in pairs(r.inputs) do
            if not items[item] then
                local count = 0
                for _, invItem in pairs(pd.items) do
                    if invItem and invItem.name == item then
                        count = count + (invItem.amount or 0)
                    end
                end
                items[item] = count
            end
        end
    end
    return items
end

-- NUI Callbacks
RegisterNUICallback('craft', function(data, cb)
    cb('ok')
    local recipeKey = data.recipeKey
    local qty = math.max(1, tonumber(data.qty) or 1)
    local bid = data.benchId
    startCraftNUI(bid, recipeKey, qty)
end)

RegisterNUICallback('close', function(data, cb)
    cb('ok')
    SetNuiFocus(false, false)
end)

function startCraftNUI(bid, recipeKey, batch)
    local recipe = Config.Recipes[recipeKey]; if not recipe then return end
    batch = math.max(1, tonumber(batch) or 1)
    for i = 1, batch do
        local canCraft = lib.callback.await('mike-crafting:server:checkMaterials', false, bid, recipeKey)
        if not canCraft then
            SendNUIMessage({ action = 'craftDone', inventory = getInventoryCounts(Config.Recipes) })
            return
        end

        SendNUIMessage({
            action   = 'craftProgress',
            label    = ('Crafting %s (%d/%d)...'):format(recipe.label or recipe.output, i, batch),
            duration = recipe.time,
        })

        Wait(recipe.time)

        local ok = lib.callback.await('mike-crafting:server:craft', false, bid, recipeKey)
        if not ok then
            SendNUIMessage({ action = 'craftDone', inventory = getInventoryCounts(Config.Recipes) })
            return
        end
    end
    SendNUIMessage({ action = 'craftDone', inventory = getInventoryCounts(Config.Recipes) })
end

function startCraft(benchId, recipeKey, batch)
    local recipe = Config.Recipes[recipeKey]; if not recipe then return end
    batch = math.max(1, tonumber(batch) or 1)
    for i = 1, batch do
        -- Check materials BEFORE starting progress bar
        local canCraft = lib.callback.await('mike-crafting:server:checkMaterials', false, benchId, recipeKey)
        if not canCraft then return end
        if not lib.progressBar({
            duration = recipe.time,
            label    = ('Crafting %s (%d/%d)...'):format(recipe.label or recipe.output, i, batch),
            useWhileDead = false,
            canCancel = true,
            disable  = { move = true, car = true, combat = true },
        }) then
            lib.notify({ type = 'error', description = 'Crafting cancelled' })
            return
        end
        local ok = lib.callback.await('mike-crafting:server:craft', false, benchId, recipeKey)
        if not ok then return end
    end
end

-- ──────────────────────────────────────────────────────────────────────────
-- Sync: on join, server sends all placed benches
-- ──────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mike-crafting:client:syncBenches', function(benches)
    for _, b in ipairs(benches or {}) do
        TriggerEvent('mike-crafting:client:spawnBench', b.id, b.x, b.y, b.z, b.heading)
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        for benchId, data in pairs(placedBenches) do
            if data.zoneId then exports.ox_target:removeZone(data.zoneId) end
            if data.prop and DoesEntityExist(data.prop) then
                SetEntityAsMissionEntity(data.prop, true, true)
                DeleteEntity(data.prop)
            end
        end
        placedBenches = {}
    end
end)
