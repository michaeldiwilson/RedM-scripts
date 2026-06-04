local function getIdentifierByType(src, kind)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:sub(1, #kind + 1) == kind .. ':' then
            return id
        end
    end
end

local function collectIdentifiers(src)
    return {
        license = getIdentifierByType(src, 'license'),
        steam   = getIdentifierByType(src, 'steam'),
        discord = getIdentifierByType(src, 'discord'),
        xbl     = getIdentifierByType(src, 'xbl'),
        live    = getIdentifierByType(src, 'live'),
        ip      = getIdentifierByType(src, 'ip'),
    }
end

local function banCheckString(ids)
    return (ids.license or '__none__') .. '|' ..
           (ids.steam   or '__none__') .. '|' ..
           (ids.discord or '__none__')
end

local function isBanned(ids)
    local now = os.time()
    local row = MySQL.single.await([[
        SELECT id, reason, expires_at, banned_by FROM mike_bans
        WHERE (license = ? OR steam = ? OR discord = ?)
          AND (expires_at IS NULL OR expires_at > ?)
        LIMIT 1
    ]], { ids.license or '', ids.steam or '', ids.discord or '', now })
    return row
end

AddEventHandler('playerConnecting', function(_, _, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)
    local ids = collectIdentifiers(src)
    local row = isBanned(ids)
    if row then
        local exp = row.expires_at and ('Expires: ' .. os.date('%Y-%m-%d %H:%M', row.expires_at)) or 'Permanent'
        deferrals.done(('You are banned.\nReason: %s\n%s'):format(row.reason or 'None', exp))
        return
    end
    deferrals.done()
end)

local function doBan(adminSrc, targetId, hours, reason)
    targetId = tonumber(targetId)
    if not targetId or not GetPlayerName(targetId) then return false end
    local ids = collectIdentifiers(targetId)
    local expires = hours == -1 and nil or (os.time() + hours * 3600)
    MySQL.insert.await([[
        INSERT INTO mike_bans (license, steam, discord, xbl, ip, name, reason, banned_by, created_at, expires_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        ids.license, ids.steam, ids.discord, ids.xbl, ids.ip,
        GetPlayerName(targetId), reason or 'No reason',
        GetPlayerName(adminSrc) or 'CONSOLE', os.time(), expires,
    })
    DropPlayer(targetId, ('Banned: %s (%s)'):format(reason or 'No reason', expires and os.date('%Y-%m-%d %H:%M', expires) or 'Permanent'))
    if adminSrc and adminSrc > 0 then
        TriggerClientEvent('ox_lib:notify', adminSrc, { type = 'success', description = 'Banned ' .. targetId })
    end
    return true
end
_G.DoBan = doBan

RegisterNetEvent('mike-adminmenu:server:ban', function(targetId, hours, reason)
    local src = source
    if not AssertAdmin(src) then return end
    doBan(src, targetId, hours, reason)
end)

RSGCore.Functions.CreateCallback('mike-adminmenu:server:listBans', function(source, cb)
    if not IsAdmin(source) then return cb({}) end
    local rows = MySQL.query.await([[
        SELECT id, license, steam, name, reason, banned_by, created_at, expires_at
        FROM mike_bans
        WHERE expires_at IS NULL OR expires_at > ?
        ORDER BY created_at DESC
        LIMIT 100
    ]], { os.time() })
    cb(rows or {})
end)

RegisterNetEvent('mike-adminmenu:server:unban', function(banId)
    local src = source
    if not AssertAdmin(src) then return end
    MySQL.update.await('DELETE FROM mike_bans WHERE id = ?', { tonumber(banId) })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Removed ban #' .. banId })
end)
