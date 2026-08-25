local RSGCore = exports['rsg-core']:GetCoreObject()

-- ──────────────────────────────────────────────────────────────────────────
-- DB: animals table (with ranch_id and scale for growth)
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS mike_ranch_animals (
            id           INT AUTO_INCREMENT PRIMARY KEY,
            ranch_id     INT DEFAULT NULL,
            type         VARCHAR(30) NOT NULL,
            name         VARCHAR(50) DEFAULT 'Animal',
            hunger       INT NOT NULL DEFAULT 100,
            thirst       INT NOT NULL DEFAULT 100,
            scale        FLOAT NOT NULL DEFAULT 0.5,
            x            FLOAT NOT NULL,
            y            FLOAT NOT NULL,
            z            FLOAT NOT NULL,
            heading      FLOAT NOT NULL DEFAULT 0,
            last_fed     INT NOT NULL,
            last_water   INT NOT NULL,
            last_produce INT NOT NULL,
            created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    -- Add scale column if upgrading from old version
    MySQL.query('ALTER TABLE mike_ranch_animals ADD COLUMN IF NOT EXISTS scale FLOAT NOT NULL DEFAULT 1.0')
    MySQL.query('ALTER TABLE mike_ranch_animals ADD COLUMN IF NOT EXISTS ranch_id INT DEFAULT NULL')
end)

-- ──────────────────────────────────────────────────────────────────────────
-- In-memory state
-- ──────────────────────────────────────────────────────────────────────────
local animals = {}

local function loadAnimals()
    local rows = MySQL.query.await('SELECT * FROM mike_ranch_animals')
    animals = {}
    for _, r in ipairs(rows or {}) do
        animals[r.id] = {
            id = r.id, ranch_id = r.ranch_id, type = r.type,
            name = r.name or 'Animal',
            hunger = r.hunger, thirst = r.thirst, scale = r.scale or 1.0,
            x = r.x, y = r.y, z = r.z, heading = r.heading,
            last_fed = r.last_fed, last_water = r.last_water,
            last_produce = r.last_produce,
        }
    end
end

local function broadcast()
    local data = {}
    for id, a in pairs(animals) do data[id] = a end
    for _, pid in ipairs(GetPlayers()) do
        TriggerClientEvent('mike-ranching:client:syncAnimals', tonumber(pid), data)
    end
end

CreateThread(function()
    Wait(3500)
    loadAnimals()
    broadcast()
end)

