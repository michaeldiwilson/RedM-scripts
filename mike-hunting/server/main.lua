local RSGCore = exports['rsg-core']:GetCoreObject()

-- ──────────────────────────────────────────────────────────────────────────
-- Skinning: give player meat + pelt + extras (quality-aware)
-- ──────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mike-hunting:server:skin', function(netId, typeKey, quality)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    local animalData = Config.Animals[typeKey]; if not animalData then return end

    quality = tonumber(quality) or 2
    if quality < 1 then quality = 1 end
    if quality > 3 then quality = 3 end
    local qInfo = Config.QualityMultiplier[quality]
    local stars = string.rep('★', quality) .. string.rep('☆', 3 - quality)

    -- Give meat (scaled by quality)
    local baseMeat = math.random(animalData.meat.min, animalData.meat.max)
    local meatQty = math.max(1, math.floor(baseMeat * qInfo.meatMulti))
    P.Functions.AddItem(animalData.meat.item, meatQty)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[animalData.meat.item], 'add', meatQty)

    -- Give quality-prefixed pelt
    local peltItem = qInfo.prefix .. animalData.pelt
    P.Functions.AddItem(peltItem, 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[peltItem], 'add', 1)

    -- Give extras (antlers, claws, etc.) — unaffected by quality
    for _, extra in ipairs(animalData.extras) do
        P.Functions.AddItem(extra.item, extra.qty)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[extra.item], 'add', extra.qty)
    end

    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = ('%s %s — %s: %d× %s, 1× %s'):format(stars, qInfo.label, animalData.label, meatQty, animalData.meat.item, peltItem),
    })

    -- Notify client about carcass (for wagon loading hint)
    TriggerClientEvent('mike-hunting:client:carcassReady', src, typeKey, netId)
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Butcher: player sells meat, pelts, carcasses from inventory
-- ──────────────────────────────────────────────────────────────────────────
-- All sellable items and their prices
local sellableItems = {}

-- Build sellable list from carcass prices
for item, price in pairs(Config.CarcassPrices) do
    sellableItems[item] = price
end

-- Add meat + pelt prices
local meatPrices = {
    venison    = 5,
    bear_meat  = 8,
    bison_meat = 8,
    game_meat  = 4,
    pork       = 5,
    mutton     = 5,
}

-- Base pelt prices (2-star "Good")
local basePeltPrices = {
    deer_pelt   = 8,
    elk_pelt    = 14,
    bear_pelt   = 25,
    bison_pelt  = 25,
    boar_pelt   = 7,
    rabbit_pelt = 4,
    cougar_pelt = 18,
    wolf_pelt   = 8,
    sheep_pelt  = 5,
    goat_pelt   = 5,
    coyote_pelt = 6,
}

-- Build quality-tiered pelt prices from base prices
local peltPrices = {}
for peltItem, basePrice in pairs(basePeltPrices) do
    peltPrices['poor_' .. peltItem]    = math.max(1, math.floor(basePrice * Config.QualityMultiplier[1].priceMulti))
    peltPrices[peltItem]               = basePrice
    peltPrices['perfect_' .. peltItem] = math.floor(basePrice * Config.QualityMultiplier[3].priceMulti)
end

local partPrices = {
    antlers     = 10,
    bear_claw   = 15,
    bison_horn  = 18,
    tusk        = 8,
}

-- Legendary pelt/part prices
local legendaryPrices = {
    legendary_bear_pelt   = 80,
    legendary_cougar_pelt = 60,
    legendary_elk_pelt    = 55,
    legendary_wolf_pelt   = 45,
    legendary_bison_pelt  = 90,
    legendary_bear_claw   = 40,
    legendary_antlers     = 35,
    legendary_bison_horn  = 50,
}

local fishPrices = {
    a_c_fishbluegil_01_ms        = 5,
    a_c_fishbluegil_01_sm        = 3,
    a_c_fishbullheadcat_01_ms    = 6,
    a_c_fishbullheadcat_01_sm    = 3,
    a_c_fishchainpickerel_01_ms  = 7,
    a_c_fishchainpickerel_01_sm  = 4,
    a_c_fishchannelcatfish_01_lg = 15,
    a_c_fishchannelcatfish_01_xl = 25,
    a_c_fishlakesturgeon_01_lg   = 22,
    a_c_fishlargemouthbass_01_lg = 14,
    a_c_fishlargemouthbass_01_ms = 7,
    a_c_fishlongnosegar_01_lg    = 16,
    a_c_fishmuskie_01_lg         = 18,
    a_c_fishnorthernpike_01_lg   = 16,
    a_c_fishperch_01_ms          = 5,
    a_c_fishperch_01_sm          = 3,
    a_c_fishrainbowtrout_01_lg   = 12,
    a_c_fishrainbowtrout_01_ms   = 6,
    a_c_fishredfinpickerel_01_ms = 5,
    a_c_fishredfinpickerel_01_sm = 3,
    a_c_fishrockbass_01_ms       = 5,
    a_c_fishrockbass_01_sm       = 3,
    a_c_fishsalmonsockeye_01_lg  = 14,
    a_c_fishsalmonsockeye_01_ml  = 8,
    a_c_fishsalmonsockeye_01_ms  = 5,
    a_c_fishsmallmouthbass_01_lg = 12,
    a_c_fishsmallmouthbass_01_ms = 6,
    a_c_fishsteelheadtrout       = 14,
}

for item, price in pairs(meatPrices)      do sellableItems[item] = price end
for item, price in pairs(peltPrices)      do sellableItems[item] = price end
for item, price in pairs(partPrices)      do sellableItems[item] = price end
for item, price in pairs(fishPrices)      do sellableItems[item] = price end
for item, price in pairs(legendaryPrices) do sellableItems[item] = price end

RegisterNetEvent('mike-hunting:server:getButcherStock', function()
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end

    local list = {}
    for item, price in pairs(sellableItems) do
        local have = exports['rsg-inventory']:GetItemByName(src, item)
        if have and have.amount > 0 then
            local info = RSGCore.Shared.Items[item]
            list[#list + 1] = {
                item   = item,
                label  = info and info.label or item,
                price  = price,
                amount = have.amount,
            }
        end
    end

    TriggerClientEvent('mike-hunting:client:showButcher', src, list)
end)

RegisterNetEvent('mike-hunting:server:sellToButcher', function(item, qty)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    qty = math.max(1, tonumber(qty) or 1)

    local price = sellableItems[item]
    if not price then return end

    local have = exports['rsg-inventory']:GetItemByName(src, item)
    if not have or have.amount < qty then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough to sell' })
    end

    P.Functions.RemoveItem(item, qty)
    local payout = qty * price
    P.Functions.AddMoney('cash', payout)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Sold %d× %s for $%d'):format(qty, item, payout) })
end)
