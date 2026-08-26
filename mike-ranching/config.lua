Config = {}

-- ── Ranch Definition ──
Config.Ranch = {
    key        = 'beechers_hope',
    name       = "Beecher's Hope Ranch",
    coords     = vector3(-1626.67, -1395.06, 82.69),
    animalArea = vector3(-1616.46, -1403.41, 82.02),  -- where animals spawn
    price      = 5000,
    sellBack   = 2500,
    radius     = 80.0,
}

-- ── Grazing & Watering Zones ──
-- Owner sets these in-game via trader menu. Stored in DB.
Config.PastureRadius = 50.0     -- large area so animals stay in zone
Config.PastureRestoreRate = 5   -- hunger restored per tick (every 60s) — must outpace decay of 2
Config.WaterRadius = 25.0      -- generous water zone
Config.WaterRestoreRate = 5     -- thirst restored per tick — must outpace decay of 2

-- ── Trader NPC (buy ranch + buy animals) ──
Config.Trader = {
    coords  = vector3(-1620.0, -1390.0, 82.69),
    heading = 90.0,
    model   = 's_m_m_rhdcowpoke_01',
    name    = 'Livestock Trader',
}

-- ── Rank Permissions ──
-- owner > head_rancher > hand
Config.Ranks = {
    owner        = { level = 3, label = 'Owner' },
    head_rancher = { level = 2, label = 'Head Rancher' },
    hand         = { level = 1, label = 'Ranch Hand' },
}

-- Actions and minimum rank level required
Config.Permissions = {
    feed_water      = 1,  -- hand+
    collect_produce = 1,  -- hand+
    buy_animal      = 2,  -- head_rancher+
    sell_animal      = 2,  -- head_rancher+
    hire_fire       = 3,  -- owner only
    sell_ranch      = 3,  -- owner only
}

-- ── Growth System ──
Config.Growth = {
    TickRate       = 60 * 1000,   -- check every 60 seconds
    ScaleIncrease  = 0.05,        -- TESTING: fast growth, set back to 0.00278 for prod
    StartScale     = 0.5,         -- baby size
    MaxScale       = 1.0,         -- adult size
    MinHungerToGrow = 30,         -- must be fed above this to grow
    MinScaleToProduce = 0.95,     -- must be nearly full grown to produce
}

-- ── Hunger/Thirst ──
Config.HungerDecayPerTick = 0.5  -- hunger drops per growth tick (very slow)
Config.ThirstDecayPerTick = 0.5  -- thirst drops per growth tick (very slow)
Config.MaxHunger  = 100
Config.MaxThirst  = 100
Config.ProduceTime = 20 * 60    -- seconds between production cycles

-- ── Animal Types ──
Config.AnimalTypes = {
    cow = {
        label        = 'Cow',
        model        = 'a_c_cow',
        price        = 50,
        produce      = { item = 'milk_pail', qty = 1, label = 'Milk' },
        feedItem     = 'hay_cube',
        feedQty      = 1,
        feedRestore  = 30,
        waterRestore = 30,
    },
    bull = {
        label        = 'Bull',
        model        = 'a_c_bull_01',
        price        = 100,
        produce      = { item = 'manure', qty = 1, label = 'Manure' },
        feedItem     = 'hay_cube',
        feedQty      = 2,
        feedRestore  = 25,
        waterRestore = 25,
    },
    chicken = {
        label        = 'Chicken',
        model        = 'a_c_chicken_01',
        price        = 10,
        produce      = { item = 'eggs', qty = 2, label = 'Eggs' },
        feedItem     = 'crop_corn',
        feedQty      = 1,
        feedRestore  = 40,
        waterRestore = 40,
    },
    rooster = {
        label        = 'Rooster',
        model        = 'a_c_rooster_01',
        price        = 15,
        produce      = { item = 'manure', qty = 1, label = 'Manure' },
        feedItem     = 'crop_corn',
        feedQty      = 1,
        feedRestore  = 40,
        waterRestore = 40,
    },
    sheep = {
        label        = 'Sheep',
        model        = 'mp_a_c_sheep_01',
        price        = 30,
        produce      = { item = 'raw_wool', qty = 1, label = 'Wool' },
        feedItem     = 'hay_cube',
        feedQty      = 1,
        feedRestore  = 30,
        waterRestore = 30,
    },
    goat = {
        label        = 'Goat',
        model        = 'a_c_goat_01',
        price        = 20,
        produce      = { item = 'milk_pail', qty = 1, label = 'Milk' },
        feedItem     = 'hay_cube',
        feedQty      = 1,
        feedRestore  = 35,
        waterRestore = 35,
    },
    pig = {
        label        = 'Pig',
        model        = 'a_c_pig_01',
        price        = 25,
        produce      = { item = 'fat', qty = 2, label = 'Fat' },
        feedItem     = 'crop_corn',
        feedQty      = 2,
        feedRestore  = 25,
        waterRestore = 25,
    },
}

Config.MaxAnimals = 15

-- ── Market Stall (rancher sells produce to other players) ──
Config.MarketStall = {
    coords  = vector3(-836.60, -1224.19, 43.53),
    heading = 0.0,
    radius  = 3.0,
    name    = 'Ranch Market',
    npcmodel = 's_m_m_rhdcowpoke_01',
}

-- ── Barn ──
Config.Barn = {
    coords  = vector3(-1607.0, -1410.0, 82.69),  -- barn door location
    heading = 0.0,
    radius  = 3.0,
    barnDecayMultiplier = 0.5,  -- hunger/thirst decays 50% slower in barn
}

-- ── Slaughterhouse ──
Config.Slaughterhouses = {
    {
        name   = 'Blackwater Slaughterhouse',
        coords = vector3(-951.32, -1339.85, 50.66),
        radius = 5.0,
        npcmodel = 's_m_m_unibutchers_01',
        heading = 0.0,
    },
}
Config.OnSitePenalty = 0.9  -- 90% yield if slaughtered on ranch (10% penalty)

-- ── Butcher yields per animal type (when slaughtered) ──
Config.SlaughterYields = {
    cow     = { { item = 'venison', qty = 8 },  { item = 'leather', qty = 2 }, { item = 'fat', qty = 2 } },
    bull    = { { item = 'venison', qty = 12 }, { item = 'leather', qty = 3 } },
    chicken = { { item = 'game_meat', qty = 2 }, { item = 'eggs', qty = 3 } },
    rooster = { { item = 'game_meat', qty = 2 } },
    sheep   = { { item = 'mutton', qty = 5 },   { item = 'raw_wool', qty = 3 } },
    goat    = { { item = 'game_meat', qty = 4 }, { item = 'fat', qty = 1 } },
    pig     = { { item = 'pork', qty = 6 },      { item = 'fat', qty = 3 } },
}

-- ── Animals that can't graze (must be hand-fed or barn-fed) ──
Config.NoGrazeAnimals = {
    pig = true,
    chicken = true,
    rooster = true,
}
