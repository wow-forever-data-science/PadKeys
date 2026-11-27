-- PadKeys_NotReady settings. Edit, then /reload.

local ns = PadKeys

ns.config.not_ready = {
  -- Icon size in pixels, and its offset from the centre of the screen
  -- (positive y is up).
  size = 32,
  x = 0,
  y = 0,
  -- Seconds the icon stays at full strength, then seconds to fade out.
  -- Another press (the same key or another one on cooldown) starts over.
  hold = 0,
  fade_out = 1,
  -- The countdown on the icon, and its size.
  countdown = true,
  countdown_size = 14,
  -- A dark clock-hand shadow over the icon for the time left.
  swipe = true,
  -- Slightly rounded corners, as on the PadKeys bar; false for square.
  rounded = true,
  -- Pressing a key during the global cooldown alone flashes nothing.
  ignore_gcd = true,
}
