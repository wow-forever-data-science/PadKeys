-- The town page (Config.lua, radial.town): what G opens while you rest in
-- an inn or a city, out of a fight. Fixed entries, east then
-- counter-clockwise: your professions' windows, cast as spells, and
-- Blizzard windows from the main-menu list (Menu.lua). One ring: the
-- consumables stay off it (Ring.lua).
--
-- A segment is a list of spell names, best first: the first one you know
-- that no earlier segment took, so the two crafting segments get your two
-- crafting professions. { menu = "bags" } opens a main-menu entry. Which
-- spells you know is read out of combat (a secure button's attributes
-- can't change in combat) and again as you learn one.

local ns = PadKeys
local config = ns.config.radial
local town = config.town
local button = ns.ring_button
if not (town and button and ns.ring_add_page) then
  return
end

-- The spell's info if you know it, else nil.
local function known(name)
  local ok, info = pcall(C_Spell.GetSpellInfo, name)
  if not (ok and info and info.spellID) then
    return nil
  end
  local id = info.spellID
  local has = (IsPlayerSpell and IsPlayerSpell(id)) or
              (IsSpellKnown and IsSpellKnown(id))
  if (IsPlayerSpell or IsSpellKnown) and not has then
    return nil
  end
  return info
end

local picks = {}

local function resolve()
  wipe(picks)
  local used = {}
  for i = 1, ns.wheel_segments do
    local segment = town[i]
    local pick
    if type(segment) == "table" and segment.menu then
      if ns.menu_macro(segment.menu) then
        pick = { menu = segment.menu }
      end
    elseif type(segment) == "table" then
      for _, name in ipairs(segment) do
        local info = not used[name] and known(name)
        if info then
          used[name] = true
          pick = { spell = name, icon = info.iconID, label = info.name }
          break
        end
      end
    end
    picks[i] = pick
    local key = "town" .. i
    if pick and pick.spell then
      button:SetAttribute("*type-" .. key, "spell")
      button:SetAttribute("*spell-" .. key, pick.spell)
      button:SetAttribute("*macrotext-" .. key, nil)
    elseif pick then
      button:SetAttribute("*type-" .. key, "macro")
      button:SetAttribute("*macrotext-" .. key, ns.menu_macro(pick.menu))
      button:SetAttribute("*spell-" .. key, nil)
    else
      button:SetAttribute("*type-" .. key, nil)
    end
  end
end

ns.ring_add_page("town", "Town", function()
  local entries = {}
  for i, pick in pairs(picks) do
    if pick.spell then
      entries[i] = { icon = pick.icon, label = pick.label, enabled = true }
    else
      entries[i] = ns.menu_entry(pick.menu)
    end
  end
  return entries
end)

local pending = false
local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "SPELLS_CHANGED", "SKILL_LINES_CHANGED",
                         "PLAYER_REGEN_ENABLED" }) do
  pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_REGEN_ENABLED" and not pending then
    return
  end
  if InCombatLockdown() then
    pending = true
    return
  end
  pending = false
  resolve()
end)
