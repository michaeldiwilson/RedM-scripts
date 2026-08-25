local RSGCore = exports['rsg-core']:GetCoreObject()
local placedCampfires = {}
local placedDryingRacks = {}

-- ──────────────────────────────────────────────────────────────────────────
-- Register ox_target on world cooking stations
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    Wait(2000)

    -- Campfire models (tier 1)
    local campfireHashes = {}
    for _, model in ipairs(Config.CampfireModels) do
        campfireHashes[#campfireHashes + 1] = joaat(model)
    end
    exports.ox_target:addModel(campfireHashes, {
        {
            name     = 'mike_cook_campfire',
            label    = 'Cook (Campfire)',
            icon     = 'fa-solid fa-fire',
            onSelect = function() openCookMenu('campfire') end,
        },
    })

    -- Cooking pot models (tier 2)
    local potHashes = {}
    for _, model in ipairs(Config.CookingPotModels) do
        potHashes[#potHashes + 1] = joaat(model)
    end
    exports.ox_target:addModel(potHashes, {
        {
            name     = 'mike_cook_pot',
            label    = 'Cook (Cooking Pot)',
            icon     = 'fa-solid fa-fire',
            onSelect = function() openCookMenu('campfire_pot') end,
        },
    })

    -- Stove models (tier 3)
    local stoveHashes = {}
    for _, model in ipairs(Config.StoveModels) do
        stoveHashes[#stoveHashes + 1] = joaat(model)
    end
    exports.ox_target:addModel(stoveHashes, {
        {
            name     = 'mike_cook_stove',
            label    = 'Cook (Stove)',
            icon     = 'fa-solid fa-fire-burner',
            onSelect = function() openCookMenu('stove') end,
        },
    })
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Place portable campfire from inventory
-- ──────────────────────────────────────────────────────────────────────────
local function loadModel(hash)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 5000 do Wait(10) end
    return HasModelLoaded(hash)
end

RegisterNetEvent('mike-cooking:client:placeCampfire', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local fwd = GetEntityForwardVector(ped)
    local placeCoords = coords + fwd * 1.5

    local hash = GetHashKey('p_campfire05x')
    if not loadModel(hash) then return end

    local prop = CreateObject(hash, placeCoords.x, placeCoords.y, placeCoords.z, false, false, false, true, true)
    PlaceObjectOnGroundProperly(prop)
    FreezeEntityPosition(prop, true)
    SetEntityAsMissionEntity(prop, true, true)
    SetModelAsNoLongerNeeded(hash)

    local campId = GetGameTimer()

    local zid = exports.ox_target:addSphereZone({
        coords = vector3(placeCoords.x, placeCoords.y, placeCoords.z),
        radius = 2.5,
        debug  = false,
        options = {
            {
                name     = 'mike_cook_use_' .. campId,
                label    = 'Cook',
                icon     = 'fa-solid fa-fire',
                onSelect = function() openCookMenu('campfire') end,
            },
            {
                name     = 'mike_cook_pack_' .. campId,
                label    = 'Pack up Campfire',
                icon     = 'fa-solid fa-box',
                onSelect = function() packCampfire(campId) end,
            },
        },
    })

    placedCampfires[campId] = { prop = prop, zoneId = zid }
    lib.notify({ type = 'success', description = 'Campfire placed' })
end)

function packCampfire(campId)
    local data = placedCampfires[campId]
    if not data then return end
    if data.zoneId then exports.ox_target:removeZone(data.zoneId) end
    if data.prop and DoesEntityExist(data.prop) then
        SetEntityAsMissionEntity(data.prop, true, true)
        DeleteEntity(data.prop)
    end
    placedCampfires[campId] = nil
    TriggerServerEvent('mike-cooking:server:packCampfire')
    lib.notify({ type = 'success', description = 'Campfire packed up' })
end

-- ──────────────────────────────────────────────────────────────────────────
-- Tiered cook menu: shows recipes up to the station's tier
-- ──────────────────────────────────────────────────────────────────────────
function openCookMenu(stationType)
    local stationTier = Config.StationTier[stationType] or 1
    local pd = RSGCore.Functions.GetPlayerData()
    if not pd or not pd.items then return end

    local opts = {}
    for rawItem, recipe in pairs(Config.Recipes) do
        local recipeTier = recipe.tier or 1
        if recipeTier > stationTier then goto nextRecipe end

        -- Check if player has the raw item (or inputs for multi-ingredient recipes)
        local canCook = true
        local description = ''

        if recipe.inputs then
            -- Multi-ingredient recipe
            local parts = {}
            for item, needed in pairs(recipe.inputs) do
                local have = 0
                for _, invItem in pairs(pd.items) do
                    if invItem and invItem.name == item then
                        have = have + (invItem.amount or 0)
                    end
                end
                if have < needed then canCook = false end
                parts[#parts + 1] = ('%d/%d %s'):format(have, needed, item:gsub('_', ' '))
            end
            description = table.concat(parts, ', ')
        else
            -- Simple recipe: 1 raw item → cooked
            local have = 0
            for _, invItem in pairs(pd.items) do
                if invItem and invItem.name == rawItem then
                    have = have + (invItem.amount or 0)
                end
            end
            if have < 1 then canCook = false end
            description = ('You have: %d'):format(have)
        end

        local outputInfo = RSGCore.Shared.Items[recipe.output]
        local outputLabel = outputInfo and outputInfo.label or recipe.output
        local outputQty = recipe.qty > 1 and (' x' .. recipe.qty) or ''
        local tierLabel = recipeTier == 1 and '' or (recipeTier == 2 and ' [Pot]' or ' [Stove]')

        opts[#opts + 1] = {
            title       = recipe.label .. outputQty .. tierLabel,
            description = description .. ' → ' .. outputLabel,
            icon        = canCook and 'fa-solid fa-drumstick-bite' or 'fa-solid fa-lock',
            disabled    = not canCook,
            onSelect    = function()
                startCooking(rawItem, recipe)
            end,
        }

        ::nextRecipe::
    end

    if #opts == 0 then
        return lib.notify({ type = 'inform', description = 'You have nothing to cook here.' })
    end

    local titles = { campfire = 'Campfire Cooking', campfire_pot = 'Cooking Pot', stove = 'Stove Cooking' }
    lib.registerContext({ id = 'mike_cooking_menu', title = titles[stationType] or 'Cooking', options = opts })
    lib.showContext('mike_cooking_menu')
end

-- ──────────────────────────────────────────────────────────────────────────
-- Cooking: handles both simple (1 item) and multi-ingredient recipes
-- ──────────────────────────────────────────────────────────────────────────
function startCooking(rawItem, recipe)
    if not lib.progressBar({
        duration     = Config.CookTime,
        label        = 'Cooking ' .. recipe.label .. '...',
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
    }) then
        lib.notify({ type = 'error', description = 'Cooking cancelled' })
        return
    end

    local ok = lib.callback.await('mike-cooking:server:cook', false, rawItem)
    if ok then
        lib.notify({ type = 'success', description = ('Cooked %d× %s'):format(recipe.qty, recipe.output) })
    end
end

-- ──────────────────────────────────────────────────────────────────────────
-- Drying Rack: placeable, timer-based jerky production
-- ──────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mike-cooking:client:placeDryingRack', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local fwd = GetEntityForwardVector(ped)
    local placeCoords = coords + fwd * 1.5

    local hash = GetHashKey(Config.DryingRackProp)
    if not loadModel(hash) then return end

    local prop = CreateObject(hash, placeCoords.x, placeCoords.y, placeCoords.z, false, false, false, true, true)
    PlaceObjectOnGroundProperly(prop)
    FreezeEntityPosition(prop, true)
    SetEntityAsMissionEntity(prop, true, true)
    SetModelAsNoLongerNeeded(hash)

    local rackId = GetGameTimer()
    local propCoords = GetEntityCoords(prop)

    local zid = exports.ox_target:addSphereZone({
        coords = vector3(propCoords.x, propCoords.y, propCoords.z),
        radius = 2.5,
        debug  = false,
        options = {
            {
                name     = 'mike_dry_use_' .. rackId,
                label    = 'Drying Rack',
                icon     = 'fa-solid fa-bacon',
                onSelect = function() openDryingMenu(rackId) end,
            },
            {
                name     = 'mike_dry_pack_' .. rackId,
                label    = 'Pack up Rack',
                icon     = 'fa-solid fa-box',
                onSelect = function()
                    local data = placedDryingRacks[rackId]
                    if not data then return end
                    if data.zoneId then exports.ox_target:removeZone(data.zoneId) end
                    if data.prop and DoesEntityExist(data.prop) then
                        SetEntityAsMissionEntity(data.prop, true, true)
                        DeleteEntity(data.prop)
                    end
                    placedDryingRacks[rackId] = nil
                    TriggerServerEvent('mike-cooking:server:packDryingRack')
                    lib.notify({ type = 'success', description = 'Drying rack packed up' })
                end,
            },
        },
    })

    placedDryingRacks[rackId] = { prop = prop, zoneId = zid }
    lib.notify({ type = 'success', description = 'Drying rack placed' })
end)

function openDryingMenu(rackId)
    local opts = {}
    local pd = RSGCore.Functions.GetPlayerData()
    if not pd or not pd.items then return end

    for key, recipe in pairs(Config.DryingRecipes) do
        local have = 0
        for _, invItem in pairs(pd.items) do
            if invItem and invItem.name == recipe.input then
                have = have + (invItem.amount or 0)
            end
        end
        local canDry = have >= 1

        opts[#opts + 1] = {
            title       = recipe.label .. ' x' .. recipe.qty,
            description = ('1x %s → %dx jerky (You have: %d)'):format(recipe.input:gsub('_', ' '), recipe.qty, have),
            icon        = canDry and 'fa-solid fa-bacon' or 'fa-solid fa-lock',
            disabled    = not canDry,
            onSelect    = function()
                if lib.progressBar({
                    duration = 5000,
                    label = 'Hanging meat to dry...',
                    useWhileDead = false, canCancel = true,
                    disable = { move = true, car = true, combat = true },
                }) then
                    local ok = lib.callback.await('mike-cooking:server:dryMeat', false, key)
                    if ok then
                        lib.notify({ type = 'success', description = ('Drying %s — come back in %d min'):format(recipe.label, math.ceil(Config.DryingTime / 60)) })
                    end
                end
            end,
        }
    end

    -- Check for ready jerky
    opts[#opts + 1] = {
        title    = 'Collect Dried Jerky',
        icon     = 'fa-solid fa-hand-holding',
        onSelect = function()
            lib.callback.await('mike-cooking:server:collectJerky', false)
        end,
    }

    lib.registerContext({ id = 'mike_drying_rack', title = 'Drying Rack', options = opts })
    lib.showContext('mike_drying_rack')
end

-- Cleanup
AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        for _, data in pairs(placedCampfires) do
            if data.zoneId then exports.ox_target:removeZone(data.zoneId) end
            if data.prop and DoesEntityExist(data.prop) then
                SetEntityAsMissionEntity(data.prop, true, true)
                DeleteEntity(data.prop)
            end
        end
        for _, data in pairs(placedDryingRacks) do
            if data.zoneId then exports.ox_target:removeZone(data.zoneId) end
            if data.prop and DoesEntityExist(data.prop) then
                SetEntityAsMissionEntity(data.prop, true, true)
                DeleteEntity(data.prop)
            end
        end
        placedCampfires = {}
        placedDryingRacks = {}
    end
end)
