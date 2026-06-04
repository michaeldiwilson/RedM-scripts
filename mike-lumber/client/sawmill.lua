local millZones = {}
local millBlips = {}

local function openMillMenu(millName)
    local opts = {}
    for key, r in pairs(Config.MillRecipes) do
        local reqs = {}
        for item, n in pairs(r.inputs) do reqs[#reqs + 1] = ('%d× %s'):format(n, item) end
        opts[#opts + 1] = {
            title       = 'Mill ' .. r.output,
            description = 'Requires: ' .. table.concat(reqs, ', '),
            icon        = 'fa-solid fa-tree',
            onSelect    = function()
                local res = lib.inputDialog('Mill ' .. r.output, {
                    { type = 'number', label = 'How many to mill?', default = 1, min = 1, required = true },
                })
                if not res then return end
                StartMill(key, res[1])
            end,
        }
    end
    lib.registerContext({ id = 'mike_mill_' .. millName, title = millName, options = opts })
    lib.showContext('mike_mill_' .. millName)
end

function StartMill(recipeKey, batch)
    local recipe = Config.MillRecipes[recipeKey]; if not recipe then return end
    batch = math.max(1, tonumber(batch) or 1)
    for i = 1, batch do
        local canDo = lib.callback.await('mike-lumber:server:checkMill', false, recipeKey)
        if not canDo then return end
        if not lib.progressBar({
            duration = recipe.time,
            label    = ('Milling %s (%d/%d)...'):format(recipe.output, i, batch),
            useWhileDead = false,
            canCancel = true,
            disable  = { move = true, car = true, combat = true },
        }) then
            lib.notify({ type = 'error', description = 'Milling cancelled' })
            return
        end
        local ok = lib.callback.await('mike-lumber:server:mill', false, recipeKey)
        if not ok then return end
    end
end

CreateThread(function()
    Wait(2500)
    for _, m in ipairs(Config.Sawmills) do
        local zid = exports.ox_target:addSphereZone({
            coords = m.coords,
            radius = Config.SawmillRadius,
            debug  = false,
            options = {
                {
                    name  = 'mike_mill_' .. m.name,
                    label = 'Use ' .. m.name,
                    icon  = 'fa-solid fa-tree',
                    onSelect = function() openMillMenu(m.name) end,
                },
            },
        })
        millZones[#millZones + 1] = zid

        local blip = BlipAddForCoords(1664425300, m.coords)
        SetBlipSprite(blip, joaat('blip_shop_gunsmith'), true)
        SetBlipScale(blip, 0.75)
        SetBlipName(blip, m.name)
        millBlips[#millBlips + 1] = blip
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        for _, id in ipairs(millZones) do exports.ox_target:removeZone(id) end
        for _, b in ipairs(millBlips) do if DoesBlipExist(b) then RemoveBlip(b) end end
    end
end)
