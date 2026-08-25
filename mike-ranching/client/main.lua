local RSGCore = exports['rsg-core']:GetCoreObject()
local animalData = {}
local animalPeds = {}
local animalZones = {}
local traderPed = nil
local traderZone = nil

local leadingAnimal = nil  -- animal ID currently being led
local leadingThread = nil  -- thread handle

-- ──────────────────────────────────────────────────────────────────────────
-- Herding: lead animal to pasture/water
-- ──────────────────────────────────────────────────────────────────────────
function startLeading(animalId)
    if leadingAnimal then stopLeading() end

    local ped = animalPeds[animalId]
    if not ped or not DoesEntityExist(ped) then return end

    leadingAnimal = animalId
    local a = animalData[animalId]

    -- Make animal follow the player
    SetBlockingOfNonTemporaryEvents(ped, false)
    TaskFollowToOffsetOfEntity(ped, PlayerPedId(), 0.0, -2.0, 0.0, 1.0, -1, 2.0, true, false, false, false, false, false)

    lib.notify({ type = 'inform', description = 'Leading ' .. (a and a.name or 'animal') .. ' — walk to pasture or water', duration = 4000 })

    -- Thread to check if animal reaches pasture/water zones
    CreateThread(function()
        while leadingAnimal == animalId do
            Wait(2000)
            if not ped or not DoesEntityExist(ped) then break end

            local animalCoords = GetEntityCoords(ped)

            -- Check pasture zone
            if Config.PastureZone then
                local d = #(animalCoords - Config.PastureZone.coords)
                if d <= Config.PastureZone.radius then
                    lib.notify({ type = 'success', description = (a and a.name or 'Animal') .. ' is grazing in the pasture', duration = 3000 })
                    TriggerServerEvent('mike-ranching:server:animalInZone', animalId, 'pasture',
                        animalCoords.x, animalCoords.y, animalCoords.z)
                    stopLeading()
                    -- Make animal wander in the pasture
                    TaskWanderInArea(ped, Config.PastureZone.coords.x, Config.PastureZone.coords.y, Config.PastureZone.coords.z, Config.PastureZone.radius, 0, 0)
                    break
                end
            end

            -- Check water zone
            if Config.WaterZone then
                local d = #(animalCoords - Config.WaterZone.coords)
                if d <= Config.WaterZone.radius then
                    lib.notify({ type = 'success', description = (a and a.name or 'Animal') .. ' is drinking at the water source', duration = 3000 })
                    TriggerServerEvent('mike-ranching:server:animalInZone', animalId, 'water',
                        animalCoords.x, animalCoords.y, animalCoords.z)
                    stopLeading()
                    TaskWanderInArea(ped, Config.WaterZone.coords.x, Config.WaterZone.coords.y, Config.WaterZone.coords.z, Config.WaterZone.radius, 0, 0)
                    break
                end
            end
        end
    end)
end

function stopLeading()
    if leadingAnimal then
        local ped = animalPeds[leadingAnimal]
        if ped and DoesEntityExist(ped) then
            SetBlockingOfNonTemporaryEvents(ped, true)
            local coords = GetEntityCoords(ped)
            TaskWanderInArea(ped, coords.x, coords.y, coords.z, 10.0, 0, 0)
        end
        leadingAnimal = nil
        lib.notify({ type = 'inform', description = 'Stopped leading', duration = 2000 })
    end
end

local function loadModel(hash)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 5000 do Wait(10) end
    return HasModelLoaded(hash)
end

-- ──────────────────────────────────────────────────────────────────────────
-- Spawn/despawn animals with growth scaling
-- ──────────────────────────────────────────────────────────────────────────
local function spawnAnimal(a)
    if animalPeds[a.id] and DoesEntityExist(animalPeds[a.id]) then return end
    local typeDef = Config.AnimalTypes[a.type]; if not typeDef then return end

    local hash = GetHashKey(typeDef.model)
    if not loadModel(hash) then return end

    local ped = CreatePed(hash, a.x + 0.0, a.y + 0.0, a.z + 0.0, a.heading + 0.0, false, false, false, false)
    if not ped or ped == 0 then return end

    SetModelAsNoLongerNeeded(hash)
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    -- Apply growth scale
    local scale = a.scale or 1.0
    if scale < 1.0 then
        SetPedScale(ped, scale)
    end

    TaskWanderInArea(ped, a.x + 0.0, a.y + 0.0, a.z + 0.0, 10.0, 0, 0)
    animalPeds[a.id] = ped

    -- Attach target to the actual ped so it follows the animal as it wanders
    local zid = exports.ox_target:addLocalEntity(ped, {
        {
            name     = 'mike_ranch_' .. a.id,
            label    = a.name or 'Animal',
            icon     = 'fa-solid fa-paw',
            onSelect = function() openAnimalMenu(a.id) end,
        },
    })
    animalZones[a.id] = zid
