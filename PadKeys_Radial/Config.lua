-- PadKeys_Radial settings. Edit, then /reload (and /padkeys apply if you
-- change a key).

local ns = PadKeys

-- Hold to open, point with the mouse, release to run the pick. The ring
-- keys (G) work in combat; the page is the key you press.
local b = ns.config.bindings
b.G = "CLICK PadKeysRing:actions"           -- Action Bar 6, slots 1-8
b[ns.config.mod .. "G"] = "CLICK PadKeysRing:pings"
b["SHIFT-G"] = "CLICK PadKeysRing:markers"
b["CTRL-G"] = "PADKEYS_RADIAL"              -- Blizzard's main menu entries

ns.config.radial = {
  -- Size against Blizzard's gamepad radial (1 = the same size).
  scale = 0.5,
  -- Where the wheel's centre sits, from the screen centre.
  x = 0,
  y = 0,
  -- Mouse distance before a direction picks a segment.
  dead_zone = 12,

  -- Segments go counter-clockwise from east (right), eight per page;
  -- false leaves one empty.

  -- The combat ring (Ring.lua).
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

  -- The main-menu radial (Menu.lua).
  menu = {
    -- Page keys while it is open, out of combat.
    page_keys = {
      previous = { "Q", "MOUSEWHEELUP" },
      next = { "E", "MOUSEWHEELDOWN" },
    },
    -- The page it opens on, and the only page in combat.
    start_page = 2,
    -- Names are the entries of Blizzard's radial: bags, buffs, calendar,
    -- character, chat, collections, guild, legacy, lfd, map, menu,
    -- professions, pvp, social, spellbook, store, talents, time, tracking.
    pages = {
      { "lfd", "legacy", "store", "guild", "social", "buffs", "tracking", "collections" },
      { "bags", "professions", "character", "talents", "map", "chat", "menu", "spellbook" },
      { "time", "calendar", false, false, "pvp", false, false, false },
    },
  },
}
