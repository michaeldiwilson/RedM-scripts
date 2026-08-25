Config = {}

Config.CookTime = 8000  -- ms per item

-- ── Station tiers: higher tier can cook everything below ──
-- campfire = 1, campfire_pot = 2, stove = 3
Config.StationTier = {
    campfire     = 1,
    campfire_pot = 2,
    stove        = 3,
}

-- ── Campfire props (tier 1) ──
Config.CampfireModels = {
    'p_campfire01x',
    'p_campfire02x',
    'p_campfire03x',
    'p_campfire04x',
    'p_campfire05x',
    'p_campfirecook01x',
    'p_campfirecook02x',
    'p_campfirecombined01x',
    'p_campfirecombined02x',
    'p_campfirecombined03x',
    'p_campfirecombined04x',
    'p_gen_campfire01x',
    's_campfire01x',
    's_campfire02x',
    'mp001_p_mp_campfire03x',
}

-- ── Cooking pot props (tier 2 — campfire with pot) ──
Config.CookingPotModels = {
    'p_pot01x',
    'p_pot02x',
    'p_pot03x',
    'p_pot04x',
    'p_pot05x',
    'p_cauldron01x',
    'p_cauldron02x',
    'p_cauldron03x',
    'p_group_pot01x',
    'p_kettle01x',
}

-- ── Stove props (tier 3 — does everything) ──
Config.StoveModels = {
    'p_stove01x',
    'p_stove04x',
    'p_stove05x',
    'p_stove06x',
    'p_stove07x',
    'p_ambstove01x',
    'p_gen_stove01x_tc01',
}

-- ── Drying rack prop (separate, for jerky only) ──
Config.DryingRackProp = 'p_dryingrack02x'
Config.DryingTime = 10 * 60  -- seconds to dry (10 min)
Config.DryingSlots = 5       -- max items drying at once

