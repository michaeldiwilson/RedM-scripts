Config = {}

Config.SkinTime     = 15000
Config.SkinRadius   = 2.5
Config.WagonLoadRadius = 5.0

-- Tanning rack
Config.TanningRackProp = 'p_ambpelt01x'
Config.TanningCureTime = 5 * 60              -- seconds to cure a pelt (5 min for testing, set to 15-20 later)
Config.TanningSlots    = 4                   -- pelts per rack

-- Pelt → leather yields (used by tanning rack)
Config.PeltLeather = {
    rabbit_pelt = 1,
    deer_pelt   = 2,
    boar_pelt   = 2,
    wolf_pelt   = 2,
    coyote_pelt = 1,
    sheep_pelt  = 1,
    goat_pelt   = 1,
    elk_pelt    = 3,
    cougar_pelt = 3,
    bear_pelt   = 5,
    bison_pelt  = 5,
}

-- Animal definitions: model hash → type key
-- Multiple models can map to the same type
Config.AnimalModels = {
    -- Deer (doe)
    ['a_c_deer_01']   = 'deer',
    -- Deer (buck)
    ['a_c_buck_01']   = 'buck',
    -- Elk
    ['a_c_elk_01']    = 'elk',
    -- Grizzly bear
    ['a_c_bear_01']   = 'bear',
    ['a_c_grizzly_01'] = 'bear',
    -- Bison
    ['a_c_buffalo_01']     = 'bison',
    ['a_c_buffalo_tatanka_01'] = 'bison',
    -- Boar
    ['a_c_boar_01']   = 'boar',
    -- Rabbit
    ['a_c_rabbit_01'] = 'rabbit',
    -- Pronghorn
    ['a_c_pronghorn_01'] = 'pronghorn',
    -- Cougar
    ['a_c_cougar_01'] = 'cougar',
    -- Wolf
    ['a_c_wolf']      = 'wolf',
    ['a_c_wolf_small'] = 'wolf',
    -- Sheep
    ['a_c_sheep_01']  = 'sheep',
    -- Goat
    ['a_c_goat_01']   = 'goat',
    -- Coyote
    ['a_c_coyote_01'] = 'coyote',
}

