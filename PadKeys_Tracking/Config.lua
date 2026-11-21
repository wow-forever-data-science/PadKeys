-- PadKeys_Tracking settings. Edit, then /reload.

local ns = PadKeys

ns.config.tracking = {
  -- Where the badge sits on the minimap: its centre `radius` pixels from
  -- the minimap's centre, at `clock` on a clock face (2 is 2 o'clock).
  -- Blizzard's day and night dial sits at about 1 o'clock, radius 102.
  clock = 2,
  radius = 102,
  size = 36,
  -- How much of the ring's edge shows around the icon, in pixels.
  ring_width = 2,
}
