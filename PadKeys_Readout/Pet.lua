-- Your pet's health, lower left of the pointer (Config.lua, readout.pet):
-- its portrait and a thin bar, in combat, only once it is hurt (under
-- pet.show_below); a red wash over the bar when it is low (pet.low).
-- Out of combat the buff bar (PadKeys_Combat) tells you a pet is missing
-- or dead.
--
-- Health is secret in combat. UnitHealthPercent hands it through curves
-- (C_CurveUtil) to the client: one curve gives the bar's value (StatusBar
-- SetValue takes secret values), one the whole readout's alpha, one the
-- red wash's alpha (SetAlpha takes secret values). Nothing here compares
-- it. Whether the client reports the percent as 0-1 or 0-100 isn't
-- known, so every curve covers both, as in PadKeys_Radial's Lights.lua.

local ns = PadKeys
local c = ns.config.readout
local p = c.pet
local readout = PadKeysReadout
if not (p and p.enabled and readout and C_CurveUtil and UnitHealthPercent) then
  return
end

local size = p.size or 26

local frame = CreateFrame("Frame", "PadKeysReadoutPet", readout)
frame:SetSize(size, size + 7)
frame:SetPoint("TOPRIGHT", readout, "CENTER", p.x or -90, p.y or -40)
frame:EnableMouse(false)
frame:Hide()

local portrait = frame:CreateTexture(nil, "ARTWORK")
portrait:SetSize(size, size)
portrait:SetPoint("TOP")

local bar = CreateFrame("StatusBar", nil, frame)
bar:SetPoint("TOPLEFT", portrait, "BOTTOMLEFT", 0, -3)
bar:SetPoint("TOPRIGHT", portrait, "BOTTOMRIGHT", 0, -3)
bar:SetHeight(4)
bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
bar:SetStatusBarColor(0.3, 0.85, 0.4)
bar:SetMinMaxValues(0, 1)
local back = bar:CreateTexture(nil, "BACKGROUND")
back:SetAllPoints()
back:SetColorTexture(0, 0, 0, 0.6)
local wash = bar:CreateTexture(nil, "OVERLAY")
wash:SetAllPoints(bar:GetStatusBarTexture())
wash:SetColorTexture(1, 0.15, 0.15, 1)
wash:SetAlpha(0)

-- A curve over health 0-1 from { x, y } points, repeated at 0-100.
local function curve(points)
  local ok, cv = pcall(function()
    local cv = C_CurveUtil.CreateCurve()
    for _, pt in ipairs(points) do
      cv:AddPoint(pt[1], pt[2])
    end
    local last = points[#points]
    cv:AddPoint(last[1] + 0.0001, points[1][2])
    for _, pt in ipairs(points) do
      if pt[1] > 0 then
        cv:AddPoint(pt[1] * 100, pt[2])
      end
    end
    return cv
  end)
  return ok and cv or nil
end

local e = 0.0001
local below = p.show_below or 0.9
local low = p.low or 0.35
-- The bar's value: the percent itself (at 0-100, x / 100).
local value_curve = curve({ { 0, 0 }, { 1, 1 } })
local show_curve = curve({ { 0, 1 }, { below, 1 }, { below + e, 0 }, { 1, 0 } })
local low_curve = curve({ { 0, 0.85 }, { low, 0.85 }, { low + e, 0 }, { 1, 0 } })

local function evaluate(cv)
  if not cv then
    return nil
  end
  local ok, result = pcall(UnitHealthPercent, "pet", true, cv)
  if ok then
    return result
  end
  return nil
end

local function in_combat()
  return InCombatLockdown() or UnitAffectingCombat("player")
end

local function update()
  local on = UnitExists("pet") and (in_combat() or not p.combat_only)
  frame:SetShown(on and true or false)
  if not on then
    return
  end
  local v = evaluate(value_curve)
  if v == nil or not pcall(bar.SetValue, bar, v) then
    bar:SetValue(1)
  end
  local a = evaluate(show_curve)
  if a == nil or not pcall(frame.SetAlpha, frame, a) then
    frame:SetAlpha(1)
  end
  local w = evaluate(low_curve)
  if w == nil or not pcall(wash.SetAlpha, wash, w) then
    wash:SetAlpha(0)
  end
end

local events = CreateFrame("Frame")
pcall(events.RegisterUnitEvent, events, "UNIT_HEALTH", "pet")
pcall(events.RegisterUnitEvent, events, "UNIT_MAXHEALTH", "pet")
pcall(events.RegisterUnitEvent, events, "UNIT_PET", "player")
for _, event in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
                         "PLAYER_ENTERING_WORLD" }) do
  events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event)
  if event == "UNIT_PET" or event == "PLAYER_ENTERING_WORLD" then
    SetPortraitTexture(portrait, "pet")
  end
  update()
end)
