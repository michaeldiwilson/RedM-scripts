RSGCore = exports['rsg-core']:GetCoreObject()

Stills      = {}
StillProps  = {}
StillBlips  = {}
StillSmoke  = {}  -- id -> particle handle

local COOKING_STATES = { mashing = true, fermenting = true, distilling = true }

local function loadModel(hash)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 3000 do Wait(10) end
    return HasModelLoaded(hash)
end

local function registerTarget(obj, stillId)
    exports.ox_target:addLocalEntity(obj, {
        {
            name  = 'mike_still_open_' .. stillId,
            label = 'Use still',
            icon  = 'fa-solid fa-flask',
            onSelect = function() OpenStillMenu(stillId) end,
        },
    })
end

local function spawnProp(st)
    if StillProps[st.id] and DoesEntityExist(StillProps[st.id]) then return end
    local hash = GetHashKey(Config.StillProp)
    if not loadModel(hash) then
        print(('[mike-moonshine] Failed to load model: %s for still #%d'):format(Config.StillProp, st.id))
        return
    end
    local obj = CreateObject(hash, st.x + 0.0, st.y + 0.0, st.z + 0.0, false, false, false, true, true)
    PlaceObjectOnGroundProperly(obj)
    SetEntityHeading(obj, st.heading + 0.0)
    FreezeEntityPosition(obj, true)
    SetEntityAsMissionEntity(obj, true, true)
    StillProps[st.id] = obj
    registerTarget(obj, st.id)
    SetModelAsNoLongerNeeded(hash)
end

local function startSmoke(id, x, y, z)
    if StillSmoke[id] then return end
    -- Spawn campfire buried under the still — fire hidden, smoke rises out the top
    local hash = GetHashKey('p_campfire05x')
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 3000 do Wait(10) end
    if not HasModelLoaded(hash) then return end
    local fire = CreateObject(hash, x + 0.0, y + 0.0, z - 0.8, false, false, false, true, true)
    FreezeEntityPosition(fire, true)
    SetEntityAsMissionEntity(fire, true, true)
    SetModelAsNoLongerNeeded(hash)
    StillSmoke[id] = fire
end

local function stopSmoke(id)
    if StillSmoke[id] then
        if DoesEntityExist(StillSmoke[id]) then
            SetEntityAsMissionEntity(StillSmoke[id], true, true)
            DeleteEntity(StillSmoke[id])
        end
        StillSmoke[id] = nil
    end
end

local function removeProp(id)
    stopSmoke(id)
    local obj = StillProps[id]
    if obj and DoesEntityExist(obj) then
        exports.ox_target:removeLocalEntity(obj)
        SetEntityAsMissionEntity(obj, true, true)
        DeleteEntity(obj)
    end
    StillProps[id] = nil
end

local function addBlip(s)
    if StillBlips[s.id] and DoesBlipExist(StillBlips[s.id]) then return end
    local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, s.x + 0.0, s.y + 0.0, s.z + 0.0)
    SetBlipSprite(blip, -1253920204, true) -- bottle icon
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, ('Moonshine Still (%s)'):format(s.state))
    StillBlips[s.id] = blip
end

local function removeBlip(id)
    if StillBlips[id] and DoesBlipExist(StillBlips[id]) then RemoveBlip(StillBlips[id]) end
    StillBlips[id] = nil
end

RegisterNetEvent('mike-moonshine:client:sync', function(list)
    Stills = {}
    for id, s in pairs(list or {}) do Stills[tonumber(id) or id] = s end
    for id, _ in pairs(StillProps) do
        if not Stills[id] then removeProp(id) end
    end
    for id, _ in pairs(StillBlips) do
        if not Stills[id] then removeBlip(id) end
    end
    for _, s in pairs(Stills) do addBlip(s) end
end)

CreateThread(function()
    while true do
        Wait(3000)
        local pc = GetEntityCoords(PlayerPedId())
        for id, s in pairs(Stills) do
            local d = #(pc - vector3(s.x + 0.0, s.y + 0.0, s.z + 0.0))
            if d <= 150.0 then
                spawnProp(s)
                -- Smoke while cooking
                if COOKING_STATES[s.state] then
                    startSmoke(id, s.x, s.y, s.z)
                else
                    stopSmoke(id)
                end
            else
                removeProp(id)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        for id, _ in pairs(StillProps) do removeProp(id) end
        for id, _ in pairs(StillBlips) do removeBlip(id) end
    end
end)

function NearestStill(maxDist)
    local pc = GetEntityCoords(PlayerPedId())
    local best, bestD
    for id, s in pairs(Stills) do
        local d = #(pc - vector3(s.x + 0.0, s.y + 0.0, s.z + 0.0))
        if d <= (maxDist or Config.InteractRadius) and (not bestD or d < bestD) then
            best = s; bestD = d
        end
    end
    return best
end
