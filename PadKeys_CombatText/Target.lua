-- Your hits on your target, as a small scroll beside the right end of its
-- nameplate's health bar (Config.lua, combattext.target).
--
-- UNIT_COMBAT gives each hit on the target: the kind (WOUND, MISS, ...),
-- a flag (CRITICAL, GLANCING, ...), the school and the amount, which is
-- secret in combat. It doesn't say who hit or with what, and the combat
-- log is closed to addons. So the icon is a guess: your last cast, if it
-- ended within link_window seconds before the hit, is taken to be that
-- hit. A hit without one is a melee swing (your weapon's icon) when it is
-- physical, else a periodic tick or proc (no icon).
--
-- Colours: crits red, your casts and non-physical hits yellow, swings and
-- auto shots white.

local ns = PadKeys
local c = ns.config.combattext
local t = c.target
if not (t and t.enabled) then
  return
end

local M = ns.combattext
local scroll = M.new_scroll(t, true)
local frame = scroll.frame

local PHYSICAL = 1
local MAIN_HAND = 16
-- Casts that are plain auto attacks: white, with their icon.
local AUTO = {
  [75] = true,    -- Auto Shot
  [5019] = true,  -- Shoot (wand)
  [2480] = true,  -- Shoot Bow
  [7918] = true,  -- Shoot Gun
  [7919] = true,  -- Shoot Crossbow
  [2764] = true,  -- Throw
}

-- --- Where it sits ---------------------------------------------------------

local function plate_bar()
  local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, "target")
  if not (ok and plate) then
    return nil
  end
  local unit_frame = plate.UnitFrame
  if unit_frame then
    local container = unit_frame.HealthBarsContainer
    return unit_frame.healthBar or (container and container.healthBar)
      or unit_frame
  end
  return plate
end

local function anchor()
  frame:ClearAllPoints()
  local bar = plate_bar()
  if bar then
    frame:SetPoint("LEFT", bar, "RIGHT", t.gap or 4, 0)
    frame:Show()
  elseif t.fallback and TargetFrame and TargetFrame:IsShown() then
    frame:SetPoint("LEFT", TargetFrame, "RIGHT", t.gap or 4, 0)
    frame:Show()
  else
    frame:Hide()
  end
end

-- --- Which cast a hit belongs to ------------------------------------------

local function spell_texture(id)
  if C_Spell and C_Spell.GetSpellTexture then
    return C_Spell.GetSpellTexture(id)
  end
  return GetSpellTexture and GetSpellTexture(id)
end

-- false only when the game says a spell is not harmful (heals, buffs);
-- a secret spell or a missing API counts as harmful.
local function harmful(id)
  if M.is_secret(id) then
    return true
  end
  local check = (C_Spell and C_Spell.IsSpellHarmful) or IsHarmfulSpell
  if not check then
    return true
  end
  local ok, result = pcall(check, id)
  return not ok or result ~= false
end

local last -- { texture, auto, time } of your last harmful cast

local function on_cast(spell_id)
  if not spell_id or not harmful(spell_id) then
    return
  end
  local ok, texture = pcall(spell_texture, spell_id)
  last = {
    texture = ok and texture or nil,
    auto = not M.is_secret(spell_id) and AUTO[spell_id] or false,
    time = GetTime(),
  }
end

-- The cast that this hit belongs to, used up by it.
local function take_cast()
  local cast = last
  if cast and GetTime() - cast.time <= (t.link_window or 1.5) then
    last = nil
    return cast
  end
end

-- --- Hits --------------------------------------------------------------------

local function zero(amount)
  return not M.is_secret(amount) and amount == 0
end

local function on_hit(event, flags, amount, school)
  local word
  if event == "WOUND" then
    -- A hit fully absorbed, blocked or resisted shows the word; in combat
    -- the amount is secret, so it shows as 0.
    if M.MISS_WORDS[flags] and zero(amount) then
      word = M.MISS_WORDS[flags]
    end
  elseif M.MISS_WORDS[event] then
    word = M.MISS_WORDS[event]
  else
    return -- heals, energize and the rest
  end
  if word and not t.show_misses then
    return
  end

  local cast = take_cast()
  if not cast and IsInGroup() and t.group_only_linked then
    return
  end

  local kind, texture
  if cast then
    texture = cast.texture
    kind = cast.auto and "normal" or "special"
  elseif school == PHYSICAL then
    texture = GetInventoryItemTexture("player", MAIN_HAND)
    kind = "normal"
  else
    kind = "special"
  end
  if flags == "CRITICAL" or flags == "CRUSHING" then
    kind = "crit"
  end
  scroll:add(word or M.amount_text(amount), word and "normal" or kind, texture)
end

-- --- Events ---------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterUnitEvent("UNIT_COMBAT", "target")
events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
events:SetScript("OnEvent", function(_, event, _, a, b, c4, d)
  if event == "UNIT_COMBAT" then
    on_hit(a, b, c4, d)
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    on_cast(b)
  elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
    scroll:clear()
    last = nil
    anchor()
  else
    -- A nameplate came or went, maybe the target's: follow it once it
    -- has. (Comparing nameplate units with the target can be secret.)
    C_Timer.After(0, anchor)
  end
end)
