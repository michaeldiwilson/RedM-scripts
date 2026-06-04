RSGCore = exports['rsg-core']:GetCoreObject()

Crops     = {}
CropProps = {}
CropBlips = {}
CropStages = {}  -- id -> last known stage (to detect changes)

local function loadModel(hash)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 3000 do Wait(10) end
    return HasModelLoaded(hash)
end

local function cropStage(c)
    local def = Config.CropTypes[c.crop_type]
    if not def then return 'unknown', 0 end
    if c.withered == 1 then return 'withered', 0 end
    local growthTime = def.growthTime * (c.fertilized == 1 and (1 - Config.FertilizerBonus) or 1)
    local elapsed = GetCloudTimeAsInt() - c.planted_at
    local pct = math.min(elapsed / growthTime, 1.0)
    if pct >= 1.0 then return 'mature', pct end
    if pct >= 0.5 then return 'growing', pct end
    return 'seedling', pct
end

function GetCropStage(c) return cropStage(c) end

-- Get the right prop for current growth stage
local function getPropForStage(cropType, stage)
    local def = Config.CropTypes[cropType]
    if not def then return 'crp_seedling_aa_sim' end
    if stage == 'mature' then return def.propMature or def.propGrowing or 'crp_seedling_aa_sim' end
    if stage == 'growing' then return def.propGrowing or def.propSeedling or 'crp_seedling_aa_sim' end
    return def.propSeedling or 'crp_seedling_aa_sim'
end

local function registerTarget(obj, cropId)
    exports.ox_target:addLocalEntity(obj, {
        {
            name  = 'mike_crop_info_' .. cropId,
            label = 'Check crop',
            icon  = 'fa-solid fa-seedling',
            onSelect = function() ShowCropInfo(cropId) end,
        },
        {
            name  = 'mike_crop_water_' .. cropId,
            label = 'Water',
            icon  = 'fa-solid fa-droplet',
            canInteract = function()
                local c = Crops[cropId]; return c and c.withered == 0
            end,
            onSelect = function() DoWater(cropId) end,
        },
        {
            name  = 'mike_crop_harvest_' .. cropId,
            label = 'Harvest',
            icon  = 'fa-solid fa-wheat-awn',
            canInteract = function()
                local c = Crops[cropId]; if not c then return false end
                local stage = GetCropStage(c)
                return stage == 'mature' or stage == 'withered'
            end,
            onSelect = function() DoHarvest(cropId) end,
        },
    })
end

local function spawnProp(c)
    local stage = cropStage(c)
    local propName = getPropForStage(c.crop_type, stage)
    local hash = GetHashKey(propName)

    -- If prop exists and stage hasn't changed, keep it
    if CropProps[c.id] and DoesEntityExist(CropProps[c.id]) and CropStages[c.id] == stage then
        return CropProps[c.id]
    end

    -- Stage changed or first spawn — remove old and spawn new
    if CropProps[c.id] and DoesEntityExist(CropProps[c.id]) then
        exports.ox_target:removeLocalEntity(CropProps[c.id])
        SetEntityAsMissionEntity(CropProps[c.id], true, true)
        DeleteEntity(CropProps[c.id])
        CropProps[c.id] = nil
    end

    if not loadModel(hash) then return end
    local obj = CreateObject(hash, c.x + 0.0, c.y + 0.0, c.z + 0.0, false, false, false, true, true)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetEntityAsMissionEntity(obj, true, true)
    CropProps[c.id] = obj
    CropStages[c.id] = stage
    registerTarget(obj, c.id)
    SetModelAsNoLongerNeeded(hash)
    return obj
end

local function removeProp(id)
    local obj = CropProps[id]
    if obj and DoesEntityExist(obj) then
        exports.ox_target:removeLocalEntity(obj)
        SetEntityAsMissionEntity(obj, true, true)
        DeleteEntity(obj)
    end
    CropProps[id] = nil
    CropStages[id] = nil
end

local function addBlip(c)
    if CropBlips[c.id] and DoesBlipExist(CropBlips[c.id]) then return end
    local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, c.x + 0.0, c.y + 0.0, c.z + 0.0)
    SetBlipSprite(blip, -405833986, true)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, ('Crop: %s'):format(c.crop_type))
    CropBlips[c.id] = blip
end

local function removeBlip(id)
    if CropBlips[id] and DoesBlipExist(CropBlips[id]) then RemoveBlip(CropBlips[id]) end
    CropBlips[id] = nil
end

RegisterNetEvent('mike-farming:client:sync', function(list)
    Crops = {}
    for id, c in pairs(list or {}) do Crops[tonumber(id) or id] = c end
    for id, _ in pairs(CropProps) do
        if not Crops[id] then removeProp(id) end
    end
    for id, _ in pairs(CropBlips) do
        if not Crops[id] then removeBlip(id) end
    end
    for _, c in pairs(Crops) do addBlip(c) end
end)

-- Spawn + update props within radius (checks growth stage changes)
CreateThread(function()
    while true do
        Wait(3000)
        local pc = GetEntityCoords(PlayerPedId())
        for id, c in pairs(Crops) do
            local d = #(pc - vector3(c.x + 0.0, c.y + 0.0, c.z + 0.0))
            if d <= Config.PropRadius then
                spawnProp(c)
            else
                removeProp(id)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        for id, _ in pairs(CropProps) do removeProp(id) end
        for id, _ in pairs(CropBlips) do removeBlip(id) end
    end
end)

-- Floating 3D text above nearby crops
local function drawText3D(x, y, z, text)
    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(x, y, z)
    if not onScreen then return end
    SetTextScale(0.35, 0.35)
    SetTextColor(255, 255, 255, 215)
    SetTextCentre(true)
    SetTextDropshadow(1, 0, 0, 0, 255)
    Citizen.InvokeNative(0xADA9255D, 10)
    DisplayText(CreateVarString(10, 'LITERAL_STRING', text), sx, sy)
end

CreateThread(function()
    while true do
        Wait(0)
        if Config.ShowFloatingText then
            local pc = GetEntityCoords(PlayerPedId())
            for _, c in pairs(Crops) do
                local cp = vector3(c.x + 0.0, c.y + 0.0, c.z + 0.0)
                local d = #(pc - cp)
                if d <= Config.FloatingTextRange then
                    local stage, pct = GetCropStage(c)
                    local tag = ('%s [%s %.0f%%]'):format(c.crop_type, stage, pct * 100)
                    drawText3D(cp.x, cp.y, cp.z + 1.0, tag)
                end
            end
        end
    end
end)

function NearestCrop(maxDist)
    local pc = GetEntityCoords(PlayerPedId())
    local best, bestD
    for id, c in pairs(Crops) do
        local d = #(pc - vector3(c.x + 0.0, c.y + 0.0, c.z + 0.0))
        if d <= (maxDist or 2.0) and (not bestD or d < bestD) then
            best = c; bestD = d
        end
    end
    return best
end
