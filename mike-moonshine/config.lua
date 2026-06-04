Config = {}

-- Craft a portable still by reading the blueprint and having parts:
Config.CraftRecipe = {
    blueprint = 'still_blueprint',
    inputs    = { copper_pot = 1, copper_coil = 1, oak_barrel = 1, firewood = 2 },
    output    = 'portable_still',
    time      = 15 * 1000,
}

-- Ingredients per mash batch (one batch = one "charge" of the still):
Config.MashRecipe = {
    crop_corn = 5,
    sugar     = 3,
    water     = 2,
}

-- Optional premium add-on: using herbs OR berries bumps tier
Config.PremiumAddon = { crop_herbs = 2, crop_berries = 3 }

Config.MaxBatches       = 5    -- stack up to 5 mash batches before fermenting
Config.FermentTime      = 3 * 60   -- TODO: set back to 20 * 60 after testing
Config.DistillTime      = 2 * 60   -- TODO: set back to 15 * 60 after testing
Config.DistillFuel      = 3   -- firewood per distill
Config.BottlePerBatch   = 4   -- each mash batch yields 4 bottles
Config.BottleGlass      = 1   -- glass bottles consumed per moonshine bottle produced
Config.StillProp        = 'mp006_p_moonshiner_still02x'  -- RDR2 Online moonshiner still variant 2

-- Quality: basic / good / premium depending on score
Config.QualityThresholds = { good = 40, premium = 75 }

-- Law jobs that can destroy unowned stills
Config.LawJobs = { 'vallaw', 'rholaw', 'blklaw', 'strlaw', 'stdenlaw', 'lawman', 'sheriff' }

Config.InteractRadius = 3.0

-- ── SPEAKEASY SALES ─────────────────────────────────────────────────────────
-- The 5 real RDR Online speakeasies activated by redm-ipls. Each has an
-- "outside" entry door and an "inside" bar area. Sell zone is at the inside bar.
Config.Speakeasies = {
    {
        name    = 'Lemoyne Speakeasy',
        inside  = vector3(1785.01, -821.53, 191.01),
        outside = vector3(1784.90, -821.65, 42.86),
    },
    {
        name    = 'Cattail Pond Speakeasy',
        inside  = vector3(-1085.63, 714.14, 83.23),
        outside = vector3(-1085.63, 714.14, 103.32),
    },
    {
        name    = 'New Austin Speakeasy',
        inside  = vector3(-2769.30, -3048.87, -9.70),
        outside = vector3(-2769.23, -3048.90, 11.38),
    },
    {
        name    = 'Hanover Speakeasy',
        inside  = vector3(1627.64, 822.90, 123.94),
        outside = vector3(1627.64, 822.90, 144.03),
    },
    {
        name    = 'Manzanita Post Speakeasy',
        inside  = vector3(-1861.70, -1722.17, 88.35),
        outside = vector3(-1861.70, -1722.17, 108.35),
        bar     = vector3(-1864.84, -1728.07, 86.06),
        exit    = vector3(-1861.74, -1722.04, 89.25),
    },
}
Config.SpeakeasyPrices = {
    moonshine_basic   = 20,
    moonshine_good    = 40,
    moonshine_premium = 75,
}

-- ── STREET DEALS (/sellshine) ──────────────────────────────────────────────
-- Prices are per-bottle; higher than speakeasy but carries law risk
Config.StreetPrices = {
    moonshine_basic   = 30,
    moonshine_good    = 55,
    moonshine_premium = 110,
}
Config.Street = {
    sessionTime      = 120 * 1000,   -- 2 min total session
    spawnIntervalMin = 25 * 1000,    -- NPC appears every 25-45s
    spawnIntervalMax = 45 * 1000,
    maxNpcs          = 3,
    npcModels = {
        'a_m_m_bywworker_01','a_m_m_sdslumfolk_01','a_m_m_sdslumfolk_02',
        'a_m_m_valfarmer_01','a_m_y_sdslumfolk_01','a_m_m_rhdforeman_01',
    },
    approachDistance = 22.0,   -- NPC spawns this far from player (out of sight ideally)
    buyDistance      = 2.5,    -- must be within this to finalize sale
    bustRadius       = 15.0,   -- law within this distance = bust
    npcBuyMin        = 1,      -- NPC buys this many bottles at minimum...
    npcBuyMax        = 3,      -- ...up to this many (capped to player's stock)
    lawBlipFuzz      = 30.0,   -- coord fuzz on law alert (meters)
    lawBlipSeconds   = 60,     -- how long blip lasts
}

-- Town zones where /sellshine is allowed (x, y, radius)
Config.TownZones = {
    { name = 'Valentine',   x = -265.0,  y = 798.0,   r = 200.0 },
    { name = 'Strawberry',  x = -1807.0, y = -363.0,  r = 150.0 },
    { name = 'Rhodes',      x = 1359.0,  y = -1305.0, r = 180.0 },
    { name = 'Saint Denis', x = 2720.0,  y = -1400.0, r = 350.0 },
    { name = 'Blackwater',  x = -813.0,  y = -1328.0, r = 200.0 },
    { name = 'Armadillo',   x = -3702.0, y = -2602.0, r = 180.0 },
    { name = 'Annesburg',   x = 2935.0,  y = 1300.0,  r = 160.0 },
    { name = 'Van Horn',    x = 2976.0,  y = 551.0,   r = 150.0 },
}