end

local function removeAnimal(id)
    if animalPeds[id] and DoesEntityExist(animalPeds[id]) then
        exports.ox_target:removeLocalEntity(animalPeds[id])
    end
    animalZones[id] = nil
    if animalPeds[id] and DoesEntityExist(animalPeds[id]) then
        SetEntityAsMissionEntity(animalPeds[id], true, true)
        DeleteEntity(animalPeds[id])
    end
    animalPeds[id] = nil
end

-- ──────────────────────────────────────────────────────────────────────────
-- Sync + proximity spawning
-- ──────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mike-ranching:client:syncAnimals', function(data)
    animalData = data or {}
    for id in pairs(animalPeds) do
        if not animalData[id] then removeAnimal(id) end
    end
    -- Update scales on existing animals
    for id, a in pairs(animalData) do
        if animalPeds[id] and DoesEntityExist(animalPeds[id]) then
            local scale = a.scale or 1.0
            if scale < 1.0 then SetPedScale(animalPeds[id], scale) end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(3000)
        local pc = GetEntityCoords(PlayerPedId())
        for id, a in pairs(animalData) do
            local d = #(pc - vector3(a.x + 0.0, a.y + 0.0, a.z + 0.0))
            if d <= 120.0 then
                spawnAnimal(a)
            else
                removeAnimal(id)
            end
        end
    end
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Animal interaction menu (access-controlled)
-- ──────────────────────────────────────────────────────────────────────────
function openAnimalMenu(animalId)
    local status = lib.callback.await('mike-ranching:server:getRanchStatus', false)
    if not status or status.playerRank == 0 then
        return lib.notify({ type = 'error', description = 'You don\'t have access to this ranch' })
    end

    local info = lib.callback.await('mike-ranching:server:getAnimalInfo', false, animalId)
    if not info then return end

    local typeDef = Config.AnimalTypes[info.type]; if not typeDef then return end
    local rank = status.playerRank

    local hungerBar = string.rep('█', math.floor(info.hunger / 10)) .. string.rep('░', 10 - math.floor(info.hunger / 10))
    local thirstBar = string.rep('█', math.floor(info.thirst / 10)) .. string.rep('░', 10 - math.floor(info.thirst / 10))
    local growthText = info.isGrown and 'Adult' or (info.growthPct .. '% grown')

    local opts = {}

    -- Status
    opts[#opts + 1] = {
        title       = info.name .. ' — ' .. growthText,
        description = ('Hunger: %s %d%%\nThirst: %s %d%%'):format(hungerBar, info.hunger, thirstBar, info.thirst),
        icon        = info.isGrown and 'fa-solid fa-heart' or 'fa-solid fa-baby',
        disabled    = true,
    }

    -- Feed (hand+)
    if rank >= Config.Permissions.feed_water then
        opts[#opts + 1] = {
            title    = 'Feed (' .. typeDef.feedQty .. 'x ' .. typeDef.feedItem:gsub('_', ' ') .. ')',
            icon     = 'fa-solid fa-wheat-awn',
            onSelect = function()
                if lib.progressBar({ duration = 3000, label = 'Feeding...', useWhileDead = false, canCancel = true, disable = { move = true, car = true, combat = true } }) then
                    lib.callback.await('mike-ranching:server:feedAnimal', false, animalId)
                end
            end,
        }

        opts[#opts + 1] = {
            title    = 'Water',
            icon     = 'fa-solid fa-droplet',
            onSelect = function()
                if lib.progressBar({ duration = 3000, label = 'Watering...', useWhileDead = false, canCancel = true, disable = { move = true, car = true, combat = true } }) then
                    lib.callback.await('mike-ranching:server:waterAnimal', false, animalId)
                end
            end,
        }
    end

    -- Collect produce (hand+)
    if rank >= Config.Permissions.collect_produce then
        if info.produceReady then
            opts[#opts + 1] = {
                title    = 'Collect ' .. info.produceLabel,
                icon     = 'fa-solid fa-basket-shopping',
                onSelect = function()
                    if lib.progressBar({ duration = 4000, label = 'Collecting...', useWhileDead = false, canCancel = true, disable = { move = true, car = true, combat = true } }) then
                        lib.callback.await('mike-ranching:server:collectProduce', false, animalId)
                    end
                end,
            }
        elseif info.isGrown then
            local mins = math.ceil(info.produceRemaining / 60)
            opts[#opts + 1] = {
                title    = info.produceLabel .. ' — ' .. mins .. ' min',
                icon     = 'fa-solid fa-hourglass-half',
                disabled = true,
            }
        else
            opts[#opts + 1] = {
                title    = 'Not grown enough to produce',
                icon     = 'fa-solid fa-seedling',
                disabled = true,
            }
        end
    end

    -- Lead animal (hand+)
    if rank >= Config.Permissions.feed_water then
        local ped = animalPeds[animalId]
        if ped and DoesEntityExist(ped) then
            if leadingAnimal == animalId then
                opts[#opts + 1] = {
                    title    = 'Stop Leading',
                    icon     = 'fa-solid fa-hand',
                    onSelect = function() stopLeading() end,
                }
            else
                opts[#opts + 1] = {
                    title    = 'Lead Animal',
                    description = 'Animal follows you — lead to pasture or water',
                    icon     = 'fa-solid fa-route',
                    onSelect = function() startLeading(animalId) end,
                }
            end
        end
    end

    -- Sell animal (head_rancher+)
    if rank >= Config.Permissions.sell_animal then
        local sellPrice = math.floor((typeDef.price or 10) * 0.5 * (info.scale or 1.0))
        opts[#opts + 1] = {
            title    = 'Sell Animal ($' .. sellPrice .. ')',
            icon     = 'fa-solid fa-coins',
            onSelect = function()
                local ok = lib.callback.await('mike-ranching:server:sellAnimal', false, animalId)
                if ok then removeAnimal(animalId); animalData[animalId] = nil end
            end,
        }
    end

    lib.registerContext({ id = 'mike_ranch_animal_' .. animalId, title = info.name, options = opts })
    lib.showContext('mike_ranch_animal_' .. animalId)
