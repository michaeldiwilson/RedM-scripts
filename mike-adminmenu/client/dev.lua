function OpenDevMenu()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    lib.registerContext({
        id = 'mike_admin_dev',
        title = 'Developer',
        menu = 'mike_admin_root',
        options = {
            { title = 'Copy vector3',  description = Utils.FormatCoords3(coords),          icon = 'copy', onSelect = function()
                lib.setClipboard(Utils.FormatCoords3(coords))
                lib.notify({ description = 'vector3 copied' })
            end },
            { title = 'Copy vector4',  description = Utils.FormatCoords4(coords, heading), icon = 'copy', onSelect = function()
                lib.setClipboard(Utils.FormatCoords4(coords, heading))
                lib.notify({ description = 'vector4 copied' })
            end },
            { title = 'Print ped model', description = ('0x%X'):format(GetEntityModel(ped)), icon = 'hashtag', onSelect = function()
                print(('Model: %s (%d)'):format(('0x%X'):format(GetEntityModel(ped)), GetEntityModel(ped)))
            end },
        },
    })
    lib.showContext('mike_admin_dev')
end
