local RSGCore = exports['rsg-core']:GetCoreObject()
local activeDeals = {}  -- src -> true while in /sellshine session

local function isLaw(P)
    if not P or not P.PlayerData.job then return false end
    for _, j in ipairs(Config.LawJobs) do
        if P.PlayerData.job.name == j then return true end
    end
    return false
end

local function notifyLaw(coords)
    local fx = math.random(-Config.Street.lawBlipFuzz, Config.Street.lawBlipFuzz)
    local fy = math.random(-Config.Street.lawBlipFuzz, Config.Street.lawBlipFuzz)
    local fx_coord = { x = coords.x + fx, y = coords.y + fy, z = coords.z }
    local players = RSGCore.Functions.GetPlayers()
    for _, pid in ipairs(players) do
        local P = RSGCore.Functions.GetPlayer(pid)
        if P and isLaw(P) then
            TriggerClientEvent('ox_lib:notify', pid, {
                type = 'inform',
                title = 'Suspicious activity',
                description = 'Reports of moonshine dealing — investigate the area.',
                duration = 8000,
            })
            TriggerClientEvent('mike-moonshine:client:lawBlip', pid, fx_coord, Config.Street.lawBlipSeconds)
        end
    end
end

-- ── Speakeasy sale ──────────────────────────────────────────────────────────
RegisterNetEvent('mike-moonshine:server:sellSpeakeasy', function(tier, amount)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    local price = Config.SpeakeasyPrices[tier]
    if not price then return end
    amount = tonumber(amount) or 0
    if amount < 1 then return end

    local have = exports['rsg-inventory']:GetItemByName(src, tier)
    if not have or have.amount < amount then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough bottles' })
    end
    P.Functions.RemoveItem(tier, amount)
    local total = price * amount
    P.Functions.AddMoney('cash', total, 'speakeasy-moonshine')
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Sold %d × %s for $%d'):format(amount, tier, total) })
end)

-- ── Street deal: session management ─────────────────────────────────────────
RegisterNetEvent('mike-moonshine:server:startStreetSession', function()
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    if activeDeals[src] then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Already dealing' })
    end
    -- Verify they have at least 1 bottle of any tier
    local anyBottle = false
    for tier in pairs(Config.StreetPrices) do
        local have = exports['rsg-inventory']:GetItemByName(src, tier)
        if have and have.amount > 0 then anyBottle = true; break end
    end
    if not anyBottle then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'No moonshine to sell' })
    end
    activeDeals[src] = true
    TriggerClientEvent('mike-moonshine:client:streetSessionStart', src)
end)

RegisterNetEvent('mike-moonshine:server:stopStreetSession', function()
    local src = source
    activeDeals[src] = nil
    TriggerClientEvent('mike-moonshine:client:streetSessionStop', src)
end)

RegisterNetEvent('mike-moonshine:server:streetDealAuto', function(coords)
    local src = source
    if not activeDeals[src] then return end
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    -- pick the highest tier the player actually has
    local order = { 'moonshine_premium', 'moonshine_good', 'moonshine_basic' }
    local picked
    for _, tier in ipairs(order) do
        local have = exports['rsg-inventory']:GetItemByName(src, tier)
        if have and have.amount > 0 then picked = tier; break end
    end
    if not picked then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You have no moonshine left' })
    end
    local price = Config.StreetPrices[picked]
    local have  = exports['rsg-inventory']:GetItemByName(src, picked)
    local stock = have and have.amount or 0
    local want  = math.random(Config.Street.npcBuyMin or 1, Config.Street.npcBuyMax or 1)
    local qty   = math.min(want, stock)
    if qty < 1 then return end
    local total = price * qty
    P.Functions.RemoveItem(picked, qty)
    P.Functions.AddMoney('cash', total, 'street-moonshine')
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Sold %d × %s for $%d'):format(qty, picked, total) })
    notifyLaw(coords)
end)

RegisterNetEvent('mike-moonshine:server:bust', function()
    local src = source
    if not activeDeals[src] then return end
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    activeDeals[src] = nil
    for tier in pairs(Config.StreetPrices) do
        local have = exports['rsg-inventory']:GetItemByName(src, tier)
        if have and have.amount > 0 then
            P.Functions.RemoveItem(tier, have.amount)
        end
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Busted!', description = 'The law caught you — bottles seized.', duration = 8000 })
end)

RegisterNetEvent('mike-moonshine:server:checkBust', function(nearbyId)
    local src = source
    if not activeDeals[src] then return end
    local Near = RSGCore.Functions.GetPlayer(tonumber(nearbyId))
    if Near and isLaw(Near) then
        local P = RSGCore.Functions.GetPlayer(src)
        if not P then return end
        activeDeals[src] = nil
        for tier in pairs(Config.StreetPrices) do
            local have = exports['rsg-inventory']:GetItemByName(src, tier)
            if have and have.amount > 0 then
                P.Functions.RemoveItem(tier, have.amount)
            end
        end
        TriggerClientEvent('mike-moonshine:client:streetSessionStop', src)
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Busted!', description = 'The law caught you — bottles seized.', duration = 8000 })
        TriggerClientEvent('ox_lib:notify', nearbyId, { type = 'success', description = 'You caught a moonshine dealer!' })
    end
end)

AddEventHandler('playerDropped', function()
    activeDeals[source] = nil
end)
