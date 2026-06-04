local RSGCore = exports['rsg-core']:GetCoreObject()

-- ──────────────────────────────────────────────────────────────────────────
-- DB
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS mike_land_claims (
            id         INT AUTO_INCREMENT PRIMARY KEY,
            owner_cid  VARCHAR(50)  NOT NULL,
            claim_type VARCHAR(20)  NOT NULL,
            x          FLOAT NOT NULL,
            y          FLOAT NOT NULL,
            z          FLOAT NOT NULL,
            radius     FLOAT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS mike_land_objects (
            id         INT AUTO_INCREMENT PRIMARY KEY,
            claim_id   INT          NOT NULL,
            owner_cid  VARCHAR(50)  NOT NULL,
            obj_type   VARCHAR(30)  NOT NULL,
            prop       VARCHAR(100) NOT NULL,
            x          FLOAT NOT NULL,
            y          FLOAT NOT NULL,
            z          FLOAT NOT NULL,
            heading    FLOAT NOT NULL DEFAULT 0,
            FOREIGN KEY (claim_id) REFERENCES mike_land_claims(id) ON DELETE CASCADE
        )
    ]])
end)

-- In-memory state
local claims = {}    -- id -> { owner_cid, claim_type, x, y, z, radius, objects = {} }
local onlineOwners = {}  -- citizenid -> src

local function loadClaims()
    local rows = MySQL.query.await('SELECT * FROM mike_land_claims')
    claims = {}
    for _, r in ipairs(rows or {}) do
        claims[r.id] = {
            id = r.id, owner_cid = r.owner_cid, claim_type = r.claim_type,
            x = r.x, y = r.y, z = r.z, radius = r.radius,
            objects = {},
        }
    end
    local objRows = MySQL.query.await('SELECT * FROM mike_land_objects')
    for _, o in ipairs(objRows or {}) do
        if claims[o.claim_id] then
            claims[o.claim_id].objects[o.id] = {
                id = o.id, obj_type = o.obj_type, prop = o.prop,
                x = o.x, y = o.y, z = o.z, heading = o.heading,
            }
        end
    end
end

-- Send claims + objects to a player (only show objects for online owners)
local function syncToPlayer(src)
    local data = {}
    for id, c in pairs(claims) do
        local ownerOnline = onlineOwners[c.owner_cid] ~= nil
        data[id] = {
            id = c.id, owner_cid = c.owner_cid, claim_type = c.claim_type,
            x = c.x, y = c.y, z = c.z, radius = c.radius,
            objects = ownerOnline and c.objects or {},
            ownerOnline = ownerOnline,
        }
    end
    TriggerClientEvent('mike-property:client:sync', src, data)
end

local function broadcastAll()
    for _, pid in ipairs(GetPlayers()) do
        syncToPlayer(tonumber(pid))
    end
end

CreateThread(function()
    Wait(3000)
    loadClaims()
end)

-- Track online players
AddEventHandler('playerJoining', function()
    local src = source
    CreateThread(function()
        Wait(5000)
        local P = RSGCore.Functions.GetPlayer(src)
        if P then
            onlineOwners[P.PlayerData.citizenid] = src
            broadcastAll()
        end
    end)
end)

AddEventHandler('playerDropped', function()
    local src = source
    -- Find and remove from online owners
    for cid, sid in pairs(onlineOwners) do
        if sid == src then
            onlineOwners[cid] = nil
            break
        end
    end
    broadcastAll()
end)

-- Also handle RSGCore player loaded event
RegisterNetEvent('RSGCore:Server:OnPlayerLoaded', function()
    local src = source
    CreateThread(function()
        Wait(3000)
        local P = RSGCore.Functions.GetPlayer(src)
        if P then
            onlineOwners[P.PlayerData.citizenid] = src
            broadcastAll()
        end
    end)
end)

