-- ──────────────────────────────────────────────────────────────────────────
-- Eagle Eye: highlight nearby animals with species + weapon info
-- Activated via middle mouse button (same as RDR2 dead eye)
-- ──────────────────────────────────────────────────────────────────────────
local eagleEyeActive = false
local eagleEyeCooldownUntil = 0

-- Middle mouse button input hash
local EAGLE_EYE_KEY = 0xF84FA74F  -- INPUT_SPECIAL_ABILITY (middle mouse / caps lock)

-- 3D floating text helper
local function DrawText3D(x, y, z, text)
    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(x, y, z)
    if not onScreen then return end
    SetTextScale(0.3, 0.3)
    SetTextFontForCurrentCommand(1)
    SetTextColor(255, 255, 255, 215)
    SetTextCentre(true)
    DisplayText(CreateVarString(10, 'LITERAL_STRING', text), sx, sy)
end

local function activateEagleEye()
    eagleEyeActive = true

    -- Try to apply a subtle visual filter
    -- SetTimecycleModifier('NG_filmic25')
    -- SetTimecycleModifierStrength(0.4)

    lib.notify({ type = 'inform', description = 'Eagle Eye active', duration = 2000 })

    CreateThread(function()
        local endTime = GetGameTimer() + Config.EagleEye.duration

        while GetGameTimer() < endTime and eagleEyeActive do
            Wait(0)
            local ped = PlayerPedId()
            local pCoords = GetEntityCoords(ped)
            local currentWeapon = GetCurrentWeapon(ped)

            for _, animal in pairs(GetGamePool('CPed') or {}) do
                if DoesEntityExist(animal) and not IsPedAPlayer(animal) and not IsPedDeadOrDying(animal, true) then
                    local model = GetEntityModel(animal)
                    local typeKey = AnimalHashLookup[model]
                    if typeKey then
                        local aCoords = GetEntityCoords(animal)
                        local dist = #(aCoords - pCoords)
                        if dist <= Config.EagleEye.radius then
                            local animalInfo = Config.Animals[typeKey]
                            local label = animalInfo and animalInfo.label or typeKey
                            local sizeClass = Config.AnimalSizeClass[typeKey] or '?'

                            -- Check if current weapon is correct for this animal
                            local weaponClass = Config.WeaponClass[currentWeapon]
                            local correct = weaponClass and Config.CorrectWeapons[sizeClass] and Config.CorrectWeapons[sizeClass][weaponClass]

                            local weaponNote
                            if not weaponClass then
                                weaponNote = '~r~[No hunting weapon]'
                            elseif correct then
                                weaponNote = '~g~[Correct Weapon]'
                            else
                                weaponNote = '~r~[Wrong Weapon]'
                            end

                            -- Check for legendary
                            local legKey = LegendaryEntityLookup[animal]
                            if legKey then
                                local legInfo = Config.LegendaryAnimals[legKey]
                                label = '~o~' .. (legInfo and legInfo.label or 'Legendary')
                                weaponNote = '~o~[Legendary]'
                            end

                            DrawText3D(aCoords.x, aCoords.y, aCoords.z + 1.5,
                                ('%s (%s)'):format(label, sizeClass))
                            DrawText3D(aCoords.x, aCoords.y, aCoords.z + 1.2, weaponNote)
                        end
                    end
                end
            end
        end

        -- Deactivate
        eagleEyeActive = false
        -- ClearTimecycleModifier()
        eagleEyeCooldownUntil = GetGameTimer() + Config.EagleEye.cooldown
        lib.notify({ type = 'inform', description = 'Eagle Eye faded', duration = 2000 })
    end)
end

-- Keybind listener
CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustReleased(0, EAGLE_EYE_KEY) and not eagleEyeActive then
            if GetGameTimer() < eagleEyeCooldownUntil then
                lib.notify({ type = 'error', description = 'Eagle Eye is recharging...', duration = 2000 })
            else
                activateEagleEye()
            end
        end
    end
end)
