local RSGCore = exports['rsg-core']:GetCoreObject()
local netProps = {}  -- netId -> entity
local netZones = {}  -- netId -> zoneId
local netData = {}   -- netId -> data from server

local function loadModel(hash)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 5000 do Wait(10) end
    return HasModelLoaded(hash)
end

local function spawnNet(net)
    if netProps[net.id] and DoesEntityExist(netProps[net.id]) then return end
    local hash = GetHashKey(Config.NetProp)
    if not loadModel(hash) then return end
    local obj = CreateObject(hash, net.x + 0.0, net.y + 0.0, net.z + 0.0, false, false, false, true, true)
    PlaceObjectOnGroundProperly(obj)
    SetEntityHeading(obj, net.heading + 0.0)
    FreezeEntityPosition(obj, true)
    SetEntityAsMissionEntity(obj, true, true)
    SetModelAsNoLongerNeeded(hash)
    netProps[net.id] = obj

    -- Use the prop's actual position for the zone (may differ from stored coords after ground placement)
    local propCoords = GetEntityCoords(obj)
    local zid = exports.ox_target:addSphereZone({
        coords = vector3(propCoords.x, propCoords.y, propCoords.z),
        radius = 3.5,
        debug  = false,
        options = {
            {
                name     = 'mike_fishnet_use_' .. net.id,
                label    = 'Fishing Net',
                icon     = 'fa-solid fa-fish',
                onSelect = function() openNetMenu(net.id) end,
            },
        },
    })
    netZones[net.id] = zid
end

local function removeNet(id)
    if netZones[id] then exports.ox_target:removeZone(netZones[id]); netZones[id] = nil end
    if netProps[id] and DoesEntityExist(netProps[id]) then
        SetEntityAsMissionEntity(netProps[id], true, true)
        DeleteEntity(netProps[id])
    end
    netProps[id] = nil
end

-- ──────────────────────────────────────────────────────────────────────────
-- Sync from server
-- ──────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mike-fishing:client:syncNets', function(data)
    netData = data or {}
    for id in pairs(netProps) do
        if not netData[id] then removeNet(id) end
    end
end)

-- Spawn/despawn nets based on proximity
CreateThread(function()
    while true do
        Wait(3000)
        local pc = GetEntityCoords(PlayerPedId())
        for id, net in pairs(netData) do
            local d = #(pc - vector3(net.x + 0.0, net.y + 0.0, net.z + 0.0))
            if d <= 100.0 then
                spawnNet(net)
            else
                removeNet(id)
            end
        end
    end
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Net interaction menu
-- ──────────────────────────────────────────────────────────────────────────
function openNetMenu(netId)
    local info = lib.callback.await('mike-fishing:server:getNetInfo', false, netId)
    if not info then return end

    local opts = {}

    -- Status
    if info.ready then
        opts[#opts + 1] = {
            title       = 'Fish are ready!',
            description = (info.zone or 'Open Water') .. (info.baited and ' — Baited, extra catch' or ''),
            icon        = 'fa-solid fa-check',
        }
    else
        local mins = math.ceil(info.remaining / 60)
        opts[#opts + 1] = {
            title       = 'Fishing in ' .. (info.zone or 'Open Water') .. '...',
            description = ('%d min remaining%s'):format(mins, info.baited and ' (baited)' or ''),
            icon        = 'fa-solid fa-hourglass-half',
        }
    end

    -- Collect fish
    if info.ready then
        opts[#opts + 1] = {
            title    = 'Collect Fish',
            icon     = 'fa-solid fa-fish',
            onSelect = function()
                if lib.progressBar({
                    duration = 5000,
                    label = 'Pulling in the net...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                }) then
                    lib.callback.await('mike-fishing:server:collectFish', false, netId)
                end
            end,
        }
    end

    -- Bait net
    if not info.baited then
        opts[#opts + 1] = {
            title       = 'Add Bait',
            description = 'Increases next catch',
            icon        = 'fa-solid fa-worm',
            onSelect    = function() openBaitMenu(netId) end,
        }
    end

    -- Pick up
    opts[#opts + 1] = {
        title    = 'Pick Up Net',
        icon     = 'fa-solid fa-box',
        onSelect = function()
            local ok = lib.callback.await('mike-fishing:server:pickupNet', false, netId)
            if ok then removeNet(netId); netData[netId] = nil end
        end,
    }

    lib.registerContext({ id = 'mike_fishnet_' .. netId, title = 'Fishing Net', options = opts })
    lib.showContext('mike_fishnet_' .. netId)
end

function openBaitMenu(netId)
    local opts = {}
    for baitItem, bonus in pairs(Config.BaitBonus) do
        local has = exports['rsg-inventory']:HasItem(baitItem, 1)
        if has then
            local itemInfo = RSGCore.Shared.Items[baitItem]
            local label = itemInfo and itemInfo.label or baitItem
            opts[#opts + 1] = {
                title       = label,
                description = ('+%d bonus fish'):format(bonus),
                icon        = 'fa-solid fa-worm',
                onSelect    = function()
                    lib.callback.await('mike-fishing:server:baitNet', false, netId, baitItem)
                end,
            }
        end
    end

    if #opts == 0 then
        return lib.notify({ type = 'error', description = 'You have no bait' })
    end

    lib.registerContext({ id = 'mike_fishnet_bait_' .. netId, title = 'Select Bait', menu = 'mike_fishnet_' .. netId, options = opts })
    lib.showContext('mike_fishnet_bait_' .. netId)
end

-- Cleanup
AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        for id in pairs(netProps) do removeNet(id) end
    end
end)
