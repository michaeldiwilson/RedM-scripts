local RSGCore = exports['rsg-core']:GetCoreObject()

-- ──────────────────────────────────────────────────────────────────────────
-- DB: mike_exchange_stock (shop_id, item, stock)
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS mike_exchange_stock (
            shop_id  INT          NOT NULL,
            item     VARCHAR(50)  NOT NULL,
            stock    INT          NOT NULL DEFAULT 0,
            PRIMARY KEY (shop_id, item)
        )
    ]])
end)

-- Helper: get current stock for one shop
local function getStock(shopIdx)
    local rows = MySQL.query.await('SELECT item, stock FROM mike_exchange_stock WHERE shop_id = ?', { shopIdx })
    local data = {}
    for _, row in ipairs(rows or {}) do data[row.item] = row.stock end
    return data
end

-- Helper: find item config entry in a shop
local function findEntry(shopIdx, itemName)
    local shop = Config.Shops[shopIdx]
    if not shop then return nil end
    for _, e in ipairs(shop.items) do
        if e.item == itemName then return e end
    end
    return nil
end

-- ──────────────────────────────────────────────────────────────────────────
-- Client requests stock to build the menu
-- ──────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mike-exchange:server:getStock', function(shopIdx)
    local src = source
    local shop = Config.Shops[shopIdx]
    if not shop then return end
    local stock = getStock(shopIdx)
    TriggerClientEvent('mike-exchange:client:showMenu', src, shopIdx, shop.name, stock)
end)

-- ──────────────────────────────────────────────────────────────────────────
-- SELL: player sells items TO the shop (shop pays buyPrice, stock goes up)
-- ──────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mike-exchange:server:sell', function(shopIdx, itemName, qty)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    qty = math.max(1, tonumber(qty) or 1)

    local entry = findEntry(shopIdx, itemName)
    if not entry then return end

    -- Check player has the items
    local have = exports['rsg-inventory']:GetItemByName(src, itemName)
    if not have or have.amount < qty then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('You only have %d × %s'):format(have and have.amount or 0, itemName) })
    end

    -- Check stock cap
    local stock = getStock(shopIdx)
    local current = stock[itemName] or 0
    local room = entry.maxStock - current
    if room <= 0 then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Shop is fully stocked on ' .. itemName })
    end
    if qty > room then qty = room end

    -- Remove items, pay player
    P.Functions.RemoveItem(itemName, qty)
    local payout = qty * entry.buyPrice
    P.Functions.AddMoney('cash', payout)

    -- Update stock
    MySQL.query('INSERT INTO mike_exchange_stock (shop_id, item, stock) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE stock = stock + ?',
        { shopIdx, itemName, qty, qty })

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Sold %d × %s for $%d'):format(qty, itemName, payout) })
end)

-- ──────────────────────────────────────────────────────────────────────────
-- BUY: player buys items FROM the shop (pays sellPrice, stock goes down)
-- ──────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mike-exchange:server:buy', function(shopIdx, itemName, qty)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    qty = math.max(1, tonumber(qty) or 1)

    local entry = findEntry(shopIdx, itemName)
    if not entry then return end

    -- Check stock
    local stock = getStock(shopIdx)
    local current = stock[itemName] or 0
    if current <= 0 then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = itemName .. ' is out of stock' })
    end
    if qty > current then qty = current end

    -- Check player has money
    local cost = qty * entry.sellPrice
    local cash = P.PlayerData.money.cash or 0
    if cash < cost then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Need $%d, you have $%d'):format(cost, cash) })
    end

    -- Take money, give items
    P.Functions.RemoveMoney('cash', cost)
    P.Functions.AddItem(itemName, qty)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[itemName], 'add', qty)

    -- Update stock
    MySQL.query('UPDATE mike_exchange_stock SET stock = stock - ? WHERE shop_id = ? AND item = ?',
        { qty, shopIdx, itemName })

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Bought %d × %s for $%d'):format(qty, itemName, cost) })
end)
