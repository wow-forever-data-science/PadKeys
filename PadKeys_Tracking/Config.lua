-- PadKeys_Tracking settings. Edit, then /reload.

local ns = PadKeys

ns.config.tracking = {
  -- Where the badge sits: its centre at this point of the minimap, moved
  -- by x and y. The default is on the rim, lower left.
  point = "BOTTOMLEFT",
  x = 28,
  y = 28,
  size = 26,
  -- How much of the ring's edge shows around the icon, in pixels.
  ring_width = 2,
}
