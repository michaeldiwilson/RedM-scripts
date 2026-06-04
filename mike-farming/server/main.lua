local RSGCore = exports['rsg-core']:GetCoreObject()
local crops   = {}   -- id -> row

local function broadcast()
    TriggerClientEvent('mike-farming:client:sync', -1, crops)
end

local function loadAll()
    local rows = MySQL.query.await('SELECT * FROM mike_crops WHERE harvested = 0', {})
    crops = {}
    for _, r in ipairs(rows or {}) do crops[r.id] = r end
    broadcast()
end

AddEventHandler('onResourceStart', function(r)
    if r == GetCurrentResourceName() then CreateThread(function() Wait(2000); loadAll() end) end
end)

AddEventHandler('playerJoining', function()
    local src = source
    CreateThread(function() Wait(3000); TriggerClientEvent('mike-farming:client:sync', src, crops) end)
end)

local function countPlayerCrops(cid)
    local n = 0
    for _, c in pairs(crops) do
        if c.owner_cid == cid and c.harvested == 0 then n = n + 1 end
    end
    return n
end

RegisterNetEvent('mike-farming:server:plant', function(cropType, coords)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src)
    if not P then return end
    local def = Config.CropTypes[cropType]
    if not def then return end

    -- Verify inventory has hoe + seed
    local hoe = exports['rsg-inventory']:GetItemByName(src, 'hoe')
    if not hoe then return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You need a hoe' }) end
    local seed = exports['rsg-inventory']:GetItemByName(src, def.seed)
    if not seed or seed.amount < 1 then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'No ' .. def.seed })
    end

    local cid = P.PlayerData.citizenid
    if countPlayerCrops(cid) >= Config.MaxCropsPerPlayer then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Crop limit reached' })
    end

    local fert = exports['rsg-inventory']:GetItemByName(src, 'fertilizer')
    local useFert = fert and fert.amount >= 1

    P.Functions.RemoveItem(def.seed, 1)
    if useFert then P.Functions.RemoveItem('fertilizer', 1) end

    local now = os.time()
    local id = MySQL.insert.await([[
        INSERT INTO mike_crops (owner_cid, crop_type, x, y, z, planted_at, last_watered, fertilized)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], { cid, cropType, coords.x, coords.y, coords.z, now, now, useFert and 1 or 0 })

    crops[id] = {
        id = id, owner_cid = cid, crop_type = cropType,
        x = coords.x, y = coords.y, z = coords.z,
        planted_at = now, last_watered = now,
        fertilized = useFert and 1 or 0, withered = 0, harvested = 0,
    }
    broadcast()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Planted ' .. cropType })
end)

RegisterNetEvent('mike-farming:server:water', function(cropId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    local c = crops[tonumber(cropId)]; if not c then return end
    if c.withered == 1 then return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Crop has withered' }) end
    if not exports['rsg-inventory']:GetItemByName(src, 'watering_can') then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You need a watering can' })
    end
    c.last_watered = os.time()
    MySQL.update.await('UPDATE mike_crops SET last_watered = ? WHERE id = ?', { c.last_watered, c.id })
    broadcast()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Watered' })
end)

RegisterNetEvent('mike-farming:server:harvest', function(cropId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    local c = crops[tonumber(cropId)]; if not c then return end
    if c.harvested == 1 then return end

    local def = Config.CropTypes[c.crop_type]; if not def then return end
    local growthTime = def.growthTime * (c.fertilized == 1 and (1 - Config.FertilizerBonus) or 1)
    local elapsed = os.time() - c.planted_at
    if c.withered == 1 then
        crops[c.id] = nil
        MySQL.update.await('UPDATE mike_crops SET harvested = 1 WHERE id = ?', { c.id })
        broadcast()
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Dead crop removed' })
    end
    if elapsed < growthTime then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not ready yet' })
    end

    local yield = math.random(def.yieldMin, def.yieldMax)
    P.Functions.AddItem(def.harvest, yield)
    crops[c.id] = nil
    MySQL.update.await('UPDATE mike_crops SET harvested = 1 WHERE id = ?', { c.id })
    broadcast()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Harvested %d x %s'):format(yield, def.harvest) })
end)

-- Periodic wither check
CreateThread(function()
    while true do
        Wait(60000)
        local now = os.time()
        local changed = false
        for id, c in pairs(crops) do
            if c.withered == 0 then
                local def = Config.CropTypes[c.crop_type]
                if def and (now - c.last_watered) > def.waterGrace then
                    c.withered = 1
                    MySQL.update.await('UPDATE mike_crops SET withered = 1 WHERE id = ?', { id })
                    changed = true
                end
            end
        end
        if changed then broadcast() end
    end
end)

-- Item use handlers (server-side triggers from inventory use events)
for cropType, def in pairs(Config.CropTypes) do
    RSGCore.Functions.CreateUseableItem(def.seed, function(source)
        TriggerClientEvent('mike-farming:client:startPlant', source, cropType)
    end)
end
RSGCore.Functions.CreateUseableItem('hoe',           function(s) TriggerClientEvent('mike-farming:client:startTill',   s) end)
RSGCore.Functions.CreateUseableItem('watering_can',  function(s) TriggerClientEvent('mike-farming:client:tryWater',    s) end)

-- Crop processing (sugarcane → sugar, etc.)
for input, recipe in pairs(Config.Processing or {}) do
    RSGCore.Functions.CreateUseableItem(input, function(s)
        TriggerClientEvent('mike-farming:client:startProcess', s, input)
    end)
end

RegisterNetEvent('mike-farming:server:process', function(input, count)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    local recipe = Config.Processing and Config.Processing[input]; if not recipe then return end
    count = tonumber(count) or 0
    if count < recipe.inputPerOutput then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Need at least %d to process'):format(recipe.inputPerOutput) })
    end
    local have = exports['rsg-inventory']:GetItemByName(src, input)
    if not have or have.amount < count then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough in inventory' })
    end
    local outAmount = math.floor(count / recipe.inputPerOutput)
    local used      = outAmount * recipe.inputPerOutput
    P.Functions.RemoveItem(input, used)
    P.Functions.AddItem(recipe.output, outAmount)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Processed %d %s → %d %s'):format(used, input, outAmount, recipe.output) })
end)
