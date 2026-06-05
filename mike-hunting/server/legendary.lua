local RSGCore = exports['rsg-core']:GetCoreObject()

-- ──────────────────────────────────────────────────────────────────────────
-- Legendary animal state (server memory, resets on restart)
-- ──────────────────────────────────────────────────────────────────────────
local legendaryState = {}  -- key -> { alive, lastKilled, spawnedBy, activeCoords, activeHeading }

-- Pick a random location for a legendary (supports multi-location configs)
local function pickLocation(def)
    if def.locations and #def.locations > 0 then
        local loc = def.locations[math.random(#def.locations)]
        return loc.coords, loc.heading
    end
    return def.coords, def.heading
end

-- Initialize state for each legendary (pick initial location)
CreateThread(function()
    for key, def in pairs(Config.LegendaryAnimals) do
        local coords, heading = pickLocation(def)
        legendaryState[key] = {
            alive         = false,
            lastKilled    = 0,
            spawnedBy     = nil,
            activeCoords  = coords,
            activeHeading = heading,
        }
    end
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Callback: check which legendaries are available to spawn
-- Returns available keys + their active coords so client can check proximity
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-hunting:server:checkLegendaries', function(source)
    local available = {}
    local now = os.time()
    for key, state in pairs(legendaryState) do
        local def = Config.LegendaryAnimals[key]
        if not state.alive and (now - state.lastKilled >= def.cooldown) then
            available[key] = {
                coords  = state.activeCoords,
                heading = state.activeHeading,
            }
        end
    end
    return available
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Callback: claim a legendary spawn (prevents double-spawn)
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-hunting:server:claimLegendarySpawn', function(source, legendaryKey)
    local state = legendaryState[legendaryKey]
    if not state then return false end
    local def = Config.LegendaryAnimals[legendaryKey]
    if not def then return false end

    local now = os.time()
    if state.alive then return false end
    if (now - state.lastKilled) < def.cooldown then return false end

    state.alive = true
    state.spawnedBy = source
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Event: legendary animal was killed — give unique loot
-- ──────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mike-hunting:server:legendaryKilled', function(legendaryKey)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    local state = legendaryState[legendaryKey]
    if not state then return end
    local def = Config.LegendaryAnimals[legendaryKey]
    if not def then return end

    -- Mark as killed + pick a new random location for next spawn
    state.alive = false
    state.lastKilled = os.time()
    state.spawnedBy = nil
    local newCoords, newHeading = pickLocation(def)
    state.activeCoords = newCoords
    state.activeHeading = newHeading

    -- Give legendary pelt
    P.Functions.AddItem(def.pelt, 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[def.pelt], 'add', 1)

    -- Give meat
    local meatQty = math.random(def.meat.min, def.meat.max)
    P.Functions.AddItem(def.meat.item, meatQty)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[def.meat.item], 'add', meatQty)

    -- Give extras
    for _, extra in ipairs(def.extras) do
        P.Functions.AddItem(extra.item, extra.qty)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[extra.item], 'add', extra.qty)
    end

    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        title = 'Legendary Kill!',
        description = ('You skinned the %s! Obtained: %s, %d× %s'):format(
            def.label, def.pelt, meatQty, def.meat.item
        ),
        duration = 8000,
    })
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Event: legendary despawned (player left area without killing)
-- ──────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mike-hunting:server:legendaryDespawned', function(legendaryKey)
    local state = legendaryState[legendaryKey]
    if not state then return end
    state.alive = false
    state.spawnedBy = nil
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Butcher: buy legendary rumors — tells client the active location
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-hunting:server:buyRumor', function(source, legendaryKey)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local def = Config.LegendaryAnimals[legendaryKey]
    if not def then return false end
    local state = legendaryState[legendaryKey]
    if not state then return false end

    local price = def.rumorPrice or 25
    local cash = P.Functions.GetMoney('cash')
    if cash < price then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Not enough cash. Need $%d'):format(price) })
        return false
    end

    P.Functions.RemoveMoney('cash', price)
    -- Send the active coords to the client so the blip is in the right place
    TriggerClientEvent('mike-hunting:client:revealLegendary', src, legendaryKey, state.activeCoords)
    return true
end)
