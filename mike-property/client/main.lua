local RSGCore = exports['rsg-core']:GetCoreObject()

claimData = {}      -- id -> claim data from server (global for build.lua)
local claimBlips = {}     -- id -> blip
local claimProps = {}     -- objId -> entity
local claimZones = {}     -- zone ids
local officeZones = {}

-- ──────────────────────────────────────────────────────────────────────────
-- Sync from server
-- ──────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mike-property:client:sync', function(data)
    claimData = data or {}

    -- Remove props for objects that no longer exist
    for objId, ent in pairs(claimProps) do
        local found = false
        for _, claim in pairs(claimData) do
            if claim.objects[objId] then found = true; break end
        end
        if not found then
            if DoesEntityExist(ent) then
                SetEntityAsMissionEntity(ent, true, true)
                DeleteEntity(ent)
            end
            claimProps[objId] = nil
        end
    end

    -- Update blips
    for id in pairs(claimBlips) do
        if not claimData[id] then
            if DoesBlipExist(claimBlips[id]) then RemoveBlip(claimBlips[id]) end
            claimBlips[id] = nil
        end
    end
    for id, claim in pairs(claimData) do
        if not claimBlips[id] then
            local blip = BlipAddForCoords(1664425300, claim.x + 0.0, claim.y + 0.0, claim.z + 0.0)
            SetBlipSprite(blip, joaat('blip_shop_gunsmith'), true)
            SetBlipScale(blip, 0.6)
            SetBlipName(blip, 'Land Claim')
            claimBlips[id] = blip
        end
    end
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Spawn/despawn objects based on proximity (only for online owners)
-- ──────────────────────────────────────────────────────────────────────────
local function loadModel(hash)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 3000 do Wait(10) end
    return HasModelLoaded(hash)
end

local function spawnObject(objId, obj)
    if claimProps[objId] and DoesEntityExist(claimProps[objId]) then return end
    local hash = GetHashKey(obj.prop)
    if not loadModel(hash) then return end
    local isBuilding = obj.obj_type and (obj.obj_type:find('house') ~= nil)
    local ent = CreateObject(hash, obj.x + 0.0, obj.y + 0.0, obj.z + 0.0, false, false, false, true, true)
    if not isBuilding then
        PlaceObjectOnGroundProperly(ent)
    else
        -- Force exact saved Z for buildings (CreateObject may snap to ground)
        SetEntityCoordsNoOffset(ent, obj.x + 0.0, obj.y + 0.0, obj.z + 0.0, false, false, false)
    end
    SetEntityHeading(ent, obj.heading + 0.0)
    FreezeEntityPosition(ent, true)
    SetEntityAsMissionEntity(ent, true, true)
    SetModelAsNoLongerNeeded(hash)
    claimProps[objId] = ent

    -- Add ox_target for storage objects
    local placeable = Config.Placeables[obj.obj_type]
    if placeable and placeable.stash then
        exports.ox_target:addLocalEntity(ent, {
            {
                name     = 'mike_prop_stash_' .. objId,
                label    = 'Open ' .. placeable.label,
                icon     = 'fa-solid fa-box-open',
                onSelect = function()
                    lib.callback.await('mike-property:server:openStash', false, objId)
                end,
            },
        })
    end
end

function despawnObject(objId)
    local ent = claimProps[objId]
    if ent then
        if DoesEntityExist(ent) then
            exports.ox_target:removeLocalEntity(ent)
            SetEntityAsMissionEntity(ent, true, true)
            DeleteEntity(ent)
        end
        claimProps[objId] = nil
    end
end

-- Boundary posts (8 stakes around each claim edge)
local boundaryProps = {}  -- claimId -> { entity, ... }
local BOUNDARY_PROP = 'p_fencepost03x'
local BOUNDARY_POINTS = 8

