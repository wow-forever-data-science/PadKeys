-- A ring around the mouse pointer (Config.lua, readout.ring), empty most
-- of the time:
-- - your cast or channel fills it, blue;
-- - yellow and glowing instead when the cast lands while one of your
--   listed buffs (ring.buffs) is still on you;
-- - out of a cast, the global cooldown fills it faintly, in combat;
-- - a hit you take flashes it red for a moment: bright on a crit, a
--   crushing blow or a burst of hits, and otherwise as bright as your
--   health is low (nothing at full health).
--
-- The fill is a Cooldown frame whose swipe texture is a ring
-- (Media/Ring.tga, made by tools/make_ring.py), so the client draws it
-- from Blizzard's duration objects (UnitCastingDuration,
-- C_Spell.GetSpellCooldownDuration): times are secret in combat and
-- nothing here reads them.
--
-- Blue or yellow: whether the buff outlasts the cast is decided once as
-- the cast starts (again if it is pushed back). The cast's end time is
-- plain for your own casts; the buff's may be secret in combat. Then the
-- comparison goes to the client: a step curve at the cast's time left
-- (plain) is evaluated against the buff's duration object
-- (EvaluateRemainingDuration), and the secret result goes only to the
-- yellow and blue layers' SetAlpha. Anything refused (pcall) leaves the
-- ring blue.
--
-- The red flash's brightness by health is the same trick:
-- UnitHealthPercent through a curve, straight into SetAlpha. The amount of
-- a hit is secret and never read; crits, crushing blows and how many hits
-- came in a short time are plain.

local ns = PadKeys
local c = ns.config.readout
local r = c.ring
local readout = PadKeysReadout
if not (r and r.enabled and readout) then
  return
end

local MEDIA = "Interface\\AddOns\\PadKeys_Readout\\Media\\"
local RING, GLOW = MEDIA .. "Ring", MEDIA .. "RingGlow"
local GCD_SPELL = 61304
local size = r.size or 56

local function is_secret(v)
  return issecretvalue and issecretvalue(v)
end

local function present(v)
  if is_secret(v) then
    return true
  end
  return v ~= nil
end

local function in_combat()
  return InCombatLockdown() or UnitAffectingCombat("player")
end

local function rgb(t)
  return t[1], t[2], t[3]
end

local frame = CreateFrame("Frame", "PadKeysReadoutRing", readout)
frame:SetSize(size, size)
frame:SetPoint("CENTER")
frame:EnableMouse(false)

-- The grey track the fill runs along, while anything fills.
local track = frame:CreateTexture(nil, "BACKGROUND")
track:SetAllPoints()
track:SetTexture(RING)
track:SetVertexColor(0.5, 0.5, 0.5, r.track_alpha or 0.25)
track:Hide()

-- A layer: a frame (its alpha may be secret) holding a ring-swipe
-- Cooldown in one colour, and optionally a pulsing glow behind it.
local function make_fill(color, alpha, glow)
  local layer = CreateFrame("Frame", nil, frame)
  layer:SetAllPoints()
  local cd = CreateFrame("Cooldown", nil, layer, "CooldownFrameTemplate")
  cd:SetAllPoints()
  cd:SetDrawEdge(false)
  cd:SetDrawBling(false)
  cd:SetHideCountdownNumbers(true)
  -- Reverse: the coloured part is the time gone, so it fills up.
  cd:SetReverse(r.fill ~= false)
  pcall(cd.SetSwipeTexture, cd, RING)
  pcall(cd.SetUseCircularEdge, cd, true)
  local cr, cg, cb = rgb(color)
  cd:SetSwipeColor(cr, cg, cb, alpha)
  layer.cd = cd
  if glow then
    local tex = layer:CreateTexture(nil, "BACKGROUND", nil, 1)
    tex:SetPoint("CENTER")
    tex:SetSize(size * 1.35, size * 1.35)
    tex:SetTexture(GLOW)
    tex:SetBlendMode("ADD")
    tex:SetVertexColor(cr, cg, cb, 1)
    local pulse = tex:CreateAnimationGroup()
    pulse:SetLooping("BOUNCE")
    local a = pulse:CreateAnimation("Alpha")
    a:SetFromAlpha(0.25)
    a:SetToAlpha(0.9)
    a:SetDuration(r.glow_pulse or 0.45)
    a:SetSmoothing("IN_OUT")
    pulse:Play()
    -- Ends with the cast, though the layer's alpha says yellow.
    cd:HookScript("OnCooldownDone", function()
      tex:Hide()
    end)
    layer.glow = tex
  end
  layer:Hide()
  return layer