end

-- ──────────────────────────────────────────────────────────────────────────
-- Livestock Trader NPC
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    Wait(3000)

    local hash = GetHashKey(Config.Trader.model)
    if not loadModel(hash) then return end

    traderPed = CreatePed(hash, Config.Trader.coords.x, Config.Trader.coords.y, Config.Trader.coords.z - 1.0, Config.Trader.heading, false, false, false, false)
    Citizen.InvokeNative(0x283978A15512B2FE, traderPed, true)
    SetEntityInvincible(traderPed, true)
    SetBlockingOfNonTemporaryEvents(traderPed, true)
    FreezeEntityPosition(traderPed, true)
    SetModelAsNoLongerNeeded(hash)

    local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, Config.Trader.coords.x + 0.0, Config.Trader.coords.y + 0.0, Config.Trader.coords.z + 0.0)
    SetBlipSprite(blip, joaat('blip_shop_horse'), true)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, Config.Trader.name)

    traderZone = exports.ox_target:addSphereZone({
        coords = Config.Trader.coords,
        radius = 3.0,
        debug  = false,
        options = {
            {
                name     = 'mike_ranch_trader',
                label    = Config.Trader.name,
                icon     = 'fa-solid fa-cow',
                onSelect = function() openTraderMenu() end,
            },
        },
    })
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Trader menu: buy ranch, buy animals, manage ranch
-- ──────────────────────────────────────────────────────────────────────────
function openTraderMenu()
    local status = lib.callback.await('mike-ranching:server:getRanchStatus', false)
    if not status then return end

    local opts = {}

    if not status.owned then
        -- Ranch not owned — offer to buy
        opts[#opts + 1] = {
            title       = ('Buy %s — $%d'):format(Config.Ranch.name, Config.Ranch.price),
            description = 'Purchase this ranch and start your livestock operation',
            icon        = 'fa-solid fa-house',
            onSelect    = function()
                lib.callback.await('mike-ranching:server:buyRanch', false)
            end,
        }
    else
        local rank = status.playerRank
        if rank == 0 then
            opts[#opts + 1] = {
                title    = 'This ranch is owned by someone else',
                icon     = 'fa-solid fa-lock',
                disabled = true,
            }
        else
            opts[#opts + 1] = {
                title    = 'Your role: ' .. status.playerRankLabel,
                icon     = 'fa-solid fa-id-badge',
                disabled = true,
            }

            -- Buy animals (head_rancher+)
            if rank >= Config.Permissions.buy_animal then
                opts[#opts + 1] = {
                    title    = 'Buy Animals',
                    icon     = 'fa-solid fa-paw',
                    onSelect = function() openBuyAnimalMenu() end,
                }
            end

            -- Ranch management (owner only)
            if rank >= Config.Permissions.hire_fire then
                opts[#opts + 1] = {
                    title    = 'Manage Employees',
                    icon     = 'fa-solid fa-users',
                    onSelect = function() openEmployeeMenu() end,
                }
                opts[#opts + 1] = {
                    title    = ('Sell Ranch ($%d)'):format(Config.Ranch.sellBack),
                    icon     = 'fa-solid fa-hand-holding-dollar',
                    onSelect = function()
                        lib.callback.await('mike-ranching:server:sellRanch', false)
                    end,
                }
            end
        end
    end

    lib.registerContext({ id = 'mike_ranch_trader', title = Config.Trader.name, options = opts })
    lib.showContext('mike_ranch_trader')
