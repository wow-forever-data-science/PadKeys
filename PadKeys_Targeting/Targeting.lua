-- Targeting, the keyboard version of the gamepad's targeting buttons.
--
-- Tab and Shift+Tab (next / previous target):
-- * Out of combat they cycle everything in front of you, friend or enemy
--   (TARGETNEAREST).
-- * In combat they follow friendly/enemy mode (gamepad LB "Target
--   Friendly" / RB "Target Hostile"): one key toggles the mode.
-- A secure header rebinds the keys as combat starts and ends (a state
-- driver) and as the mode toggles, so it works in combat.
--
-- Group cycling, the keyboard version of the gamepad's party/raid targeting:
-- each press targets the next (left button) or previous (right button) group
-- member, in raid frame order. It is a secure button whose wrapped OnClick
-- picks the next unit that exists, so it works in combat.
--
-- Attack in combat: Interact (F) prefers a soft target, a corpse to loot or
-- an herb, over the enemy you are fighting. In combat, with a living enemy
-- targeted, F starts your attack instead. A state driver swaps the binding,
-- so it works in combat.

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

-- Friendly/enemy toggle and combat. The header owns override bindings for
-- the target keys: out of combat any unit, in combat friends in friendly
-- mode. In combat in enemy mode it clears them, so the layout's normal
-- enemy bindings apply again.
local APPLY = [[
  local next, prev
  if not self:GetAttribute("combat") then
    next, prev = "TARGETNEAREST", "TARGETPREVIOUS"
  elseif self:GetAttribute("friendly") then
    next, prev = "TARGETNEARESTFRIEND", "TARGETPREVIOUSFRIEND"
  end
  self:ClearBindings()
  if next then
    self:SetBinding(true, self:GetAttribute("nextkey"), next)
    self:SetBinding(true, self:GetAttribute("prevkey"), prev)
  end
]]

local TOGGLE_MODE = [[
  owner:SetAttribute("friendly", not owner:GetAttribute("friendly"))
  owner:RunAttribute("apply")
]]

local mode_header = CreateFrame("Frame", "PadKeysTargetModeHeader", UIParent,
                                "SecureHandlerStateTemplate")
mode_header:SetAttribute("nextkey", ns.config.target_mode.next)
mode_header:SetAttribute("prevkey", ns.config.target_mode.previous)
mode_header:SetAttribute("apply", APPLY)
mode_header:SetAttribute("_onstate-combat", [[
  self:SetAttribute("combat", newstate == "on")
  self:RunAttribute("apply")
]])
RegisterStateDriver(mode_header, "combat", "[combat] on; off")

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

-- Attack in combat: the header binds the key to the attack button while the
-- state is "on", and clears it (back to Interact) otherwise.
local attack = CreateFrame("Button", "PadKeysAttack", UIParent,
                           "SecureActionButtonTemplate")
attack:RegisterForClicks("AnyDown")
attack:SetAttribute("useOnKeyDown", true)
attack:SetAttribute("type", "macro")
attack:SetAttribute("macrotext", "/startattack")

local attack_header = CreateFrame("Frame", "PadKeysAttackHeader", UIParent,
                                  "SecureHandlerStateTemplate")
attack_header:SetAttribute("key", ns.config.combat_attack.key)
attack_header:SetAttribute("_onstate-attack", [[
  if newstate == "on" then
    self:SetBindingClick(true, self:GetAttribute("key"), "PadKeysAttack")
  else
    self:ClearBindings()
  end
]])
RegisterStateDriver(attack_header, "attack", "[combat,harm,nodead] on; off")
