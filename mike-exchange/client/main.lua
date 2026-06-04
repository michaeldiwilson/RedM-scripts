local shopZones = {}
local shopBlips = {}

local function openShopMenu(shopIdx)
    TriggerServerEvent('mike-exchange:server:getStock', shopIdx)
end

-- Server sends back current stock, we build the menu
RegisterNetEvent('mike-exchange:client:showMenu', function(shopIdx, shopName, stockData)
    local shop = Config.Shops[shopIdx]
    if not shop then return end

    local opts = {}
    for _, entry in ipairs(shop.items) do
        local stock = stockData[entry.item] or 0
        opts[#opts + 1] = {
            title       = ('Sell %s — $%d each'):format(entry.item, entry.buyPrice),
            description = ('Shop stock: %d / %d'):format(stock, entry.maxStock),
            icon        = 'fa-solid fa-arrow-right',
            onSelect    = function()
                local res = lib.inputDialog('Sell ' .. entry.item, {
                    { type = 'number', label = 'How many to sell?', default = 1, min = 1, required = true },
                })
                if not res then return end
                TriggerServerEvent('mike-exchange:server:sell', shopIdx, entry.item, res[1])
            end,
        }
        opts[#opts + 1] = {
            title       = ('Buy %s — $%d each'):format(entry.item, entry.sellPrice),
            description = ('In stock: %d'):format(stock),
            icon        = 'fa-solid fa-arrow-left',
            disabled    = stock == 0,
            onSelect    = function()
                local max = stock
                local res = lib.inputDialog('Buy ' .. entry.item, {
                    { type = 'number', label = ('How many to buy? (stock: %d)'):format(max), default = 1, min = 1, max = max, required = true },
                })
                if not res then return end
                TriggerServerEvent('mike-exchange:server:buy', shopIdx, entry.item, res[1])
            end,
        }
    end

    lib.registerContext({ id = 'mike_exchange_' .. shopIdx, title = shopName, options = opts })
    lib.showContext('mike_exchange_' .. shopIdx)
end)

-- Spawn zones + blips
CreateThread(function()
    Wait(2500)
    for idx, shop in ipairs(Config.Shops) do
        local zid = exports.ox_target:addSphereZone({
            coords = shop.coords,
            radius = Config.ShopRadius,
            debug  = false,
            options = {
                {
                    name  = 'mike_exchange_' .. idx,
                    label = shop.name,
                    icon  = 'fa-solid fa-store',
                    onSelect = function() openShopMenu(idx) end,
                },
            },
        })
        shopZones[#shopZones + 1] = zid

        if shop.blip then
            local blip = BlipAddForCoords(1664425300, shop.coords)
            SetBlipSprite(blip, joaat('blip_shop_gunsmith'), true)
            SetBlipScale(blip, 0.75)
            SetBlipName(blip, shop.name)
            shopBlips[#shopBlips + 1] = blip
        end
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        for _, id in ipairs(shopZones) do exports.ox_target:removeZone(id) end
        for _, b in ipairs(shopBlips) do if DoesBlipExist(b) then RemoveBlip(b) end end
    end
end)
