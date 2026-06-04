local RSGCore = exports['rsg-core']:GetCoreObject()

-- Indexed by node index (1-based as in Config.Nodes). value = expiresAt (epoch)
local depleted = {}

local function rollGem()
    local total = 0
    for _, g in ipairs(Config.GemRoll) do total = total + g.weight end
    local r = math.random(1, total)
    local acc = 0
    for _, g in ipairs(Config.GemRoll) do
        acc = acc + g.weight
        if r <= acc then return g.item end
    end
end

local function broadcastDepleted()
    TriggerClientEvent('mike-mining:client:syncDepleted', -1, depleted)
end

AddEventHandler('playerJoining', function()
    local src = source
    CreateThread(function() Wait(3000); TriggerClientEvent('mike-mining:client:syncDepleted', src, depleted) end)
end)

CreateThread(function()
    while true do
        Wait(30 * 1000)
        local now = os.time()
        local changed = false
        for k, exp in pairs(depleted) do
            if now >= exp then depleted[k] = nil; changed = true end
        end
        if changed then broadcastDepleted() end
    end
end)

RegisterNetEvent('mike-mining:server:mine', function(nodeIndex)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    local node = Config.Nodes[tonumber(nodeIndex)]; if not node then return end
    if depleted[nodeIndex] then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Node is depleted' })
    end
    if not exports['rsg-inventory']:GetItemByName(src, 'pickaxe') then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You need a pickaxe' })
    end

    if math.random() < (Config.MissChance or 0) then
        local lines = { 'The rock barely chips', 'Nothing useful this time', 'Just dust', 'A clean miss' }
        return TriggerClientEvent('ox_lib:notify', src, { type = 'inform', description = lines[math.random(#lines)] })
    end

    local oreItem = node.type == 'iron' and 'iron_ore' or 'copper_ore'
    local oreQty  = math.random(Config.OreYieldMin, Config.OreYieldMax)
    local addedOk = P.Functions.AddItem(oreItem, oreQty)
    print(('[mike-mining] AddItem %s x%d for src=%d -> %s'):format(oreItem, oreQty, src, tostring(addedOk)))
    if not addedOk then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Could not add ore (inventory full?)' })
    end

    local gemMsg = ''
    if math.random() < Config.GemChance then
        local gem = rollGem()
        if gem then
            P.Functions.AddItem(gem, 1)
            gemMsg = ' (+1 ' .. gem .. ')'
        end
    end

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Mined %d %s%s'):format(oreQty, oreItem, gemMsg) })
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[oreItem], 'add', oreQty)
end)

local activeTnt = {}  -- nodeIndex -> true while a fuse is running

RegisterNetEvent('mike-mining:server:tntPlaced', function(nodeIndex, placeCoords)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    local idx  = tonumber(nodeIndex)
    local node = Config.Nodes[idx]; if not node then return end
    if depleted[idx] or activeTnt[idx] then return end

    local tnt = exports['rsg-inventory']:GetItemByName(src, 'tnt')
    if not tnt or tnt.amount < 1 then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You have no TNT' })
    end
    P.Functions.RemoveItem('tnt', 1)
    activeTnt[idx] = true

    local blastPos = placeCoords or { x = node.x, y = node.y, z = node.z }
    TriggerClientEvent('mike-mining:client:armTNT', -1, idx, blastPos)
    TriggerClientEvent('ox_lib:notify', src, { type = 'inform', description = ('TNT placed — %ds fuse, get clear!'):format(Config.TNT.fuseSeconds) })

    SetTimeout(Config.TNT.fuseSeconds * 1000, function()
        activeTnt[idx] = nil
        if depleted[idx] then return end

        local oreItem = node.type == 'iron' and 'iron_ore' or 'copper_ore'
        local oreQty  = math.random(Config.TNT.oreMin, Config.TNT.oreMax)
        local gemQty  = math.random(Config.TNT.gemMin, Config.TNT.gemMax)

        -- Award to the placer if they're still connected
        local placer = RSGCore.Functions.GetPlayer(src)
        if placer then
            placer.Functions.AddItem(oreItem, oreQty)
            local gems = {}
            for _ = 1, gemQty do
                local g = rollGem(); if g then
                    placer.Functions.AddItem(g, 1)
                    gems[#gems + 1] = g
                end
            end
            TriggerClientEvent('ox_lib:notify', src, {
                type = 'success',
                title = 'Blast haul',
                description = ('+%d %s, +%d gems (%s)'):format(oreQty, oreItem, gemQty, table.concat(gems, ', ')),
                duration = 8000,
            })
        end

        depleted[idx] = os.time() + Config.TNT.nodeRespawnSec
        broadcastDepleted()
        TriggerClientEvent('mike-mining:client:tntBoom', -1, idx, blastPos)
    end)
end)
