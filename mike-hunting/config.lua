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
