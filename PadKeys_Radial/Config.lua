-- PadKeys_Radial settings. Edit, then /reload (and /padkeys apply if you
-- change a key).

local ns = PadKeys

-- Hold to open, point with the mouse, release to run the pick. All work in
-- combat; the page is the key you press.
local b = ns.config.bindings
b.G = "CLICK PadKeysRing:actions"           -- Action Bar 6, slots 1-8
b[ns.config.mod .. "G"] = "CLICK PadKeysRing:pings"
b["SHIFT-G"] = "CLICK PadKeysRing:markers"
b["CTRL-G"] = "CLICK PadKeysRing:menu"      -- Blizzard's main menu entries

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
  -- Mouse distance before a direction picks a segment.
  dead_zone = 8,

  -- Segments go counter-clockwise from east (right), eight per page;
  -- false leaves one empty.

  -- The ring pages (Ring.lua).
  ring = {
    -- Action Bar 6 (Blizzard's MultiBar5) starts at action slot 145.
    first_slot = 145,
    -- attack, warning, assist, onmyway; sent as ping_macro.
    pings = { "assist", false, "attack", false, "warning", false, "onmyway", false },
    ping_macro = "/ping %s",
    -- Target markers 1-8: star, circle, diamond, triangle, moon, square,
    -- cross, skull; sent as marker_macro. Skull at the top.
    markers = { 6, 7, 8, 1, 2, 3, 4, 5 },
    marker_macro = "/tm %d",
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
    -- legacy, lfd, map, menu, professions, pvp, spellbook, store, talents,
    -- time.
    pages = {
      { "lfd", "legacy", "store", "guild", false, "buffs", false, "collections" },
      { "bags", "professions", "character", "talents", "map", false, "menu", "spellbook" },
      { "time", "calendar", false, false, "pvp", false, false, false },
    },
  },
}
