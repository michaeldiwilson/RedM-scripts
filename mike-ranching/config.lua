Config = {}

-- ── Ranch Location ──
Config.RanchCoords = vector3(-1626.67, -1395.06, 82.69)
Config.RanchRadius = 80.0  -- area within which animals can be placed

-- ── Animal Trader NPC ──
Config.Trader = {
    coords  = vector3(-1620.0, -1390.0, 82.69),
    heading = 90.0,
    model   = 's_m_m_rhdcowpoke_01',
    name    = 'Livestock Trader',
}

-- ── Feed/Water Props ──
Config.FeedTroughProp  = 'p_feedtrough01x'
Config.WaterTroughProp = 'p_watertrough01x'

-- ── Timers (in seconds) ──
Config.HungerRate    = 15 * 60   -- loses 1 hunger every 15 min
Config.ThirstRate    = 10 * 60   -- loses 1 thirst every 10 min
Config.ProduceTime   = 20 * 60  -- produces goods every 20 min (if fed + watered)
Config.MaxHunger     = 100
Config.MaxThirst     = 100

-- ── Animal Types ──
Config.AnimalTypes = {
    cow = {
        label    = 'Cow',
        model    = 'a_c_cow',
        price    = 50,
        produce  = { item = 'milk_pail', qty = 1, label = 'Milk' },
        feedItem = 'hay_cube',
        feedQty  = 1,
        feedRestore = 30,
        waterRestore = 30,
    },
    chicken = {
        label    = 'Chicken',
        model    = 'a_c_chicken_01',
        price    = 10,
        produce  = { item = 'eggs', qty = 2, label = 'Eggs' },
        feedItem = 'crop_corn',
        feedQty  = 1,
        feedRestore = 40,
        waterRestore = 40,
    },
    sheep = {
        label    = 'Sheep',
        model    = 'mp_a_c_sheep_01',
        price    = 30,
        produce  = { item = 'raw_wool', qty = 1, label = 'Wool' },
        feedItem = 'hay_cube',
        feedQty  = 1,
        feedRestore = 30,
        waterRestore = 30,
    },
    goat = {
        label    = 'Goat',
        model    = 'a_c_goat_01',
        price    = 20,
        produce  = { item = 'milk_pail', qty = 1, label = 'Milk' },
        feedItem = 'hay_cube',
        feedQty  = 1,
        feedRestore = 35,
        waterRestore = 35,
    },
    pig = {
        label    = 'Pig',
        model    = 'a_c_pig_01',
        price    = 25,
        produce  = { item = 'fat', qty = 2, label = 'Fat' },
        feedItem = 'crop_corn',
        feedQty  = 2,
        feedRestore = 25,
        waterRestore = 25,
    },
}

-- Max animals per player
Config.MaxAnimals = 10

-- ── Sell prices for produce ──
Config.ProducePrices = {
    milk_pail = 8,
    eggs      = 4,
    raw_wool  = 12,
}
