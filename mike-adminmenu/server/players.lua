RegisterNetEvent('mike-adminmenu:server:action', function(action, targetId, payload)
    local src = source
    if not AssertAdmin(src) then return end
    targetId = tonumber(targetId)
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Target not online' })
        return
    end

    if action == 'revive' then
        TriggerClientEvent('mike-adminmenu:client:revive', targetId)
    elseif action == 'heal' then
        TriggerClientEvent('mike-adminmenu:client:heal', targetId)
    elseif action == 'freeze' then
        TriggerClientEvent('mike-adminmenu:client:freeze', targetId, payload and payload.state)
    elseif action == 'spectate' then
        TriggerClientEvent('mike-adminmenu:client:spectate', src, targetId)
    elseif action == 'goto' then
        local ped = GetPlayerPed(targetId)
        if ped ~= 0 then
            local c = GetEntityCoords(ped)
            TriggerClientEvent('mike-adminmenu:client:teleport', src, { x = c.x, y = c.y, z = c.z })
        end
    elseif action == 'bring' then
        local adminPed = GetPlayerPed(src)
        if adminPed ~= 0 then
            local c = GetEntityCoords(adminPed)
            TriggerClientEvent('mike-adminmenu:client:teleport', targetId, { x = c.x, y = c.y, z = c.z })
        end
    elseif action == 'kick' then
        DropPlayer(targetId, 'Kicked: ' .. (payload and payload.reason or 'No reason'))
    elseif action == 'giveMoney' then
        local P = RSGCore.Functions.GetPlayer(targetId)
        local account = payload and payload.account or 'cash'
        local amount  = tonumber(payload and payload.amount) or 0
        if P and amount > 0 then
            P.Functions.AddMoney(account, amount, 'admin-give')
            TriggerClientEvent('ox_lib:notify', src,       { type = 'success', description = ('Gave %s $%d'):format(GetPlayerName(targetId), amount) })
            TriggerClientEvent('ox_lib:notify', targetId,  { type = 'inform',  description = ('Received $%d (%s) from admin'):format(amount, account) })
        end
    end
end)

RegisterNetEvent('mike-adminmenu:server:selfAction', function(action, payload)
    local src = source
    if not AssertAdmin(src) then return end
    if action == 'revive' then
        TriggerClientEvent('mike-adminmenu:client:revive', src)
    elseif action == 'heal' then
        TriggerClientEvent('mike-adminmenu:client:heal', src)
    end
end)

RegisterNetEvent('mike-adminmenu:server:announce', function(message, jobName)
    local src = source
    if not AssertAdmin(src) then return end
    if not message or message == '' then return end
    local prefix = Config.AnnouncePrefix
    if jobName then
        local players = RSGCore.Functions.GetPlayers()
        for _, pid in ipairs(players) do
            local P = RSGCore.Functions.GetPlayer(pid)
            if P and P.PlayerData.job and P.PlayerData.job.name == jobName then
                TriggerClientEvent('ox_lib:notify', pid, { type = 'inform', title = prefix .. ' ' .. jobName, description = message, duration = 10000 })
            end
        end
    else
        TriggerClientEvent('ox_lib:notify', -1, { type = 'inform', title = prefix, description = message, duration = 10000 })
    end
end)

RegisterNetEvent('mike-adminmenu:server:setWeather', function(weather)
    local src = source
    if not AssertAdmin(src) then return end
    TriggerClientEvent('mike-adminmenu:client:setWeather', -1, weather)
end)

RegisterNetEvent('mike-adminmenu:server:setTime', function(hour, minute)
    local src = source
    if not AssertAdmin(src) then return end
    TriggerClientEvent('mike-adminmenu:client:setTime', -1, tonumber(hour) or 12, tonumber(minute) or 0)
end)

RegisterNetEvent('mike-adminmenu:server:cleanup', function(kind)
    local src = source
    if not AssertAdmin(src) then return end
    TriggerClientEvent('mike-adminmenu:client:cleanup', -1, kind)
end)