end

local gcd = make_fill(r.gcd_color or { 1, 1, 1 }, r.gcd_alpha or 0.35)
local blue = make_fill(r.cast_color or { 0.25, 0.6, 1 }, 1)
local yellow = make_fill(r.buffed_color or { 1, 0.85, 0.2 }, 1, true)

local function set_duration(layer, get, ...)
  local ok = pcall(function(...)
    layer.cd:SetCooldownFromDurationObject(get(...))
  end, ...)
  if not ok then
    layer.cd:Clear()
  end
  return ok
end

-- --- Blue or yellow ---------------------------------------------------------

-- Step curves over seconds left: 1 from `t` on (the buff outlasts the
-- cast), 0 below; and the opposite.
local function step_curve(t, below, above)
  local ok, curve = pcall(function()
    local cv = C_CurveUtil.CreateCurve()
    local e = 0.01
    cv:AddPoint(0, below)
    cv:AddPoint(math.max(t - e, 0), below)
    cv:AddPoint(t, above)
    cv:AddPoint(86400, above)
    return cv
  end)
  return ok and curve or nil
end

-- Your cast's or channel's end, in GetTime() seconds; nil when secret.
local function cast_end()
  local ok, value = pcall(function()
    local name, _, _, _, end_ms = UnitCastingInfo("player")
    if not present(name) then
      name, _, _, _, end_ms = UnitChannelInfo("player")
    end
    if not present(name) or is_secret(end_ms) or not end_ms then
      return nil
    end
    return end_ms / 1000
  end)
  return ok and value or nil
end

-- Returns yellow's and blue's alpha, plain or secret.
local function decide()
  local buffs = r.buffs
  if not (buffs and buffs[1] and C_UnitAuras) then
    return 0, 1
  end
  local ends = cast_end()
  if not ends then
    return 0, 1
  end
  local left = ends - GetTime()
  for _, id in ipairs(buffs) do
    local ok, y, b = pcall(function()
      local aura = C_UnitAuras.GetPlayerAuraBySpellID(id)
      if not present(aura) then
        return nil
      end
      local expires = aura.expirationTime
      if not is_secret(expires) then
        -- 0: no end at all.
        if expires == 0 or expires >= ends then
          return 1, 0
        end
        return nil
      end
      local duration = C_UnitAuras.GetAuraDuration("player",
                                                   aura.auraInstanceID)
      local on = step_curve(left, 0, 1)
      local off = step_curve(left, 1, 0)
      return duration:EvaluateRemainingDuration(on),
             duration:EvaluateRemainingDuration(off)
    end)
    -- y is maybe secret: only nil is tested, which a secret never is.
    if ok and y ~= nil then
      return y, b
    end
  end
  return 0, 1
end

-- --- Driver -------------------------------------------------------------------

local casting = false

local function refresh_track()
  track:SetShown(gcd:IsShown() or blue:IsShown() or yellow:IsShown())
end

local function update_gcd()
  if casting or not r.gcd or (r.gcd_in_combat_only and not in_combat()) then
    gcd.cd:Clear()
    gcd:Hide()
  else
    gcd:SetShown(set_duration(gcd, C_Spell.GetSpellCooldownDuration,
                              GCD_SPELL))
  end
  refresh_track()
end

local function start_cast()
  casting = true
  local ok = false
  for _, layer in ipairs({ blue, yellow }) do
    ok = set_duration(layer, UnitCastingDuration, "player")
      or set_duration(layer, UnitChannelDuration, "player")
  end
  if ok then
    local y, b = decide()
    if not pcall(yellow.SetAlpha, yellow, y) then
      yellow:SetAlpha(0)
    end
    if not pcall(blue.SetAlpha, blue, b) then
      blue:SetAlpha(1)
    end
    if yellow.glow then
      yellow.glow:Show()
    end
  end
  blue:SetShown(ok)
  yellow:SetShown(ok)
  update_gcd()
end

local function stop_cast()
  casting = false
  for _, layer in ipairs({ blue, yellow }) do
    layer.cd:Clear()
    layer:Hide()
  end
  update_gcd()
end

