local treeCooldown = {}

local function keyForPos(x, y, z)
    return ('%.0f_%.0f_%.0f'):format(x, y, z)
end

local function posOnCooldown(x, y, z)
    local k = keyForPos(x, y, z)
    local t = treeCooldown[k]
    if not t then return false end
    if GetGameTimer() - t >= (Config.TreeCooldownSec * 1000) then
        treeCooldown[k] = nil
        return false
    end
    return true
end

-- ──────────────────────────────────────────────────────────────────────────
-- Raycast forward from player to find a solid object (tree trunk) nearby
-- Returns hit position if something is in front of the player within range
-- ──────────────────────────────────────────────────────────────────────────
local function raycastForTree()
    local ped = PlayerPedId()
    local p = GetEntityCoords(ped)
    local fwd = GetEntityForwardVector(ped)
    local from = vector3(p.x, p.y, p.z + 0.5)
    local to   = vector3(p.x + fwd.x * Config.TreeSearchRadius,
                         p.y + fwd.y * Config.TreeSearchRadius,
                         p.z + 0.5)

    local ray = StartShapeTestRay(from.x, from.y, from.z, to.x, to.y, to.z, -1, ped, 0)
    local _, hit, hitPos, _, hitEnt = GetShapeTestResult(ray)

    if hit ~= 1 or not hitPos then return nil end

    -- Ignore hits on the ground (z too far below player)
    if hitPos.z < p.z - 1.0 then return nil end

    -- Ignore hits on peds or vehicles
    if hitEnt and hitEnt ~= 0 then
        local entType = GetEntityType(hitEnt)
        if entType == 1 or entType == 2 then return nil end  -- 1=ped, 2=vehicle
    end

    return hitPos.x, hitPos.y, hitPos.z
end

-- ──────────────────────────────────────────────────────────────────────────
-- /chopwood (G key) — face a tree trunk, press G to chop
-- ──────────────────────────────────────────────────────────────────────────
local function tryChop()
    local x, y, z = raycastForTree()
    if not x then
        return lib.notify({ type = 'error', description = 'No tree in front of you. Face a trunk and try again.' })
    end
    if posOnCooldown(x, y, z) then
        return lib.notify({ type = 'error', description = 'This tree is spent — find another.' })
    end
    if lib.progressBar({
        duration = Config.ChopTime,
        label = 'Chopping wood...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    }) then
        treeCooldown[keyForPos(x, y, z)] = GetGameTimer()
        TriggerServerEvent('mike-lumber:server:chop')
    end
end

RegisterCommand('chopwood', tryChop, false)

-- G key (0x760A9C6F) — same pattern rsg-inventory uses for I key
CreateThread(function()
    local G_KEY = 0x760A9C6F
    while true do
        Wait(0)
        if IsControlJustReleased(0, G_KEY) then
            local hatchet = exports['rsg-inventory']:HasItem('hatchet', 1)
            if hatchet then
                tryChop()
            end
        end
    end
end)
