local RSGCore = exports['rsg-core']:GetCoreObject()
local zones = {}

local function hasJob(locationKey)
    local loc = Config.Locations[locationKey]
    if not loc then return false end
    local pd = RSGCore.Functions.GetPlayerData()
    return pd and pd.job and pd.job.name == loc.job
end

CreateThread(function()
    Wait(3000)

    for key, loc in pairs(Config.Locations) do
        -- Shop counter (job-gated: sell to customers)
        zones[#zones + 1] = exports.ox_target:addSphereZone({
            coords = loc.shop,
            radius = Config.ShopRadius,
            debug  = false,
            options = {
                {
                    name     = 'gunsmith_shop_' .. key,
                    label    = 'Gun Shop',
                    icon     = 'fa-solid fa-gun',
                    onSelect = function()
                        if hasJob(key) then
                            TriggerServerEvent('mike-gunsmith:server:openShop', key)
                        else
                            -- Customer: browse and buy
                            TriggerServerEvent('mike-gunsmith:server:openCustomerShop', key)
                        end
                    end,
                },
            },
        })

        -- Weapon customisation (job-gated only)
        zones[#zones + 1] = exports.ox_target:addSphereZone({
            coords = loc.custom,
            radius = Config.CustomRadius,
            debug  = false,
            options = {
                {
                    name     = 'gunsmith_custom_' .. key,
                    label    = 'Weapon Customisation',
                    icon     = 'fa-solid fa-wrench',
                    onSelect = function()
                        if not hasJob(key) then
                            return lib.notify({ type = 'error', description = 'Only the gunsmith can use this' })
                        end
                        -- Use rsg-weaponcomp's customisation system
                        lib.notify({ type = 'inform', description = 'Use /inspect with a weapon equipped to customise', duration = 5000 })
                    end,
                },
            },
        })

        -- Work bench (job-gated: repairs, cleaning)
        zones[#zones + 1] = exports.ox_target:addSphereZone({
            coords = loc.bench,
            radius = Config.BenchRadius,
            debug  = false,
            options = {
                {
                    name     = 'gunsmith_bench_' .. key,
                    label    = 'Gunsmith Workbench',
                    icon     = 'fa-solid fa-hammer',
                    onSelect = function()
                        if not hasJob(key) then
                            return lib.notify({ type = 'error', description = 'Only the gunsmith can use this' })
                        end
                        openWorkbenchMenu(key)
                    end,
                },
            },
        })

        -- Storage (job-gated stash)
        zones[#zones + 1] = exports.ox_target:addSphereZone({
            coords = loc.storage,
            radius = Config.StorageRadius,
            debug  = false,
            options = {
                {
                    name     = 'gunsmith_storage_' .. key,
                    label    = 'Gunsmith Storage',
                    icon     = 'fa-solid fa-box',
                    onSelect = function()
                        if not hasJob(key) then
                            return lib.notify({ type = 'error', description = 'Only the gunsmith can access storage' })
                        end
                        TriggerServerEvent('mike-gunsmith:server:openStorage', key)
                    end,
                },
            },
        })

        -- Blip
        local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, loc.shop.x + 0.0, loc.shop.y + 0.0, loc.shop.z + 0.0)
        SetBlipSprite(blip, joaat('blip_shop_gunsmith'), true)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, loc.name)
    end
end)

function openWorkbenchMenu(key)
    local opts = {
        {
            title    = 'Clean Weapon (Gun Oil)',
            description = 'Requires gun_oil in inventory',
            icon     = 'fa-solid fa-spray-can',
            onSelect = function()
                lib.notify({ type = 'inform', description = 'Use /inspect to clean your equipped weapon' })
            end,
        },
        {
            title    = 'Repair Weapon (Repair Kit)',
            description = 'Requires weapon_repair_kit in inventory',
            icon     = 'fa-solid fa-screwdriver-wrench',
            onSelect = function()
                lib.notify({ type = 'inform', description = 'Use a weapon_repair_kit from your inventory' })
            end,
        },
    }

    lib.registerContext({ id = 'gunsmith_bench_' .. key, title = 'Gunsmith Workbench', options = opts })
    lib.showContext('gunsmith_bench_' .. key)
end

-- Cleanup
AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        for _, zid in ipairs(zones) do
            exports.ox_target:removeZone(zid)
        end
    end
end)
