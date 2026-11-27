-- A buff you need that is missing, in combat, just above the pointer
-- (Config.lua, readout.missing): its icon with a red frame, e.g. Aspect
-- of the Hawk for a hunter. Out of combat the buff bar (PadKeys_Combat)
-- shows it, with a click to cast it.
--
-- Buffs are secret in combat and addon code can't read them, so which
-- buff of the group is on you is read out of combat, then followed
-- through combat by your own casts (UNIT_SPELLCAST_SUCCEEDED): casting
-- another aspect replaces the hawk. Death clears it. A buff cancelled in
-- combat is only seen as combat ends, as on PadKeys_Portrait. Nothing
-- here is secure, and nothing takes the mouse.

local ns = PadKeys
local c = ns.config.readout
local m = c.missing
local readout = PadKeysReadout
local _, class = UnitClass("player")
local need = m and m.enabled and m.buffs and m.buffs[class]
if not (need and readout) then
  return
end

local function is_secret(v)
  return issecretvalue and issecretvalue(v)
end

local function spell_name(id)
  if C_Spell and C_Spell.GetSpellName then
    return C_Spell.GetSpellName(id)
  end
  return GetSpellInfo and (GetSpellInfo(id))
end

local function spell_texture(id)
  if C_Spell and C_Spell.GetSpellTexture then
    return C_Spell.GetSpellTexture(id)
  end
  return GetSpellTexture and GetSpellTexture(id)
end

local function knows(id)
  if IsPlayerSpell and IsPlayerSpell(id) then
    return true
  end
  return IsSpellKnown and IsSpellKnown(id) or false
end

-- The group's names (every rank shares its name), filled once the client
-- has them.
local names = {}
local function group_names()
  if not next(names) then
    for _, id in ipairs(need.group or { need.spell }) do
      local name = spell_name(id)
      if name then
        names[name] = true
      end
    end
  end
  return names
end

local size = m.size or 29
local frame = CreateFrame("Frame", nil, readout)
frame:SetSize(size, size)
frame:SetPoint(m.point or "BOTTOM", readout, "CENTER", m.x or 0, m.y or 22)
frame:EnableMouse(false)
local edge = frame:CreateTexture(nil, "BACKGROUND")
edge:SetPoint("TOPLEFT", -2, 2)
edge:SetPoint("BOTTOMRIGHT", 2, -2)
edge:SetColorTexture(0.9, 0.1, 0.1, 1)
if c.rounded then
  ns.round(frame, edge, -2)
end
local icon = frame:CreateTexture(nil, "ARTWORK")
ns.fit_icon(frame, icon)
if c.rounded then
  ns.round(frame, icon, 1)
end
ns.icon(icon)
frame:Hide()

-- The group's buff on you: its name, false for none, nil not known yet.
local active

local function read_auras()
  if InCombatLockdown() then
    return
  end
  local group = group_names()
  local found = false
  local ok = pcall(function()
    for i = 1, 40 do
      local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
      if not aura then
        break
      end
      if group[aura.name] then
        found = aura.name
        return
      end
    end
  end)
  if ok then
    active = found
  end
end

local function in_combat()
  return InCombatLockdown() or UnitAffectingCombat("player")
end

local function update()
  local name = spell_name(need.spell)
  local on = in_combat() and knows(need.spell) and name and active ~= nil and
             active ~= name and not UnitIsDeadOrGhost("player")
  if on then
    icon:SetTexture(spell_texture(need.spell))
  end
  frame:SetShown(on and true or false)
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED",
                         "PLAYER_REGEN_ENABLED", "PLAYER_DEAD", "SPELLS_CHANGED" }) do
  events:RegisterEvent(event)
end
events:RegisterUnitEvent("UNIT_AURA", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
events:SetScript("OnEvent", function(_, event, _, _, spell_id)
  if event == "UNIT_SPELLCAST_SUCCEEDED" then
    -- A cast of one of the group makes it the one on you.
    local name = spell_id and not is_secret(spell_id) and spell_name(spell_id)
    if name and not is_secret(name) and group_names()[name] then
      active = name
    end
  elseif event == "PLAYER_DEAD" then
    active = false
  else
    read_auras()
  end
  update()
end)
