-- PadKeys_Targeting settings. Edit, then /reload and /padkeys apply.

local ns = PadKeys

local b = ns.config.bindings
-- ` toggles ally mode, in which F targets the ally you face (2 below).
b["`"] = "CLICK PadKeysAllyMode:LeftButton"
-- Ctrl+Tab / Ctrl+Shift+Tab: next / previous party or raid member, in raid
-- frame order. All of these work in combat.
b["CTRL-TAB"] = "CLICK PadKeysGroupCycle:LeftButton"
b["CTRL-SHIFT-TAB"] = "CLICK PadKeysGroupCycle:RightButton"

-- The Interact key (F), picked by what is around you, first match wins:
--   1. a living enemy targeted, in combat: start your attack (hunters:
--      Auto Shot, unless auto_shot is false)
--   2. in ally mode (`), a living ally soft targeted: make them your target
--   3. otherwise: Interact
-- 2 is opt in because macro conditions can't see soft interact targets, so
-- F would pick a nearby ally over a mailbox or NPC.
ns.config.interact = { key = "F", auto_shot = true }

-- Ally soft targeting, used by 2 above and by helpful spells, needs these
-- CVars. They belong to wow-settings (see CLAUDE.md), not this addon:
--   SoftTargetFriend      3   on for keyboard and gamepad
--   SoftTargetFriendArc   1   a cone in front of you, like enemies
--   SoftTargetFriendRange 40  about your healing range
--   SoftTargetIconFriend  1   an icon over the ally a heal will land on
--   autoSelfCast          1   a helpful spell with no ally lands on you
