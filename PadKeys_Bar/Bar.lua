-- One bar for every layer. It shows what the eight action keys do with the
-- modifiers you hold right now: Bar 1 with no modifier, Bar 2 while you
-- hold Cmd, and so on, read from your live key bindings. So you can hide
-- Blizzard's bars in Edit Mode and keep only this one.
--
-- It only shows; it never casts. The keys still press Blizzard's buttons,
-- which work while hidden (MultiActionButtonDown and friends don't check
-- visibility). Each slot shows the action of the Blizzard button the key
-- presses (button.action, so stance and override paging carry over), with
-- Blizzard's own action API for the icon, cooldown, count, usable tint and
-- range. Out of range greys the icon; a cooldown makes it see-through
-- with the seconds left on top (no swipe). Nothing here is secure, so it updates freely in combat.

local ns = PadKeys
local c = ns.config.bar

local FACE_KEYS = ns.config.face_keys
local UPDATE_INTERVAL = 0.1

-- Buttons are c.size wide and HEIGHT tall. A short button shows the middle
-- band of the icon (ICON_TOP to ICON_BOTTOM) so it isn't squashed; 0.07 and
-- 0.93 trim Blizzard's icon border, as on a square button.
local HEIGHT = c.size * math.min(c.height or 1, 1)
local ICON_SPAN = 0.86 * HEIGHT / c.size
local ICON_TOP = 0.5 - ICON_SPAN / 2
local ICON_BOTTOM = 0.5 + ICON_SPAN / 2

-- Blizzard's multi bars by binding number: MULTIACTIONBAR1BUTTON1 presses
-- MultiBarBottomLeft's first button (Bindings_Standard.xml).
local MULTI_BARS = {
  "MultiBarBottomLeft",  -- Bar 2
  "MultiBarBottomRight", -- Bar 3
  "MultiBarRight",       -- Bar 4
  "MultiBarLeft",        -- Bar 5
  "MultiBar5",           -- Bar 6
  "MultiBar6",           -- Bar 7
  "MultiBar7",           -- Bar 8
}

local IS_MAC = IsMacClient and IsMacClient()
local MOD_NAMES = {
  ALT = IS_MAC and "Option" or "Alt",
  CTRL = "Ctrl",
  SHIFT = "Shift",
  META = "Cmd",
}