-- A finished fill hides its layer, so the track goes with it.
for _, layer in ipairs({ gcd, blue, yellow }) do
  layer.cd:HookScript("OnCooldownDone", function()
    layer:Hide()
    refresh_track()
  end)
end

-- --- Red flash ------------------------------------------------------------------

local function make_flash()
  local holder = CreateFrame("Frame", nil, frame)
  holder:SetAllPoints()
  holder:SetFrameLevel(frame:GetFrameLevel() + 5)
  -- The flash itself: on at once, then fading. Its alpha is plain; the
  -- holder's (by health) may be secret, and they multiply.
  local body = CreateFrame("Frame", nil, holder)
  body:SetAllPoints()
  body:SetAlpha(0)
  local cr, cg, cb = rgb(r.hit_color or { 1, 0.1, 0.1 })
  local ring = body:CreateTexture(nil, "OVERLAY")
  ring:SetAllPoints()
  ring:SetTexture(RING)
  ring:SetVertexColor(cr, cg, cb, 1)
  local glow = body:CreateTexture(nil, "ARTWORK")
  glow:SetPoint("CENTER")
  glow:SetSize(size * 1.35, size * 1.35)
  glow:SetTexture(GLOW)
  glow:SetBlendMode("ADD")
  glow:SetVertexColor(cr, cg, cb, 1)
  local anim = body:CreateAnimationGroup()
  local fade = anim:CreateAnimation("Alpha")
  fade:SetFromAlpha(1)
  fade:SetToAlpha(0)
  fade:SetDuration(r.hit_time or 0.35)
  fade:SetSmoothing("OUT")
  holder.flash = function()
    anim:Stop()
    anim:Play()
  end
  return holder
end

local strong = make_flash()     -- crits, crushing blows, bursts
local by_health = make_flash()  -- every other hit, as bright as health low

local health_curve
if C_CurveUtil and C_CurveUtil.CreateCurve and r.hit_by_health then
  local ok, cv = pcall(function()
    local cv = C_CurveUtil.CreateCurve()
    for _, p in ipairs(r.hit_by_health) do
      cv:AddPoint(p[1], p[2])
    end
    return cv
  end)
  health_curve = ok and cv or nil
end

local function update_health_alpha()
  if health_curve and UnitHealthPercent then
    local ok, alpha = pcall(UnitHealthPercent, "player", true, health_curve)
    if ok and pcall(by_health.SetAlpha, by_health, alpha) then
      return
    end
  end
  by_health:SetAlpha(0) -- without the curve, only strong hits flash
end

local hits = {}
local last_flash = 0

local function on_hit(action, flags, amount)
  if action ~= "WOUND" or not r.hits then
    return
  end
  if not is_secret(amount) and amount == 0 then
    return -- fully absorbed, blocked or resisted
  end
  local now = GetTime()
  -- This hit, and those still inside the burst window.
  local window = r.burst_window or 1.5
  local kept = { now }
  for _, t in ipairs(hits) do
    if now - t <= window then
      kept[#kept + 1] = t
    end
  end
  hits = kept
  if now - last_flash < (r.hit_min_gap or 0.12) then
    return
  end
  last_flash = now
  if flags == "CRITICAL" or flags == "CRUSHING"
      or #hits >= (r.burst_hits or 4) then
    strong.flash()
  else
    update_health_alpha()
    by_health.flash()
  end
end

-- --- Events -------------------------------------------------------------------

local CAST_START = {
  UNIT_SPELLCAST_START = true, UNIT_SPELLCAST_CHANNEL_START = true,
  UNIT_SPELLCAST_DELAYED = true, UNIT_SPELLCAST_CHANNEL_UPDATE = true,
}

local events = CreateFrame("Frame")
for _, event in ipairs({
  "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED",
  "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_DELAYED",
  "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE",
  "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_COMBAT",
}) do
  pcall(events.RegisterUnitEvent, events, event, "player")
end
for _, event in ipairs({
  "SPELL_UPDATE_COOLDOWN", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
  "PLAYER_ENTERING_WORLD",
}) do
  pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event, _, a, b, c4)
  if event == "UNIT_COMBAT" then
    on_hit(a, b, c4)
  elseif event == "PLAYER_ENTERING_WORLD" then
    stop_cast()
  elseif CAST_START[event] then
    start_cast()
  elseif event:find("^UNIT_SPELLCAST") then
    stop_cast()
  else
    update_gcd()
  end
end)
