local zones = {}
local inZone = nil
local zoneBlips = {}

local function clearBlips()
    for _, b in ipairs(zoneBlips) do if DoesBlipExist(b) then RemoveBlip(b) end end
    zoneBlips = {}
end

local function rebuildBlips()
    clearBlips()
    for _, z in ipairs(zones) do
        if z.blip_sprite then
            local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, z.x + 0.0, z.y + 0.0, z.z + 0.0)
            SetBlipSprite(blip, tonumber(z.blip_sprite), true)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, z.name) -- SetBlipName
            zoneBlips[#zoneBlips + 1] = blip
        end
    end
end

RegisterNetEvent('mike-adminmenu:client:syncZones', function(list)
    zones = list or {}
    rebuildBlips()
end)

local function applyZoneEffects(z)
    local ped = PlayerPedId()
    if z.auto_revive == 1 and IsPedDeadOrDying(ped, true) then
        NetworkResurrectLocalPlayer(GetEntityCoords(ped), GetEntityHeading(ped), true, false, false)
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
    end
    if z.invincible == 1 then SetEntityInvincible(ped, true) end
    if z.disarm == 1 then
        RemoveAllPedWeapons(ped, true)
    end
end

local function clearZoneEffects()
    SetEntityInvincible(PlayerPedId(), false)
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local pc  = GetEntityCoords(ped)
        local currentZone = nil
        for _, z in ipairs(zones) do
            local d = #(pc - vector3(z.x + 0.0, z.y + 0.0, z.z + 0.0))
            if d <= (z.radius or 20.0) then currentZone = z; break end
        end
        if currentZone and not inZone then
            inZone = currentZone
            lib.notify({ type = 'inform', description = 'Entered admin zone: ' .. currentZone.name })
        elseif not currentZone and inZone then
            lib.notify({ type = 'inform', description = 'Left admin zone: ' .. inZone.name })
            inZone = nil
            clearZoneEffects()
        end
        if inZone then applyZoneEffects(inZone) end
        Wait(1000)
    end
end)

function OpenZonesMenu()
    RSGCore.Functions.TriggerCallback('mike-adminmenu:server:getZones', function(list)
        local opts = {
            { title = 'Create zone here', description = 'Use current coords', icon = 'plus', onSelect = CreateZoneDialog },
        }
        for _, z in ipairs(list or {}) do
            opts[#opts + 1] = {
                title       = ('#%d %s'):format(z.id, z.name),
                description = ('r=%.0f revive=%s disarm=%s god=%s'):format(z.radius, z.auto_revive == 1 and 'Y' or 'N', z.disarm == 1 and 'Y' or 'N', z.invincible == 1 and 'Y' or 'N'),
                onSelect    = function() ZoneActions(z) end,
            }
        end
        lib.registerContext({ id = 'mike_admin_zones', title = ('Admin Zones (%d)'):format(#(list or {})), menu = 'mike_admin_root', options = opts })
        lib.showContext('mike_admin_zones')
    end)
end

function CreateZoneDialog()
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local r = lib.inputDialog('Create Admin Zone', {
        { type = 'input',  label = 'Name', required = true },
        { type = 'number', label = 'Radius (meters)', default = 20, min = 1, max = 500 },
        { type = 'number', label = 'Blip sprite (optional)', min = 0 },
        { type = 'checkbox', label = 'Auto revive' },
        { type = 'checkbox', label = 'Disarm on enter' },
        { type = 'checkbox', label = 'Invincible inside' },
        { type = 'number', label = 'Speed limit (optional, mph)', min = 0 },
    })
    if not r then return end
    TriggerServerEvent('mike-adminmenu:server:createZone', {
        name        = r[1],
        x = c.x, y = c.y, z = c.z,
        radius      = r[2],
        blip_sprite = r[3],
        auto_revive = r[4],
        disarm      = r[5],
        invincible  = r[6],
        speed_limit = r[7],
    })
end

function ZoneActions(z)
    lib.registerContext({
        id = 'mike_admin_zone_' .. z.id,
        title = z.name,
        menu = 'mike_admin_zones',
        options = {
            { title = 'Teleport here', icon = 'map-pin', onSelect = function()
                SetEntityCoords(PlayerPedId(), z.x + 0.0, z.y + 0.0, z.z + 0.5, false, false, false, false)
            end },
            { title = 'Delete zone', icon = 'trash', onSelect = function()
                local ok = lib.alertDialog({ header = 'Delete zone', content = 'Delete "' .. z.name .. '"?', cancel = true, labels = { confirm = 'Delete' } })
                if ok == 'confirm' then
                    TriggerServerEvent('mike-adminmenu:server:deleteZone', z.id)
                    Wait(300); OpenZonesMenu()
                end
            end },
        },
    })
    lib.showContext('mike_admin_zone_' .. z.id)
end
