local RSGCore = exports['rsg-core']:GetCoreObject()

-- ──────────────────────────────────────────────────────────────────────────
-- DB
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS mike_benches (
            id         INT AUTO_INCREMENT PRIMARY KEY,
            owner_cid  VARCHAR(50) NOT NULL,
            x          FLOAT NOT NULL,
            y          FLOAT NOT NULL,
            z          FLOAT NOT NULL,
            heading    FLOAT NOT NULL DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
end)

-- In-memory list of active benches
local activeBenches = {}  -- id -> { owner_cid, x, y, z, heading }

-- Load benches from DB on start
CreateThread(function()
    Wait(2000)
    local rows = MySQL.query.await('SELECT * FROM mike_benches')
    for _, row in ipairs(rows or {}) do
        activeBenches[row.id] = { owner_cid = row.owner_cid, x = row.x, y = row.y, z = row.z, heading = row.heading }
    end
    -- Sync to all connected players
    for _, pid in ipairs(GetPlayers()) do
        syncBenchesToPlayer(tonumber(pid))
    end
end)

function syncBenchesToPlayer(src)
    local list = {}
    for id, b in pairs(activeBenches) do
        list[#list + 1] = { id = id, x = b.x, y = b.y, z = b.z, heading = b.heading }
    end
    TriggerClientEvent('mike-crafting:client:syncBenches', src, list)
end

AddEventHandler('playerJoining', function()
    syncBenchesToPlayer(source)
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Build bench from blueprint (useable item)
-- ──────────────────────────────────────────────────────────────────────────
RSGCore.Functions.CreateUseableItem('craftbench_blueprint', function(src, item)
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end

    -- Check inputs
    for inputItem, n in pairs(Config.BenchRecipe.inputs) do
        local have = exports['rsg-inventory']:GetItemByName(src, inputItem)
        if not have or have.amount < n then
            return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Need %d × %s'):format(n, inputItem) })
        end
    end

    -- Check player doesn't already have max benches placed
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    -- Remove inputs
    for inputItem, n in pairs(Config.BenchRecipe.inputs) do P.Functions.RemoveItem(inputItem, n) end

    -- Give portable_craftbench
    P.Functions.AddItem(Config.BenchRecipe.output, 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.BenchRecipe.output], 'add', 1)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Crafting bench built! Use it from inventory to place.' })
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Place bench (useable item)
-- ──────────────────────────────────────────────────────────────────────────
RSGCore.Functions.CreateUseableItem('portable_craftbench', function(src, item)
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    -- Remove item from inventory
    P.Functions.RemoveItem('portable_craftbench', 1)

    -- Save to DB
    local id = MySQL.insert.await('INSERT INTO mike_benches (owner_cid, x, y, z, heading) VALUES (?, ?, ?, ?, ?)',
        { P.PlayerData.citizenid, coords.x, coords.y, coords.z, heading })

    activeBenches[id] = { owner_cid = P.PlayerData.citizenid, x = coords.x, y = coords.y, z = coords.z, heading = heading }

    -- Broadcast to all clients
    for _, pid in ipairs(GetPlayers()) do
        TriggerClientEvent('mike-crafting:client:spawnBench', tonumber(pid), id, coords.x, coords.y, coords.z, heading)
    end

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Crafting bench placed!' })
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Pack up bench (anyone can use it, owner gets the item back)
-- ──────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mike-crafting:server:packBench', function(benchId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    local bench = activeBenches[benchId]
    if not bench then return end

    -- Only owner can pack up
    if bench.owner_cid ~= P.PlayerData.citizenid then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'This isn\'t your bench.' })
    end

    -- Remove from DB + memory
    MySQL.query('DELETE FROM mike_benches WHERE id = ?', { benchId })
    activeBenches[benchId] = nil

    -- Give item back
    P.Functions.AddItem('portable_craftbench', 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['portable_craftbench'], 'add', 1)

    -- Remove from all clients
    for _, pid in ipairs(GetPlayers()) do
        TriggerClientEvent('mike-crafting:client:removeBench', tonumber(pid), benchId)
    end

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Bench packed up.' })
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Pre-check: verify player has materials (before progress bar starts)
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-crafting:server:checkMaterials', function(source, benchId, recipeKey)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    if not activeBenches[benchId] then return false end
    local recipe = Config.Recipes[recipeKey]; if not recipe then return false end

    for item, n in pairs(recipe.inputs) do
        local have = exports['rsg-inventory']:GetItemByName(src, item)
        if not have or have.amount < n then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Need %d × %s'):format(n, item) })
            return false
        end
    end

    -- Check output limit before starting
    local qty = recipe.qty or 1
    local outputInfo = RSGCore.Shared.Items[recipe.output]
    if outputInfo and outputInfo.limit then
        local currentCount = 0
        for _, invItem in pairs(P.PlayerData.items or {}) do
            if invItem and invItem.name == recipe.output then
                currentCount = currentCount + (invItem.amount or 0)
            end
        end
        if currentCount + qty > outputInfo.limit then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Cannot carry more than %d × %s'):format(outputInfo.limit, outputInfo.label) })
            return false
        end
    end

    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Craft at bench
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-crafting:server:craft', function(source, benchId, recipeKey)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    if not activeBenches[benchId] then return false end

    local recipe = Config.Recipes[recipeKey]; if not recipe then return false end

    -- Verify inputs
    for item, n in pairs(recipe.inputs) do
        local have = exports['rsg-inventory']:GetItemByName(src, item)
        if not have or have.amount < n then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Need %d × %s'):format(n, item) })
            return false
        end
    end

    -- Check if player can receive the output before consuming inputs
    local qty = recipe.qty or 1
    local outputInfo = RSGCore.Shared.Items[recipe.output]
    if outputInfo and outputInfo.limit then
        local currentCount = 0
        for _, invItem in pairs(P.PlayerData.items or {}) do
            if invItem and invItem.name == recipe.output then
                currentCount = currentCount + (invItem.amount or 0)
            end
        end
        if currentCount + qty > outputInfo.limit then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Cannot carry more than %d × %s'):format(outputInfo.limit, outputInfo.label) })
            return false
        end
    end

    -- Consume inputs
    for item, n in pairs(recipe.inputs) do P.Functions.RemoveItem(item, n) end

    -- Give output
    P.Functions.AddItem(recipe.output, qty)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[recipe.output], 'add', qty)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Crafted %d × %s'):format(qty, recipe.output) })
    return true
end)