-- The key chord for a key with the modifiers held now, in WoW's binding
-- order ("CTRL-SHIFT-1"), and the held modifiers' names.
local function held_modifiers()
  local mods = {}
  if IsAltKeyDown() then mods[#mods + 1] = "ALT" end
  if IsControlKeyDown() then mods[#mods + 1] = "CTRL" end
  if IsShiftKeyDown() then mods[#mods + 1] = "SHIFT" end
  if IsMetaKeyDown and IsMetaKeyDown() then mods[#mods + 1] = "META" end
  return mods
end

local function chord(mods, key)
  if #mods == 0 then
    return key
  end
  return table.concat(mods, "-") .. "-" .. key
end

-- What a key press would do: a Blizzard action button, a pet bar slot, or
-- nothing we can show. An unbound modified key falls back to the plain key,
-- as WoW does (that's how [mod:alt] macros work).
local function source_for(mods, key)
  local command = GetBindingAction(chord(mods, key), true)
  if (not command or command == "") and #mods > 0 then
    command = GetBindingAction(key, true)
  end
  if not command or command == "" then
    return nil
  end

  local n = command:match("^ACTIONBUTTON(%d+)$")
  if n then
    local button = GetActionButtonForID and GetActionButtonForID(tonumber(n))
                   or _G["ActionButton" .. n]
    return button and { button = button, action = button.action }
  end

  local bar, slot = command:match("^MULTIACTIONBAR(%d+)BUTTON(%d+)$")
  if bar then
    local frame = _G[MULTI_BARS[tonumber(bar)] or ""]
    local button = frame and frame.actionButtons and
                   frame.actionButtons[tonumber(slot)]
    return button and { button = button, action = button.action }
  end

  n = command:match("^BONUSACTIONBUTTON(%d+)$")
  if n then
    if not (PetHasActionBar and PetHasActionBar()) then
      return nil
    end
    n = tonumber(n)
    local button = PetActionBar and PetActionBar.actionButtons and
                   PetActionBar.actionButtons[n]
    return { button = button, pet = n }
  end
  return nil
end

-- Range per action slot, from Blizzard's range events. Blizzard turns range
-- checks on for every action on its bars, hidden ones too; we turn them on
-- for the slots we show as well, in case it hasn't.
local out_of_range = {}
local range_checked = {}
local function watch_range(action)
  if action and not range_checked[action] and C_ActionBar and
     C_ActionBar.EnableActionRangeCheck then
    range_checked[action] = true
    C_ActionBar.EnableActionRangeCheck(action, true)
  end
end

-- Which action slots are only on the global cooldown, so a cast doesn't
-- dim the whole bar. Blizzard's isOnGCD flag is only right while handling
-- SPELL_UPDATE_COOLDOWN, so it is read then for every slot and kept.
local MAX_ACTION_SLOT = 180
local on_gcd = {}
local function read_gcd()
  local ab = C_ActionBar
  for action = 1, MAX_ACTION_SLOT do
    local cd = ab.HasAction(action) and ab.GetActionCooldown(action)
    on_gcd[action] = cd and cd.isOnGCD or nil
  end
end

-- --- The bar ------------------------------------------------------------

local bar = CreateFrame("Frame", "PadKeysBar", UIParent)
bar:SetScale(c.scale or 1)
bar:SetSize(#FACE_KEYS * c.size + (#FACE_KEYS - 1) * c.spacing, HEIGHT)
bar:SetClampedToScreen(true)
bar:SetMovable(true)

-- White text in the PadKeys font (ns.config.theme) with a drop shadow,
-- which keeps it brighter than an outline; Blizzard's font object stays if
-- the file can't be loaded.
local function text(parent, size, fallback)
  return ns.text(parent, size, "white", "OVERLAY", fallback)
end

local layer_text = text(bar, 15, "GameFontHighlightOutline")
layer_text:SetPoint("BOTTOM", bar, "TOP", 0, 6)

local function place()
  bar:ClearAllPoints()
  local saved = ns.db and ns.db.bar_position
  if saved then
    bar:SetPoint(saved[1], UIParent, saved[2], saved[3], saved[4])
  else
    bar:SetPoint(c.point, UIParent, c.point, c.x, c.y)
  end
end

-- Slightly rounded corners: the base addon's mask (PadKeys/Skin.lua).
local function round(frame, texture, inset)
  if c.rounded then
    ns.round(frame, texture, inset)
  end
end

local buttons = {}
for i, key in ipairs(FACE_KEYS) do
  local b = CreateFrame("Frame", nil, bar)
  b:SetSize(c.size, HEIGHT)
  b:SetPoint("LEFT", bar, "LEFT", (i - 1) * (c.size + c.spacing), 0)

  -- 1px border: a shape behind the icon, black normally, grey while the
  -- action is active (casting, auto attack, a pet stance), white while its
  -- key is down.
  b.border = b:CreateTexture(nil, "BACKGROUND", nil, 0)
  b.border:SetAllPoints()
  b.border:SetColorTexture(1, 1, 1)
  round(b, b.border, 0)

  b.bg = b:CreateTexture(nil, "BACKGROUND", nil, 1)
  b.bg:SetPoint("TOPLEFT", 1, -1)
  b.bg:SetPoint("BOTTOMRIGHT", -1, 1)
  b.bg:SetColorTexture(0, 0, 0, c.background_alpha)
  round(b, b.bg, 1)

  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetPoint("TOPLEFT", 1, -1)
  b.icon:SetPoint("BOTTOMRIGHT", -1, 1)
  b.icon:SetTexCoord(0.07, 0.93, ICON_TOP, ICON_BOTTOM)
  round(b, b.icon, 1)
  ns.icon(b.icon)

  b.cooldown = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
  b.cooldown:SetPoint("TOPLEFT", 1, -1)
  b.cooldown:SetPoint("BOTTOMRIGHT", -1, 1)
  -- Only the countdown: no swipe, edge or flash. Blizzard shows the
  -- numbers by the countdownForCooldowns setting; ours always shows them.
  b.cooldown:SetDrawSwipe(false)
  b.cooldown:SetDrawEdge(false)
  b.cooldown:SetDrawBling(false)
  b.cooldown:SetHideCountdownNumbers(false)
  local countdown = b.cooldown.GetCountdownFontString and
    b.cooldown:GetCountdownFontString()
  if countdown then
    ns.style(countdown, c.countdown_size or 20)
  end

  -- Text above the countdown.
  local top = CreateFrame("Frame", nil, b)
  top:SetAllPoints()
  top:SetFrameLevel(b.cooldown:GetFrameLevel() + 1)

  b.hotkey = text(top, c.hotkey_size or 13, "NumberFontNormalSmall")
  b.hotkey:SetPoint("TOPRIGHT", -3, -3)
  b.hotkey:SetJustifyH("RIGHT")
  b.hotkey:SetText(GetBindingText and GetBindingText(key) or key)

  -- A see-through black box behind the key label, tucked into the top right
  -- corner of the icon. The button's border already edges its top and right,
  -- so the outline only needs the left and bottom sides. The font string
  -- sizes itself to its text, so the box follows the label's corners.
  if c.hotkey_background then
    local box = top:CreateTexture(nil, "BACKGROUND", nil, 0)
    box:SetPoint("TOPRIGHT", b, "TOPRIGHT", -1, -1)
    box:SetPoint("BOTTOMLEFT", b.hotkey, "BOTTOMLEFT", -3, -2)
    box:SetColorTexture(0, 0, 0, c.hotkey_background_alpha)
    round(top, box, 1)
    if c.hotkey_outline then
      local left = top:CreateTexture(nil, "BACKGROUND", nil, 1)
      left:SetPoint("TOPRIGHT", box, "TOPLEFT", 0, 0)
      left:SetPoint("BOTTOMRIGHT", box, "BOTTOMLEFT", 0, -1)
      left:SetWidth(1)
      left:SetColorTexture(0, 0, 0, c.hotkey_outline_alpha)
      local bottom = top:CreateTexture(nil, "BACKGROUND", nil, 1)
      bottom:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, 0)
      bottom:SetPoint("TOPRIGHT", box, "BOTTOMRIGHT", 0, 0)
      bottom:SetHeight(1)
      bottom:SetColorTexture(0, 0, 0, c.hotkey_outline_alpha)
      round(top, bottom, 1)
    end
  end

  -- Stack count top left, across from the key label, so the macro name has
  -- the bottom edge to itself on a short button.
  b.count = text(top, c.count_size or 15, "NumberFontNormal")
  b.count:SetPoint("TOPLEFT", 3, -3)

  b.name = text(top, c.name_size or 11, "GameFontHighlightSmallOutline")
  b.name:SetPoint("BOTTOMLEFT", 2, 2)
  b.name:SetPoint("BOTTOMRIGHT", -2, 2)
  b.name:SetHeight((c.name_size or 11) - 1)

  -- Proc glow: a pulsing white ring.
  b.glow = top:CreateTexture(nil, "OVERLAY")
  b.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  b.glow:SetBlendMode("ADD")
  ns.tint(b.glow, "white")
  b.glow:SetPoint("CENTER")
  b.glow:SetSize(c.size * 1.8, HEIGHT * 1.8)
  b.glow:Hide()
  b.pulse = b.glow:CreateAnimationGroup()
  b.pulse:SetLooping("BOUNCE")
  local fade = b.pulse:CreateAnimation("Alpha")
  fade:SetFromAlpha(1)
  fade:SetToAlpha(0.3)
  fade:SetDuration(0.5)

  b.key = key
  buttons[i] = b
end

-- Proc glow. SpellActivationOverlay (and other addons) light up Blizzard's
-- buttons with LibButtonGlow (button.__LBGoverlay), and Blizzard's own proc
-- alerts go through ActionButtonSpellAlertManager. Both work on buttons of
-- hidden bars, so we copy the glow of the button a key presses. Ours is a
-- white ring rather than LibButtonGlow's gold one, to stay black and white.
local function source_glows(button)
  if not button then
    return false
  end
  local overlay = button.__LBGoverlay
  if overlay and not (overlay.animOut and overlay.animOut:IsPlaying()) then
    return true
  end
  local alerts = ActionButtonSpellAlertManager
  if alerts and alerts.HasAlert and alerts:HasAlert(button) then
    return true
  end
  return false
end

local function set_glow(b, on)
  on = on and true or false
  if b.glowing == on then
    return
  end
  b.glowing = on
  if on then
    b.glow:Show()
    b.pulse:Play()
  else
    b.pulse:Stop()
    b.glow:Hide()
  end
end

local function set_border(b, r, g, bl)
  b.border:SetVertexColor(r, g, bl)
end

-- Cooldown numbers are secret values in combat: addon code may neither
-- compare them nor pass them to SetCooldown. A duration object wraps them
-- (C_ActionBar.GetActionCooldownDuration), and the widget takes it with
-- SetCooldownFromDurationObject. A plain flag (isActive) decides whether
-- to show one, as in Blizzard's ActionButton_ApplyCooldown.
local function set_cooldown(b, duration)
  if duration then
    b.cooldown:SetCooldownFromDurationObject(duration)
  else
    b.cooldown:Clear()
  end
end

-- Out of range: the icon in grey. On cooldown: see-through, the countdown
-- on top. Both only change the icon; the key label stays white.
local function set_state(b, far, cooling)
  b.icon:SetDesaturated(far or ns.config.theme.grey_icons or false)
  local alpha = 1
  if cooling then
    alpha = c.cooldown_alpha or 0.35
  end
  if far then
    alpha = math.min(alpha, c.range_alpha or 0.6)
  end
  b.icon:SetAlpha(alpha)
end

local function clear(b)
  b.icon:SetTexture(nil)
  b.count:SetText("")
  b.name:SetText("")
  set_cooldown(b, nil)
  set_state(b, false, false)
  set_border(b, 0, 0, 0)
  set_glow(b, false)
end

local function show_action(b, action)
  local ab = C_ActionBar
  if not action or not ab.HasAction(action) then
    clear(b)
    return false
  end
  watch_range(action)
  b.icon:SetTexture(ab.GetActionTexture(action))

  local usable, no_mana = ab.IsUsableAction(action)
  if usable then
    b.icon:SetVertexColor(1, 1, 1)
  elseif no_mana then
    b.icon:SetVertexColor(0.6, 0.6, 0.6)
  else
    b.icon:SetVertexColor(0.35, 0.35, 0.35)
  end

  -- The global cooldown alone shows nothing. A spell out of charges is on
  -- cooldown; one recharging with charges left shows the recharge time but
  -- stays solid, as it can still be cast.
  local cd = ab.GetActionCooldown(action)
  local charges = ab.GetActionCharges and ab.GetActionCharges(action)
  local cooling = cd and cd.isActive and not on_gcd[action] or false
  if cooling then
    set_cooldown(b, ab.GetActionCooldownDuration(action, true))
  elseif charges and charges.isActive then
    set_cooldown(b, ab.GetActionChargeDuration(action))
  else
    set_cooldown(b, nil)
  end

  -- The count may be secret too: SetText takes it, testing it would not.
  b.count:SetText(ab.GetActionDisplayCount(action))
  local is_macro = GetActionInfo(action) == "macro"
  b.name:SetText(c.show_macro_names and is_macro and
                 ab.GetActionText(action) or "")
  return ab.IsCurrentAction(action) or ab.IsAutoRepeatAction(action),
         out_of_range[action], cooling
end

local function show_pet(b, slot)
  local name, texture, is_token, is_active, _, _, _, checks_range, in_range =
    GetPetActionInfo(slot)
  if not name and not texture then
    clear(b)
    return false
  end
  b.icon:SetTexture(is_token and _G[texture] or texture)
  if GetPetActionSlotUsable(slot) then
    b.icon:SetVertexColor(1, 1, 1)
  else
    b.icon:SetVertexColor(0.35, 0.35, 0.35)
  end
  -- The pet API has no duration object and no plain "active" flag, so a
  -- pet cooldown shows the countdown but doesn't fade the icon. If its
  -- numbers are secret, SetCooldown refuses them and nothing shows.
  local start, duration = GetPetActionCooldown(slot)
  if not pcall(b.cooldown.SetCooldown, b.cooldown, start, duration) then
    b.cooldown:Clear()
  end
  b.count:SetText("")
  b.name:SetText("")
  return is_active, checks_range and not in_range
end

local function update()
  local mods = held_modifiers()
  local names = {}
  for i, m in ipairs(mods) do
    names[i] = MOD_NAMES[m]
  end
  layer_text:SetText(c.show_layer and table.concat(names, "+") or "")

  for _, b in ipairs(buttons) do
    local src = source_for(mods, b.key)
    local active, far, cooling
    if not src then
      clear(b)
    elseif src.pet then
      active, far = show_pet(b, src.pet)
    else
      active, far, cooling = show_action(b, src.action)
    end
    if src and b.icon:GetTexture() then
      set_state(b, far, cooling)
      local pushed = src.button and src.button:GetButtonState() == "PUSHED"
      if pushed then
        set_border(b, 1, 1, 1)
      elseif active then
        set_border(b, ns.grey.mid, ns.grey.mid, ns.grey.mid)
      else
        set_border(b, 0, 0, 0)
      end
      set_glow(b, c.glow and not src.pet and source_glows(src.button))
    end
  end
end

-- --- Events and moving --------------------------------------------------

local elapsed = 0
bar:SetScript("OnUpdate", function(_, dt)
  elapsed = elapsed + dt
  if elapsed >= UPDATE_INTERVAL then
    elapsed = 0
    update()
  end
end)

bar:RegisterEvent("PLAYER_LOGIN")
bar:RegisterEvent("MODIFIER_STATE_CHANGED")
bar:RegisterEvent("ACTION_RANGE_CHECK_UPDATE")
bar:RegisterEvent("SPELL_UPDATE_COOLDOWN")
bar:SetScript("OnEvent", function(_, event, ...)
  if event == "SPELL_UPDATE_COOLDOWN" then
    read_gcd()
  elseif event == "ACTION_RANGE_CHECK_UPDATE" then
    local action, in_range, checks_range = ...
    out_of_range[action] = checks_range and not in_range or nil
    return
  end
  if event == "PLAYER_LOGIN" then
    place()
  end
  update()
end)

-- /padkeys bar: unlock to drag, again to lock. The spot is saved per
-- account in PadKeysDB; "/padkeys bar reset" goes back to Config.lua.
local mover = CreateFrame("Frame", nil, bar)
mover:SetAllPoints()
mover:SetFrameLevel(bar:GetFrameLevel() + 20)
mover.tex = mover:CreateTexture(nil, "OVERLAY")
mover.tex:SetAllPoints()
mover.tex:SetColorTexture(1, 1, 1, 0.25)
mover:EnableMouse(true)
mover:RegisterForDrag("LeftButton")
mover:SetScript("OnDragStart", function() bar:StartMoving() end)
mover:SetScript("OnDragStop", function()
  bar:StopMovingOrSizing()
  local point, _, relative, x, y = bar:GetPoint(1)
  ns.db.bar_position = { point, relative or point, x, y }
  place()
end)
mover:Hide()
place()

function ns.toggle_bar_move(arg)
  if arg == "reset" then
    ns.db.bar_position = nil
    place()
    ns.say("bar back at its Config.lua position.")
    return
  end
  if mover:IsShown() then
    mover:Hide()
    ns.say("bar locked.")
  else
    mover:Show()
    ns.say("drag the bar, then /padkeys bar to lock it.")
  end
end
