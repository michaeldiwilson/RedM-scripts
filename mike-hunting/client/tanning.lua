local RSGCore = exports['rsg-core']:GetCoreObject()
local rackProps = {}  -- rackId -> entity
local rackZones = {}  -- rackId -> zoneId

local function loadModel(hash)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 3000 do Wait(10) end
    return HasModelLoaded(hash)
end

local function spawnRack(rack)
    if rackProps[rack.id] and DoesEntityExist(rackProps[rack.id]) then return end
    local hash = GetHashKey(Config.TanningRackProp)
    if not loadModel(hash) then return end
    local obj = CreateObject(hash, rack.x + 0.0, rack.y + 0.0, rack.z + 0.0, false, false, false, true, true)
    PlaceObjectOnGroundProperly(obj)
    SetEntityHeading(obj, rack.heading + 0.0)
    FreezeEntityPosition(obj, true)
    SetEntityAsMissionEntity(obj, true, true)
    SetModelAsNoLongerNeeded(hash)
    rackProps[rack.id] = obj

    local zid = exports.ox_target:addSphereZone({
        coords = vector3(rack.x, rack.y, rack.z),
        radius = 2.5,
        debug  = false,
        options = {
            {
                name     = 'mike_rack_use_' .. rack.id,
                label    = 'Tanning Rack',
                icon     = 'fa-solid fa-scroll',
                onSelect = function() openRackMenu(rack.id) end,
            },
        },
    })
    rackZones[rack.id] = zid
end

local function removeRack(id)
    if rackZones[id] then exports.ox_target:removeZone(rackZones[id]); rackZones[id] = nil end
    if rackProps[id] and DoesEntityExist(rackProps[id]) then
        SetEntityAsMissionEntity(rackProps[id], true, true)
        DeleteEntity(rackProps[id])
    end
    rackProps[id] = nil
end

-- ──────────────────────────────────────────────────────────────────────────
-- Sync from server
-- ──────────────────────────────────────────────────────────────────────────
local rackData = {}

RegisterNetEvent('mike-hunting:client:syncRacks', function(data)
    rackData = data or {}
    -- Remove racks that no longer exist
    for id in pairs(rackProps) do
        if not rackData[id] then removeRack(id) end
    end
end)

-- Spawn/despawn racks based on proximity
CreateThread(function()
    while true do
        Wait(3000)
        local pc = GetEntityCoords(PlayerPedId())
        for id, rack in pairs(rackData) do
            local d = #(pc - vector3(rack.x + 0.0, rack.y + 0.0, rack.z + 0.0))
            if d <= 100.0 then
                spawnRack(rack)
            else
                removeRack(id)
            end
        end
    end
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Rack menu
-- ──────────────────────────────────────────────────────────────────────────
function openRackMenu(rackId)
    local info = lib.callback.await('mike-hunting:server:getRackInfo', false, rackId)
    if not info then return end

    local opts = {}

    -- Show current pelts
    for _, p in ipairs(info.pelts) do
        local peltInfo = RSGCore.Shared.Items[p.pelt_item]
        local label = peltInfo and peltInfo.label or p.pelt_item
        if p.ready then
            opts[#opts + 1] = {
                title       = label .. ' — READY!',
                description = ('→ %d leather'):format(p.leatherQty),
                icon        = 'fa-solid fa-check',
            }
        else
            local mins = math.ceil(p.remaining / 60)
            opts[#opts + 1] = {
                title       = label .. ' — curing...',
                description = ('%d min remaining → %d leather'):format(mins, p.leatherQty),
                icon        = 'fa-solid fa-hourglass-half',
            }
        end
    end

    -- Hang pelt option (if slots available)
    if #info.pelts < info.slots then
        opts[#opts + 1] = {
            title       = ('Hang a pelt (%d/%d slots)'):format(#info.pelts, info.slots),
            description = 'Select a pelt + salt to start curing',
            icon        = 'fa-solid fa-plus',
            onSelect    = function() selectPeltToHang(rackId) end,
        }
    end

    -- Collect leather
    local hasReady = false
    for _, p in ipairs(info.pelts) do if p.ready then hasReady = true; break end end
    if hasReady then
        opts[#opts + 1] = {
            title       = 'Collect cured leather',
            icon        = 'fa-solid fa-hand-holding',
            onSelect    = function()
                lib.callback.await('mike-hunting:server:collectLeather', false, rackId)
            end,
        }
    end

    -- Pack up
    opts[#opts + 1] = {
        title       = 'Pack up rack',
        icon        = 'fa-solid fa-box',
        onSelect    = function()
            local ok = lib.callback.await('mike-hunting:server:packRack', false, rackId)
            if ok then removeRack(rackId); rackData[rackId] = nil end
        end,
    }

    lib.registerContext({ id = 'mike_tanning_' .. rackId, title = 'Tanning Rack', options = opts })
    lib.showContext('mike_tanning_' .. rackId)
end

function selectPeltToHang(rackId)
    -- Build list of pelts player has
    local peltTypes = {}
    for peltItem, _ in pairs(Config.PeltLeather) do
        peltTypes[#peltTypes + 1] = peltItem
    end

    local opts = {}
    for _, peltItem in ipairs(peltTypes) do
        local has = exports['rsg-inventory']:HasItem(peltItem, 1)
        if has then
            local itemInfo = RSGCore.Shared.Items[peltItem]
            local label = itemInfo and itemInfo.label or peltItem
            local leatherQty = Config.PeltLeather[peltItem] or 1
            local saltNeeded = (peltItem == 'bear_pelt' or peltItem == 'bison_pelt') and 2 or 1
            opts[#opts + 1] = {
                title       = label,
                description = ('+ %d salt → %d leather in %d min'):format(saltNeeded, leatherQty, math.ceil(Config.TanningCureTime / 60)),
                icon        = 'fa-solid fa-scroll',
                onSelect    = function()
                    if lib.progressBar({
                        duration = 3000,
                        label = 'Hanging pelt...',
                        useWhileDead = false,
                        canCancel = true,
                        disable = { move = true, car = true, combat = true },
                    }) then
                        lib.callback.await('mike-hunting:server:hangPelt', false, rackId, peltItem)
                    end
                end,
            }
        end
    end

    if #opts == 0 then
        return lib.notify({ type = 'error', description = 'You have no pelts to hang' })
    end

    lib.registerContext({ id = 'mike_tanning_pelts_' .. rackId, title = 'Select Pelt', menu = 'mike_tanning_' .. rackId, options = opts })
    lib.showContext('mike_tanning_pelts_' .. rackId)
end

-- Cleanup
AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        for id in pairs(rackProps) do removeRack(id) end
    end
end)
