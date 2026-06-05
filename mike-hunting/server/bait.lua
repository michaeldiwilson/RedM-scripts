local RSGCore = exports['rsg-core']:GetCoreObject()

-- ──────────────────────────────────────────────────────────────────────────
-- Bait useable items: remove from inventory, tell client to place
-- ──────────────────────────────────────────────────────────────────────────
RSGCore.Functions.CreateUseableItem('herbivore_bait', function(src, item)
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    P.Functions.RemoveItem('herbivore_bait', 1)
    TriggerClientEvent('mike-hunting:client:placeBait', src, 'herbivore_bait')
end)

RSGCore.Functions.CreateUseableItem('predator_bait', function(src, item)
    local P = RSGCore.Functions.GetPlayer(src); if not P then return end
    P.Functions.RemoveItem('predator_bait', 1)
    TriggerClientEvent('mike-hunting:client:placeBait', src, 'predator_bait')
end)
