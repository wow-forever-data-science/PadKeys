-- Lit segments: a segment glows when its rule (Config.lua, `lights`) says
-- now is its moment: low health on the healing potion, the first seconds
-- of a pull on your opener, a proc. Both the wheel (Ring.lua) and its
-- faint copy at the mouse (Ghost.lua) show them.
--
-- Lighting only changes how a segment looks, never what it does, so it
-- works in combat: the action stays the one set out of combat.
--
-- Health and power are secret in combat and addon code may not compare
-- them. The health and mana rules give the comparison to the client: a
-- curve (C_CurveUtil.CreateCurve) maps the percent to an alpha, and
-- UnitHealthPercent / UnitPowerPercent evaluate it. The result may be
-- secret; it only ever goes to SetAlpha, which takes secret values. So a
-- health-lit segment can't make anything else show: it only glows where
-- it is drawn. The other rules are plain values (our own clock, Blizzard's
-- usable and glow flags) and can.

local ns = PadKeys
local config = ns.config.radial
local lights = config.lights or {}

local ab = C_ActionBar
local MANA = Enum and Enum.PowerType and Enum.PowerType.Mana or 0

local function is_secret(v)
  return issecretvalue and issecretvalue(v)
end

-- --- Curves -----------------------------------------------------------------

-- A step curve: `on` below the threshold, `off` above it. Whether the
-- client hands the percent over as 0-1 or 0-100, the same curve answers:
-- the 0-1 step is repeated at 0-100 (a reading under 1 on the 0-100 scale
-- means under 1% health, where on is right anyway).
local curves = {}
local function step_curve(threshold, on, off)
  local key = threshold .. ":" .. on .. ":" .. off
  if curves[key] == nil then
    local ok, curve = pcall(function()
      local c = C_CurveUtil.CreateCurve()
      local e = 0.0001
      c:AddPoint(0, on)
      c:AddPoint(threshold, on)
      c:AddPoint(threshold + e, off)
      c:AddPoint(1, off)
      c:AddPoint(1 + e, on)
      c:AddPoint(threshold * 100, on)
      c:AddPoint(threshold * 100 + e, off)
      c:AddPoint(100, off)
      return c
    end)
    curves[key] = ok and curve or false
  end
  return curves[key] or nil
end

-- Health is read as it is (usePredicted false): a heal on its way
-- (Mend Pet) pushes the predicted percent over 100%, which the 0-100 half
-- of the curve would read as under 35% and light the slice.
local function percent_alpha(kind, threshold, on, off)
  local curve = step_curve(threshold, on, off)
  if not curve then
    return off
  end
  local ok, result
  if kind == "health" then
    ok, result = pcall(UnitHealthPercent, "player", false, curve)
  elseif kind == "pet" then
    if not UnitExists("pet") or UnitIsDead("pet") then
      return off
    end
    ok, result = pcall(UnitHealthPercent, "pet", false, curve)
  else
    -- No mana (a warrior, a rogue): never lit. The maximum is only read
    -- when the client hands it over as a plain number.
    local okm, max = pcall(UnitPowerMax, "player", MANA)
    if okm and max ~= nil and not is_secret(max) and max == 0 then
      return off
    end
    ok, result = pcall(UnitPowerPercent, "player", MANA, false, curve)
  end
  if not ok or result == nil then
    return off
  end
  return result
end

-- --- Plain state ------------------------------------------------------------

local combat_start
local target_casting = false
-- Boss abilities the encounter timeline highlights now, by event ID (never
-- secret).
local boss_soon = {}

local function in_combat()
  return InCombatLockdown() or UnitAffectingCombat("player")
end

local function enemy_target()
  return UnitExists("target") and UnitCanAttack("player", "target") and
         not UnitIsDead("target")
end

-- The pull: before combat with an enemy targeted, and its first seconds.
local function pulling(seconds)
  if in_combat() then
    return combat_start and GetTime() - combat_start < seconds or false
  end
  return enemy_target()
end

-- The Blizzard button that shows an action slot, for its proc glow.
local BARS = {
  "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
  "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button",
  "MultiBar6Button", "MultiBar7Button",
}
local button_for = {}
local function find_button(slot)
  local b = button_for[slot]
  if b and b.action == slot then
    return b
  end
  for _, prefix in ipairs(BARS) do
    for i = 1, 12 do
      b = _G[prefix .. i]
      if b and b.action == slot then
        button_for[slot] = b
        return b
      end
    end
  end
  return nil
end

-- A proc on that slot, as PadKeys_Bar reads it: LibButtonGlow's overlay
-- (SpellActivationOverlay) or Blizzard's own spell alert.
local function glowing(slot)
  local b = slot and find_button(slot)
  if not b then
    return false
  end
  local overlay = b.__LBGoverlay
  if overlay and not (overlay.animOut and overlay.animOut:IsPlaying()) then
    return true
  end
  local alerts = ActionButtonSpellAlertManager
  return alerts and alerts.HasAlert and alerts:HasAlert(b) and true or false
