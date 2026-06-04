local RSGCore = exports['rsg-core']:GetCoreObject()

lib.callback.register('mike-lumber:server:checkMill', function(source, recipeKey)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local recipe = Config.MillRecipes[recipeKey]; if not recipe then return false end

    for item, n in pairs(recipe.inputs) do
        local have = exports['rsg-inventory']:GetItemByName(src, item)
        if not have or have.amount < n then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Need %d × %s'):format(n, item) })
            return false
        end
    end
    return true
end)

lib.callback.register('mike-lumber:server:mill', function(source, recipeKey)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local recipe = Config.MillRecipes[recipeKey]; if not recipe then return false end

    for item, n in pairs(recipe.inputs) do
        local have = exports['rsg-inventory']:GetItemByName(src, item)
        if not have or have.amount < n then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Need %d × %s'):format(n, item) })
            return false
        end
    end

    for item, n in pairs(recipe.inputs) do P.Functions.RemoveItem(item, n) end
    P.Functions.AddItem(recipe.output, 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[recipe.output], 'add', 1)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Milled 1 × ' .. recipe.output })
    return true
end)
