-- PadKeys_Targeting settings. Edit, then /reload and /padkeys apply.

local ns = PadKeys

local b = ns.config.bindings
-- ` toggles ally mode, in which F targets the ally you face (3 below).
b["`"] = "CLICK PadKeysAllyMode:LeftButton"
-- Ctrl+Tab / Ctrl+Shift+Tab: next / previous party or raid member, in raid
-- frame order. All of these work in combat.
b["CTRL-TAB"] = "CLICK PadKeysGroupCycle:LeftButton"
b["CTRL-SHIFT-TAB"] = "CLICK PadKeysGroupCycle:RightButton"

-- The Interact key (F), picked by what is around you, first match wins:
--   1. in combat, with a living enemy targeted: start your attack
--   2. a soft interact target that is a unit (corpse, NPC): Interact
--   3. in ally mode (`), a living ally soft targeted: make them your target
--   4. otherwise: Interact (mailboxes, herbs, chests and other game objects)
-- 3 is opt in because macro conditions can't see soft targeted game
-- objects, so F would pick a nearby ally over a mailbox.
ns.config.interact = { key = "F" }

-- Ally soft targeting, used by 3 above and by helpful spells, needs these
-- CVars. They belong to wow-settings (see CLAUDE.md), not this addon:
--   SoftTargetFriend      3   on for keyboard and gamepad
--   SoftTargetFriendArc   1   a cone in front of you, like enemies
--   SoftTargetFriendRange 40  about your healing range
--   SoftTargetIconFriend  1   an icon over the ally a heal will land on
--   autoSelfCast          1   a helpful spell with no ally lands on you
