Config = {}

-- Prop used for the placed bench
Config.BenchProp = 'p_workbench01x'

-- Building the bench (triggered by using craftbench_blueprint item)
Config.BenchRecipe = {
    inputs = { craftbench_blueprint = 1, oak_plank = 4, nails = 10 },
    output = 'portable_craftbench',
    time   = 10000,
}

-- Recipes available at the placed bench
-- blueprint = 'item_name' means recipe is hidden unless player has that item
Config.Recipes = {
    copper_pot = {
        label  = 'Copper Pot',
        inputs = { copper_bar = 5, firewood = 2 },
        output = 'copper_pot',
        qty    = 1,
        time   = 3000,   -- TODO: set back to 30000 after testing
    },
    copper_coil = {
        label  = 'Copper Coil',
        inputs = { copper_bar = 3 },
        output = 'copper_coil',
        qty    = 1,
        time   = 3000,   -- TODO: set back to 20000 after testing
    },
    oak_barrel = {
        label  = 'Oak Barrel',
        inputs = { oak_plank = 4, nails = 10 },
        output = 'oak_barrel',
        qty    = 1,
        time   = 3000,   -- TODO: set back to 30000 after testing
    },
    portable_still = {
        label     = 'Portable Still',
        blueprint = 'still_blueprint',
        inputs    = { copper_pot = 1, copper_coil = 1, oak_barrel = 1 },
        output    = 'portable_still',
        qty       = 1,
        time      = 5000,   -- TODO: set back to 60000 after testing
    },
    lockpick = {
        label     = 'Lockpick',
        blueprint = 'lockpick_blueprint',
        inputs    = { iron_bar = 1, nails = 5 },
        output    = 'lockpick',
        qty       = 3,
        time      = 3000,   -- TODO: set back to 15000 after testing
    },
    -- ── No blueprint needed ──
    tanning_rack = {
        label  = 'Tanning Rack',
        inputs = { oak_plank = 3, nails = 5, rope = 2 },
        output = 'tanning_rack',
        qty    = 1,
        time   = 3000,  -- TODO: set back to 20000 after testing
    },
    -- Rope
    rope = {
        label  = 'Rope',
        inputs = { crop_cotton = 3 },
        output = 'rope',
        qty    = 1,
        time   = 3000,   -- TODO: set back to 8000 after testing
    },
    -- Cloth
    cloth = {
        label  = 'Cloth',
        inputs = { crop_cotton = 3 },
        output = 'cloth',
        qty    = 1,
        time   = 3000,   -- TODO: set back to 10000 after testing
    },
    -- ── Wagon components (no blueprint needed) ──
    wagon_wheel = {
        label  = 'Wagon Wheel',
        inputs = { oak_plank = 2, nails = 5, iron_bar = 1 },
        output = 'wagon_wheel',
        qty    = 1,
        time   = 3000,   -- TODO: set back to 15000 after testing
    },
    wagon_axle = {
        label  = 'Wagon Axle',
        inputs = { oak_plank = 2, nails = 3, iron_bar = 1 },
        output = 'wagon_axle',
        qty    = 1,
        time   = 3000,   -- TODO: set back to 12000 after testing
    },
    wagon_frame = {
        label  = 'Wagon Frame',
        inputs = { oak_plank = 4, nails = 10, iron_bar = 2 },
        output = 'wagon_frame',
        qty    = 1,
        time   = 5000,   -- TODO: set back to 25000 after testing
    },
    wagon_seat = {
        label  = 'Wagon Seat',
        inputs = { oak_plank = 2, cloth = 1 },
        output = 'wagon_seat',
        qty    = 1,
        time   = 3000,   -- TODO: set back to 10000 after testing
    },
    -- ── Wagon assembly (blueprint-gated, uses components) ──
    wagon_kit_work = {
        label     = 'Assemble Work Wagon',
        blueprint = 'wagon_blueprint',
        inputs    = { wagon_wheel = 4, wagon_axle = 2, wagon_frame = 1, wagon_seat = 1 },
        output    = 'wagon_kit_work',
        qty       = 1,
        time      = 5000,   -- TODO: set back to 45000 after testing
    },
    wagon_kit_covered = {
        label     = 'Assemble Covered Wagon',
        blueprint = 'wagon_blueprint',
        inputs    = { wagon_wheel = 4, wagon_axle = 2, wagon_frame = 1, wagon_seat = 1, cloth = 4, leather = 2 },
        output    = 'wagon_kit_covered',
        qty       = 1,
        time      = 5000,   -- TODO: set back to 60000 after testing
    },
    wagon_kit_hunting = {
        label     = 'Assemble Hunting Wagon',
        blueprint = 'wagon_blueprint',
        inputs    = { wagon_wheel = 4, wagon_axle = 2, wagon_frame = 1, wagon_seat = 1, leather = 6 },
        output    = 'wagon_kit_hunting',
        qty       = 1,
        time      = 5000,   -- TODO: set back to 50000 after testing
    },
}
