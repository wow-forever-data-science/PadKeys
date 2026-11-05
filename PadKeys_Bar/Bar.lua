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
-- range. Nothing here is secure, so it updates freely in combat.

local ns = PadKeys
local c = ns.config.bar

local FACE_KEYS = ns.config.face_keys
local UPDATE_INTERVAL = 0.1

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

-- --- The bar ------------------------------------------------------------

local bar = CreateFrame("Frame", "PadKeysBar", UIParent)
bar:SetScale(c.scale or 1)
bar:SetSize(#FACE_KEYS * c.size + (#FACE_KEYS - 1) * c.spacing, c.size)
bar:SetClampedToScreen(true)
bar:SetMovable(true)

local layer_text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
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

local function edge(parent, a, b, horizontal)
  local t = parent:CreateTexture(nil, "OVERLAY")
  t:SetColorTexture(1, 1, 1)
  t:SetPoint(a)
  t:SetPoint(b)
  if horizontal then t:SetHeight(1) else t:SetWidth(1) end
  return t
end

local buttons = {}
for i, key in ipairs(FACE_KEYS) do
  local b = CreateFrame("Frame", nil, bar)
  b:SetSize(c.size, c.size)
  b:SetPoint("LEFT", bar, "LEFT", (i - 1) * (c.size + c.spacing), 0)

  b.bg = b:CreateTexture(nil, "BACKGROUND")
  b.bg:SetAllPoints()
  b.bg:SetColorTexture(0, 0, 0, 0.5)

  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetPoint("TOPLEFT", 1, -1)
  b.icon:SetPoint("BOTTOMRIGHT", -1, 1)
  b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

  b.cooldown = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
  b.cooldown:SetPoint("TOPLEFT", 1, -1)
  b.cooldown:SetPoint("BOTTOMRIGHT", -1, 1)
  b.cooldown:SetDrawEdge(false)

  -- Text above the cooldown swipe.
  local top = CreateFrame("Frame", nil, b)
  top:SetAllPoints()
  top:SetFrameLevel(b.cooldown:GetFrameLevel() + 1)

  -- 1px border: dark normally, gold while the action is active (casting,
  -- auto attack, a pet stance), white while its key is down.
  b.edges = {
    edge(top, "TOPLEFT", "TOPRIGHT", true),
    edge(top, "BOTTOMLEFT", "BOTTOMRIGHT", true),
    edge(top, "TOPLEFT", "BOTTOMLEFT", false),
    edge(top, "TOPRIGHT", "BOTTOMRIGHT", false),
  }

  b.hotkey = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
  b.hotkey:SetPoint("TOPRIGHT", -3, -3)
  b.hotkey:SetText(GetBindingText and GetBindingText(key) or key)

  b.count = top:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  b.count:SetPoint("BOTTOMRIGHT", -2, 2)

  b.name = top:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
  b.name:SetPoint("BOTTOMLEFT", 2, 2)
  b.name:SetPoint("BOTTOMRIGHT", -2, 2)
  b.name:SetHeight(10)

  -- Fallback proc glow, for when no addon has loaded LibButtonGlow: a
  -- pulsing gold ring.
  b.glow = top:CreateTexture(nil, "OVERLAY")
  b.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  b.glow:SetBlendMode("ADD")
  b.glow:SetVertexColor(1, 0.85, 0.2)
  b.glow:SetPoint("CENTER")
  b.glow:SetSize(c.size * 1.8, c.size * 1.8)
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
-- hidden bars, so we copy the glow of the button a key presses. Our glow
-- uses LibButtonGlow too when it's loaded, so it looks the same.
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
  local lbg = LibStub and LibStub("LibButtonGlow-1.0", true)
  if on and lbg then
    lbg.ShowOverlayGlow(b)
    b.lbg = lbg
  elseif on then
    b.glow:Show()
    b.pulse:Play()
  else
    if b.lbg then
      b.lbg.HideOverlayGlow(b)
      b.lbg = nil
    end
    b.pulse:Stop()
    b.glow:Hide()
  end
end

local function set_border(b, r, g, bl)
  for _, t in ipairs(b.edges) do
    t:SetVertexColor(r, g, bl)
  end
end

-- Cooldown numbers are secret values in combat: our code may hand them to
-- the cooldown widget but not compare them (that errors). So, as in
-- Blizzard's ActionButton_ApplyCooldown, a plain flag decides whether to
-- show one, and the numbers go straight to SetCooldown.
local function set_cooldown(b, show, start, duration, mod_rate)
  if show then
    b.cooldown:SetCooldown(start, duration, mod_rate or 1)
  else
    b.cooldown:Clear()
  end
end

local function clear(b)
  b.icon:SetTexture(nil)
  b.count:SetText("")
  b.name:SetText("")
  b.hotkey:SetTextColor(0.6, 0.6, 0.6)
  set_cooldown(b, false)
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
    b.icon:SetVertexColor(0.5, 0.5, 1)
  else
    b.icon:SetVertexColor(0.4, 0.4, 0.4)
  end

  local cd = ab.GetActionCooldown(action)
  local charges = ab.GetActionCharges and ab.GetActionCharges(action)
  if cd and cd.isActive then
    set_cooldown(b, true, cd.startTime, cd.duration, cd.modRate)
  elseif charges and charges.isActive then
    set_cooldown(b, true, charges.cooldownStartTime, charges.cooldownDuration,
                 charges.chargeModRate)
  else
    set_cooldown(b, false)
  end

  b.count:SetText(ab.GetActionDisplayCount and
                  ab.GetActionDisplayCount(action) or "")
  local is_macro = GetActionInfo(action) == "macro"
  b.name:SetText(c.show_macro_names and is_macro and
                 ab.GetActionText(action) or "")
  return ab.IsCurrentAction(action) or ab.IsAutoRepeatAction(action),
         out_of_range[action]
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
    b.icon:SetVertexColor(0.4, 0.4, 0.4)
  end
  -- The pet API has no plain flag; a duration of 0 shows no swipe, so the
  -- numbers go to the widget unchecked.
  local start, duration = GetPetActionCooldown(slot)
  set_cooldown(b, type(start) == "number", start, duration)
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
    local active, far
    if not src then
      clear(b)
    elseif src.pet then
      active, far = show_pet(b, src.pet)
    else
      active, far = show_action(b, src.action)
    end
    if src and b.icon:GetTexture() then
      if far then
        b.hotkey:SetTextColor(1, 0.1, 0.1)
      else
        b.hotkey:SetTextColor(0.8, 0.8, 0.8)
      end
      local pushed = src.button and src.button:GetButtonState() == "PUSHED"
      if pushed then
        set_border(b, 1, 1, 1)
      elseif active then
        set_border(b, 1, 0.82, 0)
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
bar:SetScript("OnEvent", function(_, event, ...)
  if event == "ACTION_RANGE_CHECK_UPDATE" then
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
mover.tex:SetColorTexture(0.2, 0.6, 1, 0.35)
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
