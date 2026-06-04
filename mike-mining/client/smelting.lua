local furnaceZones = {}
local furnaceBlips  = {}

local function openSmeltMenu(furnaceName)
    local opts = {}
    for key, r in pairs(Config.SmeltRecipes) do
        local reqs = {}
        for item, n in pairs(r.inputs) do reqs[#reqs + 1] = ('%d× %s'):format(n, item) end
        opts[#opts + 1] = {
            title       = 'Smelt ' .. (r.qty and r.qty > 1 and ('%d× %s'):format(r.qty, r.output) or r.output),
            description = 'Requires: ' .. table.concat(reqs, ', '),
            icon        = 'fa-solid fa-fire',
            onSelect    = function()
                local res = lib.inputDialog('Smelt ' .. r.output, {
                    { type = 'number', label = 'How many bars to smelt?', default = 1, min = 1, required = true },
                })
                if not res then return end
                StartSmelt(key, res[1])
            end,
        }
    end
    lib.registerContext({ id = 'mike_smelt_' .. furnaceName, title = furnaceName, options = opts })
    lib.showContext('mike_smelt_' .. furnaceName)
end

function StartSmelt(recipeKey, batch)
    local recipe = Config.SmeltRecipes[recipeKey]; if not recipe then return end
    batch = math.max(1, tonumber(batch) or 1)
    for i = 1, batch do
        local canDo = lib.callback.await('mike-mining:server:checkSmelt', false, recipeKey)
        if not canDo then return end
        if not lib.progressBar({
            duration = recipe.time,
            label    = ('Smelting %s (%d/%d)...'):format(recipe.output, i, batch),
            useWhileDead = false,
            canCancel = true,
            disable  = { move = true, car = true, combat = true },
        }) then
            lib.notify({ type = 'error', description = 'Smelting cancelled' })
            return
        end
        local ok = lib.callback.await('mike-mining:server:smelt', false, recipeKey)
        if not ok then return end
    end
end

CreateThread(function()
    Wait(2500)
    for _, f in ipairs(Config.Furnaces) do
        local zid = exports.ox_target:addSphereZone({
            coords = f.coords,
            radius = Config.FurnaceRadius,
            debug  = false,
            options = {
                {
                    name  = 'mike_smelt_' .. f.name,
                    label = 'Use ' .. f.name,
                    icon  = 'fa-solid fa-fire',
                    onSelect = function() openSmeltMenu(f.name) end,
                },
            },
        })
        furnaceZones[#furnaceZones + 1] = zid

        local blip = BlipAddForCoords(1664425300, f.coords)
        SetBlipSprite(blip, joaat('blip_shop_gunsmith'), true)
        SetBlipScale(blip, 0.75)
        SetBlipName(blip, f.name)
        furnaceBlips[#furnaceBlips + 1] = blip
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        for _, id in ipairs(furnaceZones) do exports.ox_target:removeZone(id) end
        for _, b in ipairs(furnaceBlips) do if DoesBlipExist(b) then RemoveBlip(b) end end
    end
end)
