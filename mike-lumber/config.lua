Config = {}

Config.ChopTime        = 5000
Config.LogYieldMin     = 1
Config.LogYieldMax     = 2
Config.FirewoodChance  = 0.35
Config.MissChance      = 0.15
Config.TreeCooldownSec = 120      -- same tree can't be chopped again for 2 min
Config.TreeSearchRadius = 3.0     -- how close the player must be to a tree
Config.ChopKey = 0x760A9C6F       -- G by default (CONTROL_CONTEXT / INPUT_CONTEXT)

-- Starter list of RDR2 tree model names. Hashes are computed via joaat().
-- Add any new tree name the /treescan command reveals.
Config.TreeModels = {
    -- Oaks
    'p_tree_oak_01',      'p_tree_oak_02',      'p_tree_oak_03',      'p_tree_oak_04',
    'p_tree_oak_ca_01',   'p_tree_oak_ca_02',   'p_tree_oak_sm_01',   'p_tree_oak_sm_02',
    -- Pines (US variants)
    'p_tree_pine_us_01a', 'p_tree_pine_us_02a', 'p_tree_pine_us_03a', 'p_tree_pine_us_04a',
    'p_tree_pine_us_05a', 'p_tree_pine_us_06',  'p_tree_pine_us_07',  'p_tree_pine_us_08a',
    'p_tree_pine_ca_01',  'p_tree_pine_ca_02',
    'p_tree_pine_01a',    'p_tree_pine_02a',    'p_tree_pine_03a',    'p_tree_pine_04a',
    -- Spruce / Fir
    'p_tree_spruce_01a',  'p_tree_spruce_02a',  'p_tree_spruce_03a',
    'p_tree_fir_01a',     'p_tree_fir_02a',     'p_tree_fir_03a',
    -- Birch / Maple / Willow
    'p_tree_birch_01a',   'p_tree_birch_02a',   'p_tree_birch_03a',
    'p_tree_maple_01a',   'p_tree_maple_02a',
    'p_tree_willow_01a',  'p_tree_willow_02',
    -- Cottonwood / Aspen
    'p_tree_cottonwood_01', 'p_tree_cottonwood_02',
    'p_tree_aspen_01',      'p_tree_aspen_02',
    -- MP / other variants seen on servers
    'mp005_p_tree_pine_us_06',
    'mp006_p_tree_pine_us_06',
}

-- Prefixes used by the /treescan debug command to highlight "probably a tree"
Config.TreePrefixes = {
    'p_tree', 'p_treelog', 'pg_tree',
    'mp005_p_tree', 'mp006_p_tree',
    's_tree', 'p_oaktree', 'p_pinetree', 'p_birchtree', 'p_aspen', 'p_cottonwood',
}

Config.Sawmills = {
    { name = 'Valentine Sawmill',      coords = vector3(-320.50, 801.50, 117.20) },
    { name = 'Annesburg Sawmill',      coords = vector3(2914.00, 1305.00, 44.80) },
    { name = 'Riggs Station Sawmill',  coords = vector3(-1827.00, -411.00, 161.50) },
}
Config.SawmillRadius = 6.0

Config.MillRecipes = {
    oak_plank = { inputs = { oak_log = 2 }, output = 'oak_plank', time = 10000 },
}
