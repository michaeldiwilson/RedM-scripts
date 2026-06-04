local speakeasyPeds  = {}
local speakeasyZones = {}
local streetSession  = nil

-- ── Speakeasy bartender spawning + target ───────────────────────────────────
local function loadModel(hash)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 3000 do Wait(10) end
    return HasModelLoaded(hash)
end

local function openSpeakeasyMenu(spec)
    local opts = {}
    for tier, price in pairs(Config.SpeakeasyPrices) do
        opts[#opts + 1] = {
            title = ('%s — $%d each'):format(tier, price),
            onSelect = function()
                local r = lib.inputDialog('Sell ' .. tier, {
                    { type = 'number', label = 'Amount', min = 1, default = 1, required = true },
                })
                if not r then return end
                TriggerServerEvent('mike-moonshine:server:sellSpeakeasy', tier, r[1])
            end,
        }
    end
    lib.registerContext({ id = 'mike_speakeasy_' .. spec.name, title = spec.name, options = opts })
    lib.showContext('mike_speakeasy_' .. spec.name)
end

CreateThread(function()
    Wait(3000)
    for _, spec in ipairs(Config.Speakeasies) do
        -- Outside: enter the speakeasy (TP down to inside)
        local enterId = exports.ox_target:addSphereZone({
            coords = spec.outside,
            radius = 2.0,
            debug  = false,
            options = {
                {
                    name = 'mike_speakeasy_enter_' .. spec.name,
                    label = 'Enter ' .. spec.name,
                    icon  = 'fa-solid fa-door-open',
                    onSelect = function()
                        DoScreenFadeOut(500); Wait(500)
                        SetEntityCoords(PlayerPedId(), spec.inside.x, spec.inside.y, spec.inside.z, false, false, false, false)
                        Wait(500); DoScreenFadeIn(500)
                    end,
                },
            },
        })
        -- Inside: sell moonshine + exit back up
        local sellId = exports.ox_target:addSphereZone({
            coords = spec.bar or spec.inside,
            radius = spec.bar and 3.0 or 25.0,
            debug  = false,
            options = {
                {
                    name = 'mike_speakeasy_sell_' .. spec.name,
                    label = 'Sell moonshine',
                    icon  = 'fa-solid fa-whiskey-glass',
                    onSelect = function() openSpeakeasyMenu(spec) end,
                },
                {
                    name = 'mike_speakeasy_exit_' .. spec.name,
                    label = 'Leave ' .. spec.name,
                    icon  = 'fa-solid fa-door-closed',
                    onSelect = function()
                        DoScreenFadeOut(500); Wait(500)
                        SetEntityCoords(PlayerPedId(), spec.outside.x, spec.outside.y, spec.outside.z, false, false, false, false)
                        Wait(500); DoScreenFadeIn(500)
                    end,
                },
            },
        })
        -- Separate exit zone at the inside coords (covers the whole interior)
        local exitId = exports.ox_target:addSphereZone({
            coords = spec.exit or spec.inside,
            radius = 3.0,
            debug  = false,
            options = {
                {
                    name = 'mike_speakeasy_exit2_' .. spec.name,
                    label = 'Leave ' .. spec.name,
                    icon  = 'fa-solid fa-door-closed',
                    onSelect = function()
                        DoScreenFadeOut(500); Wait(500)
                        SetEntityCoords(PlayerPedId(), spec.outside.x, spec.outside.y, spec.outside.z, false, false, false, false)
                        Wait(500); DoScreenFadeIn(500)
                    end,
                },
            },
        })
        speakeasyZones[#speakeasyZones + 1] = enterId
        speakeasyZones[#speakeasyZones + 1] = sellId
        speakeasyZones[#speakeasyZones + 1] = exitId
    end
    print(('[mike-moonshine] Registered %d speakeasy zones'):format(#speakeasyZones))
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        for _, id in ipairs(speakeasyZones) do
            exports.ox_target:removeZone(id)
        end
    end
end)

-- ── Street dealing ──────────────────────────────────────────────────────────
local function inTown()
    local pc = GetEntityCoords(PlayerPedId())
    for _, z in ipairs(Config.TownZones) do
        local d = #(pc - vector3(z.x, z.y, pc.z))
        if d <= z.r then return z.name end
    end
end

local function getMostValuableBottle()
    -- prefer premium > good > basic for what NPC offers to buy
    for _, tier in ipairs({ 'moonshine_premium', 'moonshine_good', 'moonshine_basic' }) do
        -- client doesn't know inventory; server will verify, but we let all tiers be attempted
        if Config.StreetPrices[tier] then return tier end
    end
end

local function cleanupSession()
    if not streetSession then return end
    for _, entry in ipairs(streetSession.activeNpcs) do
        if entry.ped and DoesEntityExist(entry.ped) then
            exports.ox_target:removeLocalEntity(entry.ped)
            SetEntityAsMissionEntity(entry.ped, true, true)
            DeleteEntity(entry.ped)
        end
    end
    streetSession = nil
end

local function spawnBuyerNPC()
    if not streetSession then return end
    if #streetSession.activeNpcs >= Config.Street.maxNpcs then return end
    local pc  = GetEntityCoords(PlayerPedId())
    local ang = math.random() * 2 * math.pi
    local dx, dy = math.cos(ang) * Config.Street.approachDistance, math.sin(ang) * Config.Street.approachDistance
    local _, gz = GetGroundZFor_3dCoord(pc.x + dx, pc.y + dy, pc.z + 1.0, false)
    local model = Config.Street.npcModels[math.random(#Config.Street.npcModels)]
    local hash  = GetHashKey(model)
    if not loadModel(hash) then return end
    -- Find valid ground for spawn (must be within ~5m of player's Z, else use player's Z)
    local spawnX, spawnY, spawnZ = pc.x + dx, pc.y + dy, pc.z
    local ok, groundZ = GetGroundZFor_3dCoord(spawnX, spawnY, pc.z + 3.0, false)
    if ok and groundZ and math.abs(groundZ - pc.z) <= 5.0 then
        spawnZ = groundZ
    end

    local ped = CreatePed(hash, spawnX, spawnY, spawnZ, math.deg(math.atan(-dx, -dy)), true, false, false, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedConfigFlag(ped, 229, true)
    SetEntityVisible(ped, true)
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true)  -- SetRandomOutfitVariation
    Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, false, true, true, true, false) -- Clear outfit flags / update
    SetModelAsNoLongerNeeded(hash)
    print(('[mike-moonshine] Spawned buyer at %.1f,%.1f,%.1f (dist %.1f)'):format(spawnX, spawnY, spawnZ, #(vector3(spawnX, spawnY, spawnZ) - pc)))

    CreateThread(function()
        Wait(500)
        local startTime = GetGameTimer()
        while DoesEntityExist(ped) and streetSession do
            local player = PlayerPedId()
            local pp = GetEntityCoords(player)
            local np = GetEntityCoords(ped)
            local d = #(pp - np)
            if d <= Config.Street.buyDistance + 0.5 then
                ClearPedTasks(ped)
                TaskTurnPedToFaceEntity(ped, player, 2000)
                return
            end
            -- Hard timeout: if after 20s still not close, teleport right next to player
            if GetGameTimer() - startTime > 20000 then
                print('[mike-moonshine] buyer stuck, teleporting close')
                local fx, fy = pp.x + 1.5, pp.y + 1.5
                SetEntityCoords(ped, fx, fy, pp.z, false, false, false, false)
                ClearPedTasks(ped)
                TaskTurnPedToFaceEntity(ped, player, 2000)
                return
            end
            ClearPedTasks(ped)
            TaskGoToCoordAnyMeans(ped, pp.x, pp.y, pp.z, 1.5, 0, false, 786603, 0)
            Wait(2500)
        end
    end)

    local tier = 'moonshine_basic'  -- NPC picks tier at sale time; client sends all tiers, server picks first available
    local entry = { ped = ped }
    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'mike_street_sell_' .. ped,
            label = 'Sell a jug ($??)',
            icon  = 'fa-solid fa-wine-bottle',
            canInteract = function()
                local p = PlayerPedId()
                return #(GetEntityCoords(p) - GetEntityCoords(ped)) <= Config.Street.buyDistance
            end,
            onSelect = function()
                TriggerServerEvent('mike-moonshine:server:streetDealAuto', GetEntityCoords(PlayerPedId()))
                -- despawn this NPC after deal
                SetTimeout(1500, function()
                    if DoesEntityExist(ped) then
                        exports.ox_target:removeLocalEntity(ped)
                        SetEntityAsMissionEntity(ped, true, true)
                        DeleteEntity(ped)
                    end
                    if streetSession then
                        for i, e in ipairs(streetSession.activeNpcs) do
                            if e.ped == ped then table.remove(streetSession.activeNpcs, i); break end
                        end
                    end
                end)
            end,
        },
    })
    streetSession.activeNpcs[#streetSession.activeNpcs + 1] = entry
end

RegisterCommand('sellshine', function()
    if streetSession then
        lib.notify({ type = 'error', description = 'Already dealing — /stopsell to end' })
        return
    end
    local town = inTown()
    if not town then
        lib.notify({ type = 'error', description = 'You need to be in a town to do this' })
        return
    end
    TriggerServerEvent('mike-moonshine:server:startStreetSession')
end, false)

RegisterCommand('stopsell', function()
    if not streetSession then return end
    TriggerServerEvent('mike-moonshine:server:stopStreetSession')
end, false)

RegisterNetEvent('mike-moonshine:client:streetSessionStart', function()
    streetSession = { activeNpcs = {}, endsAt = GetGameTimer() + Config.Street.sessionTime, spawnedCount = 0 }
    lib.notify({ type = 'inform', title = 'Dealing moonshine', description = 'Wait for buyers to approach... /stopsell to end.' })
    CreateThread(function()
        local nextSpawn = GetGameTimer() + math.random(5000, 15000)
        while streetSession and GetGameTimer() < streetSession.endsAt do
            if GetGameTimer() >= nextSpawn then
                spawnBuyerNPC()
                nextSpawn = GetGameTimer() + math.random(Config.Street.spawnIntervalMin, Config.Street.spawnIntervalMax)
            end
            Wait(500)
        end
        if streetSession then
            TriggerServerEvent('mike-moonshine:server:stopStreetSession')
        end
    end)
end)

RegisterNetEvent('mike-moonshine:client:streetSessionStop', function()
    cleanupSession()
    lib.notify({ type = 'inform', description = 'Dealing session ended.' })
end)

-- Law side: receive a blip alert
local lawBlips = {}
RegisterNetEvent('mike-moonshine:client:lawBlip', function(coords, seconds)
    local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    SetBlipSprite(blip, -1938215886, true) -- suspicious activity-ish icon
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, 'Suspicious activity')
    lawBlips[#lawBlips + 1] = blip
    SetTimeout((seconds or 60) * 1000, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
end)

-- Bust detection: if any law player gets within bustRadius of the dealer during a session
CreateThread(function()
    while true do
        Wait(2000)
        if streetSession then
            local pc = GetEntityCoords(PlayerPedId())
            for _, pid in ipairs(GetActivePlayers()) do
                local ped = GetPlayerPed(pid)
                if ped ~= PlayerPedId() and DoesEntityExist(ped) then
                    local d = #(pc - GetEntityCoords(ped))
                    if d <= Config.Street.bustRadius then
                        -- we don't know their job client-side; let server verify on bust request
                        TriggerServerEvent('mike-moonshine:server:checkBust', GetPlayerServerId(pid))
                    end
                end
            end
        end
    end
end)
