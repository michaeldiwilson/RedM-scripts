RegisterNetEvent('mike-adminmenu:server:viewInventory', function(targetId)
    local src = source
    if not AssertAdmin(src) then return end
    targetId = tonumber(targetId)
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Target not online' })
        return
    end
    local ok = pcall(function()
        exports['rsg-inventory']:OpenInventoryById(src, targetId)
    end)
    if not ok then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Inventory export failed' })
    end
end)

RegisterNetEvent('mike-adminmenu:server:clearInventory', function(targetId)
    local src = source
    if not AssertAdmin(src) then return end
    targetId = tonumber(targetId)
    if not targetId or not GetPlayerName(targetId) then return end
    local ok = pcall(function()
        exports['rsg-inventory']:ClearInventory(targetId)
    end)
    if ok then
        TriggerClientEvent('ox_lib:notify', src,      { type = 'success', description = 'Cleared inventory of ' .. GetPlayerName(targetId) })
        TriggerClientEvent('ox_lib:notify', targetId, { type = 'inform',  description = 'Your inventory was cleared by an admin' })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Clear failed' })
    end
end)

RegisterNetEvent('mike-adminmenu:server:giveItem', function(targetId, item, amount)
    local src = source
    if not AssertAdmin(src) then return end
    targetId = tonumber(targetId); amount = tonumber(amount) or 1
    if not targetId or not GetPlayerName(targetId) or not item or item == '' then return end
    local P = RSGCore.Functions.GetPlayer(targetId)
    if not P then return end
    local ok = P.Functions.AddItem(item, amount)
    if ok then
        TriggerClientEvent('ox_lib:notify', src,      { type = 'success', description = ('Gave %d x %s to %s'):format(amount, item, GetPlayerName(targetId)) })
        TriggerClientEvent('ox_lib:notify', targetId, { type = 'inform',  description = ('Received %d x %s from admin'):format(amount, item) })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Failed to add item (invalid name or inventory full)' })
    end
end)
