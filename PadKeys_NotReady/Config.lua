-- PadKeys_NotReady settings. Edit, then /reload.

local ns = PadKeys

ns.config.not_ready = {
  -- Icon size in pixels, and its offset from the centre of the screen
  -- (positive y is up): above your character, under the combat banner
  -- (PadKeys_Combat, y = 120).
  size = 32,
  x = 0,
  y = 80,
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
  -- Pressing a bandage under Recently Bandaged flashes the debuff with its
  -- time left (bandages have no cooldown of their own). PadKeys_Readout
  -- leaves the debuff out at the mouse (debuffs_hide).
  bandage = true,
}