-- Yields per animal type
-- meat: { item, min, max }
-- pelt: item name
-- extras: { {item, qty}, ... }
-- carcass: item name for wagon stash
-- carcassProp: prop to attach to wagon (visual)
-- leatherYield: how much leather when curing the pelt
Config.Animals = {
    deer = {
        label        = 'Deer',
        meat         = { item = 'venison', min = 2, max = 3 },
        pelt         = 'deer_pelt',
        extras       = {},
        carcass      = 'deer_carcass',
        carcassProp  = 'p_opossum01x',  -- placeholder prop
        leatherYield = 2,
    },
    buck = {
        label        = 'Buck',
        meat         = { item = 'venison', min = 2, max = 4 },
        pelt         = 'deer_pelt',
        extras       = { { item = 'antlers', qty = 1 } },
        carcass      = 'deer_carcass',
        carcassProp  = 'p_opossum01x',
        leatherYield = 2,
    },
    elk = {
        label        = 'Elk',
        meat         = { item = 'venison', min = 3, max = 5 },
        pelt         = 'elk_pelt',
        extras       = { { item = 'antlers', qty = 2 } },
        carcass      = 'elk_carcass',
        carcassProp  = 'p_opossum01x',
        leatherYield = 3,
    },
    bear = {
        label        = 'Grizzly Bear',
        meat         = { item = 'bear_meat', min = 3, max = 5 },
        pelt         = 'bear_pelt',
        extras       = { { item = 'bear_claw', qty = 2 } },
        carcass      = 'bear_carcass',
        carcassProp  = 'p_opossum01x',
        leatherYield = 5,
    },
    bison = {
        label        = 'Bison',
        meat         = { item = 'bison_meat', min = 4, max = 6 },
        pelt         = 'bison_pelt',
        extras       = { { item = 'bison_horn', qty = 1 } },
        carcass      = 'bison_carcass',
        carcassProp  = 'p_opossum01x',
        leatherYield = 5,
    },
    boar = {
        label        = 'Boar',
        meat         = { item = 'pork', min = 2, max = 3 },
        pelt         = 'boar_pelt',
        extras       = { { item = 'tusk', qty = 1 } },
        carcass      = 'boar_carcass',
        carcassProp  = 'p_opossum01x',
        leatherYield = 2,
    },
    rabbit = {
        label        = 'Rabbit',
        meat         = { item = 'game_meat', min = 1, max = 1 },
        pelt         = 'rabbit_pelt',
        extras       = {},
        carcass      = 'rabbit_carcass',
        carcassProp  = 'p_opossum01x',
        leatherYield = 1,
    },
    pronghorn = {
        label        = 'Pronghorn',
        meat         = { item = 'venison', min = 2, max = 4 },
        pelt         = 'deer_pelt',
        extras       = { { item = 'antlers', qty = 1 } },
        carcass      = 'deer_carcass',
        carcassProp  = 'p_opossum01x',
        leatherYield = 2,
    },
    cougar = {
        label        = 'Cougar',
        meat         = { item = 'game_meat', min = 2, max = 3 },
        pelt         = 'cougar_pelt',
        extras       = {},
        carcass      = 'cougar_carcass',
        carcassProp  = 'p_opossum01x',
        leatherYield = 3,
    },
    wolf = {
        label        = 'Wolf',
        meat         = { item = 'game_meat', min = 1, max = 2 },
        pelt         = 'wolf_pelt',
        extras       = {},
        carcass      = 'wolf_carcass',
        carcassProp  = 'p_opossum01x',
        leatherYield = 2,
    },
    sheep = {
        label        = 'Sheep',
        meat         = { item = 'mutton', min = 2, max = 3 },
        pelt         = 'sheep_pelt',
        extras       = {},
        carcass      = 'sheep_carcass',
        carcassProp  = 'p_opossum01x',
        leatherYield = 1,
    },
    goat = {
        label        = 'Goat',
        meat         = { item = 'game_meat', min = 1, max = 2 },
        pelt         = 'goat_pelt',
        extras       = {},
        carcass      = 'goat_carcass',
        carcassProp  = 'p_opossum01x',
        leatherYield = 1,
    },
    coyote = {
        label        = 'Coyote',
        meat         = { item = 'game_meat', min = 1, max = 2 },
        pelt         = 'coyote_pelt',
        extras       = {},
        carcass      = 'coyote_carcass',
        carcassProp  = 'p_opossum01x',
        leatherYield = 1,
    },
}

-- Butcher locations (sell carcasses + meat)
Config.Butchers = {
    { name = 'Valentine Butcher',   coords = vector3(-339.19, 767.54, 116.58), npcmodel = 's_m_m_unibutchers_01' },
    { name = 'Rhodes Butcher',      coords = vector3(1330.00, -1310.00, 77.50) },
    { name = 'Saint Denis Butcher', coords = vector3(2828.00, -1332.00, 46.00) },
}
Config.ButcherRadius = 4.0

-- ──────────────────────────────────────────────────────────────────────────
-- Pelt Quality System
-- ──────────────────────────────────────────────────────────────────────────

-- Animal size classes — determines which weapon category is "correct"
Config.AnimalSizeClass = {
    rabbit    = 'small',
    coyote    = 'small',
    goat      = 'small',
    sheep     = 'medium',
    deer      = 'medium',
    buck      = 'medium',
    pronghorn = 'medium',
    boar      = 'medium',
    wolf      = 'medium',
    cougar    = 'medium',
    elk       = 'large',
    bear      = 'large',
    bison     = 'large',
}