end

function openBuyAnimalMenu()
    local opts = {}
    for typeKey, typeDef in pairs(Config.AnimalTypes) do
        opts[#opts + 1] = {
            title       = ('Buy %s — $%d'):format(typeDef.label, typeDef.price),
            description = ('Produces: %s | Feed: %s'):format(typeDef.produce.label, typeDef.feedItem:gsub('_', ' ')),
            icon        = 'fa-solid fa-paw',
            onSelect    = function()
                lib.callback.await('mike-ranching:server:buyAnimal', false, typeKey)
            end,
        }
    end

    lib.registerContext({ id = 'mike_ranch_buy', title = 'Buy Livestock', menu = 'mike_ranch_trader', options = opts })
    lib.showContext('mike_ranch_buy')
end

-- ──────────────────────────────────────────────────────────────────────────
-- Employee management menu
-- ──────────────────────────────────────────────────────────────────────────
function openEmployeeMenu()
    local employees = lib.callback.await('mike-ranching:server:getEmployees', false)
    local opts = {}

    if employees and #employees > 0 then
        for _, emp in ipairs(employees) do
            local actions = {}
            if emp.rank == 'hand' then
                actions = 'Promote / Fire'
            else
                actions = 'Demote / Fire'
            end
            opts[#opts + 1] = {
                title       = emp.name .. ' — ' .. emp.rankLabel,
                description = actions,
                icon        = 'fa-solid fa-user',
                onSelect    = function() openEmployeeActions(emp) end,
            }
        end
    else
        opts[#opts + 1] = {
            title    = 'No employees yet',
            icon     = 'fa-solid fa-user-slash',
            disabled = true,
        }
    end

    opts[#opts + 1] = {
        title    = 'Hire New Employee',
        description = 'Select a nearby player to hire',
        icon     = 'fa-solid fa-user-plus',
        onSelect = function() openHireMenu() end,
    }

    lib.registerContext({ id = 'mike_ranch_employees', title = 'Ranch Employees', menu = 'mike_ranch_trader', options = opts })
    lib.showContext('mike_ranch_employees')
end

function openEmployeeActions(emp)
    local opts = {}

    if emp.rank == 'hand' then
        opts[#opts + 1] = {
            title    = 'Promote to Head Rancher',
            icon     = 'fa-solid fa-arrow-up',
            onSelect = function()
                lib.callback.await('mike-ranching:server:setEmployeeRank', false, emp.cid, 'head_rancher')
            end,
        }
    elseif emp.rank == 'head_rancher' then
        opts[#opts + 1] = {
            title    = 'Demote to Ranch Hand',
            icon     = 'fa-solid fa-arrow-down',
            onSelect = function()
                lib.callback.await('mike-ranching:server:setEmployeeRank', false, emp.cid, 'hand')
            end,
        }
    end

    opts[#opts + 1] = {
        title    = 'Fire ' .. emp.name,
        icon     = 'fa-solid fa-user-minus',
        onSelect = function()
            lib.callback.await('mike-ranching:server:fireEmployee', false, emp.cid)
        end,
    }

    lib.registerContext({ id = 'mike_ranch_emp_actions', title = emp.name, menu = 'mike_ranch_employees', options = opts })
    lib.showContext('mike_ranch_emp_actions')
end

function openHireMenu()
    local nearby = lib.callback.await('mike-ranching:server:getNearbyPlayers', false)
    local opts = {}

    if nearby and #nearby > 0 then
        for _, p in ipairs(nearby) do
            opts[#opts + 1] = {
                title    = p.name .. ' (ID: ' .. p.src .. ')',
                icon     = 'fa-solid fa-user-plus',
                onSelect = function()
                    lib.callback.await('mike-ranching:server:hireEmployee', false, p.src)
                end,
            }
        end
    else
        opts[#opts + 1] = {
            title    = 'No players nearby',
            icon     = 'fa-solid fa-user-slash',
            disabled = true,
        }
    end

    lib.registerContext({ id = 'mike_ranch_hire', title = 'Hire Employee', menu = 'mike_ranch_employees', options = opts })
    lib.showContext('mike_ranch_hire')
end

-- Cleanup
AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        for id in pairs(animalPeds) do removeAnimal(id) end
        if traderPed and DoesEntityExist(traderPed) then
            SetEntityAsMissionEntity(traderPed, true, true)
            DeleteEntity(traderPed)
        end
        if traderZone then exports.ox_target:removeZone(traderZone) end
    end
end)
