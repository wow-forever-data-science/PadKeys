-- PadKeys_Targeting settings. Edit, then /reload and /padkeys apply.

local ns = PadKeys

local b = ns.config.bindings
-- ` toggles ally mode, in which F targets allies (2 and 3 below).
b["`"] = "CLICK PadKeysAllyMode:LeftButton"
-- Ctrl+Tab / Ctrl+Shift+Tab: next / previous party or raid member, in raid
-- frame order. All of these work in combat.
b["CTRL-TAB"] = "CLICK PadKeysGroupCycle:LeftButton"
b["CTRL-SHIFT-TAB"] = "CLICK PadKeysGroupCycle:RightButton"

-- The Interact key (F), picked by what is around you, first match wins:
--   1. outside ally mode, a living enemy targeted, in combat: start your
--      attack (hunters: Auto Shot, unless auto_shot is false; with a wand
--      equipped: Shoot, also out of combat, unless wand is false)
--   2. in ally mode (`), a living ally or enemy targeted: target the next
--      ally in front of you, so each press moves on
--   3. in ally mode (`), a living ally soft targeted: make them your target
--   4. otherwise: Interact
-- In ally mode in a raid, F picks a raid member instead (raid below).
-- 2 and 3 are opt in because macro conditions can't see soft interact
-- targets, so F would pick a nearby ally over a mailbox or NPC.
-- inspect: in ally mode with a living ally targeted, this key (Cmd+F on a
-- Mac, the base MOD) inspects them instead of targeting the last enemy.
ns.config.interact = {
  key = "F",
  inspect = ns.config.mod .. "F",
  auto_shot = true,
  wand = true,
  -- In ally mode in a raid, F picks a raid member instead: hold F, move
  -- the mouse a little (it can be anywhere on screen) to move the
  -- highlight over the raid frames, release F to target them. A tap
  -- targets the member you last picked.
  raid = {
    -- Mouse distance (UI units) that moves the pick one raid frame.
    step = 30,
    -- Mouse distance below which the pick stays where it started.
    dead_zone = 8,
  },
}

-- Ally soft targeting, used by 3 above and by helpful spells, needs these
-- CVars. They belong to wow-settings (see CLAUDE.md), not this addon:
--   SoftTargetFriend      3   on for keyboard and gamepad
--   SoftTargetFriendArc   1   a cone in front of you, like enemies
--   SoftTargetFriendRange 40  about your healing range
--   SoftTargetIconFriend  1   an icon over the ally a heal will land on
--   autoSelfCast          1   a helpful spell with no ally lands on you
