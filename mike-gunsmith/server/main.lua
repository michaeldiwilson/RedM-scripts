local RSGCore = exports['rsg-core']:GetCoreObject()

-- ──────────────────────────────────────────────────────────────────────────
-- Job check helper
-- ──────────────────────────────────────────────────────────────────────────
local function hasGunsmithJob(src, locationKey)
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local loc = Config.Locations[locationKey]
    if not loc then return false end
    return P.PlayerData.job and P.PlayerData.job.name == loc.job
end

-- ──────────────────────────────────────────────────────────────────────────
-- Gun shop: inventory UI for selling weapons to customers
-- Gunsmith stocks it, customers buy from it
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    Wait(4000)
    for key, loc in pairs(Config.Locations) do
        -- Register a shop that the gunsmith can stock
        exports['rsg-inventory']:CreateShop({
            name  = 'gunshop_' .. key,
            label = loc.name,
            items = {},  -- starts empty, gunsmith stocks it
        })
    end
end)

-- Gunsmith opens shop to manage stock
RegisterNetEvent('mike-gunsmith:server:openShop', function(locationKey)
    local src = source
    if not hasGunsmithJob(src, locationKey) then return end
    exports['rsg-inventory']:OpenShop(src, 'gunshop_' .. locationKey)
end)

-- Customer browses and buys
RegisterNetEvent('mike-gunsmith:server:openCustomerShop', function(locationKey)
    local src = source
    exports['rsg-inventory']:OpenShop(src, 'gunshop_' .. locationKey)
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Storage: stash for the gunsmith
-- ──────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mike-gunsmith:server:openStorage', function(locationKey)
    local src = source
    if not hasGunsmithJob(src, locationKey) then return end
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end

    local stashName = Config.StorageName .. '_' .. locationKey
    exports['rsg-inventory']:OpenInventory(src, stashName, {
        label    = Config.Locations[locationKey].name .. ' Storage',
        maxweight = Config.StorageWeight,
        slots    = Config.StorageSlots,
    })
end)