local function spawnBoundary(claim)
    if boundaryProps[claim.id] then return end
    local hash = GetHashKey(BOUNDARY_PROP)
    if not loadModel(hash) then return end

    local posts = {}
    for i = 1, BOUNDARY_POINTS do
        local angle = (i / BOUNDARY_POINTS) * math.pi * 2
        local bx = claim.x + math.cos(angle) * claim.radius
        local by = claim.y + math.sin(angle) * claim.radius
        local _, gz = GetGroundZFor_3dCoord(bx, by, claim.z + 5.0, false)
        local bz = gz > 0 and gz or claim.z
        local post = CreateObject(hash, bx, by, bz, false, false, false, true, true)
        PlaceObjectOnGroundProperly(post)
        FreezeEntityPosition(post, true)
        SetEntityAsMissionEntity(post, true, true)
        posts[#posts + 1] = post
    end
    SetModelAsNoLongerNeeded(hash)
    boundaryProps[claim.id] = posts
end

local function despawnBoundary(claimId)
    if not boundaryProps[claimId] then return end
    for _, post in ipairs(boundaryProps[claimId]) do
        if DoesEntityExist(post) then
            SetEntityAsMissionEntity(post, true, true)
            DeleteEntity(post)
        end
    end
    boundaryProps[claimId] = nil
end

CreateThread(function()
    while true do
        Wait(3000)
        local pc = GetEntityCoords(PlayerPedId())
        for id, claim in pairs(claimData) do
            local d = #(pc - vector3(claim.x + 0.0, claim.y + 0.0, claim.z + 0.0))
            if d <= 150.0 then
                -- Always show boundary when nearby
                spawnBoundary(claim)
                -- Only show placed objects if owner is online
                if claim.ownerOnline then
                    for objId, obj in pairs(claim.objects or {}) do
                        spawnObject(objId, obj)
                    end
                else
                    for objId in pairs(claim.objects or {}) do
                        despawnObject(objId)
                    end
                end
            else
                despawnBoundary(id)
                for objId in pairs(claim.objects or {}) do
                    despawnObject(objId)
                end
            end
        end
    end
end)

-- ──────────────────────────────────────────────────────────────────────────
-- Land Office: buy claim + manage
-- ──────────────────────────────────────────────────────────────────────────
local function openLandOffice()
    local opts = {}

    -- Buy deed items
    for typeKey, ct in pairs(Config.ClaimTypes) do
        opts[#opts + 1] = {
            title       = ('Buy %s Deed — $%d'):format(ct.label, ct.price),
            description = ('%s (%.0fm radius) — use from inventory to claim'):format(ct.description, ct.radius),
            icon        = 'fa-solid fa-map',
            onSelect    = function()
                lib.callback.await('mike-property:server:buyDeed', false, typeKey)
            end,
        }
    end

    -- Manage existing claims
    opts[#opts + 1] = {
        title = 'Manage my claims',
        icon  = 'fa-solid fa-list',
        onSelect = function() openMyClaimsMenu() end,
    }

    lib.registerContext({ id = 'mike_land_office', title = 'Land Office', options = opts })
    lib.showContext('mike_land_office')
end

function openMyClaimsMenu()
    local myClaims = lib.callback.await('mike-property:server:getMyClaims', false)
    if not myClaims or #myClaims == 0 then
        return lib.notify({ type = 'inform', description = 'You have no land claims' })
    end

    local opts = {}
    for _, c in ipairs(myClaims) do
        local ct = Config.ClaimTypes[c.claim_type] or {}
        opts[#opts + 1] = {
            title       = (ct.label or c.claim_type) .. (' (%.0f, %.0f)'):format(c.x, c.y),
            description = ('%.0fm radius'):format(c.radius),
            icon        = 'fa-solid fa-house',
            onSelect    = function()
                local confirm = lib.alertDialog({
                    header = 'Abandon this claim?',
                    content = 'All placed objects will be lost. This cannot be undone.',
                    centered = true,
                    cancel = true,
                })
                if confirm == 'confirm' then
                    lib.callback.await('mike-property:server:abandon', false, c.id)
                end
            end,
        }
    end

    lib.registerContext({ id = 'mike_my_claims', title = 'My Claims', menu = 'mike_land_office', options = opts })
    lib.showContext('mike_my_claims')
end

-- ──────────────────────────────────────────────────────────────────────────
-- Claim placement (ghost boundary)
-- ──────────────────────────────────────────────────────────────────────────
-- Deed items handle claiming via server-side CreateUseableItem

-- ──────────────────────────────────────────────────────────────────────────
-- Land office zones
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    Wait(2500)
    for idx, office in ipairs(Config.LandOffices) do
        local zid = exports.ox_target:addSphereZone({
            coords = office.coords,
            radius = Config.LandOfficeRadius,
            debug  = false,
            options = {
                {
                    name  = 'mike_land_office_' .. idx,
                    label = office.name,
                    icon  = 'fa-solid fa-map',
                    onSelect = function() openLandOffice() end,
                },
            },
        })
        officeZones[#officeZones + 1] = zid

        local blip = BlipAddForCoords(1664425300, office.coords)
        SetBlipSprite(blip, joaat('blip_shop_gunsmith'), true)
        SetBlipScale(blip, 0.75)
        SetBlipName(blip, office.name)
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        for _, id in ipairs(officeZones) do exports.ox_target:removeZone(id) end
        for _, b in pairs(claimBlips) do if DoesBlipExist(b) then RemoveBlip(b) end end
        for objId in pairs(claimProps) do despawnObject(objId) end
        for id in pairs(boundaryProps) do despawnBoundary(id) end
    end
end)

-- ──────────────────────────────────────────────────────────────────────────
-- /buildingscan — scans all objects within 25m and prints their model hashes.
-- Stand next to a cabin/building, run this, check F8 for model hashes.
-- Then try spawning them with admin spawner to see if they work.
-- ──────────────────────────────────────────────────────────────────────────
RegisterCommand('buildingscan', function()
    local p = GetEntityCoords(PlayerPedId())
    local found = 0

    -- Scan CObject pool
    local objects = GetGamePool('CObject')
    if objects then
        for _, obj in pairs(objects) do
            if DoesEntityExist(obj) then
                local c = GetEntityCoords(obj)
                local d = #(c - p)
                if d <= 25.0 then
                    local model = GetEntityModel(obj)
                    found = found + 1
                    print(('[buildingscan] OBJ model=0x%X (%d) dist=%.1fm pos=%.1f,%.1f,%.1f'):format(model, model, d, c.x, c.y, c.z))
                end
            end
        end
    end

    -- Also scan building entities (type 3 = object)
    local handle, entity = FindFirstObject()
    local success = true
    local buildingCount = 0
    while success do
        if DoesEntityExist(entity) then
            local c = GetEntityCoords(entity)
            local d = #(c - p)
            if d <= 25.0 then
                local model = GetEntityModel(entity)
                if model ~= 0 then
                    buildingCount = buildingCount + 1
                    print(('[buildingscan] FIND model=0x%X (%d) dist=%.1fm'):format(model, model, d))
                end
            end
        end
        success, entity = FindNextObject(handle)
    end
    EndFindObject(handle)

    local msg = ('Pool: %d objects | FindObject: %d objects'):format(found, buildingCount)
    print('[buildingscan] ' .. msg)
    lib.notify({ type = 'inform', title = 'Building Scan', description = msg .. ' — check F8', duration = 8000 })
end, false)
