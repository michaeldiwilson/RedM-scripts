RegisterNetEvent('mike-moonshine:client:tryCraft', function()
    local parts = ''
    for item, n in pairs(Config.CraftRecipe.inputs) do
        parts = parts .. ('\n- %d x %s'):format(n, item)
    end
    local ok = lib.alertDialog({
        header  = 'Build Portable Still',
        content = 'Required:' .. parts .. '\n\nProceed?',
        cancel  = true,
        labels  = { confirm = 'Build', cancel = 'Cancel' },
    })
    if ok ~= 'confirm' then return end
    if lib.progressBar({ duration = Config.CraftRecipe.time, label = 'Assembling still...', useWhileDead = false, canCancel = true,
        disable = { move = true, car = true, combat = true } }) then
        TriggerServerEvent('mike-moonshine:server:craftStill')
    end
end)

RegisterNetEvent('mike-moonshine:client:startPlace', function()
    local ped = PlayerPedId()
    local c = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.5, 0.0)
    local _, gz = GetGroundZFor_3dCoord(c.x, c.y, c.z + 2.0, false)
    if lib.progressBar({ duration = 6000, label = 'Placing still...', useWhileDead = false, canCancel = true,
        disable = { move = true, car = true, combat = true } }) then
        TriggerServerEvent('mike-moonshine:server:place', { x = c.x, y = c.y, z = gz > 0 and gz or c.z }, GetEntityHeading(ped))
    end
end)
