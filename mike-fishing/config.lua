Config = {}

Config.NetProp     = 'mp007_p_fishnet_damage01x'
Config.NetSlots    = 5          -- max fish per net per cycle
Config.NetCycleTime = 10 * 60  -- seconds until fish are ready (10 min, set to 20-30 for prod)
Config.MaxNets     = 3          -- max nets a player can have placed at once

-- Fish catch table: what fish can be caught and their relative weight (higher = more common)
Config.CatchTable = {
    { item = 'a_c_fishbluegil_01_ms',        label = 'Bluegill',           weight = 10 },
    { item = 'a_c_fishbluegil_01_sm',        label = 'Small Bluegill',     weight = 8 },
    { item = 'a_c_fishperch_01_ms',          label = 'Perch',              weight = 10 },
    { item = 'a_c_fishperch_01_sm',          label = 'Small Perch',        weight = 8 },
    { item = 'a_c_fishbullheadcat_01_ms',    label = 'Bullhead Catfish',   weight = 6 },
    { item = 'a_c_fishrockbass_01_ms',       label = 'Rock Bass',          weight = 7 },
    { item = 'a_c_fishrockbass_01_sm',       label = 'Small Rock Bass',    weight = 5 },
    { item = 'a_c_fishredfinpickerel_01_ms', label = 'Redfin Pickerel',    weight = 6 },
    { item = 'a_c_fishredfinpickerel_01_sm', label = 'Small Redfin Pickerel', weight = 4 },
    { item = 'a_c_fishchainpickerel_01_ms',  label = 'Chain Pickerel',     weight = 4 },
    { item = 'a_c_fishrainbowtrout_01_ms',   label = 'Rainbow Trout',      weight = 3 },
    { item = 'a_c_fishsalmonsockeye_01_ms',  label = 'Sockeye Salmon',     weight = 3 },
    { item = 'a_c_fishsmallmouthbass_01_ms', label = 'Smallmouth Bass',    weight = 3 },
    { item = 'a_c_fishlargemouthbass_01_ms', label = 'Largemouth Bass',    weight = 2 },
    { item = 'a_c_fishrainbowtrout_01_lg',   label = 'Large Rainbow Trout', weight = 1 },
    { item = 'a_c_fishsalmonsockeye_01_lg',  label = 'Large Sockeye Salmon', weight = 1 },
    { item = 'a_c_fishsteelheadtrout',       label = 'Steelhead Trout',    weight = 1 },
}

-- Bait: optional, placing bait with the net increases catch count
Config.BaitBonus = {
    p_baitworm01x    = 2,   -- +2 extra fish
    p_baitbread01x   = 1,   -- +1 extra fish
    p_baitcorn01x    = 1,
    p_baitcheese01x  = 1,
    p_baitcricket01x = 2,
    p_crawdad01x     = 2,
}
