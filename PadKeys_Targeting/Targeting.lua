-- Targeting, the keyboard version of the gamepad's targeting buttons.
--
-- Group cycling, the keyboard version of the gamepad's party/raid targeting:
-- each press targets the next (left button) or previous (right button) group
-- member, in raid frame order. It is a secure button whose wrapped OnClick
-- picks the next unit that exists, so it works in combat.
--
-- Interact (F) does what fits what is around you: in combat, with a living
-- enemy targeted, it starts your attack, Auto Shot for hunters, Shoot with
-- a wand (Interact would prefer a corpse or herb nearby over the enemy you
-- fight); otherwise it interacts. Out of combat F is left to the client's
-- Interact, which alone sees what is in front of you and starts Auto Shot
-- on a targeted enemy. It would not start a wand, so with a wand equipped
-- F also shoots a living enemy you target out of combat.
-- Ally mode (one key toggles it) makes F target the ally you
-- face instead, as F picks an enemy by attacking it. It takes F over
-- attacking, so F never shoots in ally mode. With an ally already
-- targeted F moves on to the next ally: the client stops picking soft
-- targets while you have a target (SoftTargetWithLocked 0, kept so enemy
-- targets stay put), so F on softfriend would retarget the same ally.
-- In a raid, ally mode turns F into raid picking (Raid.lua): hold F and
-- move the mouse a little to walk a highlight over the raid frames,
-- release to target that member.
-- Ally mode is opt in because macro conditions can't see soft interact
-- targets: [@softinteract,exists] is false at a corpse, NPC, mailbox or
-- herb, so F would target a nearby ally over them. A state driver swaps
-- the binding and the toggle is a secure button, so both work in combat.
--
-- In ally mode with an ally targeted, Cmd+F inspects them. It runs
-- Blizzard's /inspect from a secure button, as InspectUnit called from
-- addon code would taint the inspect window. Outside ally mode Cmd+F stays
-- last hostile target, which you want back after healing an ally.

local ns = PadKeys

BINDING_HEADER_PADKEYS_TARGETING = "PadKeys: targeting"
_G["BINDING_NAME_CLICK PadKeysAllyMode:LeftButton"] = "Toggle ally mode (F targets the ally you face, Cmd+F inspects)"
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
-- "attack", "friend" and "next" states, and clears it (back to Interact)
-- otherwise.
-- Hunters attack with Auto Shot (spell 75, by its localized name); the !
-- keeps a second press from turning it off. In melee range Auto Shot
-- fails, and a melee ability such as Raptor Strike starts the melee swing.
-- With a wand equipped F shoots it (spell 5019), else it starts the melee
-- swing. The macro condition checks the wand on each press, so swapping
-- weapons in combat needs no rebuild. It takes the localized subclass name.
local AUTO_SHOT = 75
local SHOOT = 5019

local function auto_shot()
  local _, class = UnitClass("player")
  return class == "HUNTER" and ns.config.interact.auto_shot
end

local function spell_name(id)
  return C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)
    or GetSpellInfo and (GetSpellInfo(id))
end

local function wand_type()
  local subclass_info = C_Item and C_Item.GetItemSubClassInfo or GetItemSubClassInfo
  return subclass_info
    and (subclass_info(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Wand))
end

local function wand_shot()
  local shoot, wand = spell_name(SHOOT), wand_type()
  if ns.config.interact.wand and shoot and wand then
    return shoot, wand
  end
end

local function attack_macro()
  if auto_shot() then
    local name = spell_name(AUTO_SHOT)
    if name then
      return "/cast !" .. name
    end
  end
  local shoot, wand = wand_shot()
  if shoot then
    return ("/cast [equipped:%s] !%s\n/startattack [noequipped:%s]")
      :format(wand, shoot, wand)
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

-- With an ally targeted: the next ally in front of you, as Tab does for
-- enemies.
local next_friend = CreateFrame("Button", "PadKeysTargetNextFriend", UIParent,
                                "SecureActionButtonTemplate")
next_friend:RegisterForClicks("AnyDown")
next_friend:SetAttribute("useOnKeyDown", true)
next_friend:SetAttribute("type", "macro")
next_friend:SetAttribute("macrotext", "/targetfriend")

local inspect = CreateFrame("Button", "PadKeysInspect", UIParent,
                            "SecureActionButtonTemplate")
inspect:RegisterForClicks("AnyDown")
inspect:SetAttribute("useOnKeyDown", true)
inspect:SetAttribute("type", "macro")
inspect:SetAttribute("macrotext", "/inspect")

-- The header binds F (and the inspect key) from two inputs: the state
-- driver's state and the ally mode attribute that the toggle flips. Both
-- run "apply". The inspect key binds without priority, so PadKeys_Cursor's
-- all key wins while the cursor is on.
local interact_header = CreateFrame("Frame", "PadKeysInteractHeader",
                                    UIParent, "SecureHandlerStateTemplate")
interact_header:SetAttribute("key", ns.config.interact.key)
interact_header:SetAttribute("inspect", ns.config.interact.inspect)
interact_header:SetAttribute("apply", [[
  local key = self:GetAttribute("key")
  local state = self:GetAttribute("state-interact")
  self:ClearBindings()
  if self:GetAttribute("ally") and self:GetAttribute("state-raid") == "on" then
    -- Raid picking (Raid.lua) takes F over attacking and ally targeting.
    self:SetBindingClick(true, key, "PadKeysRaidPick")
    if state == "next" then
      self:SetBindingClick(false, self:GetAttribute("inspect"), "PadKeysInspect")
    end
  elseif state == "attack" and self:GetAttribute("ally") then
    -- No soft target exists with an enemy targeted (SoftTargetWithLocked 0),
    -- so F moves from the enemy to the next ally.
    self:SetBindingClick(true, key, "PadKeysTargetNextFriend")
  elseif state == "attack" then
    self:SetBindingClick(true, key, "PadKeysAttack")
  elseif state == "friend" and self:GetAttribute("ally") then
    self:SetBindingClick(true, key, "PadKeysTargetSoftFriend")
  elseif state == "next" and self:GetAttribute("ally") then
    self:SetBindingClick(true, key, "PadKeysTargetNextFriend")
    self:SetBindingClick(false, self:GetAttribute("inspect"), "PadKeysInspect")
  end
]])
interact_header:SetAttribute("_onstate-interact", [[
  self:RunAttribute("apply")
]])
interact_header:SetAttribute("_onstate-raid", [[
  self:RunAttribute("apply")
]])
RegisterStateDriver(interact_header, "raid", "[group:raid] on; off")

local function interact_states()
  local _, wand = wand_shot()
  local wand_state = wand and ("[equipped:%s,harm,nodead] attack; "):format(wand) or ""
  return "[combat,harm,nodead] attack; " .. wand_state
    .. "[help,nodead] next; [@softfriend,help,nodead] friend; interact"
end

RegisterStateDriver(interact_header, "interact", interact_states())

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
  label:SetShown(ns.is_ally_mode())
end)

function ns.is_ally_mode()
  return interact_header:GetAttribute("ally") and true or false
end