-- ──────────────────────────────────────────────────────────────────────────
-- Cooking recipes: tier determines which stations can make it
-- ──────────────────────────────────────────────────────────────────────────
Config.Recipes = {
    -- ── Tier 1: Campfire (basic meat/fish) ──
    -- Fish
    a_c_fishbluegil_01_sm       = { label = 'Small Bluegill',           output = 'cooked_fish', qty = 1, tier = 1 },
    a_c_fishperch_01_sm         = { label = 'Small Perch',              output = 'cooked_fish', qty = 1, tier = 1 },
    a_c_fishbullheadcat_01_sm   = { label = 'Small Bullhead Catfish',   output = 'cooked_fish', qty = 1, tier = 1 },
    a_c_fishredfinpickerel_01_sm = { label = 'Small Redfin Pickerel',   output = 'cooked_fish', qty = 1, tier = 1 },
    a_c_fishrockbass_01_sm      = { label = 'Small Rock Bass',          output = 'cooked_fish', qty = 1, tier = 1 },
    a_c_fishchainpickerel_01_sm = { label = 'Small Chain Pickerel',     output = 'cooked_fish', qty = 1, tier = 1 },
    a_c_fishbluegil_01_ms       = { label = 'Bluegill',                 output = 'cooked_fish', qty = 2, tier = 1 },
    a_c_fishperch_01_ms         = { label = 'Perch',                    output = 'cooked_fish', qty = 2, tier = 1 },
    a_c_fishbullheadcat_01_ms   = { label = 'Bullhead Catfish',         output = 'cooked_fish', qty = 2, tier = 1 },
    a_c_fishredfinpickerel_01_ms = { label = 'Redfin Pickerel',         output = 'cooked_fish', qty = 2, tier = 1 },
    a_c_fishrockbass_01_ms      = { label = 'Rock Bass',                output = 'cooked_fish', qty = 2, tier = 1 },
    a_c_fishchainpickerel_01_ms = { label = 'Chain Pickerel',           output = 'cooked_fish', qty = 2, tier = 1 },
    a_c_fishlargemouthbass_01_ms = { label = 'Largemouth Bass',         output = 'cooked_fish', qty = 2, tier = 1 },
    a_c_fishsmallmouthbass_01_ms = { label = 'Smallmouth Bass',         output = 'cooked_fish', qty = 2, tier = 1 },
    a_c_fishrainbowtrout_01_ms  = { label = 'Rainbow Trout',           output = 'cooked_fish', qty = 2, tier = 1 },
    a_c_fishsalmonsockeye_01_ms = { label = 'Sockeye Salmon',           output = 'cooked_fish', qty = 2, tier = 1 },
    a_c_fishsalmonsockeye_01_ml = { label = 'Sockeye Salmon (Med-Lg)',  output = 'cooked_fish', qty = 2, tier = 1 },
    a_c_fishlargemouthbass_01_lg = { label = 'Large Largemouth Bass',   output = 'cooked_fish', qty = 3, tier = 1 },
    a_c_fishsmallmouthbass_01_lg = { label = 'Large Smallmouth Bass',   output = 'cooked_fish', qty = 3, tier = 1 },
    a_c_fishrainbowtrout_01_lg  = { label = 'Large Rainbow Trout',     output = 'cooked_fish', qty = 3, tier = 1 },
    a_c_fishsalmonsockeye_01_lg = { label = 'Large Sockeye Salmon',     output = 'cooked_fish', qty = 3, tier = 1 },
    a_c_fishlakesturgeon_01_lg  = { label = 'Lake Sturgeon',           output = 'cooked_fish', qty = 3, tier = 1 },
    a_c_fishlongnosegar_01_lg   = { label = 'Longnose Gar',            output = 'cooked_fish', qty = 3, tier = 1 },
    a_c_fishmuskie_01_lg        = { label = 'Muskie',                  output = 'cooked_fish', qty = 3, tier = 1 },
    a_c_fishnorthernpike_01_lg  = { label = 'Northern Pike',           output = 'cooked_fish', qty = 3, tier = 1 },
    a_c_fishsteelheadtrout      = { label = 'Steelhead Trout',         output = 'cooked_fish', qty = 3, tier = 1 },
    a_c_fishchannelcatfish_01_lg = { label = 'Channel Catfish',         output = 'cooked_fish', qty = 4, tier = 1 },
    a_c_fishchannelcatfish_01_xl = { label = 'XL Channel Catfish',      output = 'cooked_fish', qty = 5, tier = 1 },
    -- Meat
    venison    = { label = 'Raw Venison',    output = 'cooked_venison',   qty = 1, tier = 1 },
    bear_meat  = { label = 'Raw Bear Meat',  output = 'cooked_bear_meat', qty = 1, tier = 1 },
    bison_meat = { label = 'Raw Bison Meat', output = 'cooked_bison_meat',qty = 1, tier = 1 },
    game_meat  = { label = 'Raw Game Meat',  output = 'cooked_game_meat', qty = 1, tier = 1 },
    pork       = { label = 'Raw Pork',       output = 'cooked_pork',      qty = 1, tier = 1 },
    mutton     = { label = 'Raw Mutton',     output = 'cooked_mutton',    qty = 1, tier = 1 },

    -- ── Tier 2: Campfire + Cooking Pot ──
    boiled_egg = { label = 'Boiled Egg',  output = 'boiled_egg', qty = 1, tier = 2, inputs = { eggs = 1 } },
    butter     = { label = 'Butter',      output = 'butter',     qty = 1, tier = 2, inputs = { milk_pail = 1 } },
    stew       = { label = 'Stew',        output = 'stew',       qty = 1, tier = 2, inputs = { game_meat = 1, crop_corn = 1 } },

    -- ── Tier 3: Stove only ──
    cheese     = { label = 'Cheese',      output = 'cheese',     qty = 1, tier = 3, inputs = { milk_pail = 1 } },
    flour      = { label = 'Flour',       output = 'flour',      qty = 1, tier = 3, inputs = { crop_wheat = 2 } },
    bread      = { label = 'Bread',       output = 'bread',      qty = 1, tier = 3, inputs = { flour = 1, milk_pail = 1 } },
    sausage    = { label = 'Sausage',     output = 'sausage',    qty = 2, tier = 3, inputs = { game_meat = 2 } },
    fertilizer = { label = 'Fertilizer',  output = 'fertilizer', qty = 2, tier = 3, inputs = { manure = 1 } },
}

-- Drying rack recipes (separate from cooking)
Config.DryingRecipes = {
    jerky_venison = { input = 'venison',   output = 'jerky', qty = 2, label = 'Venison Jerky' },
    jerky_game    = { input = 'game_meat', output = 'jerky', qty = 2, label = 'Game Jerky' },
    jerky_pork    = { input = 'pork',      output = 'jerky', qty = 2, label = 'Pork Jerky' },
    jerky_bison   = { input = 'bison_meat',output = 'jerky', qty = 2, label = 'Bison Jerky' },
}
