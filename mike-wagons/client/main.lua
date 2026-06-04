local yardZones = {}
local yardBlips = {}
local mySpawnedWagons = {}  -- wagonId -> { entity, type }

-- ──────────────────────────────────────────────────────────────────────────
-- Wagon yard menu
-- ──────────────────────────────────────────────────────────────────────────
local function openYardMenu(yardIdx)
    local wagons = lib.callback.await('mike-wagons:server:getMyWagons', false)
    if not wagons or #wagons == 0 then
        return lib.notify({ type = 'inform', description = 'You have no wagons. Register one with a wagon kit.' })
    end

    local opts = {}
    for _, w in ipairs(wagons) do
        local stored = w.stored == 1
        opts[#opts + 1] = {
            title       = w.label .. (stored and ' [STORED]' or ' [OUT]'),
            description = stored and 'Pull out this wagon' or 'Store this wagon',
            icon        = stored and 'fa-solid fa-arrow-right' or 'fa-solid fa-warehouse',
            onSelect    = function()
                if stored then
                    pullOutWagon(w.id, yardIdx)
                else
                    storeWagon(w.id)
                end
            end,
        }
    end

    lib.registerContext({ id = 'mike_wagon_yard_' .. yardIdx, title = Config.Yards[yardIdx].name, options = opts })
    lib.showContext('mike_wagon_yard_' .. yardIdx)
end

-- ──────────────────────────────────────────────────────────────────────────
-- Pull out
-- ──────────────────────────────────────────────────────────────────────────
function pullOutWagon(wagonId, yardIdx)
    local result = lib.callback.await('mike-wagons:server:pullOut', false, wagonId, yardIdx)
    if not result then return end

    local hash = GetHashKey(result.model)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 5000 do Wait(10) end
    if not HasModelLoaded(hash) then
        lib.notify({ type = 'error', description = 'Failed to load wagon model' })
        return
    end

    local sp = result.spawn
    local veh = CreateVehicle(hash, sp.x, sp.y, sp.z, sp.h, true, false, false, false)
    SetModelAsNoLongerNeeded(hash)
    SetEntityAsMissionEntity(veh, true, true)

    local netId = NetworkGetNetworkIdFromEntity(veh)
    TriggerServerEvent('mike-wagons:server:setNetId', result.wagonId, netId)

    mySpawnedWagons[result.wagonId] = { entity = veh, type = result.type, label = result.label }

    -- Add ox_target on the wagon for stash + store
    addWagonTargets(result.wagonId, veh)

    lib.notify({ type = 'success', description = result.label .. ' is ready!' })
end

-- ──────────────────────────────────────────────────────────────────────────
-- Store
-- ──────────────────────────────────────────────────────────────────────────
function storeWagon(wagonId)
    -- Must be near a yard
    local p = GetEntityCoords(PlayerPedId())
    local nearYard = false
    for _, yard in ipairs(Config.Yards) do
        if #(p - yard.coords) <= Config.YardRadius * 2 then
            nearYard = true
            break
        end
    end
    if not nearYard then
        return lib.notify({ type = 'error', description = 'Bring the wagon to a wagon yard to store it.' })
    end

    local ok = lib.callback.await('mike-wagons:server:store', false, wagonId)
    if not ok then return end

    local data = mySpawnedWagons[wagonId]
    if data and data.entity and DoesEntityExist(data.entity) then
        SetEntityAsMissionEntity(data.entity, true, true)
        DeleteEntity(data.entity)
    end
    mySpawnedWagons[wagonId] = nil
end

-- ──────────────────────────────────────────────────────────────────────────
-- Wagon targets: open stash + store
-- ──────────────────────────────────────────────────────────────────────────
function addWagonTargets(wagonId, entity)
    exports.ox_target:addLocalEntity(entity, {
        {
            name     = 'mike_wagon_stash_' .. wagonId,
            label    = 'Open wagon storage',
            icon     = 'fa-solid fa-box-open',
            distance = 3.0,
            onSelect = function()
                lib.callback.await('mike-wagons:server:openStash', false, wagonId)
            end,
        },
        {
            name     = 'mike_wagon_store_' .. wagonId,
            label    = 'Store wagon',
            icon     = 'fa-solid fa-warehouse',
            distance = 3.0,
            onSelect = function()
                storeWagon(wagonId)
            end,
        },
    })
end

-- ──────────────────────────────────────────────────────────────────────────
-- Yard zones + blips
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    Wait(2500)
    for idx, yard in ipairs(Config.Yards) do
        local zid = exports.ox_target:addSphereZone({
            coords = yard.coords,
            radius = Config.YardRadius,
            debug  = false,
            options = {
                {
                    name  = 'mike_wagon_yard_' .. idx,
                    label = yard.name,
                    icon  = 'fa-solid fa-horse-head',
                    onSelect = function() openYardMenu(idx) end,
                },
            },
        })
        yardZones[#yardZones + 1] = zid

        local blip = BlipAddForCoords(1664425300, yard.coords)
        SetBlipSprite(blip, joaat('blip_shop_gunsmith'), true)
        SetBlipScale(blip, 0.75)
        SetBlipName(blip, yard.name)
        yardBlips[#yardBlips + 1] = blip
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        for _, id in ipairs(yardZones) do exports.ox_target:removeZone(id) end
        for _, b in ipairs(yardBlips) do if DoesBlipExist(b) then RemoveBlip(b) end end
        for _, data in pairs(mySpawnedWagons) do
            if data.entity and DoesEntityExist(data.entity) then
                SetEntityAsMissionEntity(data.entity, true, true)
                DeleteEntity(data.entity)
            end
        end
    end
end)
