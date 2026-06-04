local function parseTarget(src, arg)
    local tid = tonumber(arg)
    if not tid then return nil end
    if not GetPlayerName(tid) then return nil end
    return tid
end

local function joinArgs(args, from)
    local out = {}
    for i = from, #args do out[#out + 1] = args[i] end
    return table.concat(out, ' ')
end

if Config.Commands.Ban.enabled then
    RSGCore.Commands.Add(Config.Commands.Ban.name, 'Ban a player permanently', {{ name = 'id', help = 'player id' }}, true, function(source, args)
        if not IsAdmin(source) then return end
        local tid = parseTarget(source, args[1])
        if not tid then
            TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Invalid target' })
            return
        end
        local reason = joinArgs(args, 2)
        DoBan(source, tid, -1, reason ~= '' and reason or 'No reason')
    end, 'admin')
end

if Config.Commands.Kick.enabled then
    RSGCore.Commands.Add(Config.Commands.Kick.name, 'Kick a player', {{ name = 'id', help = 'player id' }}, true, function(source, args)
        if not IsAdmin(source) then return end
        local tid = parseTarget(source, args[1])
        if not tid then return end
        DropPlayer(tid, 'Kicked: ' .. (joinArgs(args, 2) ~= '' and joinArgs(args, 2) or 'No reason'))
    end, 'admin')
end

if Config.Commands.Noclip.enabled then
    RSGCore.Commands.Add(Config.Commands.Noclip.name, 'Toggle noclip', {}, false, function(source)
        if not IsAdmin(source) then return end
        TriggerClientEvent('mike-adminmenu:client:toggleNoclip', source)
    end, 'admin')
end

if Config.Commands.Revive.enabled then
    RSGCore.Commands.Add(Config.Commands.Revive.name, 'Revive a player (or self)', {{ name = 'id', help = 'optional player id' }}, false, function(source, args)
        if not IsAdmin(source) then return end
        local tid = args[1] and parseTarget(source, args[1]) or source
        TriggerClientEvent('mike-adminmenu:client:revive', tid)
    end, 'admin')
end

if Config.Commands.Tp.enabled then
    RSGCore.Commands.Add(Config.Commands.Tp.name, 'Teleport to waypoint', {}, false, function(source)
        if not IsAdmin(source) then return end
        TriggerClientEvent('mike-adminmenu:client:tpWaypoint', source)
    end, 'admin')
end

if Config.Commands.Goto.enabled then
    RSGCore.Commands.Add(Config.Commands.Goto.name, 'Teleport to player', {{ name = 'id', help = 'player id' }}, true, function(source, args)
        if not IsAdmin(source) then return end
        local tid = parseTarget(source, args[1]); if not tid then return end
        local c = GetEntityCoords(GetPlayerPed(tid))
        TriggerClientEvent('mike-adminmenu:client:teleport', source, { x = c.x, y = c.y, z = c.z })
    end, 'admin')
end

if Config.Commands.Bring.enabled then
    RSGCore.Commands.Add(Config.Commands.Bring.name, 'Teleport a player to you', {{ name = 'id', help = 'player id' }}, true, function(source, args)
        if not IsAdmin(source) then return end
        local tid = parseTarget(source, args[1]); if not tid then return end
        local c = GetEntityCoords(GetPlayerPed(source))
        TriggerClientEvent('mike-adminmenu:client:teleport', tid, { x = c.x, y = c.y, z = c.z })
    end, 'admin')
end
