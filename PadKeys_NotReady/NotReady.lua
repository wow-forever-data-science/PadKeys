-- Pressing a key or using an item that is still on cooldown flashes its
-- icon just above the mouse pointer (or mid-screen, anchor in
-- Config.lua), with the time left, and fades it out
-- (Config.lua: one second). Another such press, of the same key or
-- another, replaces it at once and starts the fade again.
--
-- Which press it was comes from post-hooks on the functions every press
-- goes through: UseAction (action bars, PadKeys_Bar and the radials all
-- call it via SecureActionButton), C_Container.UseContainerItem (bags)
-- and UseInventoryItem (worn items). hooksecurefunc runs after Blizzard's
-- call and leaves it untainted.
--
-- How an action press "on cooldown" is told apart: the Forever client
-- sends no "Spell is not ready yet." error for it, so the slot's state from
-- just before the press decides. Each slot's state is kept from the
-- cooldown events; a press's own cooldown only arrives in a later event,
-- so at the press the kept state is the one from before it. The flash
-- also needs the slot to be cooling right after the press, so a cooldown
-- that ended without an event flashes nothing. Items still wait for the
-- game's "Item is not ready yet." error (UI_ERROR_MESSAGE).
--
-- Cooldown numbers are secret in combat, so the countdown goes through a
-- duration object (C_ActionBar.GetActionCooldownDuration) and
-- SetCooldownFromDurationObject, and only the plain flags (isActive,
-- isOnGCD) are tested, as on PadKeys_Bar. Item cooldowns have no duration
-- object: SetCooldown is tried with pcall and the countdown is left out if
-- it refuses the numbers.
--
-- Bandages have no cooldown, only the Recently Bandaged debuff (60
-- seconds). Pressing one under it (action slot or bag) flashes the
-- debuff's icon with its time left. The debuff is kept from your own
-- First Aid channel starting (a plain event, also in combat), and set
-- right from the aura itself whenever the client hands it over (out of
-- combat; someone else's bandage, or the debuff gone as you die).

local ns = PadKeys
local c = ns.config.not_ready

local ab = C_ActionBar

-- Seconds between a press and its error for the two to count as one.
local WINDOW = 0.5

local COOLDOWN_ERRORS = {}
for _, key in ipairs({ "LE_GAME_ERR_SPELL_COOLDOWN",
                       "LE_GAME_ERR_ABILITY_COOLDOWN",
                       "LE_GAME_ERR_ITEM_COOLDOWN" }) do
  if _G[key] then
    COOLDOWN_ERRORS[_G[key]] = true
  end
end

local function is_secret(v)
  return issecretvalue and issecretvalue(v)
end

-- --- The flash --------------------------------------------------------------

local frame = CreateFrame("Frame", "PadKeysNotReady", UIParent)
frame:SetSize(c.size, c.size)
if c.anchor == "cursor" then
  -- Follows the pointer; turning with the mouse hides it: stay put then.
  frame:SetScript("OnUpdate", function(self)
    if IsMouselooking and IsMouselooking() then
      return
    end
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "BOTTOMLEFT",
                  x / scale + (c.x or 0), y / scale + (c.y or 0))
  end)
else
  frame:SetPoint("CENTER", UIParent, "CENTER", c.x or 0, c.y or 0)
end
-- Over the readout (DIALOG) and the ready flash, whatever it overlaps.
frame:SetFrameStrata("FULLSCREEN_DIALOG")
frame:SetAlpha(0)
frame:EnableMouse(false)

-- The glow: Blizzard's button border in additive blend, tinted (colour
-- before alpha: SetVertexColor would undo an alpha set first). Its art has
-- wide see-through margins, hence the size. It fades with the frame.
if c.glow then
  local glow = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
  glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  glow:SetBlendMode("ADD")
  glow:SetDesaturated(true)
  glow:SetVertexColor(c.glow[1], c.glow[2], c.glow[3])
  glow:SetAlpha(c.glow_alpha or 0.9)
  glow:SetPoint("CENTER")
  glow:SetSize(c.size * 1.9, c.size * 1.9)
end

