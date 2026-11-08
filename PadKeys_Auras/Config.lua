-- PadKeys_Auras settings. Edit, then /reload and /padkeys apply.

local ns = PadKeys

-- Inspect auras, in combat too: C highlights your target's auras, Ctrl+C
-- your own debuffs, one more each press; hold Shift+C for the highlighted
-- one's tooltip. C replaces the character window (it's on the menu
-- radial, Ctrl+G).
local b = ns.config.bindings
b.C = "CLICK PadKeysAura:target"
b["CTRL-C"] = "CLICK PadKeysAura:mine"
b["SHIFT-C"] = "CLICK PadKeysAura:tooltip"

ns.config.auras = {
  -- The auras C steps through, in order, as Blizzard's aura filters.
  -- Debuffs: all of them ("HARMFUL|PLAYER" for only yours). Buffs: the
  -- ones Blizzard flags as important to see on an enemy.
  target_lists = {
    { name = "Debuff", filter = "HARMFUL|INCLUDE_NAME_PLATE_ONLY" },
    { name = "Buff", filter = "HELPFUL|IMPORTANT|INCLUDE_NAME_PLATE_ONLY" },
  },
  -- The auras Ctrl+C steps through: your debuffs, in Blizzard's order.
  my_lists = {
    { name = "Your debuff", filter = "HARMFUL" },
  },
  -- Each C / Ctrl+C press also shows the highlighted aura's tooltip,
  -- fading with the highlight. false: only while Shift+C is held.
  tooltip_on_step = true,
  -- The label: text size, and pixels above the nameplate.
  label_size = 13,
  label_gap = 4,
  -- Seconds the highlight stays after the last press, and the tooltip
  -- after Shift+C is let go, before they fade; then seconds to fade.
  show_for = 4,
  linger = 2,
  fade_time = 1,
}
