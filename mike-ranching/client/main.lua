local RSGCore = exports['rsg-core']:GetCoreObject()
local animalData = {}
local animalPeds = {}
local animalZones = {}
local traderPed = nil
local traderZone = nil

local leadingAnimals = {}  -- { [animalId] = true } — multiple animals can be led

-- ──────────────────────────────────────────────────────────────────────────
-- Herding: lead animal to pasture/water
-- ──────────────────────────────────────────────────────────────────────────
function startLeading(animalId)
    local ped = animalPeds[animalId]
    if not ped or not DoesEntityExist(ped) then return end

    leadingAnimals[animalId] = true
    local a = animalData[animalId]

    -- Make animal follow the player
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    TaskFollowToOffsetOfEntity(ped, PlayerPedId(), 0.0, -2.0 - (math.random(0, 3)), 0.0, 1.5, -1, 2.0, 1)

    lib.notify({ type = 'inform', description = 'Leading ' .. (a and a.name or 'animal') .. ' — walk to pasture or water', duration = 4000 })

    -- Thread to check if animal reaches pasture/water zones + update position
    CreateThread(function()
        while leadingAnimals[animalId] do
            Wait(2000)
            if not ped or not DoesEntityExist(ped) then break end

            local animalCoords = GetEntityCoords(ped)

            -- Keep DB position in sync so the proximity spawner doesn't yank it back
            if animalData[animalId] then
                animalData[animalId].x = animalCoords.x
                animalData[animalId].y = animalCoords.y
                animalData[animalId].z = animalCoords.z
            end
            TriggerServerEvent('mike-ranching:server:animalInZone', animalId, 'moving',
                animalCoords.x, animalCoords.y, animalCoords.z)

            -- Re-issue follow task in case it dropped
            TaskFollowToOffsetOfEntity(ped, PlayerPedId(), 0.0, -2.0, 0.0, 1.5, -1, 2.0, 1)

            -- Get zones from server
            local zones = lib.callback.await('mike-ranching:server:getZones', false) or {}

            -- Notify when entering zones (but keep following)
            if zones.pasture then
                local pCoords = vector3(zones.pasture.x, zones.pasture.y, zones.pasture.z)
                local d = #(animalCoords - pCoords)
                if d <= Config.PastureRadius then
                    if not a.notifiedPasture then
                        lib.notify({ type = 'success', description = (a and a.name or 'Animal') .. ' has entered the pasture zone', duration = 4000 })
                        TriggerServerEvent('mike-ranching:server:animalInZone', animalId, 'pasture',
                            animalCoords.x, animalCoords.y, animalCoords.z)
                        a.notifiedPasture = true
                    end
                else
                    a.notifiedPasture = nil
                end
            end

            if zones.water then
                local wCoords = vector3(zones.water.x, zones.water.y, zones.water.z)
                local d = #(animalCoords - wCoords)
                if d <= Config.WaterRadius then
                    if not a.notifiedWater then
                        lib.notify({ type = 'success', description = (a and a.name or 'Animal') .. ' has entered the water zone', duration = 4000 })
                        TriggerServerEvent('mike-ranching:server:animalInZone', animalId, 'water',
                            animalCoords.x, animalCoords.y, animalCoords.z)
                        a.notifiedWater = true
                    end
                else
                    a.notifiedWater = nil
                end
            end
        end
    end)
end

