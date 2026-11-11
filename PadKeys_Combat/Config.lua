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
  -- Where the list sits. "center": just below the middle of the screen,
  -- under your character (the combat banner is above it). Or a frame's
  -- name to sit under it, e.g. "PlayerFrame" or "TargetFrame" (party and
  -- pet frames sit under the player frame, so it can cover them).
  -- x, y move it, in pixels (positive y is up).
  anchor = "center",
  x = 0,
  y = -120,
  size = 14,
  max_rows = 8,
  -- Names listed per buff before "+N".
  max_names = 3,
  -- Hide the list while resting (in an inn or a city).
  hide_resting = true,
  -- Buffs to leave out: fortitude, mark, intellect, spirit, blessing,
  -- mage_armor, demon_armor, inner_fire, omen, trueshot, poisons,
  -- lightning_shield, imbue.
  -- e.g. ignore = { spirit = true },
  ignore = {},
  -- Consumables in your bags whose buff you don't have (elixirs, flasks,
  -- scrolls, Well Fed food, sharpening stones and oils), out of combat.
  consumables = true,
  -- In combat, fade out the long buffs in Blizzard's buff frame (over 90
  -- seconds left as combat starts, or no duration) and weapon enchants,
  -- so it shows the short ones (LongBuffs.lua).
  hide_long_in_combat = true,
}
