local RSGCore = exports['rsg-core']:GetCoreObject()

lib.callback.register('mike-mining:server:checkSmelt', function(source, recipeKey)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local recipe = Config.SmeltRecipes[recipeKey]; if not recipe then return false end

    for item, n in pairs(recipe.inputs) do
        local have = exports['rsg-inventory']:GetItemByName(src, item)
        if not have or have.amount < n then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Need %d × %s'):format(n, item) })
            return false
        end
    end
    return true
end)

lib.callback.register('mike-mining:server:smelt', function(source, recipeKey)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local recipe = Config.SmeltRecipes[recipeKey]; if not recipe then return false end

    for item, n in pairs(recipe.inputs) do
        local have = exports['rsg-inventory']:GetItemByName(src, item)
        if not have or have.amount < n then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Need %d × %s'):format(n, item) })
            return false
        end
    end

    for item, n in pairs(recipe.inputs) do P.Functions.RemoveItem(item, n) end
    local qty = recipe.qty or 1
    P.Functions.AddItem(recipe.output, qty)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[recipe.output], 'add', qty)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Smelted %d × %s'):format(qty, recipe.output) })
    return true
end)
