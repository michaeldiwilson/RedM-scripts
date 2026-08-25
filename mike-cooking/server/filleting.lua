local RSGCore = exports['rsg-core']:GetCoreObject()

-- ──────────────────────────────────────────────────────────────────────────
-- Fish filleting: use a fish item (right-click) while having a knife
-- Converts whole fish → fish fillets based on size
-- ──────────────────────────────────────────────────────────────────────────

-- Knife items that work for filleting
local knifeItems = {
    'weapon_melee_knife',
    'weapon_melee_knife_jawbone',
    'weapon_melee_knife_trader',
    'weapon_melee_knife_horror',
    'weapon_melee_knife_rustic',
    'weapon_melee_knife_bear',
    'weapon_melee_knife_civil_war',
    'weapon_melee_knife_miner',
    'weapon_melee_knife_vampire',
}

local function hasKnife(src)
    for _, knife in ipairs(knifeItems) do
        local have = exports['rsg-inventory']:GetItemByName(src, knife)
        if have and have.amount > 0 then return true end
    end
    return false
end

-- Fish → fillet yield (by size: sm=1, ms=2, lg=3, xl=4)
local fishFillets = {
    -- Small fish → 1 fillet
    a_c_fishbluegil_01_sm        = 1,
    a_c_fishperch_01_sm          = 1,
    a_c_fishbullheadcat_01_sm    = 1,
    a_c_fishredfinpickerel_01_sm = 1,
    a_c_fishrockbass_01_sm       = 1,
    a_c_fishchainpickerel_01_sm  = 1,
    -- Medium fish → 2 fillets
    a_c_fishbluegil_01_ms        = 2,
    a_c_fishperch_01_ms          = 2,
    a_c_fishbullheadcat_01_ms    = 2,
    a_c_fishredfinpickerel_01_ms = 2,
    a_c_fishrockbass_01_ms       = 2,
    a_c_fishchainpickerel_01_ms  = 2,
    a_c_fishlargemouthbass_01_ms = 2,
    a_c_fishsmallmouthbass_01_ms = 2,
    a_c_fishrainbowtrout_01_ms   = 2,
    a_c_fishsalmonsockeye_01_ms  = 2,
    a_c_fishsalmonsockeye_01_ml  = 2,
    -- Large fish → 3 fillets
    a_c_fishlargemouthbass_01_lg = 3,
    a_c_fishsmallmouthbass_01_lg = 3,
    a_c_fishrainbowtrout_01_lg   = 3,
    a_c_fishsalmonsockeye_01_lg  = 3,
    a_c_fishlakesturgeon_01_lg   = 3,
    a_c_fishlongnosegar_01_lg    = 3,
    a_c_fishmuskie_01_lg         = 3,
    a_c_fishnorthernpike_01_lg   = 3,
    a_c_fishsteelheadtrout       = 3,
    -- XL fish → 4-5 fillets
    a_c_fishchannelcatfish_01_lg = 4,
    a_c_fishchannelcatfish_01_xl = 5,
}

-- Register every fish as a useable item
CreateThread(function()
    Wait(2000)
    for fishItem, filletQty in pairs(fishFillets) do
        RSGCore.Functions.CreateUseableItem(fishItem, function(src, item)
            local P = RSGCore.Functions.GetPlayer(src); if not P then return end

            if not hasKnife(src) then
                TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You need a knife to fillet fish' })
                return
            end

            P.Functions.RemoveItem(fishItem, 1)
            P.Functions.AddItem('fish_fillet', filletQty)
            TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['fish_fillet'], 'add', filletQty)

            local fishInfo = RSGCore.Shared.Items[fishItem]
            local fishLabel = fishInfo and fishInfo.label or fishItem
            TriggerClientEvent('ox_lib:notify', src, {
                type = 'success',
                description = ('Filleted %s → %dx fish fillet'):format(fishLabel, filletQty),
            })
        end)
    end
end)
