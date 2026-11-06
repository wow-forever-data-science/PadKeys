-- PadKeys_Combat settings. Edit, then /reload.

local ns = PadKeys

ns.config.combat = {
  -- A short text in the middle of the screen when you enter and leave
  -- combat, in white and the PadKeys font (PadKeys/Config.lua, theme).
  banner = true,
  enter_text = "Combat",
  leave_text = "Out of Combat",
  size = 28,
  -- Offset from the centre of the screen, in pixels (positive is up).
  x = 0,
  y = 120,
  -- Seconds to fade in, stay, and fade out.
  fade_in = 0.15,
  hold = 0.8,
  fade_out = 0.6,
}

-- Buff reminder (Buffs.lua): out of combat, the long buffs your class and
-- group should have that are missing or running out, as a short list. It
-- fades out as you enter combat (at the banner's fade_out speed above) and
-- back in as you leave it (fade_in).
ns.config.combat.buffs = {
  enabled = true,
  -- Seconds left under which a buff shows (5 minutes).
  warn_at = 300,
  -- Where the list sits: its top left corner, from this point of the
  -- screen, in pixels (positive y is up).
  point = "TOP",
  x = -120,
  y = -140,
  size = 14,
  max_rows = 8,
  -- Names listed per buff before "+N".
  max_names = 3,
  -- Hide the list while resting (in an inn or a city).
  hide_resting = false,
  -- Buffs to leave out: fortitude, mark, intellect, spirit, blessing,
  -- mage_armor, demon_armor, inner_fire, omen, trueshot, poisons.
  -- e.g. ignore = { spirit = true },
  ignore = {},
  -- In combat, turn on Blizzard's buff consolidation (the consolidateBuffs
  -- setting): buffs with no duration or a long one fold into one icon, so
  -- the buff frame shows only the short ones. Your own setting comes back
  -- as you leave combat.
  consolidate_in_combat = true,
}
