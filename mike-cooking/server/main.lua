local RSGCore = exports['rsg-core']:GetCoreObject()

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
