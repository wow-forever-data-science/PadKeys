-- PadKeys_NotReady settings. Edit, then /reload.

local ns = PadKeys

ns.config.not_ready = {
  -- Where it flashes. "cursor": above the mouse pointer, just over the
  -- swing ring and PadKeys_Readout's missing buff, bigger than the icons
  -- around the pointer (29-37) so it stands out; PadKeys_Ready's flash
  -- overlaps its top when both show. "center": above your
  -- character, under the combat banner (PadKeys_Combat), e.g. y = 80.
  -- x, y is the icon's centre from the pointer or the middle of the
  -- screen (positive y is up).
  anchor = "cursor",
  size = 42,
  x = 0,
  y = 44,
  -- A soft glow behind the icon, so it stands apart from the buffs and
  -- totems around the pointer: soft gold, as WeakAuras and Blizzard
  -- highlight spells and procs. false for none.
  glow = { 1, 0.82, 0 },
  glow_alpha = 0.7,
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
