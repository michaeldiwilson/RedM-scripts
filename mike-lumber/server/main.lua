local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterNetEvent('mike-lumber:server:chop', function()
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end

    local hatchet = exports['rsg-inventory']:GetItemByName(src, 'hatchet')
    if not hatchet then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You need a hatchet in your inventory.' })
    end

    if math.random() < Config.MissChance then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'inform', description = 'Axe bounced off — nothing came loose.' })
    end

    local logQty = math.random(Config.LogYieldMin, Config.LogYieldMax)
    P.Functions.AddItem('oak_log', logQty)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['oak_log'], 'add', logQty)

    if math.random() < Config.FirewoodChance then
        P.Functions.AddItem('firewood', 1)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['firewood'], 'add', 1)
    end
end)
