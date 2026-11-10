-- PadKeys_Combo settings. Edit, then /reload.

local ns = PadKeys

ns.config.combo = {
  -- Where the pips sit: a point on the row, anchored to the same point of
  -- the screen, plus an offset in pixels. The default is just above the
  -- PadKeys bar.
  point = "BOTTOM",
  x = 0,
  y = 80,
  size = 18,          -- pip width
  height = 8,         -- pip height
  spacing = 3,        -- gap between pips
  scale = 1,
  -- Slightly rounded corners, as on the PadKeys bar; false for square.
  rounded = true,
  -- Behind an empty pip; 0 is see-through, 1 is solid black.
  background_alpha = 0.75,
  -- Shows in combat and while you have points; true for always (rogue,
  -- or druid in Cat Form).
  always = false,
  -- Hide Blizzard's combo points around the target's portrait.
  hide_blizzard = true,
  -- Size of the number shown in place of the pips when the client keeps
  -- the count secret (addons can show it but not count it).
  number_size = 14,
}
