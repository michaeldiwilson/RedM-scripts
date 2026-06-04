local HORSE_MODELS = {
    { label = 'American Standardbred (Black)',      model = 'a_c_horse_americanstandard_black' },
    { label = 'Appaloosa (Black Snowflake)',        model = 'a_c_horse_appaloosa_blacksnowflake' },
    { label = 'Arabian (White)',                    model = 'a_c_horse_arabian_white' },
    { label = 'Arabian (Black)',                    model = 'a_c_horse_arabian_black' },
    { label = 'Arabian (Rose Grey Bay)',            model = 'a_c_horse_arabian_rosegreybay' },
    { label = 'Breton (Sorrel)',                    model = 'a_c_horse_breton_sorrel' },
    { label = 'Dutch Warmblood (Chocolate Roan)',   model = 'a_c_horse_dutchwarmblood_chocolateroan' },
    { label = 'Hungarian Halfbred (Dark Dapple)',   model = 'a_c_horse_hungarianhalfbred_darkdapplegrey' },
    { label = 'Kentucky Saddler (Black)',           model = 'a_c_horse_kentuckysaddler_black' },
    { label = 'Missouri Fox Trotter (Amber Champ)', model = 'a_c_horse_missourifoxtrotter_amberchampagne' },
    { label = 'Morgan (Bay Roan)',                  model = 'a_c_horse_morgan_bayroan' },
    { label = 'Mustang (Golden Dun)',               model = 'a_c_horse_mustang_goldendun' },
    { label = 'Nokota (Blue Roan)',                 model = 'a_c_horse_nokota_blueroan' },
    { label = 'Shire (Dark Bay)',                   model = 'a_c_horse_shire_darkbay' },
    { label = 'Tennessee Walker (Red Roan)',        model = 'a_c_horse_tennesseewalker_redroan' },
    { label = 'Turkoman (Dark Bay)',                model = 'a_c_horse_turkoman_darkbay' },
}

local WAGON_MODELS = {
    { label = 'Wooden Cart 1', model = 'CART01' },
    { label = 'Wooden Cart 2', model = 'CART02' },
    { label = 'Wooden Cart 3', model = 'CART03' },
    { label = 'Wagon 1',       model = 'WAGON01X' },
    { label = 'Wagon 2',       model = 'WAGON02X' },
    { label = 'Wagon 3',       model = 'WAGON03X' },
    { label = 'Stagecoach',    model = 'COACH2' },
    { label = 'Buggy',         model = 'BUGGY01' },
    { label = 'Oil Wagon',     model = 'OILWAGON01X' },
    { label = 'Prison Wagon',  model = 'WAGONPRISON01X' },
}

local function loadModel(hash)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 5000 do Wait(10) end
    return HasModelLoaded(hash)
end

local function spawnHorse(model)
    local hash = GetHashKey(model)
    if not loadModel(hash) then
        lib.notify({ type = 'error', description = 'Failed to load model: ' .. model })
        return
    end
    local ped = PlayerPedId()
    local c   = GetOffsetFromEntityInWorldCoords(ped, 1.5, 1.5, 0.0)
    local horse = CreatePed(hash, c.x, c.y, c.z, GetEntityHeading(ped), true, false, false, false)
    Citizen.InvokeNative(0x283978A15512B2FE, horse, true) -- SetRandomOutfitVariation
    SetModelAsNoLongerNeeded(hash)
    lib.notify({ type = 'success', description = 'Spawned horse: ' .. model })
end

local function spawnVehicle(model)
    local hash = GetHashKey(model)
    if not loadModel(hash) then
        lib.notify({ type = 'error', description = 'Failed to load model: ' .. model })
        return
    end
    local ped = PlayerPedId()
    local c   = GetOffsetFromEntityInWorldCoords(ped, 0.0, 4.0, 0.0)
    local veh = CreateVehicle(hash, c.x, c.y, c.z, GetEntityHeading(ped), true, false)
    SetModelAsNoLongerNeeded(hash)
    lib.notify({ type = 'success', description = 'Spawned: ' .. model })
end

function OpenSpawnerMenu()
    lib.registerContext({
        id = 'mike_admin_spawner',
        title = 'Spawner',
        menu = 'mike_admin_root',
        options = {
            { title = 'Horses',       description = 'Pick a preset horse',  icon = 'horse',     onSelect = function() SpawnerListMenu('horse', HORSE_MODELS) end },
            { title = 'Wagons & Carts', description = 'Pick a preset wagon', icon = 'truck',     onSelect = function() SpawnerListMenu('vehicle', WAGON_MODELS) end },
            { title = 'Custom horse (by model)',    icon = 'keyboard', onSelect = function() CustomSpawn('horse') end },
            { title = 'Custom wagon (by model)',    icon = 'keyboard', onSelect = function() CustomSpawn('vehicle') end },
        },
    })
    lib.showContext('mike_admin_spawner')
end

function SpawnerListMenu(kind, list)
    local opts = {}
    for _, m in ipairs(list) do
        opts[#opts + 1] = {
            title       = m.label,
            description = m.model,
            onSelect    = function() if kind == 'horse' then spawnHorse(m.model) else spawnVehicle(m.model) end end,
        }
    end
    lib.registerContext({ id = 'mike_admin_spawner_list', title = kind == 'horse' and 'Horses' or 'Wagons', menu = 'mike_admin_spawner', options = opts })
    lib.showContext('mike_admin_spawner_list')
end

function CustomSpawn(kind)
    local r = lib.inputDialog('Spawn by Model', { { type = 'input', label = 'Model name', required = true } })
    if not r then return end
    if kind == 'horse' then spawnHorse(r[1]) else spawnVehicle(r[1]) end
end
