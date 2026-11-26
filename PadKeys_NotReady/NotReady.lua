-- Pressing a key or using an item that is still on cooldown flashes its
-- icon in the middle of the screen, with the time left, and fades it out
-- (Config.lua: one second). Another such press, of the same key or
-- another, replaces it at once and starts the fade again.
--
-- How a press "on cooldown" is told apart: the game answers it with a UI
-- error ("Spell is not ready yet.", "Item is not ready yet."), as
-- UI_ERROR_MESSAGE with a plain error type. Which action it was comes from
-- post-hooks on the functions every press goes through: UseAction (action
-- bars, PadKeys_Bar and the radials all call it via SecureActionButton),
-- C_Container.UseContainerItem (bags) and UseInventoryItem (worn items).
-- hooksecurefunc runs after Blizzard's call and leaves it untainted.
--
-- Cooldown numbers are secret in combat, so the countdown goes through a
-- duration object (C_ActionBar.GetActionCooldownDuration) and
-- SetCooldownFromDurationObject, and only the plain flags (isActive,
-- isOnGCD) are tested, as on PadKeys_Bar. Item cooldowns have no duration
-- object: SetCooldown is tried with pcall and the countdown is left out if
-- it refuses the numbers.

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
frame:SetPoint("CENTER", UIParent, "CENTER", c.x or 0, c.y or 0)
frame:SetFrameStrata("HIGH")
frame:SetAlpha(0)
frame:EnableMouse(false)

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

-- --- What was pressed -------------------------------------------------------

-- Which action slots are only on the global cooldown. Blizzard's isOnGCD
-- is only right while handling SPELL_UPDATE_COOLDOWN, so it is read then
-- for every slot and kept (as on PadKeys_Bar).
local MAX_ACTION_SLOT = 180
local on_gcd = {}
local function read_gcd()
  for action = 1, MAX_ACTION_SLOT do
    local cd = ab.HasAction(action) and ab.GetActionCooldown(action)
    on_gcd[action] = cd and cd.isOnGCD or nil
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
  if press.kind == "action" then
    show_action(press.a)
  elseif press.kind == "bag" then
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

hooksecurefunc("UseAction", function(action)
  if type(action) == "number" then
    pressed("action", action)
  end
end)
if C_Container and C_Container.UseContainerItem then
  hooksecurefunc(C_Container, "UseContainerItem", function(bag, slot)
    pressed("bag", bag, slot)
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
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, event, error_type)
  if event == "UI_ERROR_MESSAGE" then
    if not is_secret(error_type) and COOLDOWN_ERRORS[error_type] then
      error_at = GetTime()
      try_match()
    end
  else
    read_gcd()
  end
end)
