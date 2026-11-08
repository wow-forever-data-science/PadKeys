-- PadKeys_Auras settings. Edit, then /reload and /padkeys apply.

local ns = PadKeys

-- Your target's auras, in combat too: C highlights the next one, holding
-- Shift+C shows its tooltip. C replaces the character window (it's on the
-- menu radial, Ctrl+G).
local b = ns.config.bindings
b.C = "CLICK PadKeysAura:next"
b["SHIFT-C"] = "CLICK PadKeysAura:tooltip"

ns.config.auras = {
  -- The auras C steps through, in order: Blizzard's aura filters closest
  -- to what the nameplate shows. Debuffs: yours (and your pet's). Buffs:
  -- the ones Blizzard flags as important to see on an enemy.
  lists = {
    { name = "Debuff", filter = "HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY" },
    { name = "Buff", filter = "HELPFUL|IMPORTANT|INCLUDE_NAME_PLATE_ONLY" },
  },
  -- The label: text size, and pixels above the nameplate.
  label_size = 13,
  label_gap = 4,
  -- Seconds the tooltip takes to fade after Shift+C is let go.
  fade_time = 1,
}
