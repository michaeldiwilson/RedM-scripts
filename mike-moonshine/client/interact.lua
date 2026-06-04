local function stageRemaining(st)
    if not st.stage_started then return 0 end
    local total
    if st.state == 'fermenting' then total = Config.FermentTime
    elseif st.state == 'distilling' then total = Config.DistillTime
    else return 0 end
    return math.max(total - (GetCloudTimeAsInt() - st.stage_started), 0)
end

local function formatTime(s)
    if s <= 0 then return 'done' end
    return ('%dm %ds'):format(math.floor(s / 60), s % 60)
end

function OpenStillMenu(stillId)
    local st = Stills[stillId]
    if not st then
        lib.notify({ type = 'error', description = 'Still not found' })
        return
    end

    local remaining = stageRemaining(st)
    local lines = {
        ('State: **%s**'):format(st.state),
        ('Mash batches: %d / %d'):format(st.mash_batches, Config.MaxBatches),
        ('Quality score: %d'):format(st.quality_score),
    }
    if st.state == 'fermenting' or st.state == 'distilling' then
        lines[#lines + 1] = ('Time left: %s'):format(formatTime(remaining))
    end
    if st.state == 'ready' then
        lines[#lines + 1] = ('Bottles ready: %d (%s)'):format(st.bottles_ready, st.bottle_tier or '?')
    end

    local opts = {
        { title = 'Status', description = table.concat(lines, '\n'), disabled = true },
    }

    if st.state == 'empty' or st.state == 'mashing' then
        opts[#opts + 1] = { title = 'Add mash batch', description = 'Corn + sugar + water (optional herbs/berries for quality)', onSelect = function()
            TriggerServerEvent('mike-moonshine:server:addMash', st.id)
        end }
    end
    if st.state == 'mashing' and st.mash_batches > 0 then
        opts[#opts + 1] = { title = 'Start fermenting', onSelect = function()
            TriggerServerEvent('mike-moonshine:server:startFerment', st.id)
        end }
    end
    if st.state == 'fermented' then
        opts[#opts + 1] = { title = 'Start distilling', description = ('Costs %d firewood'):format(Config.DistillFuel), onSelect = function()
            TriggerServerEvent('mike-moonshine:server:startDistill', st.id)
        end }
    end
    if st.state == 'ready' then
        opts[#opts + 1] = { title = 'Bottle moonshine', description = ('Needs %d glass bottles'):format(st.bottles_ready * Config.BottleGlass), onSelect = function()
            TriggerServerEvent('mike-moonshine:server:bottle', st.id)
        end }
    end

    if st.state == 'empty' then
        opts[#opts + 1] = { title = 'Pick up still', description = 'Return the portable_still to your inventory (owner only)', icon = 'fa-solid fa-box', onSelect = function()
            TriggerServerEvent('mike-moonshine:server:pickup', st.id)
        end }
    end

    opts[#opts + 1] = { title = 'Destroy still', icon = 'hammer', onSelect = function()
        local ok = lib.alertDialog({ header = 'Destroy still', content = 'Are you sure? (Item is LOST)', cancel = true, labels = { confirm = 'Destroy' } })
        if ok == 'confirm' then TriggerServerEvent('mike-moonshine:server:destroy', st.id) end
    end }

    lib.registerContext({ id = 'mike_still_' .. st.id, title = 'Moonshine Still #' .. st.id, options = opts })
    lib.showContext('mike_still_' .. st.id)
end