function stopLeading(animalId)
    if animalId then
        leadingAnimals[animalId] = nil
        local ped = animalPeds[animalId]
        if ped and DoesEntityExist(ped) then
            ClearPedTasks(ped)
            local coords = GetEntityCoords(ped)
            -- Wander in small area where they stopped
            TaskWanderInArea(ped, coords.x, coords.y, coords.z, 8.0, 0, 0)
            -- Update server position
            TriggerServerEvent('mike-ranching:server:animalInZone', animalId, 'stopped',
                coords.x, coords.y, coords.z)
        end
    else
        -- Stop all
        for id in pairs(leadingAnimals) do
            local ped = animalPeds[id]
            if ped and DoesEntityExist(ped) then
                ClearPedTasks(ped)
                local coords = GetEntityCoords(ped)
                TaskWanderInArea(ped, coords.x, coords.y, coords.z, 8.0, 0, 0)
                TriggerServerEvent('mike-ranching:server:animalInZone', id, 'stopped',
                    coords.x, coords.y, coords.z)
            end
        end
        leadingAnimals = {}
    end
    lib.notify({ type = 'inform', description = 'Stopped leading', duration = 2000 })
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
    SetPedFleeAttributes(ped, 0, 0)
    SetPedConfigFlag(ped, 294, false)  -- disable shocking events
    SetPedConfigFlag(ped, 301, false)  -- disable seeing shocked events

    -- Apply growth scale
    local scale = a.scale or 1.0
    if scale < 1.0 then
        SetPedScale(ped, scale)
    end

    -- Auto-follow the player when first spawned (brought out of barn)
    TaskFollowToOffsetOfEntity(ped, PlayerPedId(), 0.0, -2.0 - (a.id % 4), 0.0, 1.5, -1, 3.0, 1)
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
            if a.in_barn then
                removeAnimal(id)  -- don't render barn animals
            else
                -- If the animal ped exists, use its REAL position for distance check
                local checkCoords = vector3(a.x + 0.0, a.y + 0.0, a.z + 0.0)
                if animalPeds[id] and DoesEntityExist(animalPeds[id]) then
                    local realCoords = GetEntityCoords(animalPeds[id])
                    checkCoords = realCoords
                    -- Keep local data in sync with entity position
                    a.x = realCoords.x
                    a.y = realCoords.y
                    a.z = realCoords.z
                end

                local d = #(pc - checkCoords)
                if d <= 120.0 then
                    spawnAnimal(a)
                else
                    removeAnimal(id)
                end
            end
        end

        -- Update server with real positions of spawned animals (every 10 seconds)
        for id, ped in pairs(animalPeds) do
            if DoesEntityExist(ped) then
                local coords = GetEntityCoords(ped)
                TriggerServerEvent('mike-ranching:server:animalInZone', id, 'moving',
                    coords.x, coords.y, coords.z)
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
                local ped = animalPeds[animalId]
                if ped and DoesEntityExist(ped) then
                    ClearPedTasks(ped)
                    FreezeEntityPosition(ped, true)
                end

                local playerPed = PlayerPedId()
                ClearPedTasksImmediately(playerPed)
                SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true)
                Wait(200)
                TaskStartScenarioInPlace(playerPed, GetHashKey('WORLD_HUMAN_BUCKET_POUR_LOW'), -1, true, false, false, false)

                if lib.progressBar({ duration = 5000, label = 'Feeding ' .. (info.name or 'animal') .. '...', useWhileDead = false, canCancel = true, disable = { move = true, car = true, combat = true } }) then
                    lib.callback.await('mike-ranching:server:feedAnimal', false, animalId)
                end

                ClearPedTasks(playerPed)
                Wait(100)
                ClearPedTasks(playerPed)
                if ped and DoesEntityExist(ped) then
                    FreezeEntityPosition(ped, false)
                    TaskWanderStandard(ped, 10.0, 10)
                end
            end,
        }

        opts[#opts + 1] = {
            title    = 'Water',
            icon     = 'fa-solid fa-droplet',
            onSelect = function()
                local ped = animalPeds[animalId]
                if ped and DoesEntityExist(ped) then
                    ClearPedTasks(ped)
                    FreezeEntityPosition(ped, true)
                end

                local playerPed = PlayerPedId()
                ClearPedTasksImmediately(playerPed)
                SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true)
                Wait(200)
                TaskStartScenarioInPlace(playerPed, GetHashKey('WORLD_HUMAN_BUCKET_POUR_LOW'), -1, true, false, false, false)

                if lib.progressBar({ duration = 5000, label = 'Watering ' .. (info.name or 'animal') .. '...', useWhileDead = false, canCancel = true, disable = { move = true, car = true, combat = true } }) then
                    lib.callback.await('mike-ranching:server:waterAnimal', false, animalId)
                end

                ClearPedTasks(playerPed)
                Wait(100)
                ClearPedTasks(playerPed)
                if ped and DoesEntityExist(ped) then
                    FreezeEntityPosition(ped, false)
                    TaskWanderStandard(ped, 10.0, 10)
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
                    local ped = animalPeds[animalId]
                    if ped and DoesEntityExist(ped) then
                        ClearPedTasks(ped)
                        FreezeEntityPosition(ped, true)
                    end

                    local playerPed = PlayerPedId()
                    ClearPedTasksImmediately(playerPed)
                    SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true)
                    Wait(200)
                    TaskStartScenarioInPlace(playerPed, GetHashKey('WORLD_HUMAN_BUCKET_POUR_LOW'), -1, true, false, false, false)

                    if lib.progressBar({ duration = 6000, label = 'Collecting ' .. info.produceLabel .. '...', useWhileDead = false, canCancel = true, disable = { move = true, car = true, combat = true } }) then
                        lib.callback.await('mike-ranching:server:collectProduce', false, animalId)
                    end

                    ClearPedTasks(playerPed)
                    Wait(100)
                    ClearPedTasks(playerPed)
                    if ped and DoesEntityExist(ped) then
                        FreezeEntityPosition(ped, false)
                        TaskWanderStandard(ped, 10.0, 10)
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

    -- Leave here (stop following, wander in place)
    if rank >= Config.Permissions.feed_water then
        opts[#opts + 1] = {
            title    = 'Leave Here',
            description = 'Animal stops following and stays in this area',
            icon     = 'fa-solid fa-hand',
            onSelect = function()
                local ped = animalPeds[animalId]
                if ped and DoesEntityExist(ped) then
                    ClearPedTasks(ped)
                    local coords = GetEntityCoords(ped)
                    TaskWanderInArea(ped, coords.x, coords.y, coords.z, 8.0, 0, 0)
                    TriggerServerEvent('mike-ranching:server:animalInZone', animalId, 'stopped',
                        coords.x, coords.y, coords.z)
                    lib.notify({ type = 'inform', description = (info.name or 'Animal') .. ' will stay here', duration = 3000 })
                end
            end,
        }

        -- Call back (make it follow again)
        opts[#opts + 1] = {
            title    = 'Follow Me',
            icon     = 'fa-solid fa-route',
            onSelect = function()
                local ped = animalPeds[animalId]
                if ped and DoesEntityExist(ped) then
                    ClearPedTasks(ped)
                    FreezeEntityPosition(ped, false)
                    TaskFollowToOffsetOfEntity(ped, PlayerPedId(), 0.0, -2.0, 0.0, 1.5, -1, 3.0, 1)
                    lib.notify({ type = 'inform', description = (info.name or 'Animal') .. ' is following you', duration = 3000 })
                end
            end,
        }
    end

    -- Send to barn (hand+)
    if rank >= Config.Permissions.feed_water then
        opts[#opts + 1] = {
            title    = 'Send to Barn',
            icon     = 'fa-solid fa-house',
            onSelect = function()
                local ok = lib.callback.await('mike-ranching:server:sendToBarn', false, animalId)
                if ok then removeAnimal(animalId) end
            end,
        }
    end

    -- Slaughter on-site (head_rancher+) — 10% penalty
    if rank >= Config.Permissions.sell_animal then
        opts[#opts + 1] = {
            title       = 'Slaughter On-Site (10% penalty)',
            icon        = 'fa-solid fa-skull',
            onSelect    = function()
                local ped = animalPeds[animalId]
                if ped and DoesEntityExist(ped) then
                    ClearPedTasks(ped)
                    FreezeEntityPosition(ped, true)
                end
                if lib.progressBar({ duration = 8000, label = 'Slaughtering...', useWhileDead = false, canCancel = true, disable = { move = true, car = true, combat = true } }) then
                    local ok = lib.callback.await('mike-ranching:server:slaughterAnimal', false, animalId, false)
                    if ok then removeAnimal(animalId); animalData[animalId] = nil end
                else
                    if ped and DoesEntityExist(ped) then
                        FreezeEntityPosition(ped, false)
                        TaskWanderStandard(ped, 10.0, 10)
                    end
                end
            end,
        }

        -- Sell animal
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
                    title       = 'Set Pasture Zone',
                    description = 'You will be asked to walk to the spot and confirm',
                    icon        = 'fa-solid fa-leaf',
                    onSelect    = function() startZonePlacement('pasture') end,
                }
                opts[#opts + 1] = {
                    title       = 'Set Water Zone',
                    description = 'You will be asked to walk to the spot and confirm',
                    icon        = 'fa-solid fa-water',
                    onSelect    = function() startZonePlacement('water') end,
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

-- ──────────────────────────────────────────────────────────────────────────
-- Zone placement: walk to spot, press ENTER to confirm, BACKSPACE to cancel
-- ──────────────────────────────────────────────────────────────────────────
function startZonePlacement(zoneType)
    local label = zoneType == 'pasture' and 'Pasture' or 'Water'
    lib.notify({ type = 'inform', description = 'Walk to where you want the ' .. label .. ' zone. Press ENTER to confirm, BACKSPACE to cancel.', duration = 8000 })

    local CONFIRM_KEY = 0xC7B5340A   -- ENTER
    local CANCEL_KEY  = 0x156F7119   -- BACKSPACE

    CreateThread(function()
        local placing = true
        while placing do
            Wait(0)
            if IsControlJustReleased(0, CONFIRM_KEY) then
                placing = false
                lib.callback.await('mike-ranching:server:setZone', false, zoneType)
            elseif IsControlJustReleased(0, CANCEL_KEY) then
                placing = false
                lib.notify({ type = 'error', description = 'Zone placement cancelled', duration = 2000 })
            end
        end
    end)
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

-- ──────────────────────────────────────────────────────────────────────────
-- Barn interaction zone
-- ──────────────────────────────────────────────────────────────────────────
local barnZone = nil

CreateThread(function()
    Wait(4000)

    barnZone = exports.ox_target:addSphereZone({
        coords = Config.Barn.coords,
        radius = Config.Barn.radius,
        debug  = false,
        options = {
            {
                name     = 'mike_ranch_barn',
                label    = 'Barn',
                icon     = 'fa-solid fa-warehouse',
                onSelect = function() openBarnMenu() end,
            },
        },
    })
end)

function openBarnMenu()
    local status = lib.callback.await('mike-ranching:server:getRanchStatus', false)
    if not status or status.playerRank == 0 then
        return lib.notify({ type = 'error', description = 'You don\'t have access to this ranch' })
    end

    local barnAnimals = lib.callback.await('mike-ranching:server:getBarnAnimals', false) or {}
    local opts = {}

    -- Feed all
    opts[#opts + 1] = {
        title    = 'Feed All in Barn (costs hay cubes)',
        icon     = 'fa-solid fa-wheat-awn',
        onSelect = function()
            lib.callback.await('mike-ranching:server:barnFeedAll', false)
        end,
    }

    -- Water all
    opts[#opts + 1] = {
        title    = 'Water All in Barn (free)',
        icon     = 'fa-solid fa-droplet',
        onSelect = function()
            lib.callback.await('mike-ranching:server:barnWaterAll', false)
        end,
    }

    -- List barn animals
    if #barnAnimals > 0 then
        for _, ba in ipairs(barnAnimals) do
            local growthText = ba.growthPct >= 100 and 'Adult' or (ba.growthPct .. '% grown')
            opts[#opts + 1] = {
                title       = ba.name .. ' (' .. ba.label .. ')',
                description = ('Hunger: %d%% | Thirst: %d%% | %s'):format(ba.hunger, ba.thirst, growthText),
                icon        = 'fa-solid fa-paw',
                onSelect    = function()
                    lib.callback.await('mike-ranching:server:bringFromBarn', false, ba.id)
                end,
            }
        end
    else
        opts[#opts + 1] = {
            title    = 'No animals in barn',
            icon     = 'fa-solid fa-box-open',
            disabled = true,
        }
    end

    lib.registerContext({ id = 'mike_ranch_barn', title = 'Barn', options = opts })
    lib.showContext('mike_ranch_barn')
end

-- ──────────────────────────────────────────────────────────────────────────
-- Slaughterhouse NPCs
-- ──────────────────────────────────────────────────────────────────────────
local slaughterPeds = {}
local slaughterZones = {}

CreateThread(function()
    Wait(4000)
    for i, sh in ipairs(Config.Slaughterhouses) do
        -- Spawn NPC
        local hash = GetHashKey(sh.npcmodel)
        if loadModel(hash) then
            local npc = CreatePed(hash, sh.coords.x, sh.coords.y, sh.coords.z - 1.0, sh.heading, false, false, false, false)
            Citizen.InvokeNative(0x283978A15512B2FE, npc, true)
            SetEntityInvincible(npc, true)
            SetBlockingOfNonTemporaryEvents(npc, true)
            FreezeEntityPosition(npc, true)
            SetModelAsNoLongerNeeded(hash)
            slaughterPeds[#slaughterPeds + 1] = npc
        end

        -- Blip
        local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, sh.coords.x + 0.0, sh.coords.y + 0.0, sh.coords.z + 0.0)
        SetBlipSprite(blip, joaat('blip_shop_butcher'), true)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, sh.name)

        -- Interaction zone
        local zid = exports.ox_target:addSphereZone({
            coords = sh.coords,
            radius = sh.radius,
            debug  = false,
            options = {
                {
                    name     = 'mike_slaughter_' .. i,
                    label    = sh.name,
                    icon     = 'fa-solid fa-skull-crossbones',
                    onSelect = function() openSlaughterhouseMenu() end,
                },
            },
        })
        slaughterZones[#slaughterZones + 1] = zid
    end
end)

function openSlaughterhouseMenu()
    local status = lib.callback.await('mike-ranching:server:getRanchStatus', false)
    if not status or status.playerRank == 0 then
        return lib.notify({ type = 'error', description = 'You need to be a rancher to use the slaughterhouse' })
    end

    -- Find nearby ranch animals that are following/nearby
    local opts = {}
    local playerCoords = GetEntityCoords(PlayerPedId())

    for id, ped in pairs(animalPeds) do
        if DoesEntityExist(ped) then
            local d = #(GetEntityCoords(ped) - playerCoords)
            if d <= 20.0 then
                local a = animalData[id]
                if a then
                    local typeDef = Config.AnimalTypes[a.type]
                    if typeDef then
                        -- Show what you'd get
                        local yields = Config.SlaughterYields[a.type]
                        local parts = {}
                        if yields then
                            for _, y in ipairs(yields) do
                                local qty = math.max(1, math.floor(y.qty * (a.scale or 1.0)))
                                parts[#parts + 1] = qty .. 'x ' .. y.item:gsub('_', ' ')
                            end
                        end
                        local sellPrice = math.floor((typeDef.price or 10) * (a.scale or 1.0))

                        opts[#opts + 1] = {
                            title       = 'Slaughter ' .. (a.name or typeDef.label),
                            description = ('$%d + %s'):format(sellPrice, table.concat(parts, ', ')),
                            icon        = 'fa-solid fa-skull-crossbones',
                            onSelect    = function()
                                if lib.progressBar({ duration = 8000, label = 'Slaughtering...', useWhileDead = false, canCancel = true, disable = { move = true, car = true, combat = true } }) then
                                    local ok = lib.callback.await('mike-ranching:server:slaughterAtShop', false, id)
                                    if ok then removeAnimal(id); animalData[id] = nil end
                                end
                            end,
                        }
                    end
                end
            end
        end
    end

    if #opts == 0 then
        opts[#opts + 1] = {
            title    = 'No animals nearby — lead your livestock here',
            icon     = 'fa-solid fa-info',
            disabled = true,
        }
    end

    lib.registerContext({ id = 'mike_slaughterhouse', title = 'Slaughterhouse', options = opts })
    lib.showContext('mike_slaughterhouse')
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
        if barnZone then exports.ox_target:removeZone(barnZone) end
        for _, ped in ipairs(slaughterPeds) do
            if DoesEntityExist(ped) then SetEntityAsMissionEntity(ped, true, true); DeleteEntity(ped) end
        end
        for _, zid in ipairs(slaughterZones) do exports.ox_target:removeZone(zid) end
    end
end)
