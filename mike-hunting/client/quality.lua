-- ──────────────────────────────────────────────────────────────────────────
-- Pelt quality determination based on weapon + animal size class
-- Loaded before main.lua so DetermineQuality is available globally
-- ──────────────────────────────────────────────────────────────────────────

-- Track the weapon the player was holding when each animal first died nearby
AnimalKillWeapon = {}   -- netId -> weaponHash
SeenDeadAnimals  = {}   -- netId -> true (prevents re-recording weapon)

-- RedM native: GET_CURRENT_PED_WEAPON (not available as a named function)
function GetCurrentWeapon(ped)
    return Citizen.InvokeNative(0x8425C5F057012DAB, ped)
end

function DetermineQuality(typeKey, weaponHash)
    local sizeClass = Config.AnimalSizeClass[typeKey]
    if not sizeClass then return 2 end

    local weaponClass = Config.WeaponClass[weaponHash]

    -- Unknown weapon / melee / explosives = 1 star
    if not weaponClass then return 1 end

    -- Shotgun / pistol always ruins pelts
    if weaponClass == 'shotgun' or weaponClass == 'pistol' then return 1 end

    -- Check if weapon is appropriate for this size class
    local correct = Config.CorrectWeapons[sizeClass]
    if correct and correct[weaponClass] then
        -- Correct weapon: 70% chance 3-star, 30% chance 2-star
        return (math.random(1, 100) <= 70) and 3 or 2
    end

    -- Wrong category = 1 star
    return 1
end