AddEventHandler('onResourceStart', function(r)
    if r ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(4000)
        loadClaims()
        for _, pid in ipairs(GetPlayers()) do
            local P = RSGCore.Functions.GetPlayer(tonumber(pid))
            if P then
                onlineOwners[P.PlayerData.citizenid] = tonumber(pid)
            end
        end
        broadcastAll()
    end)
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Get player's claims
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-property:server:getMyClaims', function(source)
    local P = RSGCore.Functions.GetPlayer(source); if not P then return {} end
    local list = {}
    for id, c in pairs(claims) do
        if c.owner_cid == P.PlayerData.citizenid then
            list[#list + 1] = { id = c.id, claim_type = c.claim_type, x = c.x, y = c.y, z = c.z, radius = c.radius }
        end
    end
    return list
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Buy deed at land office
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-property:server:buyDeed', function(source, claimType)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local ct = Config.ClaimTypes[claimType]; if not ct then return false end

    local cash = P.PlayerData.money.cash or 0
    if cash < ct.price then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Need $%d, you have $%d'):format(ct.price, cash) })
        return false
    end

    P.Functions.RemoveMoney('cash', ct.price)
    P.Functions.AddItem(ct.deed, 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[ct.deed], 'add', 1)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Bought %s for $%d. Use it from inventory where you want to claim.'):format(ct.label, ct.price) })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Use deed item to claim land at current position
-- ──────────────────────────────────────────────────────────────────────────
for typeKey, ct in pairs(Config.ClaimTypes) do
    RSGCore.Functions.CreateUseableItem(ct.deed, function(src, item)
        local P = RSGCore.Functions.GetPlayer(src); if not P then return end
        local ped = GetPlayerPed(src)
        local coords = GetEntityCoords(ped)

        -- Check max claims
        local myCount = 0
        for _, c in pairs(claims) do
            if c.owner_cid == P.PlayerData.citizenid then myCount = myCount + 1 end
        end
        if myCount >= Config.MaxClaimsPerPlayer then
            return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Max %d claims reached'):format(Config.MaxClaimsPerPlayer) })
        end

        -- Check distance from towns
        for _, town in ipairs(Config.TownCenters) do
            local d = #(vector3(coords.x, coords.y, coords.z) - town.coords)
            if d <= town.radius then
                return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Too close to ' .. town.name })
            end
        end

        -- Check distance from other claims
        for _, c in pairs(claims) do
            local d = #(vector3(coords.x, coords.y, coords.z) - vector3(c.x, c.y, c.z))
            if d <= Config.MinClaimDistance + c.radius then
                return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Too close to another claim' })
            end
        end

        -- Consume deed
        P.Functions.RemoveItem(ct.deed, 1)

        local id = MySQL.insert.await('INSERT INTO mike_land_claims (owner_cid, claim_type, x, y, z, radius) VALUES (?, ?, ?, ?, ?, ?)',
            { P.PlayerData.citizenid, typeKey, coords.x, coords.y, coords.z, ct.radius })

        claims[id] = {
            id = id, owner_cid = P.PlayerData.citizenid, claim_type = typeKey,
            x = coords.x, y = coords.y, z = coords.z, radius = ct.radius,
            objects = {},
        }

        broadcastAll()
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ct.label .. ' claimed! Press B to build.' })
    end)
end

-- ──────────────────────────────────────────────────────────────────────────
-- Abandon claim
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-property:server:abandon', function(source, claimId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local claim = claims[claimId]; if not claim then return false end
    if claim.owner_cid ~= P.PlayerData.citizenid then return false end

    MySQL.query('DELETE FROM mike_land_claims WHERE id = ?', { claimId })
    claims[claimId] = nil
    broadcastAll()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Land claim abandoned' })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Place object on land
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-property:server:placeObject', function(source, claimId, objType, coords, heading)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local claim = claims[claimId]; if not claim then return false end
    if claim.owner_cid ~= P.PlayerData.citizenid then return false end

    local placeable = Config.Placeables[objType]; if not placeable then return false end

    -- Check within claim radius
    local d = #(vector3(coords.x, coords.y, coords.z) - vector3(claim.x, claim.y, claim.z))
    if d > claim.radius then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Outside your claim boundary' })
        return false
    end

    -- Check limit
    local count = 0
    for _, obj in pairs(claim.objects) do
        if obj.obj_type == objType then count = count + 1 end
    end
    if count >= placeable.limit then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Max %d %s per claim'):format(placeable.limit, placeable.label) })
        return false
    end

    -- Check materials
    for item, n in pairs(placeable.recipe) do
        local have = exports['rsg-inventory']:GetItemByName(src, item)
        if not have or have.amount < n then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Need %d × %s'):format(n, item) })
            return false
        end
    end

    -- Consume materials
    for item, n in pairs(placeable.recipe) do P.Functions.RemoveItem(item, n) end

    local objId = MySQL.insert.await('INSERT INTO mike_land_objects (claim_id, owner_cid, obj_type, prop, x, y, z, heading) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        { claimId, P.PlayerData.citizenid, objType, placeable.prop, coords.x, coords.y, coords.z, heading })

    claim.objects[objId] = {
        id = objId, obj_type = objType, prop = placeable.prop,
        x = coords.x, y = coords.y, z = coords.z, heading = heading,
    }

    broadcastAll()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = placeable.label .. ' placed!' })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Remove object from land
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-property:server:removeObject', function(source, claimId, objId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local claim = claims[claimId]; if not claim then return false end
    if claim.owner_cid ~= P.PlayerData.citizenid then return false end
    local obj = claim.objects[objId]; if not obj then return false end

    -- Refund materials
    local placeable = Config.Placeables[obj.obj_type]
    if placeable and placeable.recipe then
        for item, n in pairs(placeable.recipe) do
            P.Functions.AddItem(item, n)
            TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'add', n)
        end
    end

    MySQL.query('DELETE FROM mike_land_objects WHERE id = ?', { objId })
    claim.objects[objId] = nil
    broadcastAll()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Object removed — materials refunded' })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Open storage stash on claimed land
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-property:server:openStash', function(source, objId)
    local src = source
    -- Find the object
    for _, claim in pairs(claims) do
        local obj = claim.objects[objId]
        if obj then
            local placeable = Config.Placeables[obj.obj_type]
            if placeable and placeable.stash then
                local stashId = 'property_stash_' .. objId
                exports['rsg-inventory']:OpenInventory(src, stashId, {
                    maxweight = placeable.stashWeight,
                    slots     = placeable.stashSlots,
                })
                return true
            end
        end
    end
    return false
end)
