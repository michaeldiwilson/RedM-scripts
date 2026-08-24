local RSGCore = exports['rsg-core']:GetCoreObject()

-- ──────────────────────────────────────────────────────────────────────────
-- DB: create tables on start
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS mike_fishing_nets (
            id         INT AUTO_INCREMENT PRIMARY KEY,
            owner_cid  VARCHAR(50) NOT NULL,
            x          FLOAT NOT NULL,
            y          FLOAT NOT NULL,
            z          FLOAT NOT NULL,
            heading    FLOAT NOT NULL DEFAULT 0,
            placed_at  INT NOT NULL,
            baited     TINYINT NOT NULL DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
end)

-- ──────────────────────────────────────────────────────────────────────────
-- In-memory state
-- ──────────────────────────────────────────────────────────────────────────
local nets = {}  -- id -> { owner_cid, x, y, z, heading, placed_at, baited }

local function loadNets()
    local rows = MySQL.query.await('SELECT * FROM mike_fishing_nets')
    nets = {}
    for _, r in ipairs(rows or {}) do
        nets[r.id] = {
            id = r.id, owner_cid = r.owner_cid,
            x = r.x, y = r.y, z = r.z, heading = r.heading,
            placed_at = r.placed_at, baited = r.baited == 1,
        }
    end
end

local function broadcast()
    local data = {}
    for id, n in pairs(nets) do
        data[id] = { id = n.id, x = n.x, y = n.y, z = n.z, heading = n.heading, placed_at = n.placed_at, baited = n.baited }
    end
    for _, pid in ipairs(GetPlayers()) do
        TriggerClientEvent('mike-fishing:client:syncNets', tonumber(pid), data)
    end
end

CreateThread(function()
    Wait(3000)
    loadNets()
    broadcast()
end)

AddEventHandler('playerJoining', function()
    local src = source
    CreateThread(function()
        Wait(3000)
        local data = {}
        for id, n in pairs(nets) do
            data[id] = { id = n.id, x = n.x, y = n.y, z = n.z, heading = n.heading, placed_at = n.placed_at, baited = n.baited }
        end
        TriggerClientEvent('mike-fishing:client:syncNets', src, data)
    end)
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Place net (useable item)
-- ──────────────────────────────────────────────────────────────────────────
RSGCore.Functions.CreateUseableItem('fishing_net', function(src, item)
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end

    -- Check max nets
    local count = 0
    for _, n in pairs(nets) do
        if n.owner_cid == P.PlayerData.citizenid then count = count + 1 end
    end
    if count >= Config.MaxNets then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('You already have %d nets placed'):format(Config.MaxNets) })
    end

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    P.Functions.RemoveItem('fishing_net', 1)

    local now = os.time()
    local id = MySQL.insert.await('INSERT INTO mike_fishing_nets (owner_cid, x, y, z, heading, placed_at) VALUES (?, ?, ?, ?, ?, ?)',
        { P.PlayerData.citizenid, coords.x, coords.y, coords.z, heading, now })

    nets[id] = {
        id = id, owner_cid = P.PlayerData.citizenid,
        x = coords.x, y = coords.y, z = coords.z, heading = heading,
        placed_at = now, baited = false,
    }
    broadcast()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Fishing net placed! Come back later to collect.' })
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Get net status (for menu)
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-fishing:server:getNetInfo', function(source, netId)
    local net = nets[netId]; if not net then return nil end
    local now = os.time()
    local elapsed = now - net.placed_at
    local ready = elapsed >= Config.NetCycleTime
    local remaining = ready and 0 or (Config.NetCycleTime - elapsed)

    -- Calculate catch count
    local baseCatch = math.random(1, Config.NetSlots)
    if net.baited then baseCatch = math.min(baseCatch + 2, Config.NetSlots) end

    return {
        ready = ready,
        remaining = remaining,
        baited = net.baited,
        owner_cid = net.owner_cid,
    }
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Collect fish from net
-- ──────────────────────────────────────────────────────────────────────────
local function rollCatch()
    -- Weighted random pick from catch table
    local totalWeight = 0
    for _, entry in ipairs(Config.CatchTable) do
        totalWeight = totalWeight + entry.weight
    end
    local roll = math.random(1, totalWeight)
    local cumulative = 0
    for _, entry in ipairs(Config.CatchTable) do
        cumulative = cumulative + entry.weight
        if roll <= cumulative then
            return entry.item, entry.label
        end
    end
    return Config.CatchTable[1].item, Config.CatchTable[1].label
end

lib.callback.register('mike-fishing:server:collectFish', function(source, netId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local net = nets[netId]; if not net then return false end

    local now = os.time()
    if (now - net.placed_at) < Config.NetCycleTime then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Net is not ready yet' })
        return false
    end

    -- Roll catches
    local catchCount = math.random(2, Config.NetSlots)
    if net.baited then catchCount = math.min(catchCount + 2, Config.NetSlots + 2) end

    local caught = {}
    for i = 1, catchCount do
        local item, label = rollCatch()
        P.Functions.AddItem(item, 1)
        caught[label] = (caught[label] or 0) + 1
    end

    -- Build summary
    local parts = {}
    for label, qty in pairs(caught) do
        parts[#parts + 1] = qty .. '× ' .. label
    end

    -- Reset net timer
    net.placed_at = now
    net.baited = false
    MySQL.query('UPDATE mike_fishing_nets SET placed_at = ?, baited = 0 WHERE id = ?', { now, netId })
    broadcast()

    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        title = 'Fish Collected!',
        description = table.concat(parts, ', '),
        duration = 6000,
    })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Bait the net
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-fishing:server:baitNet', function(source, netId, baitItem)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local net = nets[netId]; if not net then return false end

    if net.baited then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Net is already baited' })
        return false
    end

    local have = exports['rsg-inventory']:GetItemByName(src, baitItem)
    if not have or have.amount < 1 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You don\'t have that bait' })
        return false
    end

    P.Functions.RemoveItem(baitItem, 1)
    net.baited = true
    MySQL.query('UPDATE mike_fishing_nets SET baited = 1 WHERE id = ?', { netId })
    broadcast()

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Net baited! Better catch next collection.' })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Pick up net (owner only)
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-fishing:server:pickupNet', function(source, netId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local net = nets[netId]; if not net then return false end

    if net.owner_cid ~= P.PlayerData.citizenid then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not your net' })
        return false
    end

    MySQL.query('DELETE FROM mike_fishing_nets WHERE id = ?', { netId })
    nets[netId] = nil

    P.Functions.AddItem('fishing_net', 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['fishing_net'], 'add', 1)
    broadcast()

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Net picked up' })
    return true
end)
