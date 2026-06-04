RegisterNetEvent('mike-adminmenu:server:openAppearance', function(targetId)
    local src = source
    if not AssertAdmin(src) then return end
    targetId = tonumber(targetId) or src
    if not GetPlayerName(targetId) then return end
    TriggerClientEvent('rsg-appearance:client:OpenCreator', targetId)
    if targetId ~= src then
        TriggerClientEvent('ox_lib:notify', targetId, { type = 'inform', description = 'Admin opened appearance for you' })
    end
end)
