Config = {}

Config.CookTime = 8000  -- ms per item

-- Campfire props that can be used for cooking (ox_target will detect these)
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

-- ──────────────────────────────────────────────────────────────────────────
-- Cooking recipes: raw item → cooked item + yield
-- ──────────────────────────────────────────────────────────────────────────
Config.Recipes = {
    -- ── Fish (size determines yield) ──
    -- Small fish → 1 cooked fish
    a_c_fishbluegil_01_sm       = { label = 'Small Bluegill',           output = 'cooked_fish', qty = 1 },
    a_c_fishperch_01_sm         = { label = 'Small Perch',              output = 'cooked_fish', qty = 1 },
    a_c_fishbullheadcat_01_sm   = { label = 'Small Bullhead Catfish',   output = 'cooked_fish', qty = 1 },
    a_c_fishredfinpickerel_01_sm = { label = 'Small Redfin Pickerel',   output = 'cooked_fish', qty = 1 },
    a_c_fishrockbass_01_sm      = { label = 'Small Rock Bass',          output = 'cooked_fish', qty = 1 },
    a_c_fishchainpickerel_01_sm = { label = 'Small Chain Pickerel',     output = 'cooked_fish', qty = 1 },

    -- Medium fish → 2 cooked fish
    a_c_fishbluegil_01_ms       = { label = 'Bluegill',                 output = 'cooked_fish', qty = 2 },
    a_c_fishperch_01_ms         = { label = 'Perch',                    output = 'cooked_fish', qty = 2 },
    a_c_fishbullheadcat_01_ms   = { label = 'Bullhead Catfish',         output = 'cooked_fish', qty = 2 },
    a_c_fishredfinpickerel_01_ms = { label = 'Redfin Pickerel',         output = 'cooked_fish', qty = 2 },
    a_c_fishrockbass_01_ms      = { label = 'Rock Bass',                output = 'cooked_fish', qty = 2 },
    a_c_fishchainpickerel_01_ms = { label = 'Chain Pickerel',           output = 'cooked_fish', qty = 2 },
    a_c_fishlargemouthbass_01_ms = { label = 'Largemouth Bass',         output = 'cooked_fish', qty = 2 },
    a_c_fishsmallmouthbass_01_ms = { label = 'Smallmouth Bass',         output = 'cooked_fish', qty = 2 },
    a_c_fishrainbowtrout_01_ms  = { label = 'Rainbow Trout',           output = 'cooked_fish', qty = 2 },
    a_c_fishsalmonsockeye_01_ms = { label = 'Sockeye Salmon',           output = 'cooked_fish', qty = 2 },
    a_c_fishsalmonsockeye_01_ml = { label = 'Sockeye Salmon (Med-Lg)',  output = 'cooked_fish', qty = 2 },

    -- Large fish → 3 cooked fish
    a_c_fishlargemouthbass_01_lg = { label = 'Large Largemouth Bass',   output = 'cooked_fish', qty = 3 },
    a_c_fishsmallmouthbass_01_lg = { label = 'Large Smallmouth Bass',   output = 'cooked_fish', qty = 3 },
    a_c_fishrainbowtrout_01_lg  = { label = 'Large Rainbow Trout',     output = 'cooked_fish', qty = 3 },
    a_c_fishsalmonsockeye_01_lg = { label = 'Large Sockeye Salmon',     output = 'cooked_fish', qty = 3 },
    a_c_fishlakesturgeon_01_lg  = { label = 'Lake Sturgeon',           output = 'cooked_fish', qty = 3 },
    a_c_fishlongnosegar_01_lg   = { label = 'Longnose Gar',            output = 'cooked_fish', qty = 3 },
    a_c_fishmuskie_01_lg        = { label = 'Muskie',                  output = 'cooked_fish', qty = 3 },
    a_c_fishnorthernpike_01_lg  = { label = 'Northern Pike',           output = 'cooked_fish', qty = 3 },
    a_c_fishsteelheadtrout      = { label = 'Steelhead Trout',         output = 'cooked_fish', qty = 3 },

    -- Extra large fish → 4 cooked fish
    a_c_fishchannelcatfish_01_lg = { label = 'Channel Catfish',         output = 'cooked_fish', qty = 4 },
    a_c_fishchannelcatfish_01_xl = { label = 'XL Channel Catfish',      output = 'cooked_fish', qty = 5 },

    -- ── Hunting meat ──
    venison    = { label = 'Raw Venison',    output = 'cooked_venison',   qty = 1 },
    bear_meat  = { label = 'Raw Bear Meat',  output = 'cooked_bear_meat', qty = 1 },
    bison_meat = { label = 'Raw Bison Meat', output = 'cooked_bison_meat',qty = 1 },
    game_meat  = { label = 'Raw Game Meat',  output = 'cooked_game_meat', qty = 1 },
    pork       = { label = 'Raw Pork',       output = 'cooked_pork',      qty = 1 },
    mutton     = { label = 'Raw Mutton',     output = 'cooked_mutton',    qty = 1 },
}
