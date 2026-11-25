-- PadKeys_CombatText settings. Edit, then /reload.
--
-- Blizzard's own floating combat text is switched by CVars, which belong to
-- wow-settings, not here (CLAUDE.md): turn it off there.

local ns = PadKeys

ns.config.combattext = {
  -- Colours, the same for both scrolls: crits red, special abilities
  -- yellow, everything else white. Nothing is coloured by school or source.
  colors = {
    normal = { 1, 1, 1 },
    crit = { 1, 0.25, 0.2 },
    special = { 1, 0.82, 0.1 },
  },
  -- Crits are this much bigger.
  crit_scale = 1.3,
  -- Seconds a line stays before it fades, and seconds to fade.
  hold = 0.6,
  fade = 0.4,
  -- Pixels a line drifts in its direction over those seconds.
  rise = 24,
}

-- Your hits on your target, beside the right end of its nameplate's health
-- bar. The newest line sits level with the bar, older ones move up.
ns.config.combattext.target = {
  enabled = true,
  size = 11,
  -- Lines at most; a new one past this drops the oldest.
  lines = 4,
  -- "up": older lines move up; "down": they move down.
  direction = "up",
  -- Pixels between the health bar and the icons.
  gap = 40,
  -- Without a nameplate (off screen, nameplates off): beside the target
  -- frame instead. false: nothing then.
  fallback = true,
  -- The icon of a hit is your last cast, if it ended this many seconds
  -- before the hit (spells that fly need the longer time).
  link_window = 1.5,
  -- In a group the target also takes the others' hits, which the game
  -- doesn't tell apart from yours. true: in a group, only hits that follow
  -- one of your casts show.
  group_only_linked = true,
  -- Misses, dodges, parries, blocks, resists, absorbs and immunes, as a
  -- short word.
  show_misses = true,
}

-- The hits you take, near your character. The whole list fades in as your
-- health drops: hidden at full health, clear when you're low. As a tank it
-- shows from full health, so you see the damage coming in earlier.
ns.config.combattext.incoming = {
  enabled = true,
  size = 13,
  lines = 5,
  direction = "down",
  -- "cursor": lower right of the mouse pointer, outside the G radial,
  -- offset by x, y (positive y is up). "center": under your character.
  anchor = "cursor",
  x = 110,
  y = -100,
  -- Heavy damage shows it at full strength for heavy_hold seconds: a crit,
  -- a crushing blow, or burst_hits hits within burst_window seconds.
  burst_hits = 4,
  burst_window = 1.5,
  heavy_hold = 3,
  -- Visibility by health, as { health, alpha } points from 0 to 1, joined
  -- by straight lines. Not a tank: nothing above 75% health, all of it at
  -- 40% and below.
  alpha_by_health = { { 0, 1 }, { 0.4, 1 }, { 0.75, 0 }, { 1, 0 } },
  -- As a tank: always half visible, all of it at 70% and below.
  tank_alpha_by_health = { { 0, 1 }, { 0.7, 1 }, { 1, 0.5 } },
  -- "auto": a tank in Defensive Stance, Bear or Dire Bear Form, with
  -- Righteous Fury, or with the tank role in the group. true / false to
  -- decide yourself.
  tank = "auto",
  show_misses = false,
}
