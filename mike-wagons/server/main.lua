local RSGCore = exports['rsg-core']:GetCoreObject()

-- ──────────────────────────────────────────────────────────────────────────
-- DB
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS mike_wagons (
            id         INT AUTO_INCREMENT PRIMARY KEY,
            owner_cid  VARCHAR(50)  NOT NULL,
            type       VARCHAR(30)  NOT NULL,
            label      VARCHAR(100) NOT NULL,
            model      VARCHAR(50)  NOT NULL,
            stored     TINYINT      NOT NULL DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    -- After table exists, mark all wagons as stored (server restart = all garaged)
    MySQL.query('UPDATE mike_wagons SET stored = 1')
    spawnedWagons = {}
end)

-- Track which wagons are currently spawned: wagonId -> { netId, yardIdx }
local spawnedWagons = {}

-- ──────────────────────────────────────────────────────────────────────────
-- Register wagon kit items as useable (only works at a wagon yard)
-- ──────────────────────────────────────────────────────────────────────────
for typeKey, wtype in pairs(Config.WagonTypes) do
    RSGCore.Functions.CreateUseableItem(wtype.kit, function(src, item)
        local P = RSGCore.Functions.GetPlayer(src); if not P then return end
        local ped = GetPlayerPed(src)
        local pos = GetEntityCoords(ped)

        -- Must be near a wagon yard
        local nearYard = false
        for _, yard in ipairs(Config.Yards) do
            if #(pos - yard.coords) <= Config.YardRadius then
                nearYard = true
                break
            end
        end
        if not nearYard then
            return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You must be at a wagon yard to register a wagon.' })
        end

        -- Remove kit, create DB entry
        P.Functions.RemoveItem(wtype.kit, 1)
        local id = MySQL.insert.await('INSERT INTO mike_wagons (owner_cid, type, label, model) VALUES (?, ?, ?, ?)',
            { P.PlayerData.citizenid, typeKey, wtype.label, wtype.model })

        TriggerClientEvent('ox_lib:notify', src, {
            type = 'success',
            description = ('%s registered! Pull it out from the wagon yard.'):format(wtype.label),
        })
    end)
end

-- ──────────────────────────────────────────────────────────────────────────
-- Get player's wagons (for the yard menu)
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-wagons:server:getMyWagons', function(source)
    local P = RSGCore.Functions.GetPlayer(source); if not P then return {} end
    local rows = MySQL.query.await('SELECT * FROM mike_wagons WHERE owner_cid = ?', { P.PlayerData.citizenid })
    return rows or {}
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Pull out wagon
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-wagons:server:pullOut', function(source, wagonId, yardIdx)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end

    -- Verify ownership
    local rows = MySQL.query.await('SELECT * FROM mike_wagons WHERE id = ? AND owner_cid = ?',
        { wagonId, P.PlayerData.citizenid })
    if not rows or #rows == 0 then return false end
    local wagon = rows[1]

    if wagon.stored ~= 1 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Wagon is already out.' })
        return false
    end

    if spawnedWagons[wagonId] then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Wagon is already spawned.' })
        return false
    end

    local yard = Config.Yards[yardIdx]
    if not yard then return false end

    local wtype = Config.WagonTypes[wagon.type]
    if not wtype then return false end

    -- Mark as out
    MySQL.query('UPDATE mike_wagons SET stored = 0 WHERE id = ?', { wagonId })

    return {
        wagonId = wagonId,
        model   = wtype.model,
        label   = wtype.label,
        type    = wagon.type,
        spawn   = { x = yard.spawn.x, y = yard.spawn.y, z = yard.spawn.z, h = yard.spawn.w },
    }
end)

-- Client tells us the network ID after spawning
RegisterNetEvent('mike-wagons:server:setNetId', function(wagonId, netId)
    spawnedWagons[wagonId] = { netId = netId, owner = source }
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Store wagon
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-wagons:server:store', function(source, wagonId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end

    local rows = MySQL.query.await('SELECT * FROM mike_wagons WHERE id = ? AND owner_cid = ?',
        { wagonId, P.PlayerData.citizenid })
    if not rows or #rows == 0 then return false end

    MySQL.query('UPDATE mike_wagons SET stored = 1 WHERE id = ?', { wagonId })
    spawnedWagons[wagonId] = nil

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Wagon stored.' })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Wagon inventory stash (uses rsg-inventory stash system)
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-wagons:server:openStash', function(source, wagonId)
    local src = source
    local rows = MySQL.query.await('SELECT * FROM mike_wagons WHERE id = ?', { wagonId })
    if not rows or #rows == 0 then return false end
    local wagon = rows[1]
    local wtype = Config.WagonTypes[wagon.type]
    if not wtype then return false end

    local stashId = 'wagon_' .. wagonId
    exports['rsg-inventory']:OpenInventory(src, stashId, {
        maxweight = wtype.maxweight,
        slots     = wtype.slots,
    })
    return true
end)

