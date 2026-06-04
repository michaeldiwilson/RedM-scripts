RSGCore = exports['rsg-core']:GetCoreObject()

NodeZones = {}
NodeBlips = {}
local depleted = {}

local function addBlip(idx, node)
    if NodeBlips[idx] and DoesBlipExist(NodeBlips[idx]) then return end
    local blip = BlipAddForCoords(1664425300, vector3(node.x, node.y, node.z))
    SetBlipSprite(blip, joaat('blip_shop_gunsmith'), true)
    SetBlipScale(blip, 0.9)
    SetBlipName(blip, ('%s ore deposit'):format(node.type))
    NodeBlips[idx] = blip
end

local function removeBlip(idx)
    if NodeBlips[idx] and DoesBlipExist(NodeBlips[idx]) then RemoveBlip(NodeBlips[idx]) end
    NodeBlips[idx] = nil
end

local function registerZone(idx, node)
    if NodeZones[idx] then return end
    local zoneId = exports.ox_target:addSphereZone({
        coords = vec3(node.x, node.y, node.z),
        radius = Config.ZoneRadius,
        debug  = false,
        options = {
            {
                name  = 'mike_mine_' .. idx,
                label = 'Mine ' .. node.type,
                icon  = 'fa-solid fa-hammer',
                onSelect = function() StartMine(idx) end,
            },
            {
                name  = 'mike_tnt_' .. idx,
                label = 'Place TNT',
                icon  = 'fa-solid fa-bomb',
                onSelect = function() PlaceTNT(idx, node) end,
            },
        },
    })
    NodeZones[idx] = zoneId
end

local function removeZone(idx)
    if NodeZones[idx] then
        exports.ox_target:removeZone(NodeZones[idx])
        NodeZones[idx] = nil
    end
end

RegisterNetEvent('mike-mining:client:syncDepleted', function(d)
    depleted = d or {}
    for idx, _ in pairs(Config.Nodes) do
        if depleted[idx] or depleted[tostring(idx)] then
            removeZone(idx); removeBlip(idx)
        end
    end
end)

CreateThread(function()
    Wait(2000)
    for idx, node in ipairs(Config.Nodes) do
        if not (depleted[idx] or depleted[tostring(idx)]) then
            addBlip(idx, node)
            registerZone(idx, node)
        end
    end
    print(('[mike-mining] Registered %d mining zones'):format(#Config.Nodes))
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        for idx, _ in pairs(NodeZones) do removeZone(idx) end
        for idx, _ in pairs(NodeBlips) do removeBlip(idx) end
    end
end)
