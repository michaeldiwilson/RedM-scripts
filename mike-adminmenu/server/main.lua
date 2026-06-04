RSGCore = exports['rsg-core']:GetCoreObject()

local function hasUserGroup(src)
    if not Config.Permissions.UserGroupsEnabled then return false end
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return false end
    local group = Player.PlayerData.permission or 'user'
    for _, g in ipairs(Config.Permissions.Groups) do
        if g == group then return true end
    end
    return false
end

function IsAdmin(src)
    if Config.Permissions.AceEnabled and IsPlayerAceAllowed(src, Config.Permissions.Ace) then
        return true
    end
    return hasUserGroup(src)
end
exports('IsAdmin', IsAdmin)

RSGCore.Functions.CreateCallback('mike-adminmenu:server:isAdmin', function(source, cb)
    cb(IsAdmin(source))
end)

RSGCore.Functions.CreateCallback('mike-adminmenu:server:getPlayers', function(source, cb)
    if not IsAdmin(source) then return cb({}) end
    local players = RSGCore.Functions.GetPlayers()
    local list = {}
    for _, pid in ipairs(players) do
        local P = RSGCore.Functions.GetPlayer(pid)
        if P then
            list[#list + 1] = {
                id       = pid,
                name     = GetPlayerName(pid) or 'Unknown',
                charname = (P.PlayerData.charinfo.firstname or '') .. ' ' .. (P.PlayerData.charinfo.lastname or ''),
                citizenid = P.PlayerData.citizenid,
                job      = P.PlayerData.job and P.PlayerData.job.name or '',
                ping     = GetPlayerPing(pid),
            }
        end
    end
    cb(list)
end)

RSGCore.Functions.CreateCallback('mike-adminmenu:server:getPlayerInfo', function(source, cb, targetId)
    if not IsAdmin(source) then return cb(nil) end
    local P = RSGCore.Functions.GetPlayer(tonumber(targetId))
    if not P then return cb(nil) end
    local ids = {}
    for i = 0, GetNumPlayerIdentifiers(targetId) - 1 do
        ids[#ids + 1] = GetPlayerIdentifier(targetId, i)
    end
    cb({
        name      = GetPlayerName(targetId),
        charname  = (P.PlayerData.charinfo.firstname or '') .. ' ' .. (P.PlayerData.charinfo.lastname or ''),
        citizenid = P.PlayerData.citizenid,
        job       = P.PlayerData.job and P.PlayerData.job.name,
        grade     = P.PlayerData.job and P.PlayerData.job.grade and P.PlayerData.job.grade.level,
        money     = P.PlayerData.money,
        identifiers = ids,
    })
end)

local function assertAdmin(src)
    if not IsAdmin(src) then
        DropPlayer(src, 'Insufficient permissions.')
        return false
    end
    return true
end
_G.AssertAdmin = assertAdmin

-- ──────────────────────────────────────────────────────────────────────────
-- Save all players (position + inventory)
-- ──────────────────────────────────────────────────────────────────────────
local function saveAllPlayers()
    local count = 0
    for _, pid in ipairs(GetPlayers()) do
        local P = RSGCore.Functions.GetPlayer(tonumber(pid))
        if P then
            P.Functions.Save()
            count = count + 1
        end
    end
    return count
end

-- Autosave: every 5 minutes
CreateThread(function()
    while true do
        Wait(5 * 60 * 1000) -- 5 minutes
        local n = saveAllPlayers()
        if n > 0 then
            print(('[mike-adminmenu] Autosave: %d player(s) saved'):format(n))
        end
    end
end)

-- /saveall command (admin only)
RegisterCommand('saveall', function(src)
    if src > 0 and not IsAdmin(src) then return end
    local n = saveAllPlayers()
    local msg = ('%d player(s) saved'):format(n)
    print('[mike-adminmenu] ' .. msg)
    if src > 0 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = msg })
    end
end, false)

-- Save all on resource stop (server shutdown / restart)
AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() or r == 'rsg-core' then
        local n = saveAllPlayers()
        print(('[mike-adminmenu] Shutdown save: %d player(s) saved'):format(n))
    end
end)
