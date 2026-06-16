local RSGCore = exports['rsg-core']:GetCoreObject()

-- ──────────────────────────────────────────────────────────────────────────
-- Register ox_target on all campfire models
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    Wait(2000)

    local models = {}
    for _, model in ipairs(Config.CampfireModels) do
        models[#models + 1] = joaat(model)
    end

    exports.ox_target:addModel(models, {
        {
            name     = 'mike_cooking_campfire',
            label    = 'Cook',
            icon     = 'fa-solid fa-fire',
            onSelect = function() openCookMenu() end,
        },
    })
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Cook menu: show what raw items the player has
-- ──────────────────────────────────────────────────────────────────────────
function openCookMenu()
    local pd = RSGCore.Functions.GetPlayerData()
    if not pd or not pd.items then return end

    -- Find raw items the player has that match recipes
    local opts = {}
    for _, invItem in pairs(pd.items) do
        if invItem and invItem.name then
            local recipe = Config.Recipes[invItem.name]
            if recipe then
                local itemInfo = RSGCore.Shared.Items[invItem.name]
                local outputInfo = RSGCore.Shared.Items[recipe.output]
                local outputLabel = outputInfo and outputInfo.label or recipe.output
                opts[#opts + 1] = {
                    title       = recipe.label,
                    description = ('Cook → %d× %s (You have: %d)'):format(recipe.qty, outputLabel, invItem.amount),
                    icon        = 'fa-solid fa-drumstick-bite',
                    onSelect    = function()
                        startCooking(invItem.name, recipe)
                    end,
                }
            end
        end
    end

    if #opts == 0 then
        return lib.notify({ type = 'inform', description = 'You have nothing to cook.' })
    end

    lib.registerContext({ id = 'mike_cooking_menu', title = 'Campfire Cooking', options = opts })
    lib.showContext('mike_cooking_menu')
end

-- ──────────────────────────────────────────────────────────────────────────
-- Cooking progress bar → server callback
-- ──────────────────────────────────────────────────────────────────────────
function startCooking(rawItem, recipe)
    if not lib.progressBar({
        duration     = Config.CookTime,
        label        = 'Cooking ' .. recipe.label .. '...',
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
    }) then
        lib.notify({ type = 'error', description = 'Cooking cancelled' })
        return
    end

    local ok = lib.callback.await('mike-cooking:server:cook', false, rawItem)
    if ok then
        lib.notify({ type = 'success', description = ('Cooked %d× %s'):format(recipe.qty, recipe.output) })
    end
end