end

local function ready(slot)
  if not (slot and ab.HasAction(slot)) then
    return false
  end
  local usable = ab.IsUsableAction(slot)
  local cd = ab.GetActionCooldown(slot)
  return usable and not ns.cooling(cd, cd and cd.isOnGCD) and true or false
end

local function combo(points)
  local ok, n = pcall(GetComboPoints, "player", "target")
  if not ok or n == nil or is_secret(n) then
    return false
  end
  return n >= points
end

-- --- Rules ------------------------------------------------------------------

-- The rule for a segment: the page's lights ("main" as the page G opens
-- now), or for the items page the lights of the set showing now.
local function rule_for(page, index)
  page = ns.ring_page and ns.ring_page(page) or page
  local list = lights[page]
  if page == "items" and list then
    local set = SecureCmdOptionParse(config.items.pick or "") or ""
    list = list[set]
  end
  return list and list[index]
end

-- true / false for a plain rule; nil for a health or mana one.
local function plain(rule, page, index)
  if type(rule) == "string" then
    rule = { [rule] = true }
  end
  local slot = ns.ring_slot and ns.ring_slot(page, index)
  if rule.health or rule.mana or rule.pet then
    return nil
  elseif rule.pull then
    return pulling(rule.pull)
  elseif rule.proc then
    return glowing(slot)
  elseif rule.ready then
    return ready(slot)
  elseif rule.casting then
    return target_casting
  elseif rule.combo then
    return combo(rule.combo)
  elseif rule.boss then
    return next(boss_soon) ~= nil
  end
  return false
end

-- The alpha for segment `index` of `page`: `on` when lit, else `off`. A
-- health or mana rule gives a value that may be secret (for SetAlpha only).
function ns.light_alpha(page, index, off, on)
  local rule = rule_for(page, index)
  if not rule then
    return off
  end
  -- `hits`: also lit for a few seconds after heavy damage, as the
  -- readouts at the mouse see it (PadKeys_CombatText for you,
  -- PadKeys_Readout for your pet). Plain times, so no secret is touched.
  local now = GetTime()
  -- A pet rule with a health rule beside it: the pet's health while you
  -- have a pet, your own without one, so the slot serves every class.
  if type(rule) == "table" and rule.pet and
     (not rule.health or UnitExists("pet")) then
    if rule.hits ~= false and (ns.pet_hit_until or 0) > now then
      return on
    end
    return percent_alpha("pet", rule.pet, on, off)
  end
  if type(rule) == "table" and rule.health then
    if rule.hits and (ns.player_hit_until or 0) > now then
      return on
    end
    return percent_alpha("health", rule.health, on, off)
  elseif type(rule) == "table" and rule.mana then
    return percent_alpha("mana", rule.mana, on, off)
  end
  return plain(rule, page, index) and on or off
end

-- How a lit segment looks, from its rule: a frame colour ({ r, g, b })
-- and whether it pulses; nil for the plain white frame.
function ns.light_style(page, index)
  local rule = rule_for(page, index)
  if type(rule) == "table" then
    return rule.color, rule.pulse
  end
end

-- Whether a plain rule lights anything on `page` now (health and mana
-- rules can't be asked: their answer is secret).
function ns.page_lit(page)
  for i = 1, ns.wheel_segments do
    local rule = rule_for(page, i)
    if rule and plain(rule, page, i) then
      return true
    end
  end
  return false
end

-- --- Events -----------------------------------------------------------------

local CAST_START = { UNIT_SPELLCAST_START = true, UNIT_SPELLCAST_CHANNEL_START = true }
local events = CreateFrame("Frame")
for _, event in ipairs({
  "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_TARGET_CHANGED",
  "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_STOP",
  "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_INTERRUPTED",
  "UNIT_SPELLCAST_FAILED", "ENCOUNTER_TIMELINE_EVENT_HIGHLIGHT",
  "ENCOUNTER_TIMELINE_EVENT_REMOVED", "ENCOUNTER_END",
}) do
  pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event, unit)
  if event == "PLAYER_REGEN_DISABLED" then
    combat_start = GetTime()
  elseif event == "PLAYER_REGEN_ENABLED" then
    combat_start = nil
  elseif event == "PLAYER_TARGET_CHANGED" then
    target_casting = false
  elseif event == "ENCOUNTER_TIMELINE_EVENT_HIGHLIGHT" then
    boss_soon[unit] = true -- the payload is the event ID
  elseif event == "ENCOUNTER_TIMELINE_EVENT_REMOVED" then
    boss_soon[unit] = nil
  elseif event == "ENCOUNTER_END" then
    wipe(boss_soon)
  elseif unit == "target" then
    target_casting = CAST_START[event] or false
  end
end)
