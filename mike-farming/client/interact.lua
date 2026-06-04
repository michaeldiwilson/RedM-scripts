local placingCrop  = nil   -- crop type key when in placement mode
local ghostProp    = nil   -- preview entity
local placementPos = nil   -- confirmed position

-- ──────────────────────────────────────────────────────────────────────────
-- Ghost placement: raycast to ground in front of player
-- ──────────────────────────────────────────────────────────────────────────
local function getGroundAhead()
    local ped = PlayerPedId()
    local p = GetEntityCoords(ped)
    local fwd = GetEntityForwardVector(ped)
    local ahead = vector3(p.x + fwd.x * 2.5, p.y + fwd.y * 2.5, p.z + 2.0)
    local below = vector3(ahead.x, ahead.y, ahead.z - 5.0)
    local ray = StartShapeTestRay(ahead.x, ahead.y, ahead.z, below.x, below.y, below.z, 1, ped, 0)
    local _, hit, hitPos = GetShapeTestResult(ray)
    if hit == 1 and hitPos then
        return hitPos
    end
    -- Fallback
    local _, groundZ = GetGroundZFor_3dCoord(ahead.x, ahead.y, ahead.z, false)
    return vector3(ahead.x, ahead.y, groundZ > 0 and groundZ or p.z)
end

local function startGhostPlacement(cropType)
    placingCrop = cropType
    local def = Config.CropTypes[cropType]
    local propName = def and def.propSeedling or Config.PlacementProp
    local hash = GetHashKey(propName)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 3000 do Wait(10) end
    if not HasModelLoaded(hash) then
        placingCrop = nil
        return
    end

    local pos = getGroundAhead()
    ghostProp = CreateObject(hash, pos.x, pos.y, pos.z, false, false, false, true, true)
    SetEntityAlpha(ghostProp, 150, false)
    SetEntityCollision(ghostProp, false, false)
    FreezeEntityPosition(ghostProp, true)
    SetModelAsNoLongerNeeded(hash)

    lib.notify({ type = 'inform', description = 'Move to position your crop. Press ENTER to confirm, BACKSPACE to cancel.', duration = 6000 })
end

local function cleanupGhost()
    if ghostProp and DoesEntityExist(ghostProp) then
        SetEntityAsMissionEntity(ghostProp, true, true)
        DeleteEntity(ghostProp)
    end
    ghostProp = nil
    placingCrop = nil
end

-- Ghost follows player aim while placing
CreateThread(function()
    local ENTER_KEY = 0xC7B5340A      -- ENTER
    local BACKSPACE_KEY = 0x156F7119  -- BACKSPACE

    while true do
        Wait(0)
        if placingCrop and ghostProp and DoesEntityExist(ghostProp) then
            local pos = getGroundAhead()
            SetEntityCoords(ghostProp, pos.x, pos.y, pos.z, false, false, false, false)
            PlaceObjectOnGroundProperly(ghostProp)

            if IsControlJustReleased(0, ENTER_KEY) then
                placementPos = GetEntityCoords(ghostProp)
                local cropType = placingCrop
                cleanupGhost()

                -- Till + plant at confirmed position
                if lib.progressBar({ duration = Config.TillTime, label = 'Tilling soil...', useWhileDead = false, canCancel = true,
                    disable = { move = true, car = true, combat = true } }) then
                    if lib.progressBar({ duration = Config.PlantTime, label = 'Planting ' .. cropType .. '...', useWhileDead = false, canCancel = true,
                        disable = { move = true, car = true, combat = true } }) then
                        TriggerServerEvent('mike-farming:server:plant', cropType, { x = placementPos.x, y = placementPos.y, z = placementPos.z })
                    end
                end
                placementPos = nil
            end

            if IsControlJustReleased(0, BACKSPACE_KEY) then
                cleanupGhost()
                lib.notify({ type = 'error', description = 'Placement cancelled' })
            end
        end
    end
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Hoe: now goes straight into placement mode when a seed is used
-- (hoe is still required in inventory — server checks)
-- ──────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mike-farming:client:startTill', function()
    -- Old flow: just till at feet. Now we notify to use a seed instead.
    lib.notify({ type = 'inform', description = 'Use a seed from your inventory to start planting.' })
end)

RegisterNetEvent('mike-farming:client:startPlant', function(cropType)
    if placingCrop then
        return lib.notify({ type = 'error', description = 'Already placing a crop' })
    end
    startGhostPlacement(cropType)
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Processing, watering, harvesting (unchanged)
-- ──────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mike-farming:client:startProcess', function(input)
    local recipe = Config.Processing and Config.Processing[input]
    if not recipe then return end
    local r = lib.inputDialog(recipe.label or 'Process', {
        { type = 'number', label = 'Amount to process', min = recipe.inputPerOutput, default = recipe.inputPerOutput, required = true },
    })
    if not r then return end
    if lib.progressBar({ duration = recipe.time, label = recipe.label or 'Processing...', useWhileDead = false, canCancel = true,
        disable = { move = true, car = true, combat = true } }) then
        TriggerServerEvent('mike-farming:server:process', input, r[1])
    end
end)

RegisterNetEvent('mike-farming:client:tryWater', function()
    local c = NearestCrop(2.0)
    if not c then lib.notify({ type = 'error', description = 'No crop nearby' }); return end
    if lib.progressBar({ duration = Config.WaterTime, label = 'Watering...', useWhileDead = false, canCancel = true,
        disable = { move = true, car = true } }) then
        TriggerServerEvent('mike-farming:server:water', c.id)
    end
end)

function DoHarvest(cropId)
    local c = Crops[cropId]; if not c then return end
    local stage = GetCropStage(c)
    if lib.progressBar({ duration = Config.HarvestTime, label = stage == 'withered' and 'Clearing dead crop...' or 'Harvesting...', useWhileDead = false, canCancel = true,
        disable = { move = true, car = true } }) then
        TriggerServerEvent('mike-farming:server:harvest', cropId)
    end
end

function DoWater(cropId)
    if lib.progressBar({ duration = Config.WaterTime, label = 'Watering...', useWhileDead = false, canCancel = true,
        disable = { move = true, car = true } }) then
        TriggerServerEvent('mike-farming:server:water', cropId)
    end
end

function ShowCropInfo(cropId)
    local c = Crops[cropId] or Crops[tonumber(cropId)]
    if not c then
        lib.notify({ type = 'error', description = 'Crop not found' })
        return
    end
    local stage, pct = GetCropStage(c)
    local def = Config.CropTypes[c.crop_type] or {}
    local lastWatered = tonumber(c.last_watered) or GetCloudTimeAsInt()
    local waterGrace  = tonumber(def.waterGrace) or 0
    local waterDue    = math.max(waterGrace - (GetCloudTimeAsInt() - lastWatered), 0)
    local fertilized  = (tonumber(c.fertilized) == 1)

    lib.alertDialog({
        header  = 'Crop: ' .. (c.crop_type or '?'),
        content = ('**Stage:** %s (%.0f%%)\n**Water due:** %ds\n**Fertilized:** %s')
                  :format(stage or '?', (pct or 0) * 100, waterDue, fertilized and 'Yes' or 'No'),
        centered = true,
    })
end
