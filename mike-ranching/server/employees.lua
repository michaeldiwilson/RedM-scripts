local RSGCore = exports['rsg-core']:GetCoreObject()

-- ──────────────────────────────────────────────────────────────────────────
-- DB: ranch ownership + employees
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS mike_ranches (
            id           INT AUTO_INCREMENT PRIMARY KEY,
            owner_cid    VARCHAR(50) NOT NULL,
            ranch_key    VARCHAR(30) NOT NULL,
            purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS mike_ranch_zones (
            id         INT AUTO_INCREMENT PRIMARY KEY,
            ranch_id   INT NOT NULL,
            zone_type  VARCHAR(20) NOT NULL,
            x          FLOAT NOT NULL,
            y          FLOAT NOT NULL,
            z          FLOAT NOT NULL,
            FOREIGN KEY (ranch_id) REFERENCES mike_ranches(id) ON DELETE CASCADE
        )
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS mike_ranch_employees (
            id            INT AUTO_INCREMENT PRIMARY KEY,
            ranch_id      INT NOT NULL,
            employee_cid  VARCHAR(50) NOT NULL,
            rank          VARCHAR(20) NOT NULL DEFAULT 'hand',
            hired_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (ranch_id) REFERENCES mike_ranches(id) ON DELETE CASCADE
        )
    ]])
end)

-- ──────────────────────────────────────────────────────────────────────────
-- In-memory ranch state
-- ──────────────────────────────────────────────────────────────────────────
RanchData = nil  -- { id, owner_cid, ranch_key }
RanchEmployees = {}  -- { { id, employee_cid, rank }, ... }
RanchZones = {}  -- { pasture = {x,y,z} or nil, water = {x,y,z} or nil }

function LoadRanch()
    local rows = MySQL.query.await('SELECT * FROM mike_ranches WHERE ranch_key = ?', { Config.Ranch.key })
    if rows and #rows > 0 then
        RanchData = rows[1]
        local empRows = MySQL.query.await('SELECT * FROM mike_ranch_employees WHERE ranch_id = ?', { RanchData.id })
        RanchEmployees = empRows or {}

        -- Load zones
        RanchZones = {}
        local zoneRows = MySQL.query.await('SELECT * FROM mike_ranch_zones WHERE ranch_id = ?', { RanchData.id })
        for _, z in ipairs(zoneRows or {}) do
            RanchZones[z.zone_type] = { x = z.x, y = z.y, z = z.z }
        end
    else
        RanchData = nil
        RanchEmployees = {}
        RanchZones = {}
    end
end

