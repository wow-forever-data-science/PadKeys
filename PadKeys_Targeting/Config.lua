-- PadKeys_Targeting settings. Edit, then /reload and /padkeys apply.

local ns = PadKeys

local b = ns.config.bindings
-- The next/previous target keys (Tab / Shift+Tab) cycle the enemies in
-- front of you out of combat, or the friends when there is no enemy. In combat they follow friendly/enemy mode,
-- which ` toggles.
b["`"] = "CLICK PadKeysTargetMode:LeftButton"
-- Ctrl+Tab / Ctrl+Shift+Tab: next / previous party or raid member, in raid
-- frame order. All of these work in combat.
b["CTRL-TAB"] = "CLICK PadKeysGroupCycle:LeftButton"
b["CTRL-SHIFT-TAB"] = "CLICK PadKeysGroupCycle:RightButton"

-- The next/previous target keys.
ns.config.target_mode = { next = "TAB", previous = "SHIFT-TAB" }

-- In combat, with a living enemy targeted, this key starts your attack
-- instead of interacting with a soft target (a corpse or herb nearby).
ns.config.combat_attack = { key = "F" }
