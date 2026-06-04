local RSGCore = exports['rsg-core']:GetCoreObject()
local stills  = {}

local function isLaw(P)
    if not P or not P.PlayerData.job then return false end
    for _, j in ipairs(Config.LawJobs) do
        if P.PlayerData.job.name == j then return true end
    end
    return false
end

local function broadcast()
    TriggerClientEvent('mike-moonshine:client:sync', -1, stills)
end

local function loadAll()
    local rows = MySQL.query.await('SELECT * FROM mike_stills WHERE destroyed = 0', {})
    stills = {}
    for _, r in ipairs(rows or {}) do stills[r.id] = r end
    broadcast()
end

AddEventHandler('onResourceStart', function(r)
    if r == GetCurrentResourceName() then
        CreateThread(function()
            Wait(2000)
            -- Clean up destroyed stills so the table doesn't bloat
            MySQL.query.await('DELETE FROM mike_stills WHERE destroyed = 1')
            loadAll()
        end)
    end
end)

AddEventHandler('playerJoining', function()
    local src = source
    CreateThread(function() Wait(3000); TriggerClientEvent('mike-moonshine:client:sync', src, stills) end)
end)

-- Crafting
RegisterNetEvent('mike-moonshine:server:craftStill', function()
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    if not exports['rsg-inventory']:GetItemByName(src, Config.CraftRecipe.blueprint) then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Need a still blueprint' })
    end
    for item, n in pairs(Config.CraftRecipe.inputs) do
        local have = exports['rsg-inventory']:GetItemByName(src, item)
        if not have or have.amount < n then
            return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Missing %d x %s'):format(n, item) })
        end
    end
    for item, n in pairs(Config.CraftRecipe.inputs) do P.Functions.RemoveItem(item, n) end
    P.Functions.AddItem(Config.CraftRecipe.output, 1)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Crafted a portable still' })
end)

-- Placement
RegisterNetEvent('mike-moonshine:server:place', function(coords, heading)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    if not exports['rsg-inventory']:GetItemByName(src, Config.CraftRecipe.output) then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'No still to place' })
    end
    P.Functions.RemoveItem(Config.CraftRecipe.output, 1)
    local now = os.time()
    local id = MySQL.insert.await([[
        INSERT INTO mike_stills (owner_cid, x, y, z, heading, state, created_at)
        VALUES (?, ?, ?, ?, ?, 'empty', ?)
    ]], { P.PlayerData.citizenid, coords.x, coords.y, coords.z, heading, now })
    stills[id] = {
        id = id, owner_cid = P.PlayerData.citizenid,
        x = coords.x, y = coords.y, z = coords.z, heading = heading,
        state = 'empty', stage_started = nil, mash_batches = 0,
        quality_score = 0, bottles_ready = 0, bottle_tier = nil,
        created_at = now, destroyed = 0,
    }
    broadcast()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Still placed' })
end)

RSGCore.Functions.CreateCallback('mike-moonshine:server:getStill', function(source, cb, id)
    cb(stills[tonumber(id)])
end)

