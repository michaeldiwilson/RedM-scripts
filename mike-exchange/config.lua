Config = {}

-- Each shop has a location, a name, and a list of items it trades.
-- buyPrice  = what the shop pays the player (player sells TO shop)
-- sellPrice = what the shop charges the player (player buys FROM shop)
-- maxStock  = cap on how much the shop can hold
--
-- Stock starts at 0 — players supply it by selling. Buyers can only
-- purchase what's in stock.

Config.Shops = {
    -- ── LUMBER YARDS ────────────────────────────────────────────────────────
    {
        name   = 'Valentine Lumber Yard',
        coords = vector3(-320.50, 801.50, 117.20),
        blip   = true,
        items  = {
            { item = 'oak_log',   buyPrice = 5,  sellPrice = 8,  maxStock = 200 },
            { item = 'oak_plank', buyPrice = 12, sellPrice = 18, maxStock = 100 },
            { item = 'firewood',  buyPrice = 2,  sellPrice = 4,  maxStock = 200 },
        },
    },
    {
        name   = 'Annesburg Lumber Yard',
        coords = vector3(2914.00, 1305.00, 44.80),
        blip   = true,
        items  = {
            { item = 'oak_log',   buyPrice = 5,  sellPrice = 8,  maxStock = 200 },
            { item = 'oak_plank', buyPrice = 12, sellPrice = 18, maxStock = 100 },
            { item = 'firewood',  buyPrice = 2,  sellPrice = 4,  maxStock = 200 },
        },
    },
    {
        name   = 'Riggs Station Lumber Yard',
        coords = vector3(-1827.00, -411.00, 161.50),
        blip   = true,
        items  = {
            { item = 'oak_log',   buyPrice = 5,  sellPrice = 8,  maxStock = 200 },
            { item = 'oak_plank', buyPrice = 12, sellPrice = 18, maxStock = 100 },
            { item = 'firewood',  buyPrice = 2,  sellPrice = 4,  maxStock = 200 },
        },
    },

    -- ── FORGES (ore & bars) ─────────────────────────────────────────────────
    {
        name   = 'Valentine Forge Exchange',
        coords = vector3(-369.50, 796.17, 116.20),
        blip   = false,  -- forge blip already exists from mike-mining
        items  = {
            { item = 'copper_ore',  buyPrice = 3,   sellPrice = 5,   maxStock = 300 },
            { item = 'iron_ore',    buyPrice = 4,   sellPrice = 7,   maxStock = 300 },
            { item = 'copper_bar',  buyPrice = 15,  sellPrice = 22,  maxStock = 100 },
            { item = 'iron_bar',    buyPrice = 20,  sellPrice = 30,  maxStock = 100 },
            { item = 'gem_ruby',    buyPrice = 50,  sellPrice = 75,  maxStock = 30  },
            { item = 'gem_emerald', buyPrice = 100, sellPrice = 150, maxStock = 20  },
            { item = 'gem_diamond', buyPrice = 250, sellPrice = 400, maxStock = 10  },
        },
    },
    {
        name   = 'Saint Denis Forge Exchange',
        coords = vector3(2748.0, -1268.0, 47.0),
        blip   = false,
        items  = {
            { item = 'copper_ore',  buyPrice = 3,   sellPrice = 5,   maxStock = 300 },
            { item = 'iron_ore',    buyPrice = 4,   sellPrice = 7,   maxStock = 300 },
            { item = 'copper_bar',  buyPrice = 15,  sellPrice = 22,  maxStock = 100 },
            { item = 'iron_bar',    buyPrice = 20,  sellPrice = 30,  maxStock = 100 },
            { item = 'gem_ruby',    buyPrice = 50,  sellPrice = 75,  maxStock = 30  },
            { item = 'gem_emerald', buyPrice = 100, sellPrice = 150, maxStock = 20  },
            { item = 'gem_diamond', buyPrice = 250, sellPrice = 400, maxStock = 10  },
        },
    },
    {
        name   = 'Annesburg Forge Exchange',
        coords = vector3(2929.0, 1302.0, 44.0),
        blip   = false,
        items  = {
            { item = 'copper_ore',  buyPrice = 3,   sellPrice = 5,   maxStock = 300 },
            { item = 'iron_ore',    buyPrice = 4,   sellPrice = 7,   maxStock = 300 },
            { item = 'copper_bar',  buyPrice = 15,  sellPrice = 22,  maxStock = 100 },
            { item = 'iron_bar',    buyPrice = 20,  sellPrice = 30,  maxStock = 100 },
            { item = 'gem_ruby',    buyPrice = 50,  sellPrice = 75,  maxStock = 30  },
            { item = 'gem_emerald', buyPrice = 100, sellPrice = 150, maxStock = 20  },
            { item = 'gem_diamond', buyPrice = 250, sellPrice = 400, maxStock = 10  },
        },
    },

    -- ── FARMER'S MARKET (crops) ─────────────────────────────────────────────
    {
        name   = 'Valentine Farmer\'s Market',
        coords = vector3(-337.50, 770.50, 116.80),
        blip   = true,
        items  = {
            { item = 'crop_corn',      buyPrice = 5, sellPrice = 8, maxStock = 200 },
            { item = 'crop_wheat',     buyPrice = 5, sellPrice = 8, maxStock = 200 },
            { item = 'crop_tobacco',   buyPrice = 8, sellPrice = 12, maxStock = 150 },
            { item = 'crop_sugarcane', buyPrice = 5, sellPrice = 8, maxStock = 200 },
            { item = 'crop_herbs',     buyPrice = 8, sellPrice = 12, maxStock = 150 },
            { item = 'crop_berries',   buyPrice = 5, sellPrice = 8, maxStock = 200 },
            { item = 'sugar',          buyPrice = 6, sellPrice = 10, maxStock = 100 },
        },
    },
    {
        name   = 'Rhodes Farmer\'s Market',
        coords = vector3(1328.0, -1312.0, 77.0),
        blip   = true,
        items  = {
            { item = 'crop_corn',      buyPrice = 5, sellPrice = 8, maxStock = 200 },
            { item = 'crop_wheat',     buyPrice = 5, sellPrice = 8, maxStock = 200 },
            { item = 'crop_tobacco',   buyPrice = 8, sellPrice = 12, maxStock = 150 },
            { item = 'crop_sugarcane', buyPrice = 5, sellPrice = 8, maxStock = 200 },
            { item = 'crop_herbs',     buyPrice = 8, sellPrice = 12, maxStock = 150 },
            { item = 'crop_berries',   buyPrice = 5, sellPrice = 8, maxStock = 200 },
            { item = 'sugar',          buyPrice = 6, sellPrice = 10, maxStock = 100 },
        },
    },

    -- ── SPEAKEASIES (moonshine) ─────────────────────────────────────────────
    -- Buy here cheap → /sellshine on street for profit (with law risk)
    -- Speakeasy direct sells: basic=$20, good=$40, premium=$75
    -- Street /sellshine:     basic=$30, good=$55, premium=$110
    -- Exchange buy price = between the two so buyer profits
    {
        name   = 'Lemoyne Speakeasy Exchange',
        coords = vector3(1785.01, -821.53, 191.01),
        blip   = false,  -- speakeasy blip already exists from mike-moonshine
        items  = {
            { item = 'moonshine_basic',   buyPrice = 20, sellPrice = 25, maxStock = 50 },
            { item = 'moonshine_good',    buyPrice = 40, sellPrice = 48, maxStock = 30 },
            { item = 'moonshine_premium', buyPrice = 75, sellPrice = 90, maxStock = 20 },
        },
    },
    {
        name   = 'Cattail Pond Speakeasy Exchange',
        coords = vector3(-1085.63, 714.14, 83.23),
        blip   = false,
        items  = {
            { item = 'moonshine_basic',   buyPrice = 20, sellPrice = 25, maxStock = 50 },
            { item = 'moonshine_good',    buyPrice = 40, sellPrice = 48, maxStock = 30 },
            { item = 'moonshine_premium', buyPrice = 75, sellPrice = 90, maxStock = 20 },
        },
    },
    {
        name   = 'New Austin Speakeasy Exchange',
        coords = vector3(-2769.30, -3048.87, -9.70),
        blip   = false,
        items  = {
            { item = 'moonshine_basic',   buyPrice = 20, sellPrice = 25, maxStock = 50 },
            { item = 'moonshine_good',    buyPrice = 40, sellPrice = 48, maxStock = 30 },
            { item = 'moonshine_premium', buyPrice = 75, sellPrice = 90, maxStock = 20 },
        },
    },
    {
        name   = 'Hanover Speakeasy Exchange',
        coords = vector3(1627.64, 822.90, 123.94),
        blip   = false,
        items  = {
            { item = 'moonshine_basic',   buyPrice = 20, sellPrice = 25, maxStock = 50 },
            { item = 'moonshine_good',    buyPrice = 40, sellPrice = 48, maxStock = 30 },
            { item = 'moonshine_premium', buyPrice = 75, sellPrice = 90, maxStock = 20 },
        },
    },
    {
        name   = 'Manzanita Post Speakeasy Exchange',
        coords = vector3(-1861.70, -1722.17, 88.35),
        blip   = false,
        items  = {
            { item = 'moonshine_basic',   buyPrice = 20, sellPrice = 25, maxStock = 50 },
            { item = 'moonshine_good',    buyPrice = 40, sellPrice = 48, maxStock = 30 },
            { item = 'moonshine_premium', buyPrice = 75, sellPrice = 90, maxStock = 20 },
        },
    },
}

Config.ShopRadius = 6.0
