local noclipOn = false
local speed = Config.Noclip.DefaultSpeed

function IsNoclipOn() return noclipOn end

function ToggleNoclip()
    noclipOn = not noclipOn
    local ped = PlayerPedId()
    SetEntityInvincible(ped, noclipOn)
    SetEntityVisible(ped, not noclipOn)
    SetEntityCollision(ped, not noclipOn, not noclipOn)
    FreezeEntityPosition(ped, noclipOn)
    lib.notify({ type = 'inform', description = noclipOn and 'Noclip ON' or 'Noclip OFF' })

    if not noclipOn then return end

    CreateThread(function()
        while noclipOn do
            local p = PlayerPedId()
            local coords = GetEntityCoords(p)
            local heading = GetEntityHeading(p)
            local dx, dy, dz = 0.0, 0.0, 0.0

            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 32, true)
            DisableControlAction(0, 33, true)
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 35, true)

            if IsDisabledControlPressed(0, 32) then dy = speed end   -- W
            if IsDisabledControlPressed(0, 33) then dy = -speed end  -- S
            if IsDisabledControlPressed(0, 34) then dx = -speed end  -- A
            if IsDisabledControlPressed(0, 35) then dx = speed end   -- D
            if IsControlPressed(0, 44) then dz = speed end           -- Q up
            if IsControlPressed(0, 38) then dz = -speed end          -- E down
            if IsControlJustPressed(0, 241) then                     -- wheel up
                speed = math.min(speed + Config.Noclip.SpeedStep, Config.Noclip.MaxSpeed)
            end
            if IsControlJustPressed(0, 242) then                     -- wheel down
                speed = math.max(speed - Config.Noclip.SpeedStep, Config.Noclip.MinSpeed)
            end

            local rad = math.rad(heading)
            local fx = -math.sin(rad)
            local fy =  math.cos(rad)
            local rx =  math.cos(rad)
            local ry =  math.sin(rad)

            local nx = coords.x + (fx * dy) + (rx * dx)
            local ny = coords.y + (fy * dy) + (ry * dx)
            local nz = coords.z + dz

            SetEntityCoordsNoOffset(p, nx, ny, nz, false, false, false)
            Wait(0)
        end
    end)
end

RegisterNetEvent('mike-adminmenu:client:toggleNoclip', ToggleNoclip)
