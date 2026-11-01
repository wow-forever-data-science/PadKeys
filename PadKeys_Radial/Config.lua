-- PadKeys_Radial settings. Edit, then /reload (and /padkeys apply if you
-- change the radial key).

local ns = PadKeys

-- Hold for Blizzard's gamepad main-menu radial; point with the mouse,
-- release to open. Q/E or the mouse wheel switch between its 3 pages.
ns.config.bindings.Z = "PADKEYS_RADIAL"

ns.config.radial = {
  -- Mouse distance (pixels) that counts as pushing the stick all the way.
  reach = 120,
  -- Page keys while the radial is open, like the gamepad shoulders.
  page_keys = {
    previous = { "Q", "MOUSEWHEELUP" },
    next = { "E", "MOUSEWHEELDOWN" },
  },
}
