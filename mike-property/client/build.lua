local RSGCore = exports['rsg-core']:GetCoreObject()

-- ──────────────────────────────────────────────────────────────────────────
-- Build mode: press B while standing on your claim
-- ──────────────────────────────────────────────────────────────────────────
local function getMyClaimHere()
    local p = GetEntityCoords(PlayerPedId())
    local P = RSGCore.Functions.GetPlayerData()
    if not P then return nil end
    local cid = P.citizenid

    for id, claim in pairs(claimData) do
        if claim.owner_cid == cid then
            local d = #(p - vector3(claim.x + 0.0, claim.y + 0.0, claim.z + 0.0))
            if d <= claim.radius then
                return id, claim
            end
        end
    end
    return nil
end

local function openBuildMenu(claimId, claim)
    local opts = {}

    for typeKey, placeable in pairs(Config.Placeables) do
        -- Count existing
        local count = 0
        for _, obj in pairs(claim.objects or {}) do
            if obj.obj_type == typeKey then count = count + 1 end
        end

        local reqs = {}
        for item, n in pairs(placeable.recipe) do reqs[#reqs + 1] = ('%d× %s'):format(n, item) end

        opts[#opts + 1] = {
            title       = ('Build %s (%d/%d)'):format(placeable.label, count, placeable.limit),
            description = 'Needs: ' .. table.concat(reqs, ', '),
            icon        = 'fa-solid fa-hammer',
            disabled    = count >= placeable.limit,
            onSelect    = function()
                startObjectPlacement(claimId, claim, typeKey, placeable)
            end,
        }
    end

    -- Remove objects option
    local objList = {}
    for objId, obj in pairs(claim.objects or {}) do
        local p = Config.Placeables[obj.obj_type]
        objList[#objList + 1] = { id = objId, label = p and p.label or obj.obj_type }
    end
    if #objList > 0 then
        opts[#opts + 1] = {
            title = 'Remove an object',
            icon  = 'fa-solid fa-trash',
            onSelect = function() openRemoveMenu(claimId, objList) end,
        }
    end

    lib.registerContext({ id = 'mike_build_' .. claimId, title = 'Build on your land', options = opts })
    lib.showContext('mike_build_' .. claimId)
end

function openRemoveMenu(claimId, objList)
    local opts = {}
    for _, obj in ipairs(objList) do
        opts[#opts + 1] = {
            title  = 'Remove ' .. obj.label,
            icon   = 'fa-solid fa-xmark',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Remove ' .. obj.label .. '?',
                    content = 'Materials will be refunded.',
                    centered = true,
                    cancel = true,
                })
                if confirm == 'confirm' then
                    local ok = lib.callback.await('mike-property:server:removeObject', false, claimId, obj.id)
                    if ok then
                        despawnObject(obj.id)
                    end
                end
            end,
        }
    end
    lib.registerContext({ id = 'mike_remove_' .. claimId, title = 'Remove object', menu = 'mike_build_' .. claimId, options = opts })
    lib.showContext('mike_remove_' .. claimId)
end

-- ──────────────────────────────────────────────────────────────────────────
-- Ghost placement for objects
-- ──────────────────────────────────────────────────────────────────────────
function startObjectPlacement(claimId, claim, objType, placeable)
    local hash = GetHashKey(placeable.prop)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 5000 do Wait(10) end
    if not HasModelLoaded(hash) then return end

    local ghost = CreateObject(hash, 0, 0, 0, false, false, false, true, true)
    SetEntityAlpha(ghost, 150, false)
    SetEntityCollision(ghost, false, false)
    FreezeEntityPosition(ghost, true)
    SetModelAsNoLongerNeeded(hash)

    lib.notify({ type = 'inform', description = 'ENTER = place | BACKSPACE = cancel | PGUP/PGDN = raise/lower', duration = 8000 })

    local placing = true
    local zOffset = 0.0
    CreateThread(function()
        local ENTER_KEY = 0xC7B5340A
        local BACKSPACE_KEY = 0x156F7119
        local PGUP_KEY = 0x446258B6
        local PGDN_KEY = 0x3C3DD371

        while placing do
            Wait(0)
            local ped = PlayerPedId()
            local p = GetEntityCoords(ped)
            local fwd = GetEntityForwardVector(ped)
            local ahead = vector3(p.x + fwd.x * 3.0, p.y + fwd.y * 3.0, p.z)

            -- Height adjust
            if IsControlPressed(0, PGUP_KEY) then zOffset = zOffset + 0.02 end
            if IsControlPressed(0, PGDN_KEY) then zOffset = zOffset - 0.02 end

            -- Raycast to ground
            local ray = StartShapeTestRay(ahead.x, ahead.y, ahead.z + 2.0, ahead.x, ahead.y, ahead.z - 5.0, 1, ped, 0)
            local _, hit, hitPos = GetShapeTestResult(ray)
            local placePos = (hit == 1 and hitPos) or ahead

            local isBuilding = objType and (objType:find('house') ~= nil)
            local ghostZ = placePos.z + zOffset
            SetEntityCoords(ghost, placePos.x, placePos.y, ghostZ, false, false, false, false)
            if not isBuilding then
                PlaceObjectOnGroundProperly(ghost)
            end
            SetEntityHeading(ghost, GetEntityHeading(ped))

            if IsControlJustReleased(0, ENTER_KEY) then
                placing = false
                local finalPos = GetEntityCoords(ghost)
                local finalHeading = GetEntityHeading(ghost)

                SetEntityAsMissionEntity(ghost, true, true)
                DeleteEntity(ghost)

                -- Progress bar for building
                if lib.progressBar({
                    duration = 5000,
                    label = 'Building ' .. placeable.label .. '...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                }) then
                    lib.callback.await('mike-property:server:placeObject', false, claimId, objType, { x = finalPos.x, y = finalPos.y, z = finalPos.z }, finalHeading)
                end
            end

            if IsControlJustReleased(0, BACKSPACE_KEY) then
                placing = false
                SetEntityAsMissionEntity(ghost, true, true)
                DeleteEntity(ghost)
                lib.notify({ type = 'error', description = 'Placement cancelled' })
            end
        end
    end)
end

-- ──────────────────────────────────────────────────────────────────────────
-- B key: open build menu when standing on your claim
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    local B_KEY = 0x4CC0E2FE
    while true do
        Wait(0)
        if IsControlJustReleased(0, B_KEY) then
            local claimId, claim = getMyClaimHere()
            if claimId then
                openBuildMenu(claimId, claim)
            end
        end
    end
end)