-- Weapon hash → hunting class
Config.WeaponClass = {
    -- Varmint: correct for small animals
    [joaat('WEAPON_RIFLE_VARMINT')]             = 'varmint',
    -- Bow: correct for small + medium
    [joaat('WEAPON_BOW')]                       = 'bow',
    [joaat('WEAPON_BOW_IMPROVED')]              = 'bow',
    -- Rifles/Repeaters: correct for medium
    [joaat('WEAPON_RIFLE_BOLTACTION')]          = 'rifle',
    [joaat('WEAPON_RIFLE_SPRINGFIELD')]         = 'rifle',
    [joaat('WEAPON_REPEATER_CARBINE')]          = 'rifle',
    [joaat('WEAPON_REPEATER_EVANS')]            = 'rifle',
    [joaat('WEAPON_REPEATER_HENRY')]            = 'rifle',
    [joaat('WEAPON_REPEATER_WINCHESTER')]       = 'rifle',
    -- High-power / Sniper: correct for large
    [joaat('WEAPON_SNIPERRIFLE_CARCANO')]       = 'highpower',
    [joaat('WEAPON_SNIPERRIFLE_ROLLINGBLOCK')]  = 'highpower',
    [joaat('WEAPON_RIFLE_ELEPHANT')]            = 'highpower',
    -- Shotguns: always ruins pelts
    [joaat('WEAPON_SHOTGUN_DOUBLEBARREL')]      = 'shotgun',
    [joaat('WEAPON_SHOTGUN_PUMP')]              = 'shotgun',
    [joaat('WEAPON_SHOTGUN_REPEATING')]         = 'shotgun',
    [joaat('WEAPON_SHOTGUN_SAWEDOFF')]          = 'shotgun',
    [joaat('WEAPON_SHOTGUN_SEMIAUTO')]          = 'shotgun',
    -- Pistols/Revolvers: always ruins pelts
    [joaat('WEAPON_PISTOL_M1899')]              = 'pistol',
    [joaat('WEAPON_PISTOL_MAUSER')]             = 'pistol',
    [joaat('WEAPON_PISTOL_SEMIAUTO')]           = 'pistol',
    [joaat('WEAPON_PISTOL_VOLCANIC')]           = 'pistol',
    [joaat('WEAPON_REVOLVER_CATTLEMAN')]        = 'pistol',
    [joaat('WEAPON_REVOLVER_DOUBLEACTION')]     = 'pistol',
    [joaat('WEAPON_REVOLVER_LEMAT')]            = 'pistol',
    [joaat('WEAPON_REVOLVER_NAVY')]             = 'pistol',
    [joaat('WEAPON_REVOLVER_SCHOFIELD')]        = 'pistol',
}

-- Which weapon classes are appropriate for each size class
Config.CorrectWeapons = {
    small  = { varmint = true, bow = true },
    medium = { rifle = true, bow = true },
    large  = { highpower = true, rifle = true },
}

-- Quality multipliers (1 = poor, 2 = good, 3 = perfect)
Config.QualityMultiplier = {
    [1] = { priceMulti = 0.4,  meatMulti = 0.5,  prefix = 'poor_',    label = 'Poor'    },
    [2] = { priceMulti = 1.0,  meatMulti = 1.0,  prefix = '',         label = 'Good'    },
    [3] = { priceMulti = 1.5,  meatMulti = 1.25, prefix = 'perfect_', label = 'Perfect' },
}

-- Generate quality-variant PeltLeather entries (poor = half, perfect = base+1)
for basePelt, baseLeather in pairs(Config.PeltLeather) do
    Config.PeltLeather['poor_' .. basePelt]    = math.max(1, math.floor(baseLeather / 2))
    Config.PeltLeather['perfect_' .. basePelt] = baseLeather + 1
end

