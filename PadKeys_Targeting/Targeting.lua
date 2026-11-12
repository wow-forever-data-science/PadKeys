-- Targeting, the keyboard version of the gamepad's targeting buttons.
--
-- Friendly/enemy mode (gamepad LB "Target Friendly" / RB "Target Hostile"):
-- one key toggles the mode, and the next/previous target keys (Tab and
-- Shift+Tab) cycle enemies or friends, in and out of combat. The toggle is
-- a secure button whose snippet rebinds those keys, so it works in combat.
-- (Blizzard has no command that cycles enemies and friends together: its
-- TARGETNEAREST only found friends.)
--
-- Group cycling, the keyboard version of the gamepad's party/raid targeting:
-- each press targets the next (left button) or previous (right button) group
-- member, in raid frame order. It is a secure button whose wrapped OnClick
-- picks the next unit that exists, so it works in combat.
--
-- Interact (F) does what fits what is around you: in combat, with a living
-- enemy targeted, it starts your attack (Interact would prefer a corpse or
-- herb nearby over the enemy you fight); with a soft interact target it
-- interacts; with only an ally soft targeted it makes them your target, as
-- F picks an enemy by attacking it. A state driver swaps the binding, so it
-- works in combat.

local ns = PadKeys

BINDING_HEADER_PADKEYS_TARGETING = "PadKeys: targeting"
_G["BINDING_NAME_CLICK PadKeysTargetMode:LeftButton"] = "Toggle friendly / enemy targeting"
_G["BINDING_NAME_CLICK PadKeysGroupCycle:LeftButton"] = "Next party/raid member"
_G["BINDING_NAME_CLICK PadKeysGroupCycle:RightButton"] = "Previous party/raid member"

-- Runs in the restricted environment, with self = the cycle button.
local ON_CLICK = [[
  local prefix, max = "party", 4
  if UnitExists("raid1") then
    prefix, max = "raid", 40
  end
  local step = (button == "RightButton") and -1 or 1
  local idx = self:GetAttribute("idx") or 0
  for _ = 0, max do
    idx = idx + step
    if idx > max then
      idx = 0
    elseif idx < 0 then
      idx = max
    end
    -- In a raid you are one of raid1-40, so slot 0 (player) is skipped.
    local unit = (idx == 0) and "player" or (prefix .. idx)
    if not (prefix == "raid" and idx == 0) and UnitExists(unit) then
      self:SetAttribute("idx", idx)
      self:SetAttribute("unit", unit)
      return
    end
  end
  return false
]]

local header = CreateFrame("Frame", "PadKeysHeader", UIParent,
                           "SecureHandlerBaseTemplate")

local button = CreateFrame("Button", "PadKeysGroupCycle", UIParent,
                           "SecureActionButtonTemplate")
button:RegisterForClicks("AnyDown")
button:SetAttribute("useOnKeyDown", true)
button:SetAttribute("type", "target")
SecureHandlerWrapScript(button, "OnClick", header, ON_CLICK)

ns.group_cycle = button

-- Friendly/enemy toggle. In friendly mode the header owns override bindings
-- that point the target keys at Blizzard's friendly targeting; enemy mode
-- clears them, so the layout's normal enemy bindings apply again.
local TOGGLE_MODE = [[
  local friendly = not owner:GetAttribute("friendly")
  owner:SetAttribute("friendly", friendly)
  if friendly then
    owner:SetBinding(true, owner:GetAttribute("nextkey"), "TARGETNEARESTFRIEND")
    owner:SetBinding(true, owner:GetAttribute("prevkey"), "TARGETPREVIOUSFRIEND")
  else
    owner:ClearBindings()
  end
]]

local mode_header = CreateFrame("Frame", "PadKeysTargetModeHeader", UIParent,
                                "SecureHandlerBaseTemplate")
mode_header:SetAttribute("nextkey", ns.config.target_mode.next)
mode_header:SetAttribute("prevkey", ns.config.target_mode.previous)

local mode = CreateFrame("Button", "PadKeysTargetMode", UIParent,
                         "SecureActionButtonTemplate")
mode:RegisterForClicks("AnyDown")
SecureHandlerWrapScript(mode, "OnClick", mode_header, TOGGLE_MODE)

-- A small label while friendly mode is on, so you know which mode you're in.
local label = ns.text(UIParent, 16, "white", "OVERLAY", "GameFontNormalLarge")
label:SetPoint("TOP", UIParent, "TOP", 0, -120)
label:SetText("Friendly targeting")
label:Hide()
mode:HookScript("OnClick", function()
  local friendly = mode_header:GetAttribute("friendly")
  label:SetShown(friendly)
  ns.flash(friendly and "Targeting: friendly" or "Targeting: enemy")
end)

function ns.is_friendly_mode()
  return mode_header:GetAttribute("friendly") and true or false
end

-- Interact key: the header binds the key to one of these buttons for the
-- "attack" and "friend" states, and clears it (back to Interact) otherwise.
local attack = CreateFrame("Button", "PadKeysAttack", UIParent,
                           "SecureActionButtonTemplate")
attack:RegisterForClicks("AnyDown")
attack:SetAttribute("useOnKeyDown", true)
attack:SetAttribute("type", "macro")
attack:SetAttribute("macrotext", "/startattack")

local friend = CreateFrame("Button", "PadKeysTargetSoftFriend", UIParent,
                           "SecureActionButtonTemplate")
friend:RegisterForClicks("AnyDown")
friend:SetAttribute("useOnKeyDown", true)
friend:SetAttribute("type", "target")
friend:SetAttribute("unit", "softfriend")

local interact_header = CreateFrame("Frame", "PadKeysInteractHeader",
                                    UIParent, "SecureHandlerStateTemplate")
interact_header:SetAttribute("key", ns.config.interact.key)
interact_header:SetAttribute("_onstate-interact", [[
  local key = self:GetAttribute("key")
  if newstate == "attack" then
    self:SetBindingClick(true, key, "PadKeysAttack")
  elseif newstate == "friend" then
    self:SetBindingClick(true, key, "PadKeysTargetSoftFriend")
  else
    self:ClearBindings()
  end
]])
RegisterStateDriver(interact_header, "interact",
  "[combat,harm,nodead] attack; [@softinteract,exists] interact; "
  .. "[@softfriend,help,nodead] friend; interact")
