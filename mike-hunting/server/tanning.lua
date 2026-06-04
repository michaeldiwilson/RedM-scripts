local RSGCore = exports['rsg-core']:GetCoreObject()

-- ──────────────────────────────────────────────────────────────────────────
-- DB
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS mike_tanning_racks (
            id         INT AUTO_INCREMENT PRIMARY KEY,
            owner_cid  VARCHAR(50) NOT NULL,
            x          FLOAT NOT NULL,
            y          FLOAT NOT NULL,
            z          FLOAT NOT NULL,
            heading    FLOAT NOT NULL DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS mike_tanning_pelts (
            id         INT AUTO_INCREMENT PRIMARY KEY,
            rack_id    INT NOT NULL,
            pelt_item  VARCHAR(50) NOT NULL,
            started_at INT NOT NULL,
            collected  TINYINT NOT NULL DEFAULT 0,
            FOREIGN KEY (rack_id) REFERENCES mike_tanning_racks(id) ON DELETE CASCADE
        )
    ]])
end)

-- In-memory racks
local racks = {}  -- id -> { owner_cid, x, y, z, heading, pelts = { {pelt_item, started_at, collected}, ... } }

local function loadRacks()
    local rackRows = MySQL.query.await('SELECT * FROM mike_tanning_racks')
    racks = {}
    for _, r in ipairs(rackRows or {}) do
        racks[r.id] = {
            id = r.id, owner_cid = r.owner_cid,
            x = r.x, y = r.y, z = r.z, heading = r.heading,
            pelts = {},
        }
    end
    local peltRows = MySQL.query.await('SELECT * FROM mike_tanning_pelts WHERE collected = 0')
    for _, p in ipairs(peltRows or {}) do
        if racks[p.rack_id] then
            racks[p.rack_id].pelts[#racks[p.rack_id].pelts + 1] = {
                id = p.id, pelt_item = p.pelt_item, started_at = p.started_at,
            }
        end
    end
end

local function broadcast()
    local data = {}
    for id, r in pairs(racks) do
        data[id] = { id = r.id, x = r.x, y = r.y, z = r.z, heading = r.heading, pelts = r.pelts }
    end
    for _, pid in ipairs(GetPlayers()) do
        TriggerClientEvent('mike-hunting:client:syncRacks', tonumber(pid), data)
    end
end

CreateThread(function()
    Wait(3000)
    loadRacks()
    broadcast()
end)

AddEventHandler('playerJoining', function()
    local src = source
    CreateThread(function()
        Wait(3000)
        local data = {}
        for id, r in pairs(racks) do
            data[id] = { id = r.id, x = r.x, y = r.y, z = r.z, heading = r.heading, pelts = r.pelts }
        end
        TriggerClientEvent('mike-hunting:client:syncRacks', src, data)
    end)
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Place rack (useable item)
-- ──────────────────────────────────────────────────────────────────────────
RSGCore.Functions.CreateUseableItem('tanning_rack', function(src, item)
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    P.Functions.RemoveItem('tanning_rack', 1)

    local id = MySQL.insert.await('INSERT INTO mike_tanning_racks (owner_cid, x, y, z, heading) VALUES (?, ?, ?, ?, ?)',
        { P.PlayerData.citizenid, coords.x, coords.y, coords.z, heading })

    racks[id] = {
        id = id, owner_cid = P.PlayerData.citizenid,
        x = coords.x, y = coords.y, z = coords.z, heading = heading,
        pelts = {},
    }
    broadcast()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Tanning rack placed!' })
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Hang pelt
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-hunting:server:hangPelt', function(source, rackId, peltItem)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local rack = racks[rackId]; if not rack then return false end

    -- Check slot limit
    if #rack.pelts >= Config.TanningSlots then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Rack is full (%d/%d)'):format(#rack.pelts, Config.TanningSlots) })
        return false
    end

    -- Check player has pelt + salt
    local have = exports['rsg-inventory']:GetItemByName(src, peltItem)
    if not have or have.amount < 1 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You don\'t have that pelt' })
        return false
    end

    local saltNeeded = (peltItem == 'bear_pelt' or peltItem == 'bison_pelt') and 2 or 1
    local haveSalt = exports['rsg-inventory']:GetItemByName(src, 'salt')
    if not haveSalt or haveSalt.amount < saltNeeded then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Need %d salt'):format(saltNeeded) })
        return false
    end

    P.Functions.RemoveItem(peltItem, 1)
    P.Functions.RemoveItem('salt', saltNeeded)

    local now = os.time()
    local peltId = MySQL.insert.await('INSERT INTO mike_tanning_pelts (rack_id, pelt_item, started_at) VALUES (?, ?, ?)',
        { rackId, peltItem, now })

    rack.pelts[#rack.pelts + 1] = { id = peltId, pelt_item = peltItem, started_at = now }
    broadcast()

    local leatherQty = Config.PeltLeather[peltItem] or 1
    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = ('Pelt hung! Will cure into %d leather in %d min'):format(leatherQty, math.ceil(Config.TanningCureTime / 60)),
    })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Collect cured leather
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-hunting:server:collectLeather', function(source, rackId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local rack = racks[rackId]; if not rack then return false end

    local now = os.time()
    local collected = 0
    local totalLeather = 0
    local remaining = {}

    for _, pelt in ipairs(rack.pelts) do
        if (now - pelt.started_at) >= Config.TanningCureTime then
            local qty = Config.PeltLeather[pelt.pelt_item] or 1
            totalLeather = totalLeather + qty
            collected = collected + 1
            MySQL.query('UPDATE mike_tanning_pelts SET collected = 1 WHERE id = ?', { pelt.id })
        else
            remaining[#remaining + 1] = pelt
        end
    end

    if collected == 0 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'No pelts ready yet' })
        return false
    end

    rack.pelts = remaining
    P.Functions.AddItem('leather', totalLeather)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['leather'], 'add', totalLeather)
    broadcast()

    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = ('Collected %d leather from %d cured pelt(s)'):format(totalLeather, collected),
    })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Pack up rack (owner only, must be empty)
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-hunting:server:packRack', function(source, rackId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local rack = racks[rackId]; if not rack then return false end

    if rack.owner_cid ~= P.PlayerData.citizenid then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not your rack' })
        return false
    end

    if #rack.pelts > 0 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Collect all pelts first' })
        return false
    end

    MySQL.query('DELETE FROM mike_tanning_racks WHERE id = ?', { rackId })
    racks[rackId] = nil

    P.Functions.AddItem('tanning_rack', 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['tanning_rack'], 'add', 1)
    broadcast()

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Rack packed up' })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Get rack status (for menu)
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-hunting:server:getRackInfo', function(source, rackId)
    local rack = racks[rackId]; if not rack then return nil end
    local now = os.time()
    local info = { pelts = {}, slots = Config.TanningSlots }
    for _, p in ipairs(rack.pelts) do
        local elapsed = now - p.started_at
        local ready = elapsed >= Config.TanningCureTime
        local remaining = ready and 0 or (Config.TanningCureTime - elapsed)
        local leatherQty = Config.PeltLeather[p.pelt_item] or 1
        info.pelts[#info.pelts + 1] = {
            pelt_item = p.pelt_item,
            ready = ready,
            remaining = remaining,
            leatherQty = leatherQty,
        }
    end
    return info
end)
