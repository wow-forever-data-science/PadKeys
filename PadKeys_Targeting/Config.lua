-- PadKeys_Targeting settings. Edit, then /reload and /padkeys apply.

local ns = PadKeys

local b = ns.config.bindings
-- ` toggles friendly/enemy mode, which points the next/previous target keys
-- (Tab / Shift+Tab, set in PadKeys/Config.lua) at friends or enemies.
b["`"] = "CLICK PadKeysTargetMode:LeftButton"
-- Ctrl+Tab / Ctrl+Shift+Tab: next / previous party or raid member, in raid
-- frame order. All of these work in combat.
b["CTRL-TAB"] = "CLICK PadKeysGroupCycle:LeftButton"
b["CTRL-SHIFT-TAB"] = "CLICK PadKeysGroupCycle:RightButton"

-- The keys friendly mode points at friends.
ns.config.target_mode = { next = "TAB", previous = "SHIFT-TAB" }
