local zones = {}

local function loadZones()
    local rows = MySQL.query.await('SELECT * FROM mike_admin_zones', {})
    zones = rows or {}
    TriggerClientEvent('mike-adminmenu:client:syncZones', -1, zones)
end

AddEventHandler('onResourceStart', function(r)
    if r == GetCurrentResourceName() then
        CreateThread(function() Wait(2000); loadZones() end)
    end
end)

AddEventHandler('playerJoining', function()
    local src = source
    CreateThread(function() Wait(3000); TriggerClientEvent('mike-adminmenu:client:syncZones', src, zones) end)
end)

RSGCore.Functions.CreateCallback('mike-adminmenu:server:getZones', function(source, cb)
    if not IsAdmin(source) then return cb({}) end
    cb(zones)
end)

RegisterNetEvent('mike-adminmenu:server:createZone', function(data)
    local src = source
    if not AssertAdmin(src) then return end
    if not data or not data.name or data.name == '' then return end
    local ok, err = pcall(function()
        MySQL.insert.await([[
            INSERT INTO mike_admin_zones (name, x, y, z, radius, blip_sprite, blip_color, auto_revive, disarm, invincible, speed_limit, created_by, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            data.name, data.x, data.y, data.z, data.radius or 20.0,
            data.blip_sprite, data.blip_color or 0,
            data.auto_revive and 1 or 0, data.disarm and 1 or 0, data.invincible and 1 or 0,
            data.speed_limit,
            GetPlayerName(src) or 'Admin',
            os.time(),
        })
    end)
    if not ok then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Zone exists or DB error' })
        return
    end
    loadZones()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Zone created: ' .. data.name })
end)

RegisterNetEvent('mike-adminmenu:server:deleteZone', function(id)
    local src = source
    if not AssertAdmin(src) then return end
    MySQL.update.await('DELETE FROM mike_admin_zones WHERE id = ?', { tonumber(id) })
    loadZones()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Zone deleted' })
end)
