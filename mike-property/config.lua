Config = {}

Config.MaxClaimsPerPlayer = 2

-- Claim sizes available for purchase
Config.ClaimTypes = {
    small  = { label = 'Small Plot',  radius = 15.0, price = 500,  deed = 'land_deed_small',  description = 'A small campsite' },
    medium = { label = 'Medium Plot', radius = 25.0, price = 1500, deed = 'land_deed_medium', description = 'A homestead plot' },
    large  = { label = 'Large Plot',  radius = 40.0, price = 3500, deed = 'land_deed_large',  description = 'A ranch-sized plot' },
}

-- Minimum distance between claims
Config.MinClaimDistance = 50.0

-- Minimum distance from town centers (prevent claiming in towns)
Config.TownCenters = {
    { name = 'Valentine',   coords = vector3(-280.0, 790.0, 119.0), radius = 200.0 },
    { name = 'Rhodes',      coords = vector3(1310.0, -1310.0, 77.0), radius = 150.0 },
    { name = 'Saint Denis', coords = vector3(2650.0, -1300.0, 46.0), radius = 400.0 },
    { name = 'Strawberry',  coords = vector3(-1768.0, -370.0, 160.0), radius = 120.0 },
    { name = 'Blackwater',  coords = vector3(-878.0, -1330.0, 43.0), radius = 200.0 },
    { name = 'Annesburg',   coords = vector3(2920.0, 1340.0, 44.0), radius = 120.0 },
    { name = 'Armadillo',   coords = vector3(-3660.0, -2610.0, -14.0), radius = 120.0 },
    { name = 'Van Horn',    coords = vector3(2990.0, 560.0, 44.0), radius = 100.0 },
    { name = 'Tumbleweed',  coords = vector3(-5500.0, -2940.0, -2.0), radius = 100.0 },
}

-- Placeable objects on your land
Config.Placeables = {
    tent = {
        label = 'Tent',
        prop  = 'p_ambcamp01x',
        item  = nil,  -- no item needed, just materials
        recipe = { oak_plank = 2, cloth = 3, rope = 2 },
        limit = 1,
    },
    campfire = {
        label = 'Campfire',
        prop  = 'p_campfire05x',
        item  = nil,
        recipe = { firewood = 5 },
        limit = 1,
    },
    storage = {
        label  = 'Storage Chest',
        prop   = 'p_chest_doctor01x',
        item   = nil,
        recipe = { oak_plank = 4, nails = 10, iron_bar = 1 },
        limit  = 2,
        stash  = true,  -- opens inventory stash
        stashSlots = 30,
        stashWeight = 500000,
    },
    hitching = {
        label = 'Hitching Post',
        prop  = 'p_fencepost03x',
        item  = nil,
        recipe = { oak_plank = 2, nails = 5, rope = 1 },
        limit = 2,
    },
    table_bench = {
        label = 'Table & Bench',
        prop  = 'p_table_tonkawa02x',
        item  = nil,
        recipe = { oak_plank = 4, nails = 8 },
        limit = 2,
    },
    drying_rack = {
        label = 'Drying Rack',
        prop  = 'p_ambpelt01x',
        item  = nil,
        recipe = { oak_plank = 2, nails = 4, rope = 2 },
        limit = 2,
    },
}

-- Land office locations
Config.LandOffices = {
    { name = 'Valentine Land Office', coords = vector3(-330.0, 780.0, 116.50) },
}
Config.LandOfficeRadius = 4.0