-- ──────────────────────────────────────────────────────────────────────────
-- Legendary Animals
-- ──────────────────────────────────────────────────────────────────────────
Config.LegendaryAnimals = {
    legendary_bear = {
        label        = 'Legendary Grizzly',
        model        = 'a_c_bear_01',
        typeKey      = 'bear',
        coords       = vector3(-1607.0, 725.0, 112.0),
        heading      = 180.0,
        wanderRadius = 30.0,
        cooldown     = 45 * 60,
        pelt         = 'legendary_bear_pelt',
        extras       = { { item = 'legendary_bear_claw', qty = 1 } },
        meat         = { item = 'bear_meat', min = 5, max = 8 },
        rumorPrice   = 30,
    },
    legendary_cougar = {
        label        = 'Legendary Cougar',
        model        = 'a_c_cougar_01',
        typeKey      = 'cougar',
        coords       = vector3(-2100.0, -550.0, 135.0),
        heading      = 90.0,
        wanderRadius = 25.0,
        cooldown     = 50 * 60,
        pelt         = 'legendary_cougar_pelt',
        extras       = {},
        meat         = { item = 'game_meat', min = 3, max = 5 },
        rumorPrice   = 35,
    },
    legendary_elk = {
        label        = 'Legendary Elk',
        model        = 'a_c_elk_01',
        typeKey      = 'elk',
        coords       = vector3(-800.0, 1200.0, 105.0),
        heading      = 0.0,
        wanderRadius = 40.0,
        cooldown     = 50 * 60,
        pelt         = 'legendary_elk_pelt',
        extras       = { { item = 'legendary_antlers', qty = 1 } },
        meat         = { item = 'venison', min = 5, max = 8 },
        rumorPrice   = 30,
    },
    legendary_wolf = {
        label        = 'Legendary Wolf',
        model        = 'a_c_wolf',
        typeKey      = 'wolf',
        coords       = vector3(-1200.0, 950.0, 95.0),
        heading      = 270.0,
        wanderRadius = 35.0,
        cooldown     = 45 * 60,
        pelt         = 'legendary_wolf_pelt',
        extras       = {},
        meat         = { item = 'game_meat', min = 3, max = 5 },
        rumorPrice   = 25,
    },
    legendary_bison_heartlands = {
        label        = 'Legendary Heartlands Bison',
        model        = 'a_c_buffalo_01',
        typeKey      = 'bison',
        coords       = vector3(1310.0, 400.0, 92.0),    -- Heartlands
        heading      = 45.0,
        wanderRadius = 50.0,
        cooldown     = 60 * 60,
        pelt         = 'legendary_bison_pelt',
        extras       = { { item = 'legendary_bison_horn', qty = 1 } },
        meat         = { item = 'bison_meat', min = 6, max = 10 },
        rumorPrice   = 40,
    },
    legendary_bison_plains = {
        label        = 'Legendary Plains Bison',
        model        = 'a_c_buffalo_tatanka_01',
        typeKey      = 'bison',
        coords       = vector3(-1870.0, -1650.0, 112.0), -- Great Plains near Blackwater
        heading      = 90.0,
        wanderRadius = 50.0,
        cooldown     = 60 * 60,
        pelt         = 'legendary_bison_pelt',
        extras       = { { item = 'legendary_bison_horn', qty = 1 } },
        meat         = { item = 'bison_meat', min = 6, max = 10 },
        rumorPrice   = 40,
    },
}
Config.LegendarySpawnRadius  = 200.0
Config.LegendaryNotifyRadius = 300.0

-- ──────────────────────────────────────────────────────────────────────────
-- Animal Bait
-- ──────────────────────────────────────────────────────────────────────────
Config.Bait = {
    herbivore_bait = {
        label      = 'Herbivore Bait',
        prop       = 'p_opossum01x',
        attracts   = { 'deer', 'buck', 'elk', 'bison', 'pronghorn', 'sheep', 'goat' },
        spawnCount = { min = 1, max = 2 },
        delay      = { min = 30, max = 60 },
        lifetime   = 300,
        spawnDist  = { min = 40, max = 60 },
    },
    predator_bait = {
        label      = 'Predator Bait',
        prop       = 'p_opossum01x',
        attracts   = { 'wolf', 'cougar', 'bear', 'coyote' },
        spawnCount = { min = 1, max = 2 },
        delay      = { min = 30, max = 45 },
        lifetime   = 300,
        spawnDist  = { min = 50, max = 70 },
    },
}
Config.MaxActiveBaits = 2

-- ──────────────────────────────────────────────────────────────────────────
-- Butcher / Selling
-- ──────────────────────────────────────────────────────────────────────────

-- Carcass prices (sold whole at butcher)
Config.CarcassPrices = {
    deer_carcass   = 14,
    elk_carcass    = 22,
    bear_carcass   = 35,
    bison_carcass  = 38,
    boar_carcass   = 12,
    rabbit_carcass = 5,
    cougar_carcass = 28,
    wolf_carcass   = 10,
    sheep_carcass  = 8,
    goat_carcass   = 7,
    coyote_carcass = 5,
}