ns.box(frame, 0, c.rounded)

local icon = frame:CreateTexture(nil, "ARTWORK")
ns.fit_icon(frame, icon)
if c.rounded then
  ns.round(frame, icon, 1)
end
ns.icon(icon)

local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
cooldown:SetPoint("TOPLEFT", 1, -1)
cooldown:SetPoint("BOTTOMRIGHT", -1, 1)
cooldown:SetDrawSwipe(c.swipe and true or false)
cooldown:SetSwipeColor(0, 0, 0, 0.7)
cooldown:SetDrawEdge(false)
cooldown:SetDrawBling(false)
cooldown:SetHideCountdownNumbers(not c.countdown)
local countdown = cooldown.GetCountdownFontString and
  cooldown:GetCountdownFontString()
if countdown then
  ns.style(countdown, c.countdown_size or 24)
end

-- Full strength at once, then the fade. Playing it again mid-fade stops
-- the old one first, so a new press always starts from full.
local anim = frame:CreateAnimationGroup()
local fade = anim:CreateAnimation("Alpha")
fade:SetFromAlpha(1)
fade:SetToAlpha(0)
fade:SetStartDelay(c.hold or 0)
fade:SetDuration(c.fade_out or 1)
anim:SetScript("OnFinished", function()
  frame:SetAlpha(0)
  cooldown:Clear()
end)

local function flash(texture)
  anim:Stop()
  icon:SetTexture(texture)
  frame:SetAlpha(1)
  anim:Play()
end

-- --- Recently Bandaged -----------------------------------------------------

local RECENTLY_BANDAGED = 11196
local BANDAGED_FOR = 60
local FIRST_AID = C_Spell.GetSpellName(746)  -- a bandage's channel
local GetItemSpell = C_Item and C_Item.GetItemSpell or GetItemSpell

-- When the debuff started, and how long it lasts.
local bandaged_at, bandaged_for = -math.huge, BANDAGED_FOR

local function bandaged()
  return GetTime() < bandaged_at + bandaged_for
end

local function is_bandage(item)
  return FIRST_AID ~= nil and item ~= nil and GetItemSpell(item) == FIRST_AID
end

-- The aura itself, when the client hands it over as plain numbers.
local function read_bandaged()
  local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, RECENTLY_BANDAGED)
  if not ok then
    return
  end
  -- No aura in combat may only mean the client hides it: the kept time
  -- stays then.
  if not aura then
    if not InCombatLockdown() then
      bandaged_at = -math.huge
    end
  elseif not is_secret(aura.expirationTime) and not is_secret(aura.duration) and
         aura.duration > 0 then
    bandaged_at, bandaged_for = aura.expirationTime - aura.duration, aura.duration
  end
end

-- A bandage pressed under the debuff: flashes the debuff, true. Any other
-- press: false.
local function show_bandage(item)
  if not (c.bandage and is_bandage(item) and bandaged()) then
    return false
  end
  flash(C_Spell.GetSpellTexture(RECENTLY_BANDAGED))
  cooldown:SetCooldown(bandaged_at, bandaged_for)
  return true
end

-- --- What was pressed -------------------------------------------------------

-- Which action slots are only on the global cooldown, and which are
-- cooling (ns.cooling: running past the global cooldown, or on hold).
-- Blizzard's isOnGCD is only right while handling SPELL_UPDATE_COOLDOWN,
-- so it is read then for every slot and kept (as on PadKeys_Bar).
local MAX_ACTION_SLOT = 180
local on_gcd, cooling = {}, {}
local function read_cooldowns(with_gcd)
  for action = 1, MAX_ACTION_SLOT do
    local cd = ab.HasAction(action) and ab.GetActionCooldown(action)
    if with_gcd then
      on_gcd[action] = cd and cd.isOnGCD or nil
    end
    cooling[action] = ns.cooling(cd, c.ignore_gcd and on_gcd[action]) or nil
  end
end

