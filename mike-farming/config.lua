Config = {}

-- Growth: in seconds. Total time to maturity = growthTime.
-- Water must be applied every waterInterval or crop withers after waterGrace.
-- Props: seedling = early stage, growing = mid, mature = ready to harvest
Config.CropTypes = {
    corn      = { seed = 'seed_corn',      harvest = 'crop_corn',      growthTime = 3 * 60, waterInterval = 2 * 60, waterGrace = 5 * 60, yieldMin = 3, yieldMax = 6,
                  propSeedling = 'crp_seedling_aa_sim', propGrowing = 'crp_cornstalks_ab_sim', propMature = 'crp_cornstalks_aa_sim' },
    wheat     = { seed = 'seed_wheat',     harvest = 'crop_wheat',     growthTime = 3 * 60, waterInterval = 2 * 60, waterGrace = 5 * 60, yieldMin = 3, yieldMax = 5,
                  propSeedling = 'crp_seedling_aa_sim', propGrowing = 'crp_wheat_sap_ac', propMature = 'crp_wheat_dry_aa_sim' },
    tobacco   = { seed = 'seed_tobacco',   harvest = 'crop_tobacco',   growthTime = 3 * 60, waterInterval = 2 * 60, waterGrace = 5 * 60, yieldMin = 2, yieldMax = 4,
                  propSeedling = 'crp_seedling_aa_sim', propGrowing = 'crp_tobaccoplant_ab_sim', propMature = 'crp_tobaccoplant_aa_sim' },
    sugarcane = { seed = 'seed_sugarcane', harvest = 'crop_sugarcane', growthTime = 3 * 60, waterInterval = 2 * 60, waterGrace = 5 * 60, yieldMin = 2, yieldMax = 5,
                  propSeedling = 'crp_seedling_aa_sim', propGrowing = 'crp_sugarcane_ab_sim', propMature = 'crp_sugarcane_aa_sim' },
    herbs     = { seed = 'seed_herbs',     harvest = 'crop_herbs',     growthTime = 3 * 60, waterInterval = 2 * 60, waterGrace = 5 * 60, yieldMin = 2, yieldMax = 4,
                  propSeedling = 'crp_seedling_aa_sim', propGrowing = 's_inv_oregano01x', propMature = 's_inv_oregano01x' },
    berries   = { seed = 'seed_berries',   harvest = 'crop_berries',   growthTime = 3 * 60, waterInterval = 2 * 60, waterGrace = 5 * 60, yieldMin = 3, yieldMax = 6,
                  propSeedling = 'crp_berry_sap_aa_sim', propGrowing = 'crp_berry_sap_aa_sim', propMature = 'crp_berry_aa_sim' },
    cotton    = { seed = 'seed_cotton',   harvest = 'crop_cotton',    growthTime = 3 * 60, waterInterval = 2 * 60, waterGrace = 5 * 60, yieldMin = 3, yieldMax = 6,
                  propSeedling = 'crp_seedling_aa_sim', propGrowing = 'crp_cotton_ba_sim', propMature = 'crp_cotton_ad_sim' },
}

Config.ShowFloatingText  = true
Config.FloatingTextRange = 15.0

Config.FertilizerBonus   = 0.5
Config.MaxCropsPerPlayer = 20
Config.PropRadius        = 150

Config.TillTime    = 3000
Config.PlantTime   = 4000
Config.WaterTime   = 3000
Config.HarvestTime = 3500

-- Ghost placement
Config.PlacementRange    = 5.0   -- how far in front you can place
Config.PlacementProp     = 'crp_seedling_aa_sim'  -- ghost preview prop

-- Simple crop processing: use raw crop from inventory to convert
Config.Processing = {
    crop_sugarcane = { output = 'sugar', inputPerOutput = 2, time = 4000, label = 'Pressing sugarcane' },
}