AddEventHandler('playerJoining', function()
    local src = source
    CreateThread(function()
        Wait(3000)
        local data = {}
        for id, a in pairs(animals) do data[id] = a end
        TriggerClientEvent('mike-ranching:client:syncAnimals', src, data)
    end)
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Growth + decay tick (every 60 seconds)
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    Wait(10000)
    while true do
        Wait(Config.Growth.TickRate)
        local changed = false

        for id, a in pairs(animals) do
            -- Hunger decay
            a.hunger = math.max(0, a.hunger - Config.HungerDecayPerTick)
            -- Thirst decay
            a.thirst = math.max(0, a.thirst - Config.ThirstDecayPerTick)

            -- Passive grazing: if animal is in pasture zone, slowly restore hunger
            if Config.PastureZone then
                local d = math.sqrt((a.x - Config.PastureZone.coords.x)^2 + (a.y - Config.PastureZone.coords.y)^2)
                if d <= Config.PastureZone.radius then
                    a.hunger = math.min(Config.MaxHunger, a.hunger + Config.PastureZone.restoreRate)
                end
            end

            -- Passive drinking: if animal is in water zone, slowly restore thirst
            if Config.WaterZone then
                local d = math.sqrt((a.x - Config.WaterZone.coords.x)^2 + (a.y - Config.WaterZone.coords.y)^2)
                if d <= Config.WaterZone.radius then
                    a.thirst = math.min(Config.MaxThirst, a.thirst + Config.WaterZone.restoreRate)
                end
            end

            -- Growth: only if fed enough
            if a.scale < Config.Growth.MaxScale and a.hunger >= Config.Growth.MinHungerToGrow then
                a.scale = math.min(Config.Growth.MaxScale, a.scale + Config.Growth.ScaleIncrease)
            end

            MySQL.query('UPDATE mike_ranch_animals SET hunger = ?, thirst = ?, scale = ? WHERE id = ?',
                { a.hunger, a.thirst, a.scale, id })
            changed = true
        end

        if changed then broadcast() end
    end
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Animal led to zone: update position in DB
-- ──────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mike-ranching:server:animalInZone', function(animalId, zoneType, x, y, z)
    local a = animals[animalId]; if not a then return end
    a.x = x; a.y = y; a.z = z
    MySQL.query('UPDATE mike_ranch_animals SET x = ?, y = ?, z = ? WHERE id = ?', { x, y, z, animalId })
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Buy animal (requires ranch access: head_rancher+)
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:buyAnimal', function(source, animalType)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local cid = P.PlayerData.citizenid

    if not HasPermission(cid, 'buy_animal') then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You don\'t have permission to buy animals' })
        return false
    end

    local typeDef = Config.AnimalTypes[animalType]; if not typeDef then return false end

    -- Count ranch animals
    local count = 0
    for _, a in pairs(animals) do
        if a.ranch_id and RanchData and a.ranch_id == RanchData.id then count = count + 1 end
    end
    if count >= Config.MaxAnimals then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Max %d animals'):format(Config.MaxAnimals) })
        return false
    end

    if P.PlayerData.money.cash < typeDef.price then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Need $%d'):format(typeDef.price) })
        return false
    end

    P.Functions.RemoveMoney('cash', typeDef.price)

    -- Spawn near the animal area with random offset
    local spawnCenter = Config.Ranch.animalArea or Config.Ranch.coords
    local rx = spawnCenter.x + math.random(-15, 15)
    local ry = spawnCenter.y + math.random(-15, 15)
    local rz = spawnCenter.z
    local now = os.time()

    local id = MySQL.insert.await(
        'INSERT INTO mike_ranch_animals (ranch_id, type, name, hunger, thirst, scale, x, y, z, heading, last_fed, last_water, last_produce) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { RanchData.id, animalType, typeDef.label, 100, 100, Config.Growth.StartScale, rx, ry, rz, math.random(0, 360), now, now, now }
    )

    animals[id] = {
        id = id, ranch_id = RanchData.id, type = animalType,
        name = typeDef.label, hunger = 100, thirst = 100, scale = Config.Growth.StartScale,
        x = rx, y = ry, z = rz, heading = math.random(0, 360),
        last_fed = now, last_water = now, last_produce = now,
    }

    broadcast()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Bought a baby %s for $%d'):format(typeDef.label, typeDef.price) })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Get animal info
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:getAnimalInfo', function(source, animalId)
    local a = animals[animalId]; if not a then return nil end
    local typeDef = Config.AnimalTypes[a.type]; if not typeDef then return nil end
    local now = os.time()
    local elapsed = now - a.last_produce
    local isGrown = a.scale >= Config.Growth.MinScaleToProduce
    local produceReady = isGrown and elapsed >= Config.ProduceTime and a.hunger > 20 and a.thirst > 20

    local growthPct = math.floor(((a.scale - Config.Growth.StartScale) / (Config.Growth.MaxScale - Config.Growth.StartScale)) * 100)

    return {
        id = a.id, type = a.type, name = a.name,
        hunger = a.hunger, thirst = a.thirst,
        scale = a.scale, growthPct = growthPct, isGrown = isGrown,
        produceReady = produceReady,
        produceLabel = typeDef.produce.label,
        produceRemaining = produceReady and 0 or math.max(0, Config.ProduceTime - elapsed),
    }
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Feed animal (hand+)
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:feedAnimal', function(source, animalId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local cid = P.PlayerData.citizenid

    if not HasPermission(cid, 'feed_water') then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'No ranch access' })
        return false
    end

    local a = animals[animalId]; if not a then return false end
    local typeDef = Config.AnimalTypes[a.type]; if not typeDef then return false end

    local have = exports['rsg-inventory']:GetItemByName(src, typeDef.feedItem)
    if not have or have.amount < typeDef.feedQty then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Need %dx %s'):format(typeDef.feedQty, typeDef.feedItem:gsub('_', ' ')) })
        return false
    end

    P.Functions.RemoveItem(typeDef.feedItem, typeDef.feedQty)
    a.hunger = math.min(Config.MaxHunger, a.hunger + typeDef.feedRestore)
    a.last_fed = os.time()
    MySQL.query('UPDATE mike_ranch_animals SET hunger = ?, last_fed = ? WHERE id = ?', { a.hunger, a.last_fed, animalId })
    broadcast()

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('%s fed! Hunger: %d%%'):format(a.name, a.hunger) })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Water animal (hand+)
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:waterAnimal', function(source, animalId)
    local src = source
    local cid = GetPlayerCid(src); if not cid then return false end

    if not HasPermission(cid, 'feed_water') then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'No ranch access' })
        return false
    end

    local a = animals[animalId]; if not a then return false end
    local typeDef = Config.AnimalTypes[a.type]; if not typeDef then return false end

    a.thirst = math.min(Config.MaxThirst, a.thirst + typeDef.waterRestore)
    a.last_water = os.time()
    MySQL.query('UPDATE mike_ranch_animals SET thirst = ?, last_water = ? WHERE id = ?', { a.thirst, a.last_water, animalId })
    broadcast()

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('%s watered! Thirst: %d%%'):format(a.name, a.thirst) })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Collect produce (hand+)
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:collectProduce', function(source, animalId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local cid = P.PlayerData.citizenid

    if not HasPermission(cid, 'collect_produce') then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'No ranch access' })
        return false
    end

    local a = animals[animalId]; if not a then return false end
    local typeDef = Config.AnimalTypes[a.type]; if not typeDef then return false end
    local now = os.time()

    if a.scale < Config.Growth.MinScaleToProduce then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Animal is not grown enough to produce' })
        return false
    end

    if (now - a.last_produce) < Config.ProduceTime then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not ready yet' })
        return false
    end

    if a.hunger <= 20 or a.thirst <= 20 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Animal is too hungry or thirsty' })
        return false
    end

    local produce = typeDef.produce
    P.Functions.AddItem(produce.item, produce.qty)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[produce.item], 'add', produce.qty)

    a.last_produce = now
    MySQL.query('UPDATE mike_ranch_animals SET last_produce = ? WHERE id = ?', { now, animalId })
    broadcast()

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Collected %dx %s'):format(produce.qty, produce.label) })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Sell animal (head_rancher+)
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:sellAnimal', function(source, animalId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local cid = P.PlayerData.citizenid

    if not HasPermission(cid, 'sell_animal') then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You don\'t have permission to sell animals' })
        return false
    end

    local a = animals[animalId]; if not a then return false end
    local typeDef = Config.AnimalTypes[a.type]
    local sellPrice = math.floor((typeDef and typeDef.price or 10) * 0.5 * a.scale)

    MySQL.query('DELETE FROM mike_ranch_animals WHERE id = ?', { animalId })
    animals[animalId] = nil

    P.Functions.AddMoney('cash', sellPrice)
    broadcast()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Sold %s for $%d'):format(a.name, sellPrice) })
    return true
end)
