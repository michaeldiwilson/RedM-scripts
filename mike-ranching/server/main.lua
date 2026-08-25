local RSGCore = exports['rsg-core']:GetCoreObject()

-- ──────────────────────────────────────────────────────────────────────────
-- DB
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS mike_ranch_animals (
            id          INT AUTO_INCREMENT PRIMARY KEY,
            owner_cid   VARCHAR(50) NOT NULL,
            type        VARCHAR(30) NOT NULL,
            name        VARCHAR(50) DEFAULT 'Animal',
            hunger      INT NOT NULL DEFAULT 100,
            thirst      INT NOT NULL DEFAULT 100,
            x           FLOAT NOT NULL,
            y           FLOAT NOT NULL,
            z           FLOAT NOT NULL,
            heading     FLOAT NOT NULL DEFAULT 0,
            last_fed    INT NOT NULL,
            last_water  INT NOT NULL,
            last_produce INT NOT NULL,
            created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
end)

-- ──────────────────────────────────────────────────────────────────────────
-- In-memory state
-- ──────────────────────────────────────────────────────────────────────────
local animals = {}  -- id -> data

local function loadAnimals()
    local rows = MySQL.query.await('SELECT * FROM mike_ranch_animals')
    animals = {}
    for _, r in ipairs(rows or {}) do
        animals[r.id] = {
            id = r.id, owner_cid = r.owner_cid, type = r.type,
            name = r.name or 'Animal',
            hunger = r.hunger, thirst = r.thirst,
            x = r.x, y = r.y, z = r.z, heading = r.heading,
            last_fed = r.last_fed, last_water = r.last_water,
            last_produce = r.last_produce,
        }
    end
end

local function broadcast()
    local data = {}
    for id, a in pairs(animals) do
        data[id] = a
    end
    for _, pid in ipairs(GetPlayers()) do
        TriggerClientEvent('mike-ranching:client:syncAnimals', tonumber(pid), data)
    end
end

CreateThread(function()
    Wait(3000)
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
-- Hunger/thirst decay + produce timer (runs every 60 seconds)
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    Wait(10000)
    while true do
        Wait(60000)
        local now = os.time()
        local changed = false

        for id, a in pairs(animals) do
            local typeDef = Config.AnimalTypes[a.type]
            if not typeDef then goto nextAnimal end

            -- Decay hunger
            if (now - a.last_fed) >= Config.HungerRate then
                local decay = math.floor((now - a.last_fed) / Config.HungerRate)
                a.hunger = math.max(0, a.hunger - decay)
                a.last_fed = now
                changed = true
            end

            -- Decay thirst
            if (now - a.last_water) >= Config.ThirstRate then
                local decay = math.floor((now - a.last_water) / Config.ThirstRate)
                a.thirst = math.max(0, a.thirst - decay)
                a.last_water = now
                changed = true
            end

            -- Save to DB periodically
            MySQL.query('UPDATE mike_ranch_animals SET hunger = ?, thirst = ?, last_fed = ?, last_water = ? WHERE id = ?',
                { a.hunger, a.thirst, a.last_fed, a.last_water, id })

            ::nextAnimal::
        end

        if changed then broadcast() end
    end
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Buy animal from trader
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:buyAnimal', function(source, animalType)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local typeDef = Config.AnimalTypes[animalType]; if not typeDef then return false end

    -- Check max animals
    local count = 0
    for _, a in pairs(animals) do
        if a.owner_cid == P.PlayerData.citizenid then count = count + 1 end
    end
    if count >= Config.MaxAnimals then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Max %d animals'):format(Config.MaxAnimals) })
        return false
    end

    -- Check money
    if P.PlayerData.money.cash < typeDef.price then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Need $%d'):format(typeDef.price) })
        return false
    end

    P.Functions.RemoveMoney('cash', typeDef.price)

    -- Place near the trader
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local now = os.time()

    local id = MySQL.insert.await(
        'INSERT INTO mike_ranch_animals (owner_cid, type, name, hunger, thirst, x, y, z, heading, last_fed, last_water, last_produce) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { P.PlayerData.citizenid, animalType, typeDef.label, 100, 100, coords.x, coords.y, coords.z, heading, now, now, now }
    )

    animals[id] = {
        id = id, owner_cid = P.PlayerData.citizenid, type = animalType,
        name = typeDef.label, hunger = 100, thirst = 100,
        x = coords.x, y = coords.y, z = coords.z, heading = heading,
        last_fed = now, last_water = now, last_produce = now,
    }

    broadcast()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Bought a %s for $%d'):format(typeDef.label, typeDef.price) })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Get animal info (for menu)
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:getAnimalInfo', function(source, animalId)
    local a = animals[animalId]; if not a then return nil end
    local typeDef = Config.AnimalTypes[a.type]; if not typeDef then return nil end
    local now = os.time()
    local elapsed = now - a.last_produce
    local produceReady = elapsed >= Config.ProduceTime and a.hunger > 20 and a.thirst > 20

    return {
        id = a.id,
        type = a.type,
        name = a.name,
        hunger = a.hunger,
        thirst = a.thirst,
        produceReady = produceReady,
        produceLabel = typeDef.produce.label,
        produceRemaining = produceReady and 0 or math.max(0, Config.ProduceTime - elapsed),
        owner_cid = a.owner_cid,
    }
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Feed animal
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:feedAnimal', function(source, animalId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local a = animals[animalId]; if not a then return false end
    local typeDef = Config.AnimalTypes[a.type]; if not typeDef then return false end

    local have = exports['rsg-inventory']:GetItemByName(src, typeDef.feedItem)
    if not have or have.amount < typeDef.feedQty then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Need %dx %s'):format(typeDef.feedQty, typeDef.feedItem) })
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
-- Water animal
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:waterAnimal', function(source, animalId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local a = animals[animalId]; if not a then return false end
    local typeDef = Config.AnimalTypes[a.type]; if not typeDef then return false end

    -- Water is free (from well/trough)
    a.thirst = math.min(Config.MaxThirst, a.thirst + typeDef.waterRestore)
    a.last_water = os.time()
    MySQL.query('UPDATE mike_ranch_animals SET thirst = ?, last_water = ? WHERE id = ?', { a.thirst, a.last_water, animalId })
    broadcast()

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('%s watered! Thirst: %d%%'):format(a.name, a.thirst) })
    return true
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Collect produce
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:collectProduce', function(source, animalId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local a = animals[animalId]; if not a then return false end
    local typeDef = Config.AnimalTypes[a.type]; if not typeDef then return false end

    local now = os.time()
    if (now - a.last_produce) < Config.ProduceTime then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not ready yet' })
        return false
    end

    if a.hunger <= 20 or a.thirst <= 20 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Animal is too hungry or thirsty to produce' })
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
-- Sell/release animal
-- ──────────────────────────────────────────────────────────────────────────
lib.callback.register('mike-ranching:server:sellAnimal', function(source, animalId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return false end
    local a = animals[animalId]; if not a then return false end
    if a.owner_cid ~= P.PlayerData.citizenid then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not your animal' })
        return false
    end
    local typeDef = Config.AnimalTypes[a.type]
    local sellPrice = math.floor((typeDef and typeDef.price or 10) * 0.5)

    MySQL.query('DELETE FROM mike_ranch_animals WHERE id = ?', { animalId })
    animals[animalId] = nil

    P.Functions.AddMoney('cash', sellPrice)
    broadcast()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Sold %s for $%d'):format(a.name, sellPrice) })
    return true
end)