CreateThread(function()
    Wait(2000)
    LoadRanch()
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Access control: returns rank level or 0 if no access
-- ──────────────────────────────────────────────────────────────────────────
function GetRanchRank(citizenid)
    if not RanchData then return 0 end
    -- Owner
    if RanchData.owner_cid == citizenid then
        return Config.Ranks.owner.level
    end
    -- Employee
    for _, emp in ipairs(RanchEmployees) do
        if emp.employee_cid == citizenid then
            local rankDef = Config.Ranks[emp.rank]
            return rankDef and rankDef.level or 0
        end
    end
    return 0
end

function HasPermission(citizenid, action)
    local level = GetRanchRank(citizenid)
    local required = Config.Permissions[action] or 99
    return level >= required
end

function GetPlayerCid(src)
    local P = RSGCore.Functions.GetPlayer(src)
    return P and P.PlayerData.citizenid or nil
end

-- ──────────────────────────────────────────────────────────────────────────
-- Buy ranch
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:buyRanch', function(source)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end

    if RanchData then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'This ranch already has an owner' })
        return false
    end

    if P.PlayerData.money.cash < Config.Ranch.price then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Need $%d'):format(Config.Ranch.price) })
        return false
    end

    P.Functions.RemoveMoney('cash', Config.Ranch.price)

    local id = MySQL.insert.await('INSERT INTO mike_ranches (owner_cid, ranch_key) VALUES (?, ?)',
        { P.PlayerData.citizenid, Config.Ranch.key })

    RanchData = { id = id, owner_cid = P.PlayerData.citizenid, ranch_key = Config.Ranch.key }
    RanchEmployees = {}

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', title = 'Ranch Purchased!', description = ('Welcome to %s!'):format(Config.Ranch.name), duration = 6000 })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Sell ranch
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:sellRanch', function(source)
    local src = source
    local cid = GetPlayerCid(src); if not cid then return false end
    if not RanchData or RanchData.owner_cid ~= cid then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You don\'t own this ranch' })
        return false
    end

    local P = RSGCore.Functions.GetPlayer(src)
    MySQL.query('DELETE FROM mike_ranch_employees WHERE ranch_id = ?', { RanchData.id })
    MySQL.query('DELETE FROM mike_ranches WHERE id = ?', { RanchData.id })

    P.Functions.AddMoney('cash', Config.Ranch.sellBack)
    RanchData = nil
    RanchEmployees = {}

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Ranch sold for $%d'):format(Config.Ranch.sellBack) })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Check ranch status
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:getRanchStatus', function(source)
    local src = source
    local cid = GetPlayerCid(src)
    if not cid then return nil end

    local rank = GetRanchRank(cid)
    local rankLabel = 'None'
    for name, def in pairs(Config.Ranks) do
        if def.level == rank then rankLabel = def.label; break end
    end

    return {
        owned = RanchData ~= nil,
        ownerCid = RanchData and RanchData.owner_cid or nil,
        ranchId = RanchData and RanchData.id or nil,
        playerRank = rank,
        playerRankLabel = rankLabel,
        price = Config.Ranch.price,
    }
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Hire employee (owner only, select nearby player)
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:hireEmployee', function(source, targetSrc)
    local src = source
    local cid = GetPlayerCid(src); if not cid then return false end
    if not HasPermission(cid, 'hire_fire') then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only the owner can hire' })
        return false
    end

    local targetP = RSGCore.Functions.GetPlayer(tonumber(targetSrc))
    if not targetP then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return false
    end
    local targetCid = targetP.PlayerData.citizenid

    -- Check not already employed
    for _, emp in ipairs(RanchEmployees) do
        if emp.employee_cid == targetCid then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Already employed here' })
            return false
        end
    end

    local empId = MySQL.insert.await('INSERT INTO mike_ranch_employees (ranch_id, employee_cid, rank) VALUES (?, ?, ?)',
        { RanchData.id, targetCid, 'hand' })

    RanchEmployees[#RanchEmployees + 1] = { id = empId, employee_cid = targetCid, rank = 'hand' }

    local name = targetP.PlayerData.charinfo.firstname .. ' ' .. targetP.PlayerData.charinfo.lastname
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Hired %s as Ranch Hand'):format(name) })
    TriggerClientEvent('ox_lib:notify', tonumber(targetSrc), { type = 'success', title = 'Hired!', description = ('You are now a Ranch Hand at %s'):format(Config.Ranch.name), duration = 5000 })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Fire employee
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:fireEmployee', function(source, empCid)
    local src = source
    local cid = GetPlayerCid(src); if not cid then return false end
    if not HasPermission(cid, 'hire_fire') then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only the owner can fire' })
        return false
    end

    MySQL.query('DELETE FROM mike_ranch_employees WHERE ranch_id = ? AND employee_cid = ?', { RanchData.id, empCid })

    for i, emp in ipairs(RanchEmployees) do
        if emp.employee_cid == empCid then
            table.remove(RanchEmployees, i)
            break
        end
    end

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Employee fired' })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Promote / Demote
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:setEmployeeRank', function(source, empCid, newRank)
    local src = source
    local cid = GetPlayerCid(src); if not cid then return false end
    if not HasPermission(cid, 'hire_fire') then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only the owner can change ranks' })
        return false
    end
    if not Config.Ranks[newRank] then return false end

    MySQL.query('UPDATE mike_ranch_employees SET rank = ? WHERE ranch_id = ? AND employee_cid = ?',
        { newRank, RanchData.id, empCid })

    for _, emp in ipairs(RanchEmployees) do
        if emp.employee_cid == empCid then
            emp.rank = newRank
            break
        end
    end

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Rank changed to %s'):format(Config.Ranks[newRank].label) })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Get employee list (for menu)
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:getEmployees', function(source)
    local employees = {}
    for _, emp in ipairs(RanchEmployees) do
        -- Try to get player name from DB
        local charRows = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ?', { emp.employee_cid })
        local name = emp.employee_cid
        if charRows and #charRows > 0 and charRows[1].charinfo then
            local charinfo = json.decode(charRows[1].charinfo)
            if charinfo then
                name = (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')
            end
        end
        employees[#employees + 1] = {
            cid  = emp.employee_cid,
            name = name,
            rank = emp.rank,
            rankLabel = Config.Ranks[emp.rank] and Config.Ranks[emp.rank].label or emp.rank,
        }
    end
    return employees
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Set pasture/water zone (owner places at their current position)
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:setZone', function(source, zoneType)
    local src = source
    local cid = GetPlayerCid(src); if not cid then return false end
    if not HasPermission(cid, 'hire_fire') then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only the owner can set zones' })
        return false
    end
    if zoneType ~= 'pasture' and zoneType ~= 'water' then return false end

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)

    -- Remove old zone of this type
    MySQL.query('DELETE FROM mike_ranch_zones WHERE ranch_id = ? AND zone_type = ?', { RanchData.id, zoneType })

    -- Insert new
    MySQL.insert.await('INSERT INTO mike_ranch_zones (ranch_id, zone_type, x, y, z) VALUES (?, ?, ?, ?, ?)',
        { RanchData.id, zoneType, coords.x, coords.y, coords.z })

    RanchZones[zoneType] = { x = coords.x, y = coords.y, z = coords.z }

    local label = zoneType == 'pasture' and 'Pasture' or 'Water'
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('%s zone set at your location'):format(label) })
    return true
end)

-- Get zones (for client)
lib.callback.register('mike-ranching:server:getZones', function(source)
    return RanchZones
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Get nearby players (for hire menu)
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:getNearbyPlayers', function(source)
    local src = source
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local nearby = {}

    for _, pid in ipairs(GetPlayers()) do
        pid = tonumber(pid)
        if pid ~= src then
            local tPed = GetPlayerPed(pid)
            if tPed and DoesEntityExist(tPed) then
                local tCoords = GetEntityCoords(tPed)
                if #(coords - tCoords) <= 10.0 then
                    local P = RSGCore.Functions.GetPlayer(pid)
                    if P then
                        local name = P.PlayerData.charinfo.firstname .. ' ' .. P.PlayerData.charinfo.lastname
                        nearby[#nearby + 1] = { src = pid, name = name, cid = P.PlayerData.citizenid }
                    end
                end
            end
        end
    end
    return nearby
end)
