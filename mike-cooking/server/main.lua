local RSGCore = exports['rsg-core']:GetCoreObject()

-- ──────────────────────────────────────────────────────────────────────────
-- Portable campfire: use from inventory to place
-- ──────────────────────────────────────────────────────────────────────────
RSGCore.Functions.CreateUseableItem('portable_campfire', function(src, item)
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    P.Functions.RemoveItem('portable_campfire', 1)
    TriggerClientEvent('mike-cooking:client:placeCampfire', src)
end)

-- Pack up campfire: give item back
RegisterNetEvent('mike-cooking:server:packCampfire', function()
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    P.Functions.AddItem('portable_campfire', 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['portable_campfire'], 'add', 1)
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Cook callback: remove raw item, give cooked item
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-cooking:server:cook', function(source, rawItem)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end

    local recipe = Config.Recipes[rawItem]
    if not recipe then return false end

    -- Check player has the raw item
    local have = exports['rsg-inventory']:GetItemByName(src, rawItem)
    if not have or have.amount < 1 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You don\'t have that item' })
        return false
    end

    -- Remove raw, give cooked
    P.Functions.RemoveItem(rawItem, 1)
    P.Functions.AddItem(recipe.output, recipe.qty)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[recipe.output], 'add', recipe.qty)

    return true
end)
