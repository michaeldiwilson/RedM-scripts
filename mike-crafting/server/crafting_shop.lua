local RSGCore = exports['rsg-core']:GetCoreObject()

-- ──────────────────────────────────────────────────────────────────────────
-- Register crafting as inventory shops (uses native inventory UI)
-- Player inventory on left, craftable items on right, drag to craft
-- The rsg-inventory patch handles material costs instead of money
-- ──────────────────────────────────────────────────────────────────────────

local function buildCraftingShopItems(portableOnly)
    local shopItems = {}
    for key, r in pairs(Config.Recipes) do
        if portableOnly and not r.portable then goto continue end

        -- Build description showing required materials
        local parts = {}
        for item, qty in pairs(r.inputs) do
            local info = RSGCore.Shared.Items[item]
            local label = info and info.label or item:gsub('_', ' ')
            parts[#parts + 1] = qty .. 'x ' .. label
        end

        shopItems[#shopItems + 1] = {
            name        = r.output,
            price       = nil,  -- no price shown, crafting patch handles material costs
            amount      = 999,
            info        = {
                craftInputs = r.inputs,
                craftQty    = r.qty or 1,
                description = 'Requires: ' .. table.concat(parts, ', '),
            },
        }
        ::continue::
    end
    return shopItems
end

CreateThread(function()
    Wait(3000)

    exports['rsg-inventory']:CreateShop({
        name  = 'crafting_portable',
        label = 'Crafting',
        items = buildCraftingShopItems(true),
    })

    exports['rsg-inventory']:CreateShop({
        name  = 'crafting_bench',
        label = 'Crafting Bench',
        items = buildCraftingShopItems(false),
    })
end)

-- Crafting book: open portable crafting shop
RSGCore.Functions.CreateUseableItem('crafting_book', function(src, item)
    exports['rsg-inventory']:OpenShop(src, 'crafting_portable')
end)

-- Bench: open full crafting shop
RegisterNetEvent('mike-crafting:server:openBenchShop', function(benchId)
    local src = source
    if not activeBenches[benchId] then return end
    exports['rsg-inventory']:OpenShop(src, 'crafting_bench')
end)
