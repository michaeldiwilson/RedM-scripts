local RSGCore = exports['rsg-core']:GetCoreObject()

-- ──────────────────────────────────────────────────────────────────────────
-- Market stall: rancher stocks produce, players buy via inventory shop UI
-- ──────────────────────────────────────────────────────────────────────────

-- Items the rancher can stock and their sell prices
local marketItems = {
    { name = 'milk_pail',    price = 8,  label = 'Milk' },
    { name = 'eggs',         price = 4,  label = 'Eggs' },
    { name = 'raw_wool',     price = 12, label = 'Raw Wool' },
    { name = 'cheese',       price = 15, label = 'Cheese' },
    { name = 'butter',       price = 10, label = 'Butter' },
    { name = 'cooked_fish',  price = 6,  label = 'Cooked Fish' },
    { name = 'cooked_venison', price = 8, label = 'Cooked Venison' },
    { name = 'cooked_pork',  price = 7,  label = 'Cooked Pork' },
    { name = 'cooked_mutton', price = 7, label = 'Cooked Mutton' },
    { name = 'cooked_game_meat', price = 5, label = 'Cooked Game Meat' },
    { name = 'cooked_bear_meat', price = 10, label = 'Cooked Bear Meat' },
    { name = 'cooked_bison_meat', price = 10, label = 'Cooked Bison Meat' },
    { name = 'jerky',        price = 8,  label = 'Jerky' },
    { name = 'sausage',      price = 10, label = 'Sausage' },
    { name = 'boiled_egg',   price = 5,  label = 'Boiled Egg' },
    { name = 'bread',        price = 6,  label = 'Bread' },
    { name = 'flour',        price = 4,  label = 'Flour' },
    { name = 'hay_cube',     price = 3,  label = 'Hay Cube' },
    { name = 'fat',          price = 3,  label = 'Fat' },
    { name = 'manure',       price = 2,  label = 'Manure' },
    { name = 'fertilizer',   price = 5,  label = 'Fertilizer' },
}

-- In-memory market stock: { itemName = qty }
local marketStock = {}

-- DB table
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS mike_ranch_market (
            id       INT AUTO_INCREMENT PRIMARY KEY,
            ranch_id INT NOT NULL,
            item     VARCHAR(50) NOT NULL,
            stock    INT NOT NULL DEFAULT 0,
            price    INT NOT NULL DEFAULT 0,
            UNIQUE KEY (ranch_id, item)
        )
    ]])
end)

local function loadMarketStock()
    if not RanchData then return end
    marketStock = {}
    local rows = MySQL.query.await('SELECT * FROM mike_ranch_market WHERE ranch_id = ?', { RanchData.id })
    for _, r in ipairs(rows or {}) do
        marketStock[r.item] = { stock = r.stock, price = r.price }
    end
end

CreateThread(function()
    Wait(4000)
    loadMarketStock()
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Register market as inventory shop (updates dynamically)
-- ──────────────────────────────────────────────────────────────────────────
local function buildMarketShopItems()
    local shopItems = {}
    for _, mi in ipairs(marketItems) do
        local stock = marketStock[mi.name]
        if stock and stock.stock > 0 then
            shopItems[#shopItems + 1] = {
                name     = mi.name,
                price    = stock.price or mi.price,
                amount   = stock.stock,
                buyPrice = nil,  -- players can't sell TO the market
            }
        end
    end
    return shopItems
end

local function refreshMarketShop()
    local items = buildMarketShopItems()
    if #items == 0 then
        -- Add a placeholder so shop can still open
        items[#items + 1] = { name = 'bread', price = 999, amount = 0 }
    end
    if exports['rsg-inventory']:DoesShopExist('market_ranch') then
        exports['rsg-inventory']:CreateShop({ name = 'market_ranch', label = Config.MarketStall.name, items = items })
    else
        exports['rsg-inventory']:CreateShop({ name = 'market_ranch', label = Config.MarketStall.name, items = items })
    end
end

CreateThread(function()
    Wait(5000)
    refreshMarketShop()
end)

-- Open market for buyers
RegisterNetEvent('mike-ranching:server:openMarket', function()
    local src = source
    refreshMarketShop()
    exports['rsg-inventory']:OpenShop(src, 'market_ranch')
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Rancher stocks the market: transfers items from inventory to market
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:stockMarket', function(source, itemName, qty)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local cid = P.PlayerData.citizenid
    if not RanchData then return false end

    -- Only rancher (hand+) can stock
    if GetRanchRank(cid) == 0 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'No ranch access' })
        return false
    end

    -- Validate item is a market item
    local validItem = false
    local defaultPrice = 5
    for _, mi in ipairs(marketItems) do
        if mi.name == itemName then validItem = true; defaultPrice = mi.price; break end
    end
    if not validItem then return false end

    qty = math.max(1, tonumber(qty) or 1)

    local have = exports['rsg-inventory']:GetItemByName(src, itemName)
    if not have or have.amount < qty then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough items' })
        return false
    end

    P.Functions.RemoveItem(itemName, qty)

    if not marketStock[itemName] then
        marketStock[itemName] = { stock = 0, price = defaultPrice }
    end
    marketStock[itemName].stock = marketStock[itemName].stock + qty

    MySQL.query([[
        INSERT INTO mike_ranch_market (ranch_id, item, stock, price) VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE stock = stock + ?
    ]], { RanchData.id, itemName, qty, defaultPrice, qty })

    refreshMarketShop()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Stocked %dx %s'):format(qty, itemName:gsub('_', ' ')) })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Get stockable items for rancher menu
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:getStockableItems', function(source)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return {} end

    local items = {}
    for _, mi in ipairs(marketItems) do
        local have = exports['rsg-inventory']:GetItemByName(src, mi.name)
        if have and have.amount > 0 then
            local currentStock = marketStock[mi.name] and marketStock[mi.name].stock or 0
            items[#items + 1] = {
                name = mi.name,
                label = mi.label,
                have = have.amount,
                stocked = currentStock,
                price = mi.price,
            }
        end
    end
    return items
end)
