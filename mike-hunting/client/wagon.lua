-- ──────────────────────────────────────────────────────────────────────────
-- Carcass loading onto hunting wagon (visual prop + stash item)
-- ──────────────────────────────────────────────────────────────────────────
local wagonCarcassProps = {}  -- wagonEntity -> { propHandles }

-- When near an unskinned dead animal AND a hunting wagon, show load option
-- This uses ox_target on the dead animal entity after it's been found

local function findNearbyHuntingWagon()
    local p = GetEntityCoords(PlayerPedId())
    -- Check mike-wagons spawned wagons
    if not exports['mike-wagons'] then return nil, nil end

    for _, veh in pairs(GetGamePool('CVehicle') or {}) do
        if DoesEntityExist(veh) then
            local d = #(GetEntityCoords(veh) - p)
            if d <= Config.WagonLoadRadius then
                -- Check if it's a hunting wagon model
                local model = GetEntityModel(veh)
                for typeKey, wtype in pairs(exports['mike-wagons']:GetWagonTypes and exports['mike-wagons']:GetWagonTypes() or {}) do
                    if typeKey == 'hunting' and GetHashKey(wtype.model) == model then
                        return veh, typeKey
                    end
                end
            end
        end
    end
    return nil, nil
end

-- We'll add load/unload options via a periodic scan rather than ox_target
-- since dead animals are dynamic entities
RegisterNetEvent('mike-hunting:client:carcassReady', function(typeKey, animalNetId)
    -- After skinning, the carcass remains. Show notification about wagon loading.
    lib.notify({
        type = 'inform',
        title = 'Carcass',
        description = 'Load onto a hunting wagon to sell whole at a butcher.',
        duration = 5000,
    })
end)