-- Add a mash batch
RegisterNetEvent('mike-moonshine:server:addMash', function(stillId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    local st = stills[tonumber(stillId)]; if not st then return end
    if st.state ~= 'empty' and st.state ~= 'mashing' then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Cannot add mash in current state' })
    end
    if st.mash_batches >= Config.MaxBatches then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Still is full' })
    end
    for item, n in pairs(Config.MashRecipe) do
        local have = exports['rsg-inventory']:GetItemByName(src, item)
        if not have or have.amount < n then
            return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Missing %d x %s'):format(n, item) })
        end
    end
    for item, n in pairs(Config.MashRecipe) do P.Functions.RemoveItem(item, n) end

    -- Premium add-ons (optional)
    local qualityBonus = 0
    for item, n in pairs(Config.PremiumAddon) do
        local have = exports['rsg-inventory']:GetItemByName(src, item)
        if have and have.amount >= n then
            P.Functions.RemoveItem(item, n)
            qualityBonus = qualityBonus + 20
        end
    end

    st.mash_batches = st.mash_batches + 1
    st.quality_score = st.quality_score + 20 + qualityBonus + math.random(-5, 5)
    st.state = 'mashing'
    MySQL.update.await('UPDATE mike_stills SET mash_batches=?, quality_score=?, state=? WHERE id=?', { st.mash_batches, st.quality_score, st.state, st.id })
    broadcast()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Mash added (%d/%d)'):format(st.mash_batches, Config.MaxBatches) })
end)

RegisterNetEvent('mike-moonshine:server:startFerment', function(stillId)
    local src = source
    local st = stills[tonumber(stillId)]; if not st then return end
    if st.state ~= 'mashing' or st.mash_batches == 0 then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Add mash first' })
    end
    st.state = 'fermenting'
    st.stage_started = os.time()
    MySQL.update.await('UPDATE mike_stills SET state=?, stage_started=? WHERE id=?', { st.state, st.stage_started, st.id })
    broadcast()
    TriggerClientEvent('ox_lib:notify', src, { type = 'inform', description = 'Fermenting started' })
end)

RegisterNetEvent('mike-moonshine:server:startDistill', function(stillId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    local st = stills[tonumber(stillId)]; if not st then return end
    if st.state ~= 'fermented' then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not fermented yet' })
    end
    local wood = exports['rsg-inventory']:GetItemByName(src, 'firewood')
    if not wood or wood.amount < Config.DistillFuel then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Need %d firewood'):format(Config.DistillFuel) })
    end
    P.Functions.RemoveItem('firewood', Config.DistillFuel)
    st.state = 'distilling'
    st.stage_started = os.time()
    MySQL.update.await('UPDATE mike_stills SET state=?, stage_started=? WHERE id=?', { st.state, st.stage_started, st.id })
    broadcast()
    TriggerClientEvent('ox_lib:notify', src, { type = 'inform', description = 'Distillation started' })
end)

RegisterNetEvent('mike-moonshine:server:bottle', function(stillId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    local st = stills[tonumber(stillId)]; if not st or st.state ~= 'ready' then return end

    local needed = st.bottles_ready * Config.BottleGlass
    local glass  = exports['rsg-inventory']:GetItemByName(src, 'glass_bottle')
    if not glass or glass.amount < needed then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = ('Need %d glass bottles'):format(needed) })
    end
    P.Functions.RemoveItem('glass_bottle', needed)

    local itemName = 'moonshine_basic'
    if st.bottle_tier == 'good' then itemName = 'moonshine_good'
    elseif st.bottle_tier == 'premium' then itemName = 'moonshine_premium' end
    P.Functions.AddItem(itemName, st.bottles_ready)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Bottled %d x %s'):format(st.bottles_ready, itemName) })

    st.state = 'empty'
    st.mash_batches = 0; st.quality_score = 0; st.bottles_ready = 0; st.bottle_tier = nil
    MySQL.update.await('UPDATE mike_stills SET state=?, mash_batches=0, quality_score=0, bottles_ready=0, bottle_tier=NULL WHERE id=?', { st.state, st.id })
    broadcast()
end)

RegisterNetEvent('mike-moonshine:server:destroy', function(stillId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    local st = stills[tonumber(stillId)]; if not st then return end

    local isOwner = st.owner_cid == P.PlayerData.citizenid
    if not isOwner and not isLaw(P) then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not authorized' })
    end
    MySQL.update.await('UPDATE mike_stills SET destroyed = 1 WHERE id = ?', { st.id })
    stills[st.id] = nil
    broadcast()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Still destroyed' })
end)

RegisterNetEvent('mike-moonshine:server:pickup', function(stillId)
    local src = source
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    local st = stills[tonumber(stillId)]; if not st then return end

    if st.owner_cid ~= P.PlayerData.citizenid then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only the owner can pick up this still' })
    end
    if st.state ~= 'empty' then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Empty the still before picking it up' })
    end
    MySQL.update.await('UPDATE mike_stills SET destroyed = 1 WHERE id = ?', { st.id })
    stills[st.id] = nil
    broadcast()
    P.Functions.AddItem('portable_still', 1)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Still picked up' })
end)

-- Stage progression tick
CreateThread(function()
    while true do
        Wait(15 * 1000)
        local now = os.time()
        local changed = false
        for id, st in pairs(stills) do
            if st.state == 'fermenting' and (now - (st.stage_started or now)) >= Config.FermentTime then
                st.state = 'fermented'
                MySQL.update.await('UPDATE mike_stills SET state=? WHERE id=?', { st.state, id })
                changed = true
            elseif st.state == 'distilling' and (now - (st.stage_started or now)) >= Config.DistillTime then
                local avgScore = math.floor(st.quality_score / math.max(st.mash_batches, 1))
                local tier = 'basic'
                if avgScore >= Config.QualityThresholds.premium then tier = 'premium'
                elseif avgScore >= Config.QualityThresholds.good then tier = 'good' end
                st.state = 'ready'
                st.bottles_ready = st.mash_batches * Config.BottlePerBatch
                st.bottle_tier = tier
                MySQL.update.await('UPDATE mike_stills SET state=?, bottles_ready=?, bottle_tier=? WHERE id=?', { st.state, st.bottles_ready, st.bottle_tier, id })
                changed = true
            end
        end
        if changed then broadcast() end
    end
end)

-- Usable items
RSGCore.Functions.CreateUseableItem('still_blueprint', function(src)
    TriggerClientEvent('mike-moonshine:client:tryCraft', src)
end)
RSGCore.Functions.CreateUseableItem('portable_still', function(src)
    TriggerClientEvent('mike-moonshine:client:startPlace', src)
end)
