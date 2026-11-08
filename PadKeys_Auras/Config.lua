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
  -- The auras C steps through, in order: Blizzard's aura filters closest
  -- to what the nameplate shows. Debuffs: yours (and your pet's). Buffs:
  -- the ones Blizzard flags as important to see on an enemy.
  target_lists = {
    { name = "Debuff", filter = "HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY" },
    { name = "Buff", filter = "HELPFUL|IMPORTANT|INCLUDE_NAME_PLATE_ONLY" },
  },
  -- The auras Ctrl+C steps through: your debuffs, in Blizzard's order.
  my_lists = {
    { name = "Your debuff", filter = "HARMFUL" },
  },
  -- The label: text size, and pixels above the nameplate.
  label_size = 13,
  label_gap = 4,
  -- Seconds the highlight stays after the last press, and the tooltip
  -- after Shift+C is let go, before they fade; then seconds to fade.
  show_for = 4,
  linger = 2,
  fade_time = 1,
}
