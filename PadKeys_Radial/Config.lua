-- PadKeys_Radial settings. Edit, then /reload (and /padkeys apply if you
-- change a key).

local ns = PadKeys

-- Hold to open, point with the mouse, release to run the pick. All work in
-- combat; the page is the key you press. Only G changes with the
-- situation: Bar 6 in a fight, your professions while resting in an inn
-- or a city, Bar 7 otherwise, with your consumables as an outer ring
-- (potions in a fight, food and water out; none while resting). The other
-- keys never change.
local b = ns.config.bindings
b.G = "CLICK PadKeysRing:main"              -- Bar 6 in combat, Bar 7 out (main_pick), consumables outside
b[ns.config.mod .. "G"] = "CLICK PadKeysRing:third" -- Action Bar 8, slots 1-8
-- Option+G is free on a Mac (on Windows Alt is the Cmd+G key above).
if ns.config.mod ~= "ALT-" then
  b["ALT-G"] = false
end
-- Not Shift + the side mouse button: Blizzard's ping key there takes a
-- held modifier too (to ping a bar layer's slots), so both would open.
b["SHIFT-G"] = "CLICK PadKeysRing:markers"
b["CTRL-G"] = "CLICK PadKeysRing:menu"      -- Blizzard's main menu entries
-- The consumables are G's outer ring (ring.main_outer), so 5 stays free.
-- For them on a key of their own as well: b["5"] = "CLICK PadKeysRing:items"

ns.config.radial = {
  -- Size against Blizzard's gamepad radial (1 = the same size).
  scale = 0.35,
  -- Icon size against Blizzard's (1 = the same), on top of scale.
  icon_scale = 1.5,
  -- Open centred on the mouse, so pointing at an icon picks it. false
  -- opens at x, y from the screen centre.
  at_cursor = true,
  x = 0,
  y = 0,
  -- Action pages: the cooldown countdown over an icon, in this font size,
  -- and the icon's opacity while it can't be cast (0 is invisible). The
  -- global cooldown alone shows nothing; a charge recharging shows the
  -- countdown but keeps the icon solid.
  countdown_size = 14,
  -- Stack counts of items and reagents on an icon's lower right.
  count_size = 14,
  cooldown_alpha = 0.35,
  -- Mouse distance before a direction picks a segment.
  dead_zone = 8,
  -- A second ring of icons (G's consumables): its distance against the
  -- first ring, and its icons' size against the first ring's. Flicking at
  -- least outer_from pixels picks from it; nil is halfway between the
  -- rings (about 59 px at scale 0.35).
  outer_spacing = 1.6,
  outer_icon_scale = 0.85,
  outer_from = nil,

  -- Segments go counter-clockwise from east (right), eight per page;
  -- false leaves one empty.

  -- The ring pages (Ring.lua).
  ring = {
    -- The page G opens, as a macro condition: the first that is true.
    -- By default Action Bar 6 (actions) in combat or with an enemy
    -- targeted (your opener), the town page (town, below) while resting
    -- in an inn or a city, else Action Bar 7 (extra: mount, food, buffs).
    -- Any page works: actions, extra, third, markers, menu, items, town.
    main_pick = "[combat][harm,nodead] actions; [resting] town; extra",
    -- The consumables (items, below) as G's outer ring: flick further out
    -- to use one. false for a single ring. The town page never has one.
    main_outer = true,
    -- Action Bar 6 (Blizzard's MultiBar5) starts at action slot 145.
    first_slot = 145,
    -- G's page out of combat: Action Bar 7 (MultiBar6) starts at slot 157.
    extra_first_slot = 157,
    -- The Cmd+G page: Action Bar 8 (MultiBar7) starts at slot 169.
    third_first_slot = 169,
    -- Target markers 1-8: star, circle, diamond, triangle, moon, square,
    -- cross, skull; sent as marker_macro. Skull at the top.
    markers = { 6, 7, 8, 1, 2, 3, 4, 5 },
    marker_macro = "/tm %d",
  },

  -- The consumables (G's outer ring, Items.lua). Each set is eight segments
  -- (east, then counter-clockwise; false leaves one empty). A segment is a
  -- list of item names, best first: the first one in your bags is used.
  -- { use = "Drink" } instead takes any item in your bags whose use is
  -- that spell (Drink, Food, First Aid for bandages), the highest item
  -- level your level allows. The picks are made out of combat, as your
  -- bags change; in combat a used-up item stays, greyed, until combat ends.
  items = {
    -- Which set the wheel shows, as a macro condition: the first that is
    -- true. Set names are lower-case letters. e.g.
    -- "[stealth] sneak; [combat] fight; rest" with a `sneak` set below.
    pick = "[combat] fight; rest",
    sets = {
      -- In the directions of the readouts at the mouse: buffs upper
      -- right, healing lower right (where your incoming damage shows).
      fight = {
        { "Mighty Rage Potion", "Great Rage Potion", "Rage Potion" },   -- E
        { "Limited Invulnerability Potion" },                           -- NE
        { "Swiftness Potion" },                                         -- N
        { "Free Action Potion" },                                       -- NW
        { use = "First Aid" },                                          -- W
        { "Major Mana Potion", "Superior Mana Potion", "Greater Mana Potion",
          "Mana Potion", "Lesser Mana Potion", "Minor Mana Potion" },  -- SW
        { "Major Healthstone", "Greater Healthstone", "Healthstone",
          "Lesser Healthstone", "Minor Healthstone" },                  -- S
        { "Major Healing Potion", "Superior Healing Potion",
          "Greater Healing Potion", "Healing Potion", "Lesser Healing Potion",
          "Minor Healing Potion" },                                     -- SE
      },
      rest = {
        { use = "Drink" },
        { use = "Food" },
        { "Hearthstone" },
        { use = "First Aid" },
        false,
        false,
        false,
        false,
      },
    },
  },

  -- The town page (Town.lua): G while resting. Eight segments, east then
  -- counter-clockwise; false leaves one empty. A segment is a list of
  -- spell names, best first: the first you know that no earlier segment
  -- took, cast to open its window. { menu = "bags" } opens a main-menu
  -- entry instead (the names under menu.pages below). Mailboxes, banks
  -- and auctioneers are people and objects you walk up to, so they aren't
  -- here: PadKeys_Cursor handles their windows.
  town = {
    -- E and NE: your two crafting professions.
    { "Alchemy", "Blacksmithing", "Engineering", "Leatherworking",
      "Tailoring", "Enchanting", "Jewelcrafting" },
    { "Alchemy", "Blacksmithing", "Engineering", "Leatherworking",
      "Tailoring", "Enchanting", "Jewelcrafting" },
    { "Cooking" },                         -- N
    { "First Aid" },                       -- NW
    { "Smelting", "Poisons" },             -- W
    { "Disenchant", "Basic Campfire" },    -- SW
    { menu = "professions" },              -- S: the profession book
    { menu = "bags" },                     -- SE
  },

  -- A faint copy of the wheels that follows the mouse (Ghost.lua): each
  -- page in `rings` as a ring of small icons around the cursor, the first
  -- inside ("main" is whatever G opens now). The G ring sits where the G
  -- wheel's icons will. Lit segments (below) show at full strength with a
  -- white frame.
  ghost = {
    enabled = true,
    rings = { "main", "items" },
    -- "lit": only the lit segments, each where its wheel icon will be;
    -- "combat": the whole copy in combat, and out of it while a segment is
    -- lit by a rule other than health or mana; "always".
    show = "lit",
    alpha = 1,          -- the whole copy
    idle_alpha = 0.25,  -- an icon that isn't lit
    icon_scale = 0.8,   -- against the wheel's icons; outer rings are
                        -- spaced by outer_spacing above, as on the wheel
    fade = 0.2,         -- seconds to fade in or out
  },

  -- Lit segments, on the wheels and their faint copy, per page and
  -- segment (1 = east, counter-clockwise). For the items page, per set.
  -- Lighting only changes the look; the segment does what it always does.
  --   { health = 0.35 }  your health under 35%; add hits = true to light
  --                      it too for a few seconds after heavy damage (the
  --                      incoming-damage readout's crit or burst)
  --   { pet = 0.35 }     your pet's health under 35%, or a few seconds
  --                      after it takes heavy damage (the pet readout);
  --                      with health beside it ({ pet = 0.35, health =
  --                      0.5 }) your own health while you have no pet
  --   { mana = 0.25 }    your mana under 25%
  --   { pull = 6 }       an enemy targeted before combat, and the first
  --                      6 seconds of combat
  --   "proc"             the spell's proc glow is on (SpellActivationOverlay
  --                      or Blizzard's own); action pages only
  --   "ready"            usable and off cooldown; action pages only
  --   "casting"          your target is casting (to interrupt)
  --   { combo = 5 }      5 combo points on your target
  --   "boss"             Blizzard's encounter timeline highlights a boss
  --                      ability (a few seconds before it lands): put it on
  --                      a defensive or a movement spell
  --
  -- In combat G's slices follow the readouts at the mouse, so a readout
  -- lighting up points at the slice that answers it. Each side of the
  -- wheel has one theme: the top is timing (boss abilities, cooldowns
  -- back, buffs and totems running), the right your power, the bottom
  -- health, the left debuffs. Put on Action Bar 6:
  --   slot 1 (east) and its neighbours: your big cooldowns (they show
  --     ready right of the mouse);
  --   slot 2 (north-east): your big self-buff (tracked buffs upper right);
  --   slot 6 (south-west): a mana spell (Evocation, Innervate, Life Tap),
  --     lit under 25% mana, beside the mana potion;
  --   slot 7 (south): heal your pet (Mend Pet, Health Funnel; the pet
  --     warning shows below the mouse). No pet: a second heal or
  --     defensive for you, lit by your own health instead;
  --   slot 8 (south-east): a heal or defensive for you (your incoming
  --     damage shows lower right); the healing potion and healthstone sit
  --     outside it on the consumables ring.
  -- Ready cooldowns aren't lit: the column right of the mouse shows them.
  lights = {
    actions = {
      [6] = { mana = 0.25 },                -- mana spell, south-west
      [7] = { pet = 0.35, health = 0.5, hits = true }, -- heal pet, south
      [8] = { health = 0.35, hits = true }, -- your heal, south-east
    },
    items = {
      fight = {
        [6] = { mana = 0.25 },                -- mana potion, south-west
        [7] = { health = 0.5, hits = true },  -- healthstone, south
        [8] = { health = 0.35, hits = true }, -- healing potion, south-east
      },
    },
  },

  -- The main-menu page (Menu.lua).
  menu = {
    -- Page keys while it is open, also with a modifier held (Ctrl from
    -- Ctrl+G): scroll the mouse wheel. Add keys ("Q") to page with them too.
    page_keys = {
      previous = { "MOUSEWHEELUP" },
      next = { "MOUSEWHEELDOWN" },
    },
    -- The page it opens on.
    start_page = 2,
    -- Names are entries of Blizzard's radial that have a button to click
    -- (Menu.lua): bags, buffs, calendar, character, collections, guild,
    -- legacy, lfd, map, professions, pvp, spellbook, store, talents, time.
    -- The game menu is not one: Esc opens it.
    pages = {
      { "lfd", "legacy", "store", "guild", false, "buffs", false, "collections" },
      { "bags", "professions", "character", "talents", "map", false, false, "spellbook" },
      { "time", "calendar", false, false, "pvp", false, false, false },
    },
  },
}