-- An action slot: flashes it if it is on a cooldown other than the global
-- one, out of charges, or on hold (used, its cooldown starting only when
-- its buff ends, e.g. Rapid Fire: the icon without a countdown, as there
-- is no time left to show yet).
local function show_action(action)
  if not ab.HasAction(action) then
    return
  end
  local cd = ab.GetActionCooldown(action)
  local charges = ab.GetActionCharges and ab.GetActionCharges(action)
  if cd and cd.isActive and not (c.ignore_gcd and on_gcd[action]) then
    flash(ab.GetActionTexture(action))
    cooldown:SetCooldownFromDurationObject(
      ab.GetActionCooldownDuration(action, c.ignore_gcd and true or false))
  elseif ns.on_hold(cd) then
    flash(ab.GetActionTexture(action))
    cooldown:Clear()
  elseif charges and charges.isActive then
    flash(ab.GetActionTexture(action))
    cooldown:SetCooldownFromDurationObject(ab.GetActionChargeDuration(action))
  end
end

-- An item: start and duration may be secret. Without them the icon still
-- flashes (the game said it is not ready), just without a countdown.
local function show_item(texture, start, duration)
  if not texture then
    return
  end
  if not is_secret(duration) and duration and duration > 0 and
     duration <= 1.5 and c.ignore_gcd then
    return -- the global cooldown on an item's spell
  end
  flash(texture)
  if not (start and pcall(cooldown.SetCooldown, cooldown, start, duration)) then
    cooldown:Clear()
  end
end

local function show(press)
  if press.kind == "bag" then
    local info = C_Container.GetContainerItemInfo(press.a, press.b)
    show_item(info and info.iconFileID,
              C_Container.GetContainerItemCooldown(press.a, press.b))
  elseif press.kind == "worn" then
    show_item(GetInventoryItemTexture("player", press.a),
              GetInventoryItemCooldown("player", press.a))
  end
end

-- The last press, and the time of the last cooldown error. Whichever comes
-- second matches them; each is used once.
local last_press, error_at

local function try_match()
  if last_press and error_at and
     math.abs(last_press.at - error_at) <= WINDOW then
    local press = last_press
    last_press, error_at = nil, nil
    show(press)
  end
end

local function pressed(kind, a, b)
  last_press = { kind = kind, a = a, b = b, at = GetTime() }
  -- An error that came first counts only from this very frame, so a
  -- stale one (a /cast typed in chat) never flashes a later good press.
  if error_at and error_at ~= last_press.at then
    error_at = nil
  end
  try_match()
end

-- An action pressed while it was cooling: flashed at once, no error
-- needed.
hooksecurefunc("UseAction", function(action)
  if type(action) ~= "number" then
    return
  end
  local ok, kind, id = pcall(GetActionInfo, action)
  if ok and kind == "item" and show_bandage(id) then
    return
  end
  if cooling[action] then
    show_action(action)
  end
end)
if C_Container and C_Container.UseContainerItem then
  hooksecurefunc(C_Container, "UseContainerItem", function(bag, slot)
    if not show_bandage(C_Container.GetContainerItemID(bag, slot)) then
      pressed("bag", bag, slot)
    end
  end)
end
if UseInventoryItem then
  hooksecurefunc("UseInventoryItem", function(slot)
    pressed("worn", slot)
  end)
end

-- --- Events -----------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("UI_ERROR_MESSAGE")
events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
events:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
events:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
events:RegisterUnitEvent("UNIT_AURA", "player")
events:SetScript("OnEvent", function(_, event, error_type, _, spell)
  if event == "UNIT_SPELLCAST_CHANNEL_START" then
    -- error_type is the unit here, spell the channel's spell ID.
    if not is_secret(spell) and C_Spell.GetSpellName(spell) == FIRST_AID then
      bandaged_at, bandaged_for = GetTime(), BANDAGED_FOR
    end
  elseif event == "UNIT_AURA" then
    read_bandaged()
  elseif event == "UI_ERROR_MESSAGE" then
    if not is_secret(error_type) and COOLDOWN_ERRORS[error_type] then
      error_at = GetTime()
      try_match()
    end
  else
    read_cooldowns(event ~= "ACTIONBAR_UPDATE_COOLDOWN" and
                   event ~= "ACTIONBAR_SLOT_CHANGED")
  end
end)
