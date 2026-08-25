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
                onSelect = function()
                    TriggerServerEvent('mike-crafting:server:openBenchShop', benchId)
                end,
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
-- Get full inventory for NUI (deduped items + count map)
-- ──────────────────────────────────────────────────────────────────────────
function getFullInventory()
    local pd = RSGCore.Functions.GetPlayerData()
    if not pd or not pd.items then return {}, {} end

    local counts = {}
    for _, invItem in pairs(pd.items) do
        if invItem and invItem.name and (invItem.amount or 0) > 0 then
            counts[invItem.name] = (counts[invItem.name] or 0) + (invItem.amount or 0)
        end
    end

    local items = {}
    for name, amount in pairs(counts) do
        items[#items + 1] = { name = name, amount = amount }
    end

    table.sort(items, function(a, b) return a.name < b.name end)
    return items, counts
end

-- ──────────────────────────────────────────────────────────────────────────
-- Unified craft menu: works for both bench and portable (crafting book)
-- ──────────────────────────────────────────────────────────────────────────
function openCraftMenu(bid)
    local isPortable = (bid == 'portable')

    local visibleRecipes = {}
    for key, r in pairs(Config.Recipes) do
        if isPortable and not r.portable then goto continue end
        if r.blueprint then
            local has = exports['rsg-inventory']:HasItem(r.blueprint, 1)
            if not has then goto continue end
        end
        visibleRecipes[key] = {
            label    = r.label or ('Craft ' .. r.output),
            inputs   = r.inputs,
            output   = r.output,
            qty      = r.qty or 1,
            time     = r.time,
            portable = r.portable or false,
            category = r.category or 'general',
        }
        ::continue::
    end

    local items, counts = getFullInventory()

    SetNuiFocus(true, true)
    SendNUIMessage({
        action    = 'open',
        recipes   = visibleRecipes,
        inventory = counts,
        items     = items,
        benchId   = bid,
        mode      = isPortable and 'portable' or 'bench',
        title     = isPortable and 'Crafting' or 'Crafting Bench',
    })
end

-- Portable crafting (crafting book) → same NUI
function openPortableCraftMenu()
    openCraftMenu('portable')
end

RegisterNetEvent('mike-crafting:client:openPortable', function()
    openPortableCraftMenu()
end)

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
    local isPortable = (bid == 'portable')
    batch = math.max(1, tonumber(batch) or 1)

    for i = 1, batch do
        local canCraft
        if isPortable then
            canCraft = lib.callback.await('mike-crafting:server:checkPortable', false, recipeKey)
        else
            canCraft = lib.callback.await('mike-crafting:server:checkMaterials', false, bid, recipeKey)
        end
        if not canCraft then
            local items, counts = getFullInventory()
            SendNUIMessage({ action = 'craftDone', inventory = counts, items = items })
            return
        end

        SendNUIMessage({
            action   = 'craftProgress',
            label    = ('Crafting %s (%d/%d)...'):format(recipe.label or recipe.output, i, batch),
            duration = recipe.time,
        })

        Wait(recipe.time)

        local ok
        if isPortable then
            ok = lib.callback.await('mike-crafting:server:craftPortable', false, recipeKey)
        else
            ok = lib.callback.await('mike-crafting:server:craft', false, bid, recipeKey)
        end
        if not ok then
            local items, counts = getFullInventory()
            SendNUIMessage({ action = 'craftDone', inventory = counts, items = items })
            return
        end
    end

    local items, counts = getFullInventory()
    SendNUIMessage({ action = 'craftDone', inventory = counts, items = items })
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
