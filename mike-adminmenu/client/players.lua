local playerCache = {}

function OpenPlayersMenu()
    RSGCore.Functions.TriggerCallback('mike-adminmenu:server:getPlayers', function(list)
        playerCache = list
        local options = {}
        for _, p in ipairs(list) do
            options[#options + 1] = {
                title       = ('[%d] %s'):format(p.id, p.name),
                description = ('%s | job: %s | ping: %d'):format(p.charname or '-', p.job or '-', p.ping or 0),
                onSelect    = function() OpenPlayerActionsMenu(p) end,
            }
        end
        if #options == 0 then
            options[1] = { title = 'No players online', disabled = true }
        end
        lib.registerContext({ id = 'mike_admin_players', title = ('Players (%d)'):format(#list), menu = 'mike_admin_root', options = options })
        lib.showContext('mike_admin_players')
    end)
end

function OpenPlayerActionsMenu(p)
    local opts = {
        { title = 'Info',       icon = 'id-card',  onSelect = function() ShowPlayerInfo(p.id) end },
        { title = 'Goto',       icon = 'location-arrow', onSelect = function() TriggerServerEvent('mike-adminmenu:server:action', 'goto', p.id) end },
        { title = 'Bring',      icon = 'hand-point-down', onSelect = function() TriggerServerEvent('mike-adminmenu:server:action', 'bring', p.id) end },
        { title = 'Spectate',   icon = 'eye',      onSelect = function() TriggerServerEvent('mike-adminmenu:server:action', 'spectate', p.id) end },
        { title = 'Heal',       icon = 'heart',    onSelect = function() TriggerServerEvent('mike-adminmenu:server:action', 'heal', p.id) end },
        { title = 'Revive',     icon = 'syringe',  onSelect = function() TriggerServerEvent('mike-adminmenu:server:action', 'revive', p.id) end },
        { title = 'Freeze',     icon = 'snowflake', onSelect = function() TriggerServerEvent('mike-adminmenu:server:action', 'freeze', p.id, { state = true  }) end },
        { title = 'Unfreeze',   icon = 'sun',      onSelect = function() TriggerServerEvent('mike-adminmenu:server:action', 'freeze', p.id, { state = false }) end },
        { title = 'Give Money', icon = 'dollar-sign', onSelect = function() GiveMoneyDialog(p.id) end },
        { title = 'Give Item',  icon = 'box',      onSelect = function() GiveItemDialog(p.id) end },
        { title = 'View Inventory', icon = 'backpack', onSelect = function() TriggerServerEvent('mike-adminmenu:server:viewInventory', p.id) end },
        { title = 'Clear Inventory', icon = 'trash', onSelect = function()
            local ok = lib.alertDialog({ header = 'Clear inventory', content = ('Clear %s\'s inventory?'):format(p.name), cancel = true, labels = { confirm = 'Clear' } })
            if ok == 'confirm' then TriggerServerEvent('mike-adminmenu:server:clearInventory', p.id) end
        end },
        { title = 'Appearance Menu', icon = 'user-edit', onSelect = function() TriggerServerEvent('mike-adminmenu:server:openAppearance', p.id) end },
        { title = 'Kick',       icon = 'door-open', onSelect = function() KickDialog(p.id) end },
        { title = 'Ban',        icon = 'ban',      onSelect = function() BanDialog(p.id) end },
    }
    lib.registerContext({
        id = 'mike_admin_p_' .. p.id,
        title = ('[%d] %s'):format(p.id, p.name),
        menu = 'mike_admin_players',
        options = opts,
    })
    lib.showContext('mike_admin_p_' .. p.id)
end

function ShowPlayerInfo(targetId)
    RSGCore.Functions.TriggerCallback('mike-adminmenu:server:getPlayerInfo', function(info)
        if not info then lib.notify({ type = 'error', description = 'Could not fetch' }); return end
        local cash = info.money and info.money.cash or 0
        local bank = info.money and info.money.bank or 0
        local idLines = ''
        for _, id in ipairs(info.identifiers or {}) do idLines = idLines .. '\n' .. id end
        lib.alertDialog({
            header  = info.name,
            content = ('**Character:** %s\n**CID:** %s\n**Job:** %s (%s)\n**Cash:** $%d\n**Bank:** $%d\n\n**IDs:**%s')
                       :format(info.charname, info.citizenid or '-', info.job or '-', tostring(info.grade or 0), cash, bank, idLines),
            centered = true,
        })
    end, targetId)
end

function GiveMoneyDialog(targetId)
    local r = lib.inputDialog('Give Money', {
        { type = 'select', label = 'Account', options = {
            { value = 'cash', label = 'Cash' },
            { value = 'bank', label = 'Bank' },
        }, required = true, default = 'cash' },
        { type = 'number', label = 'Amount', required = true, min = 1 },
    })
    if not r then return end
    TriggerServerEvent('mike-adminmenu:server:action', 'giveMoney', targetId, { account = r[1], amount = r[2] })
end

function GiveItemDialog(targetId)
    local r = lib.inputDialog('Give Item', {
        { type = 'input',  label = 'Item name',  required = true },
        { type = 'number', label = 'Amount', default = 1, min = 1, required = true },
    })
    if not r then return end
    TriggerServerEvent('mike-adminmenu:server:giveItem', targetId, r[1], r[2])
end

function KickDialog(targetId)
    local r = lib.inputDialog('Kick Player', { { type = 'input', label = 'Reason', required = false } })
    if not r then return end
    TriggerServerEvent('mike-adminmenu:server:action', 'kick', targetId, { reason = r[1] or 'No reason' })
end

function BanDialog(targetId)
    local durOptions = {}
    for _, d in ipairs(Config.BanDurations) do
        durOptions[#durOptions + 1] = { value = tostring(d.hours), label = d.label }
    end
    local r = lib.inputDialog('Ban Player', {
        { type = 'select', label = 'Duration', options = durOptions, required = true },
        { type = 'input',  label = 'Reason', required = false },
    })
    if not r then return end
    TriggerServerEvent('mike-adminmenu:server:ban', targetId, tonumber(r[1]), r[2] or 'No reason')
end
