local RSGCore = exports['rsg-core']:GetCoreObject()

-- ──────────────────────────────────────────────────────────────────────────
-- Portable items
-- ──────────────────────────────────────────────────────────────────────────
-- ──────────────────────────────────────────────────────────────────────────
-- Register cooking shops (inventory UI) for each tier
-- ──────────────────────────────────────────────────────────────────────────
local function buildCookingShopItems(maxTier)
    local shopItems = {}
    for rawItem, recipe in pairs(Config.Recipes) do
        local recipeTier = recipe.tier or 1
        if recipeTier > maxTier then goto nextRecipe end

        local parts = {}
        if recipe.inputs then
            for item, qty in pairs(recipe.inputs) do
                local info = RSGCore.Shared.Items[item]
                local label = info and info.label or item:gsub('_', ' ')
                parts[#parts + 1] = qty .. 'x ' .. label
            end
        else
            local info = RSGCore.Shared.Items[rawItem]
            local label = info and info.label or rawItem:gsub('_', ' ')
            parts[#parts + 1] = '1x ' .. label
        end

        shopItems[#shopItems + 1] = {
            name   = recipe.output,
            price  = nil,
            amount = 999,
            info   = {
                craftInputs = recipe.inputs or { [rawItem] = 1 },
                craftQty    = recipe.qty or 1,
                description = 'Requires: ' .. table.concat(parts, ', '),
            },
        }
        ::nextRecipe::
    end
    return shopItems
end

CreateThread(function()
    Wait(3000)
    exports['rsg-inventory']:CreateShop({ name = 'cooking_campfire', label = 'Campfire Cooking', items = buildCookingShopItems(1) })
    exports['rsg-inventory']:CreateShop({ name = 'cooking_pot', label = 'Cooking Pot', items = buildCookingShopItems(2) })
    exports['rsg-inventory']:CreateShop({ name = 'cooking_stove', label = 'Stove Cooking', items = buildCookingShopItems(3) })
end)

-- Open cooking shop via inventory UI
RegisterNetEvent('mike-cooking:server:openShop', function(shopName)
    local src = source
    exports['rsg-inventory']:OpenShop(src, shopName)
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Portable items
-- ──────────────────────────────────────────────────────────────────────────
RSGCore.Functions.CreateUseableItem('portable_campfire', function(src, item)
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    P.Functions.RemoveItem('portable_campfire', 1)
    TriggerClientEvent('mike-cooking:client:placeCampfire', src)
end)

RSGCore.Functions.CreateUseableItem('drying_rack_item', function(src, item)
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    P.Functions.RemoveItem('drying_rack_item', 1)
    TriggerClientEvent('mike-cooking:client:placeDryingRack', src)
end)

RegisterNetEvent('mike-cooking:server:packCampfire', function()
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    P.Functions.AddItem('portable_campfire', 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['portable_campfire'], 'add', 1)
end)

RegisterNetEvent('mike-cooking:server:packDryingRack', function()
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    P.Functions.AddItem('drying_rack_item', 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['drying_rack_item'], 'add', 1)
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Cook: handles both simple (1 raw → cooked) and multi-ingredient recipes
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-cooking:server:cook', function(source, rawItem)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end

    local recipe = Config.Recipes[rawItem]
    if not recipe then return false end

    if recipe.inputs then
        -- Multi-ingredient recipe: check and remove all inputs
        for item, needed in pairs(recipe.inputs) do
            local have = exports['rsg-inventory']:GetItemByName(src, item)
            if not have or have.amount < needed then
                TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Missing ingredients' })
                return false
            end
        end
        for item, needed in pairs(recipe.inputs) do
            P.Functions.RemoveItem(item, needed)
        end
    else
        -- Simple recipe: 1 raw item consumed
        local have = exports['rsg-inventory']:GetItemByName(src, rawItem)
        if not have or have.amount < 1 then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You don\'t have that item' })
            return false
        end
        P.Functions.RemoveItem(rawItem, 1)
    end

    P.Functions.AddItem(recipe.output, recipe.qty)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[recipe.output], 'add', recipe.qty)
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Drying rack: hang meat, collect later
-- ──────────────────────────────────────────────────────────────────────────
local dryingSlots = {}  -- src -> { { recipe, startTime }, ... }

lib.callback.register('mike-cooking:server:dryMeat', function(source, recipeKey)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end

    local recipe = Config.DryingRecipes[recipeKey]
    if not recipe then return false end

    local have = exports['rsg-inventory']:GetItemByName(src, recipe.input)
    if not have or have.amount < 1 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You don\'t have that meat' })
        return false
    end

    if not dryingSlots[src] then dryingSlots[src] = {} end
    if #dryingSlots[src] >= Config.DryingSlots then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Rack is full (%d/%d)'):format(#dryingSlots[src], Config.DryingSlots) })
        return false
    end

    P.Functions.RemoveItem(recipe.input, 1)
    dryingSlots[src][#dryingSlots[src] + 1] = {
        recipe = recipe,
        startTime = os.time(),
    }

    return true
end)

lib.callback.register('mike-cooking:server:collectJerky', function(source)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end

    if not dryingSlots[src] or #dryingSlots[src] == 0 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Nothing drying' })
        return false
    end

    local now = os.time()
    local collected = 0
    local remaining = {}

    for _, slot in ipairs(dryingSlots[src]) do
        if (now - slot.startTime) >= Config.DryingTime then
            P.Functions.AddItem(slot.recipe.output, slot.recipe.qty)
            TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[slot.recipe.output], 'add', slot.recipe.qty)
            collected = collected + slot.recipe.qty
        else
            remaining[#remaining + 1] = slot
        end
    end

    dryingSlots[src] = remaining

    if collected == 0 then
        local firstSlot = dryingSlots[src][1]
        local mins = math.ceil((Config.DryingTime - (now - firstSlot.startTime)) / 60)
        TriggerClientEvent('ox_lib:notify', src, { type = 'inform', description = ('Not ready yet — %d min remaining'):format(mins) })
        return false
    end

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Collected %d jerky'):format(collected) })
    return true
end)
