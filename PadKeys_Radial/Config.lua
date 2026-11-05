-- PadKeys_Radial settings. Edit, then /reload (and /padkeys apply if you
-- change the radial key).

local ns = PadKeys

-- Hold for the main-menu radial; point with the mouse, release to open.
-- Q/E or the mouse wheel switch pages.
ns.config.bindings.Z = "PADKEYS_RADIAL"

ns.config.radial = {
  -- Size against Blizzard's gamepad radial (1 = the same size).
  scale = 0.5,
  -- Where the wheel's centre sits, from the screen centre (pixels).
  x = 0,
  y = 0,
  -- Mouse distance (pixels) before a direction picks a segment.
  dead_zone = 12,
  -- Beyond this distance the centre follows the mouse, so turning to
  -- another segment is a short move from wherever the mouse is.
  reach = 60,
  -- Page keys while the radial is open.
  page_keys = {
    previous = { "Q", "MOUSEWHEELUP" },
    next = { "E", "MOUSEWHEELDOWN" },
  },
  -- The page the radial opens on.
  start_page = 2,
  -- Segments counter-clockwise from east (right), eight per page; false
  -- leaves one empty. Names are the entries of Blizzard's radial:
  -- bags, buffs, calendar, character, chat, collections, guild, legacy,
  -- lfd, map, menu, professions, pvp, social, spellbook, store, talents,
  -- time, tracking.
  pages = {
    { "lfd", "legacy", "store", "guild", "social", "buffs", "tracking", "collections" },
    { "bags", "professions", "character", "talents", "map", "chat", "menu", "spellbook" },
    { "time", "calendar", false, false, "pvp", false, false, false },
  },
}
