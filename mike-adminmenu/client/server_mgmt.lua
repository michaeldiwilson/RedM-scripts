function OpenServerMenu()
    lib.registerContext({
        id = 'mike_admin_server',
        title = 'Server',
        menu = 'mike_admin_root',
        options = {
            { title = 'Set Weather',       icon = 'cloud-sun',  onSelect = WeatherMenu },
            { title = 'Set Time',          icon = 'clock',      onSelect = TimeDialog },
            { title = 'Global Announce',   icon = 'bullhorn',   onSelect = function() AnnounceDialog(nil) end },
            { title = 'Job Announce',      icon = 'briefcase',  onSelect = JobAnnounceMenu },
            { title = 'Cleanup Horses',    icon = 'horse',      onSelect = function() TriggerServerEvent('mike-adminmenu:server:cleanup', 'horses') end },
            { title = 'Cleanup Wagons',    icon = 'truck',      onSelect = function() TriggerServerEvent('mike-adminmenu:server:cleanup', 'wagons') end },
            { title = 'Cleanup NPCs',      icon = 'user-slash', onSelect = function() TriggerServerEvent('mike-adminmenu:server:cleanup', 'peds') end },
            { title = 'Cleanup Objects',   icon = 'cube',       onSelect = function() TriggerServerEvent('mike-adminmenu:server:cleanup', 'objects') end },
        },
    })
    lib.showContext('mike_admin_server')
end

function WeatherMenu()
    local opts = {}
    for _, w in ipairs(Config.Weathers) do
        opts[#opts + 1] = { title = w.label, onSelect = function() TriggerServerEvent('mike-adminmenu:server:setWeather', w.value) end }
    end
    lib.registerContext({ id = 'mike_admin_weather', title = 'Weather', menu = 'mike_admin_server', options = opts })
    lib.showContext('mike_admin_weather')
end

function TimeDialog()
    local r = lib.inputDialog('Set Time', {
        { type = 'number', label = 'Hour',   min = 0, max = 23, default = 12, required = true },
        { type = 'number', label = 'Minute', min = 0, max = 59, default = 0,  required = true },
    })
    if not r then return end
    TriggerServerEvent('mike-adminmenu:server:setTime', r[1], r[2])
end

function AnnounceDialog(jobName)
    local title = jobName and ('Announce to ' .. jobName) or 'Global Announce'
    local r = lib.inputDialog(title, { { type = 'textarea', label = 'Message', required = true } })
    if not r then return end
    TriggerServerEvent('mike-adminmenu:server:announce', r[1], jobName)
end

function JobAnnounceMenu()
    local opts = {}
    for _, j in ipairs(Config.Jobs) do
        opts[#opts + 1] = { title = j.label, onSelect = function() AnnounceDialog(j.name) end }
    end
    lib.registerContext({ id = 'mike_admin_jobannounce', title = 'Job Announce', menu = 'mike_admin_server', options = opts })
    lib.showContext('mike_admin_jobannounce')
end

function OpenBansMenu()
    RSGCore.Functions.TriggerCallback('mike-adminmenu:server:listBans', function(rows)
        local opts = {}
        for _, b in ipairs(rows or {}) do
            local exp = b.expires_at and os.date('%Y-%m-%d %H:%M', b.expires_at) or 'Permanent'
            opts[#opts + 1] = {
                title       = ('#%d %s'):format(b.id, b.name or 'Unknown'),
                description = ('Reason: %s | Expires: %s | By: %s'):format(b.reason or '-', exp, b.banned_by or '-'),
                onSelect    = function()
                    local ok = lib.alertDialog({
                        header  = 'Unban #' .. b.id,
                        content = 'Remove this ban?',
                        cancel  = true,
                        labels  = { confirm = 'Unban', cancel = 'Cancel' },
                    })
                    if ok == 'confirm' then
                        TriggerServerEvent('mike-adminmenu:server:unban', b.id)
                        Wait(300)
                        OpenBansMenu()
                    end
                end,
            }
        end
        if #opts == 0 then opts[1] = { title = 'No active bans', disabled = true } end
        lib.registerContext({ id = 'mike_admin_bans', title = ('Bans (%d)'):format(#opts), menu = 'mike_admin_root', options = opts })
        lib.showContext('mike_admin_bans')
    end)
end
