-- Targeting, the keyboard version of the gamepad's targeting buttons.
--
-- Group cycling, the keyboard version of the gamepad's party/raid targeting:
-- each press targets the next (left button) or previous (right button) group
-- member, in raid frame order. It is a secure button whose wrapped OnClick
-- picks the next unit that exists, so it works in combat.
--
-- Interact (F) does what fits what is around you: in combat, with a living
-- enemy targeted, it starts your attack, Auto Shot for hunters (Interact
-- would prefer a corpse or herb nearby over the enemy you fight); otherwise
-- it interacts. Hunters also Auto Shot a living hard target out of combat,
-- and pull a soft targeted enemy when no corpse or NPC is in reach. Ally mode
-- (one key toggles it) makes F target the ally you face instead, as F picks
-- an enemy by attacking it. Ally mode is opt in because macro conditions
-- can't see soft targeted game objects: [@softinteract,exists] is false at
-- a mailbox, herb or chest, so F would target a nearby ally over them. A
-- state driver swaps the binding and the toggle is a secure button, so both
-- work in combat.

local ns = PadKeys

BINDING_HEADER_PADKEYS_TARGETING = "PadKeys: targeting"
_G["BINDING_NAME_CLICK PadKeysAllyMode:LeftButton"] = "Toggle ally mode (F targets the ally you face)"
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

-- Interact key: the header binds the key to one of these buttons for the
-- "attack" and "friend" states, and clears it (back to Interact) otherwise.
-- Hunters attack with Auto Shot (spell 75, by its localized name); the !
-- keeps a second press from turning it off. In melee range Auto Shot
-- fails, and a melee ability such as Raptor Strike starts the melee swing.
local AUTO_SHOT = 75

local function auto_shot()
  local _, class = UnitClass("player")
  return class == "HUNTER" and ns.config.interact.auto_shot
end

local function attack_macro()
  if auto_shot() then
    local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(AUTO_SHOT)
      or GetSpellInfo and (GetSpellInfo(AUTO_SHOT))
    if name then
      return "/cast !" .. name
    end
  end
  return "/startattack"
end

local attack = CreateFrame("Button", "PadKeysAttack", UIParent,
                           "SecureActionButtonTemplate")
attack:RegisterForClicks("AnyDown")
attack:SetAttribute("useOnKeyDown", true)
attack:SetAttribute("type", "macro")
attack:SetAttribute("macrotext", attack_macro())

local friend = CreateFrame("Button", "PadKeysTargetSoftFriend", UIParent,
                           "SecureActionButtonTemplate")
friend:RegisterForClicks("AnyDown")
friend:SetAttribute("useOnKeyDown", true)
friend:SetAttribute("type", "target")
friend:SetAttribute("unit", "softfriend")

-- The header binds F from two inputs: the state driver's state and the
-- ally mode attribute that the toggle flips. Both run "apply".
local interact_header = CreateFrame("Frame", "PadKeysInteractHeader",
                                    UIParent, "SecureHandlerStateTemplate")
interact_header:SetAttribute("key", ns.config.interact.key)
interact_header:SetAttribute("apply", [[
  local key = self:GetAttribute("key")
  local state = self:GetAttribute("state-interact")
  if state == "attack" then
    self:SetBindingClick(true, key, "PadKeysAttack")
  elseif state == "friend" and self:GetAttribute("ally") then
    self:SetBindingClick(true, key, "PadKeysTargetSoftFriend")
  else
    self:ClearBindings()
  end
]])
interact_header:SetAttribute("_onstate-interact", [[
  self:RunAttribute("apply")
]])
-- Hunters pull with F, so their attack state skips the combat check and
-- also takes a soft targeted enemy (Auto Shot then targets it). The soft
-- enemy comes after a soft interact unit, so a corpse or NPC in reach is
-- looted or talked to before F pulls the next mob.
RegisterStateDriver(interact_header, "interact",
  (auto_shot() and "[harm,nodead] attack; "
    or "[combat,harm,nodead] attack; ")
  .. "[@softinteract,exists] interact; "
  .. (auto_shot() and "[@softenemy,harm,nodead] attack; " or "")
  .. "[@softfriend,help,nodead] friend; interact")

-- Ally mode toggle. Runs in the restricted environment, with owner = the
-- interact header.
local TOGGLE_ALLY = [[
  owner:SetAttribute("ally", not owner:GetAttribute("ally"))
  owner:RunAttribute("apply")
]]

local mode = CreateFrame("Button", "PadKeysAllyMode", UIParent,
                         "SecureActionButtonTemplate")
mode:RegisterForClicks("AnyDown")
SecureHandlerWrapScript(mode, "OnClick", interact_header, TOGGLE_ALLY)

-- A small label while ally mode is on, so you know which mode you're in.
local label = ns.text(UIParent, 16, "white", "OVERLAY", "GameFontNormalLarge")
label:SetPoint("TOP", UIParent, "TOP", 0, -120)
label:SetText("F targets allies")
label:Hide()
mode:HookScript("OnClick", function()
  local ally = ns.is_ally_mode()
  label:SetShown(ally)
  ns.flash(ally and "F: target allies" or "F: interact")
end)

function ns.is_ally_mode()
  return interact_header:GetAttribute("ally") and true or false
end
