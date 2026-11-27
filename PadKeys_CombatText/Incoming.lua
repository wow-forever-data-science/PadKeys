-- The hits you take, as a small scroll lower right of the mouse (Config.lua,
-- combattext.incoming; or under your character). The whole scroll fades
-- in as your health drops, so it stays out of the way while you're fine;
-- as a tank it shows earlier. Heavy damage (a crit, a crushing blow or a
-- burst of hits) shows it at full strength for a few seconds whatever your
-- health, and lights the radial's healing slices (ns.player_hit_until).
--
-- Health is secret in combat, so the alpha is never worked out here:
-- UnitHealthPercent takes a curve (health -> alpha) and returns the
-- curve's value, still secret, and SetAlpha accepts secrets.
--
-- UNIT_COMBAT doesn't say which spell hit you, so these lines have no
-- icon. Colours: crits and crushing blows red, non-physical hits yellow,
-- the rest white.

local ns = PadKeys
local c = ns.config.combattext
local s = c.incoming
if not (s and s.enabled) then
  return
end

local M = ns.combattext
local scroll = M.new_scroll(s, false)
local frame = scroll.frame

local PHYSICAL = 1

-- --- Where it sits ---------------------------------------------------------

if s.anchor == "cursor" then
  frame:SetScript("OnUpdate", function()
    -- Turning with the mouse hides the pointer: stay where it was.
    if IsMouselooking and IsMouselooking() then
      return
    end
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT",
                   x / scale + (s.x or 0), y / scale + (s.y or 0))
  end)
else
  frame:SetPoint("CENTER", UIParent, "CENTER", s.x or 0, s.y or 0)
end

-- --- Tank or not ------------------------------------------------------------

local TANK_FORMS = {
  [71] = true,    -- Defensive Stance
  [5487] = true,  -- Bear Form
  [9634] = true,  -- Dire Bear Form
}
local RIGHTEOUS_FURY = 25780

local fury = false -- seen out of combat, or cast in combat

local function in_tank_form()
  for i = 1, GetNumShapeshiftForms() do
    local _, active, _, spell_id = GetShapeshiftFormInfo(i)
    if active and spell_id and not M.is_secret(spell_id)
        and TANK_FORMS[spell_id] then
      return true
    end
  end
  return false
end

local function read_fury()
  if InCombatLockdown() then
    return
  end
  local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, RIGHTEOUS_FURY)
  fury = ok and aura ~= nil
end

local function is_tank()
  if s.tank == true or s.tank == false then
    return s.tank
  end
  if UnitGroupRolesAssigned and UnitGroupRolesAssigned("player") == "TANK" then
    return true
  end
  return fury or in_tank_form()
end

-- --- Alpha by health --------------------------------------------------------

local function make_curve(points)
  if not (C_CurveUtil and C_CurveUtil.CreateCurve) then
    return nil
  end
  local curve = C_CurveUtil.CreateCurve()
  curve:SetType(Enum.LuaCurveType.Linear)
  for _, p in ipairs(points) do
    curve:AddPoint(p[1], p[2])
  end
  return curve
end

local curves = {
  normal = make_curve(s.alpha_by_health),
  tank = make_curve(s.tank_alpha_by_health),
}

local tank = false
local heavy_until = 0

local function update_alpha()
  if GetTime() < heavy_until then
    frame:SetAlpha(1)
    return
  end
  local curve = tank and curves.tank or curves.normal
  if curve and UnitHealthPercent then
    local ok, alpha = pcall(UnitHealthPercent, "player", false, curve)
    -- The alpha is secret: not even compared with nil here.
    if ok and pcall(frame.SetAlpha, frame, alpha) then
      return
    end
  end
  frame:SetAlpha(1) -- without curves, always shown
end

local function update_tank()
  tank = is_tank()
  update_alpha()
end

-- --- Heavy damage ------------------------------------------------------------

local recent = {}
local release = CreateFrame("Frame")
release:Hide()
release:SetScript("OnUpdate", function(self)
  if GetTime() >= heavy_until then
    self:Hide()
    update_alpha()
  end
end)

-- A hit that landed: heavy if it is a crit or crushing blow, or one of
-- burst_hits within burst_window seconds.
local function note_hit(flags)
  local now = GetTime()
  local kept = { now }
  for _, t in ipairs(recent) do
    if now - t <= (s.burst_window or 1.5) then
      kept[#kept + 1] = t
    end
  end
  recent = kept
  if flags == "CRITICAL" or flags == "CRUSHING" or #recent >= (s.burst_hits or 4) then
    heavy_until = now + (s.heavy_hold or 3)
    ns.player_hit_until = heavy_until
    frame:SetAlpha(1)
    release:Show()
  end
end

-- --- Hits --------------------------------------------------------------------

local function on_hit(event, flags, amount, school)
  local word
  if event == "WOUND" then
    if M.MISS_WORDS[flags] and not M.is_secret(amount) and amount == 0 then
      word = M.MISS_WORDS[flags]
    end
  elseif M.MISS_WORDS[event] then
    word = M.MISS_WORDS[event]
  else
    return
  end
  if word then
    if s.show_misses then
      scroll:add(word, "normal")
    end
    return
  end
  note_hit(flags)
  local kind = school == PHYSICAL and "normal" or "special"
  if flags == "CRITICAL" or flags == "CRUSHING" then
    kind = "crit"
  end
  scroll:add(M.amount_text(amount), kind)
end

-- --- Events ---------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterUnitEvent("UNIT_COMBAT", "player")
events:RegisterUnitEvent("UNIT_HEALTH", "player")
events:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
events:RegisterUnitEvent("UNIT_AURA", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
events:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
events:RegisterEvent("PLAYER_ROLES_ASSIGNED")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, event, _, a, b, c4, d)
  if event == "UNIT_COMBAT" then
    on_hit(a, b, c4, d)
  elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
    update_alpha()
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    if not M.is_secret(b) and b == RIGHTEOUS_FURY then
      fury = true
      update_tank()
    end
  elseif event == "UNIT_AURA" then
    -- Righteous Fury can only be read out of combat.
    if not InCombatLockdown() then
      read_fury()
      update_tank()
    end
  else
    read_fury()
    update_tank()
  end
end)
