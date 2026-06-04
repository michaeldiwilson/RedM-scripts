Config = {}

Config.Nodes = {
    -- Big Valley copper belt (West Elizabeth)
    { x = -1483.0, y =  370.0, z = 116.0, type = 'copper' },
    { x = -1438.5, y =  392.0, z = 121.0, type = 'copper' },
    { x = -1605.0, y =  205.0, z = 110.0, type = 'copper' },
    -- Tall Trees / Aurora Basin
    { x = -2335.0, y =  110.0, z = 169.0, type = 'copper' },
    -- Annesburg mine (iron) — clustered inside the tunnel
    { x = 2752.85, y = 1329.86, z = 69.91, type = 'iron' },
    { x = 2742.50, y = 1335.20, z = 70.10, type = 'iron' },
    { x = 2762.30, y = 1322.40, z = 69.40, type = 'iron' },
    { x = 2748.10, y = 1340.60, z = 72.00, type = 'iron' },
    { x = 2758.00, y = 1340.00, z = 68.80, type = 'iron' },
    { x = 2755.50, y = 1315.00, z = 70.00, type = 'iron' },
}

Config.OreYieldMin = 1
Config.OreYieldMax = 3
Config.MissChance  = 0.20  -- 20% of swings yield nothing

Config.MineTime    = 4000
Config.ZoneRadius  = 20.0   -- how big the "mineable area" is around each node point

-- Per-swing gem chance + tier weights
Config.GemChance = 0.05
Config.GemRoll = {
    { item = 'gem_ruby',    weight = 70 },
    { item = 'gem_emerald', weight = 25 },
    { item = 'gem_diamond', weight = 5  },
}

-- ── SMELTING ────────────────────────────────────────────────────────────────
Config.Furnaces = {
    { name = 'Valentine Forge',   coords = vector3(-369.50, 796.17, 116.20) },
    { name = 'Saint Denis Forge', coords = vector3(2748.0, -1268.0, 47.0) },
    { name = 'Annesburg Forge',   coords = vector3(2929.0, 1302.0, 44.0) },
}
Config.FurnaceRadius = 6.0

Config.SmeltRecipes = {
    copper_bar = { inputs = { copper_ore = 2, firewood = 1 }, output = 'copper_bar', time = 15000 },
    iron_bar   = { inputs = { iron_ore   = 2, firewood = 1 }, output = 'iron_bar',   time = 20000 },
    nails      = { inputs = { iron_bar   = 1 },               output = 'nails',      time = 8000, qty = 10 },
}

-- TNT mechanic
Config.TNT = {
    fuseSeconds       = 5,
    oreMin            = 8,
    oreMax            = 15,
    gemMin            = 1,
    gemMax            = 2,
    nodeRespawnSec    = 5 * 60,
    blastRadius       = 8.0,   -- damages nearby peds
    propPlaced        = 'p_dynamite01x',
}
