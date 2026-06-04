Config = {}

Config.WagonTypes = {
    work = {
        label = 'Work Wagon',
        model = 'WAGON02X',
        kit   = 'wagon_kit_work',
        slots = 10,
        maxweight = 500000,
    },
    covered = {
        label = 'Covered Wagon',
        model = 'WAGON03X',
        kit   = 'wagon_kit_covered',
        slots = 20,
        maxweight = 1000000,
    },
    hunting = {
        label = 'Hunting Wagon',
        model = 'CART02',
        kit   = 'wagon_kit_hunting',
        slots = 15,
        maxweight = 750000,
    },
}

Config.Yards = {
    { name = 'Valentine Wagon Yard',   coords = vector3(-365.00, 780.00, 116.20), spawn = vector4(-368.00, 775.00, 116.20, 270.0) },
    { name = 'Rhodes Wagon Yard',      coords = vector3(1340.00, -1300.00, 77.50), spawn = vector4(1345.00, -1295.00, 77.50, 90.0) },
    { name = 'Strawberry Wagon Yard',  coords = vector3(-1790.00, -370.00, 161.00), spawn = vector4(-1795.00, -365.00, 161.00, 180.0) },
    { name = 'Saint Denis Wagon Yard', coords = vector3(2750.00, -1280.00, 47.00), spawn = vector4(2755.00, -1275.00, 47.00, 0.0) },
}

Config.YardRadius = 8.0
