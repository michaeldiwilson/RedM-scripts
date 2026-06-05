    -----------------------------------------------
    -- MIKE-HUNTING: Paste into rsg-core/shared/items.lua
    -- under "YOUR CUSTOM ITEMS" section
    -----------------------------------------------

    -- Bait items
    herbivore_bait          = { name = 'herbivore_bait',          label = 'Herbivore Bait',          weight = 50,  type = 'item', image = 'herbivore_bait.png',          unique = false, useable = true,  shouldClose = true, description = 'Attracts deer, elk, bison and other herbivores' },
    predator_bait           = { name = 'predator_bait',           label = 'Predator Bait',           weight = 50,  type = 'item', image = 'predator_bait.png',           unique = false, useable = true,  shouldClose = true, description = 'Attracts wolves, cougars, bears and other predators' },

    -- Poor quality pelts (1-star)
    poor_deer_pelt          = { name = 'poor_deer_pelt',          label = 'Poor Deer Pelt',          weight = 300, type = 'item', image = 'deer_pelt.png',               unique = false, useable = false, shouldClose = false, description = 'A damaged deer pelt' },
    poor_elk_pelt           = { name = 'poor_elk_pelt',           label = 'Poor Elk Pelt',           weight = 500, type = 'item', image = 'elk_pelt.png',                unique = false, useable = false, shouldClose = false, description = 'A damaged elk pelt' },
    poor_bear_pelt          = { name = 'poor_bear_pelt',          label = 'Poor Bear Pelt',          weight = 600, type = 'item', image = 'bear_pelt.png',               unique = false, useable = false, shouldClose = false, description = 'A damaged bear pelt' },
    poor_bison_pelt         = { name = 'poor_bison_pelt',         label = 'Poor Bison Pelt',         weight = 600, type = 'item', image = 'bison_pelt.png',              unique = false, useable = false, shouldClose = false, description = 'A damaged bison pelt' },
    poor_boar_pelt          = { name = 'poor_boar_pelt',          label = 'Poor Boar Pelt',          weight = 300, type = 'item', image = 'boar_pelt.png',               unique = false, useable = false, shouldClose = false, description = 'A damaged boar pelt' },
    poor_rabbit_pelt        = { name = 'poor_rabbit_pelt',        label = 'Poor Rabbit Pelt',        weight = 100, type = 'item', image = 'rabbit_pelt.png',             unique = false, useable = false, shouldClose = false, description = 'A damaged rabbit pelt' },
    poor_cougar_pelt        = { name = 'poor_cougar_pelt',        label = 'Poor Cougar Pelt',        weight = 400, type = 'item', image = 'cougar_pelt.png',             unique = false, useable = false, shouldClose = false, description = 'A damaged cougar pelt' },
    poor_wolf_pelt          = { name = 'poor_wolf_pelt',          label = 'Poor Wolf Pelt',          weight = 300, type = 'item', image = 'wolf_pelt.png',               unique = false, useable = false, shouldClose = false, description = 'A damaged wolf pelt' },
    poor_sheep_pelt         = { name = 'poor_sheep_pelt',         label = 'Poor Sheep Pelt',         weight = 200, type = 'item', image = 'sheep_pelt.png',              unique = false, useable = false, shouldClose = false, description = 'A damaged sheep pelt' },
    poor_goat_pelt          = { name = 'poor_goat_pelt',          label = 'Poor Goat Pelt',          weight = 200, type = 'item', image = 'goat_pelt.png',               unique = false, useable = false, shouldClose = false, description = 'A damaged goat pelt' },
    poor_coyote_pelt        = { name = 'poor_coyote_pelt',        label = 'Poor Coyote Pelt',        weight = 200, type = 'item', image = 'coyote_pelt.png',             unique = false, useable = false, shouldClose = false, description = 'A damaged coyote pelt' },

    -- Perfect quality pelts (3-star)
    perfect_deer_pelt       = { name = 'perfect_deer_pelt',       label = 'Perfect Deer Pelt',       weight = 300, type = 'item', image = 'deer_pelt.png',               unique = false, useable = false, shouldClose = false, description = 'A pristine deer pelt' },
    perfect_elk_pelt        = { name = 'perfect_elk_pelt',        label = 'Perfect Elk Pelt',        weight = 500, type = 'item', image = 'elk_pelt.png',                unique = false, useable = false, shouldClose = false, description = 'A pristine elk pelt' },
    perfect_bear_pelt       = { name = 'perfect_bear_pelt',       label = 'Perfect Bear Pelt',       weight = 600, type = 'item', image = 'bear_pelt.png',               unique = false, useable = false, shouldClose = false, description = 'A pristine bear pelt' },
    perfect_bison_pelt      = { name = 'perfect_bison_pelt',      label = 'Perfect Bison Pelt',      weight = 600, type = 'item', image = 'bison_pelt.png',              unique = false, useable = false, shouldClose = false, description = 'A pristine bison pelt' },
    perfect_boar_pelt       = { name = 'perfect_boar_pelt',       label = 'Perfect Boar Pelt',       weight = 300, type = 'item', image = 'boar_pelt.png',               unique = false, useable = false, shouldClose = false, description = 'A pristine boar pelt' },
    perfect_rabbit_pelt     = { name = 'perfect_rabbit_pelt',     label = 'Perfect Rabbit Pelt',     weight = 100, type = 'item', image = 'rabbit_pelt.png',             unique = false, useable = false, shouldClose = false, description = 'A pristine rabbit pelt' },
    perfect_cougar_pelt     = { name = 'perfect_cougar_pelt',     label = 'Perfect Cougar Pelt',     weight = 400, type = 'item', image = 'cougar_pelt.png',             unique = false, useable = false, shouldClose = false, description = 'A pristine cougar pelt' },
    perfect_wolf_pelt       = { name = 'perfect_wolf_pelt',       label = 'Perfect Wolf Pelt',       weight = 300, type = 'item', image = 'wolf_pelt.png',               unique = false, useable = false, shouldClose = false, description = 'A pristine wolf pelt' },
    perfect_sheep_pelt      = { name = 'perfect_sheep_pelt',      label = 'Perfect Sheep Pelt',      weight = 200, type = 'item', image = 'sheep_pelt.png',              unique = false, useable = false, shouldClose = false, description = 'A pristine sheep pelt' },
    perfect_goat_pelt       = { name = 'perfect_goat_pelt',       label = 'Perfect Goat Pelt',       weight = 200, type = 'item', image = 'goat_pelt.png',               unique = false, useable = false, shouldClose = false, description = 'A pristine goat pelt' },
    perfect_coyote_pelt     = { name = 'perfect_coyote_pelt',     label = 'Perfect Coyote Pelt',     weight = 200, type = 'item', image = 'coyote_pelt.png',             unique = false, useable = false, shouldClose = false, description = 'A pristine coyote pelt' },

    -- Legendary pelts
    legendary_bear_pelt     = { name = 'legendary_bear_pelt',     label = 'Legendary Bear Pelt',     weight = 800, type = 'item', image = 'bear_pelt.png',               unique = true,  useable = false, shouldClose = false, description = 'The pelt of a legendary grizzly bear' },
    legendary_cougar_pelt   = { name = 'legendary_cougar_pelt',   label = 'Legendary Cougar Pelt',   weight = 600, type = 'item', image = 'cougar_pelt.png',             unique = true,  useable = false, shouldClose = false, description = 'The pelt of a legendary cougar' },
    legendary_elk_pelt      = { name = 'legendary_elk_pelt',      label = 'Legendary Elk Pelt',      weight = 700, type = 'item', image = 'elk_pelt.png',                unique = true,  useable = false, shouldClose = false, description = 'The pelt of a legendary elk' },
    legendary_wolf_pelt     = { name = 'legendary_wolf_pelt',     label = 'Legendary Wolf Pelt',     weight = 500, type = 'item', image = 'wolf_pelt.png',               unique = true,  useable = false, shouldClose = false, description = 'The pelt of a legendary wolf' },
    legendary_bison_pelt    = { name = 'legendary_bison_pelt',    label = 'Legendary Bison Pelt',    weight = 800, type = 'item', image = 'bison_pelt.png',              unique = true,  useable = false, shouldClose = false, description = 'The pelt of a legendary bison' },

    -- Legendary parts
    legendary_bear_claw     = { name = 'legendary_bear_claw',     label = 'Legendary Bear Claw',     weight = 100, type = 'item', image = 'bear_claw.png',               unique = true,  useable = false, shouldClose = false, description = 'A massive claw from a legendary grizzly' },
    legendary_antlers       = { name = 'legendary_antlers',       label = 'Legendary Antlers',       weight = 200, type = 'item', image = 'antlers.png',                 unique = true,  useable = false, shouldClose = false, description = 'Magnificent antlers from a legendary elk' },
    legendary_bison_horn    = { name = 'legendary_bison_horn',    label = 'Legendary Bison Horn',    weight = 200, type = 'item', image = 'bison_horn.png',              unique = true,  useable = false, shouldClose = false, description = 'A massive horn from a legendary bison' },
