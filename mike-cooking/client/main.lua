local RSGCore = exports['rsg-core']:GetCoreObject()
local placedCampfires = {} -- id -> { prop, zoneId }

-- ──────────────────────────────────────────────────────────────────────────
-- Register ox_target on all world campfire models
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    Wait(2000)

    local models = {}
    for _, model in ipairs(Config.CampfireModels) do
        models[#models + 1] = joaat(model)
    end

    exports.ox_target:addModel(models, {
        {
            name     = 'mike_cooking_campfire',
            label    = 'Cook',
            icon     = 'fa-solid fa-fire',
            onSelect = function() openCookMenu() end,
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
    if not loadModel(hash) then
        lib.notify({ type = 'error', description = 'Failed to place campfire' })
        return
    end

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
                onSelect = function() openCookMenu() end,
            },
            {
                name     = 'mike_cook_pack_' .. campId,
                label    = 'Pack up Campfire',
                icon     = 'fa-solid fa-box',
                onSelect = function()
                    packCampfire(campId)
                end,
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

    -- Give the item back
    TriggerServerEvent('mike-cooking:server:packCampfire')
    lib.notify({ type = 'success', description = 'Campfire packed up' })
end

-- ──────────────────────────────────────────────────────────────────────────
-- Cook menu: show what raw items the player has
-- ──────────────────────────────────────────────────────────────────────────
function openCookMenu()
    local pd = RSGCore.Functions.GetPlayerData()
    if not pd or not pd.items then return end

    -- Find raw items the player has that match recipes
    local opts = {}
    for _, invItem in pairs(pd.items) do
        if invItem and invItem.name then
            local recipe = Config.Recipes[invItem.name]
            if recipe then
                local outputInfo = RSGCore.Shared.Items[recipe.output]
                local outputLabel = outputInfo and outputInfo.label or recipe.output
                opts[#opts + 1] = {
                    title       = recipe.label,
                    description = ('Cook → %d× %s (You have: %d)'):format(recipe.qty, outputLabel, invItem.amount),
                    icon        = 'fa-solid fa-drumstick-bite',
                    onSelect    = function()
                        startCooking(invItem.name, recipe)
                    end,
                }
            end
        end
    end

    if #opts == 0 then
        return lib.notify({ type = 'inform', description = 'You have nothing to cook.' })
    end

    lib.registerContext({ id = 'mike_cooking_menu', title = 'Campfire Cooking', options = opts })
    lib.showContext('mike_cooking_menu')
end

-- ──────────────────────────────────────────────────────────────────────────
-- Cooking progress bar → server callback
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

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        for campId, data in pairs(placedCampfires) do
            if data.zoneId then exports.ox_target:removeZone(data.zoneId) end
            if data.prop and DoesEntityExist(data.prop) then
                SetEntityAsMissionEntity(data.prop, true, true)
                DeleteEntity(data.prop)
            end
        end
        placedCampfires = {}
    end
end)
