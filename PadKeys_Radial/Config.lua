-- PadKeys_Radial settings. Edit, then /reload (and /padkeys apply if you
-- change a key).

local ns = PadKeys

-- Hold to open, point with the mouse, release to run the pick. All work in
-- combat; the page is the key you press.
local b = ns.config.bindings
b.G = "CLICK PadKeysRing:actions"           -- Action Bar 6, slots 1-8
b[ns.config.mod .. "G"] = "CLICK PadKeysRing:extra" -- Action Bar 7, slots 1-8
-- Option+G, only on a Mac: on Windows Alt is the Cmd+G key above.
if ns.config.mod ~= "ALT-" then
  b["ALT-G"] = "CLICK PadKeysRing:third"    -- Action Bar 8, slots 1-8
end
-- Not Shift + the side mouse button: Blizzard's ping key there takes a
-- held modifier too (to ping a bar layer's slots), so both would open.
b["SHIFT-G"] = "CLICK PadKeysRing:markers"
b["CTRL-G"] = "CLICK PadKeysRing:menu"      -- Blizzard's main menu entries
-- Consumables from your bags (Items.lua): one set in combat, another out.
b.V = "CLICK PadKeysRing:items"

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

  -- Segments go counter-clockwise from east (right), eight per page;
  -- false leaves one empty.

  -- The ring pages (Ring.lua).
  ring = {
    -- Action Bar 6 (Blizzard's MultiBar5) starts at action slot 145.
    first_slot = 145,
    -- The Cmd+G page: Action Bar 7 (MultiBar6) starts at slot 157.
    extra_first_slot = 157,
    -- The Option+G page: Action Bar 8 (MultiBar7) starts at slot 169.
    third_first_slot = 169,
    -- Target markers 1-8: star, circle, diamond, triangle, moon, square,
    -- cross, skull; sent as marker_macro. Skull at the top.
    markers = { 6, 7, 8, 1, 2, 3, 4, 5 },
    marker_macro = "/tm %d",
  },

  -- The consumables page (V, Items.lua). Each set is eight segments
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
      fight = {
        { "Major Healing Potion", "Superior Healing Potion",
          "Greater Healing Potion", "Healing Potion", "Lesser Healing Potion",
          "Minor Healing Potion" },
        { "Major Healthstone", "Greater Healthstone", "Healthstone",
          "Lesser Healthstone", "Minor Healthstone" },
        { "Major Mana Potion", "Superior Mana Potion", "Greater Mana Potion",
          "Mana Potion", "Lesser Mana Potion", "Minor Mana Potion" },
        { use = "First Aid" },
        { "Free Action Potion" },
        { "Mighty Rage Potion", "Great Rage Potion", "Rage Potion" },
        { "Swiftness Potion" },
        { "Limited Invulnerability Potion" },
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
