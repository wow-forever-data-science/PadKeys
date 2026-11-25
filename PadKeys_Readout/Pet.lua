-- Your pet in trouble, lower left of the pointer (Config.lua, readout.pet):
-- its portrait with a red ring that pulses, shown only
-- - for a few seconds after it takes a lot of damage: a crit or crushing
--   blow on it, or a burst of hits (pet.burst_hits within
--   pet.burst_window seconds);
-- - for as long as its health is low (under pet.low).
-- Otherwise nothing shows. Out of combat the buff bar (PadKeys_Combat)
-- tells you a pet is missing or dead.
--
-- The hits come from UNIT_COMBAT on the pet: their amounts are secret and
-- never read; crits, crushing blows and how many hits came are plain.
-- Health is secret in combat: UnitHealthPercent hands it through a step
-- curve (C_CurveUtil) to the client, and the result goes only to the low
-- layer's SetAlpha, which takes secret values. Whether the client reports
-- the percent as 0-1 or 0-100 isn't known, so the curve covers both, as
-- in PadKeys_Radial's Lights.lua.

local ns = PadKeys
local c = ns.config.readout
local p = c.pet
local readout = PadKeysReadout
if not (p and p.enabled and readout) then
  return
end

local MEDIA = "Interface\\AddOns\\PadKeys_Readout\\Media\\"
local size = p.size or 30

local frame = CreateFrame("Frame", "PadKeysReadoutPet", readout)
frame:SetSize(size, size)
frame:SetPoint("TOPRIGHT", readout, "CENTER", p.x or -90, p.y or -40)
frame:EnableMouse(false)
frame:Hide()

-- A layer: the portrait, a red ring and a red glow that pulse. The low
-- layer's own alpha may be secret; the pulse's is plain; they multiply.
local layers = {}
local function make_layer()
  local layer = CreateFrame("Frame", nil, frame)
  layer:SetAllPoints()
  local portrait = layer:CreateTexture(nil, "ARTWORK")
  portrait:SetAllPoints()
  local pulse_frame = CreateFrame("Frame", nil, layer)
  pulse_frame:SetAllPoints()
  local glow = pulse_frame:CreateTexture(nil, "BACKGROUND")
  glow:SetPoint("CENTER")
  glow:SetSize(size * 1.7, size * 1.7)
  glow:SetTexture(MEDIA .. "RingGlow")
  glow:SetBlendMode("ADD")
  glow:SetVertexColor(1, 0.1, 0.1, 1)
  local ring = pulse_frame:CreateTexture(nil, "OVERLAY")
  ring:SetPoint("CENTER")
  ring:SetSize(size * 1.25, size * 1.25)
  ring:SetTexture(MEDIA .. "Ring")
  ring:SetVertexColor(1, 0.15, 0.15, 1)
  local anim = pulse_frame:CreateAnimationGroup()
  anim:SetLooping("BOUNCE")
  local a = anim:CreateAnimation("Alpha")
  a:SetFromAlpha(1)
  a:SetToAlpha(0.2)
  a:SetDuration(p.pulse or 0.35)
  a:SetSmoothing("IN_OUT")
  anim:Play()
  layer.portrait = portrait
  layer:Hide()
  layers[#layers + 1] = layer
  return layer
end

local hit = make_layer()  -- after a lot of damage, for a few seconds
local low = make_layer()  -- while health is low (secret alpha)

local function set_portraits()
  for _, layer in ipairs(layers) do
    SetPortraitTexture(layer.portrait, "pet")
  end
end

-- --- Low health ---------------------------------------------------------------

local low_curve
if C_CurveUtil and C_CurveUtil.CreateCurve and UnitHealthPercent then
  local t, e = p.low or 0.35, 0.0001
  local ok, cv = pcall(function()
    local cv = C_CurveUtil.CreateCurve()
    cv:AddPoint(0, 1)
    cv:AddPoint(t, 1)
    cv:AddPoint(t + e, 0)
    cv:AddPoint(1, 0)
    cv:AddPoint(1 + e, 1)
    cv:AddPoint(t * 100, 1)
    cv:AddPoint(t * 100 + e, 0)
    cv:AddPoint(100, 0)
    return cv
  end)
  low_curve = ok and cv or nil
end

local function update_low()
  if low_curve then
    local ok, alpha = pcall(UnitHealthPercent, "pet", true, low_curve)
    if ok and pcall(low.SetAlpha, low, alpha) then
      return
    end
  end
  low:SetAlpha(0)
end

-- --- Driver ---------------------------------------------------------------------

local function in_combat()
  return InCombatLockdown() or UnitAffectingCombat("player")
end

local hit_until = 0

local function update()
  local on = UnitExists("pet") and not UnitIsDead("pet")
    and (in_combat() or not p.combat_only)
  frame:SetShown(on and true or false)
  if not on then
    return
  end
  low:Show()
  update_low()
  hit:SetShown(GetTime() < hit_until)
end

-- Hides the hit layer once its time is up.
local timer = CreateFrame("Frame")
timer:Hide()
timer:SetScript("OnUpdate", function(self)
  if GetTime() >= hit_until then
    self:Hide()
    hit:Hide()
  end
end)

local hits = {}
local function on_hit(action, flags, amount)
  if action ~= "WOUND" then
    return
  end
  if not (issecretvalue and issecretvalue(amount)) and amount == 0 then
    return
  end
  local now = GetTime()
  local window = p.burst_window or 2
  local kept = { now }
  for _, t in ipairs(hits) do
    if now - t <= window then
      kept[#kept + 1] = t
    end
  end
  hits = kept
  if flags == "CRITICAL" or flags == "CRUSHING" or #hits >= (p.burst_hits or 3) then
    hit_until = now + (p.hold or 3)
    ns.pet_hit_until = hit_until -- for the radial's lit slices
    timer:Show()
    update()
  end
end

local events = CreateFrame("Frame")
pcall(events.RegisterUnitEvent, events, "UNIT_HEALTH", "pet")
pcall(events.RegisterUnitEvent, events, "UNIT_MAXHEALTH", "pet")
pcall(events.RegisterUnitEvent, events, "UNIT_COMBAT", "pet")
pcall(events.RegisterUnitEvent, events, "UNIT_PET", "player")
for _, event in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
                         "PLAYER_ENTERING_WORLD" }) do
  events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event, _, a, b, c4)
  if event == "UNIT_COMBAT" then
    on_hit(a, b, c4)
    return
  end
  if event == "UNIT_PET" or event == "PLAYER_ENTERING_WORLD" then
    set_portraits()
  end
  update()
end)
