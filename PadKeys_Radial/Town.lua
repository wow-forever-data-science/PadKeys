-- The town page (Config.lua, radial.town): what G opens while you rest in
-- an inn or a city, out of a fight. Fixed entries, east then
-- counter-clockwise, for town errands: Consumabuddy, the minimap's town
-- tracking (repair, trainers, vendors...) in one segment, Blizzard's
-- windows for what you do in town (Dungeon Finder, PvP, guild...), and
-- if you like your professions' windows. One ring: the
-- consumables stay off it (Ring.lua).
--
-- A segment is one of:
-- - { track_all = { "Repair", "Mailbox", ... } }: all of these minimap
--   trackings at once: on if any is off, else all off (names as the
--   minimap's tracking menu shows them, in your client's language; the
--   ones it doesn't offer are skipped). Grey while all are off.
-- - { track = { "Repair" } }: one tracking on or off (the first name the
--   minimap offers). Off shows the icon grey.
-- - { macro = "/cbuddy", label = ..., icon = ..., addon = "Consumabuddy" }:
--   runs the macro; left out while that addon isn't loaded.
-- - { menu = "bags" }: a main-menu entry (Menu.lua).
-- - a list of spell names, best first: the first you know that no earlier
--   segment took (professions: cast to open the window).
-- What exists is read out of combat (a secure button's attributes can't
-- change in combat) and again as spells, skills or tracking change.

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

-- Every minimap tracking entry with one of these names: { index, info }.
local function find_all_tracking(names)
  local found = {}
  if not (C_Minimap and C_Minimap.GetNumTrackingTypes) then
    return found
  end
  local wanted = {}
  for _, name in ipairs(names) do
    wanted[name] = true
  end
  pcall(function()
    for i = 1, C_Minimap.GetNumTrackingTypes() do
      local info = C_Minimap.GetTrackingInfo(i)
      if info and wanted[info.name] then
        found[#found + 1] = { index = i, info = info }
      end
    end
  end)
  return found
end

-- The minimap tracking entry with one of these names: its index and info.
local function find_tracking(names)
  if not (C_Minimap and C_Minimap.GetNumTrackingTypes) then
    return nil
  end
  local ok, index, found = pcall(function()
    for _, name in ipairs(names) do
      for i = 1, C_Minimap.GetNumTrackingTypes() do
        local info = C_Minimap.GetTrackingInfo(i)
        if info and info.name == name then
          return i, info
        end
      end
    end
  end)
  if ok and index then
    return index, found
  end
  return nil
end

local function addon_loaded(name)
  if C_AddOns and C_AddOns.IsAddOnLoaded then
    return C_AddOns.IsAddOnLoaded(name)
  end
  return IsAddOnLoaded and IsAddOnLoaded(name)
end

-- One plain button per segment for tracking: the ring's secure button
-- /clicks it. Tracking isn't protected, and no Blizzard window opens.
local trackers = {}
local function tracker(i)
  if not trackers[i] then
    local b = CreateFrame("Button", "PadKeysTownTrack" .. i, UIParent)
    b:SetScript("OnClick", function(self)
      if self.all then
        local found = find_all_tracking(self.names or {})
        local any_off = false
        for _, t in ipairs(found) do
          any_off = any_off or not t.info.active
        end
        for _, t in ipairs(found) do
          C_Minimap.SetTracking(t.index, any_off)
        end
        return
      end
      local index, info = find_tracking(self.names or {})
      if index then
        C_Minimap.SetTracking(index, not info.active)
      end
    end)
    trackers[i] = b
  end
  return trackers[i]
end

local picks = {}

local function set_segment(i, kind, value)
  local key = "town" .. i
  button:SetAttribute("*type-" .. key, kind)
  button:SetAttribute("*spell-" .. key, kind == "spell" and value or nil)
  button:SetAttribute("*macrotext-" .. key, kind == "macro" and value or nil)
end

local function resolve()
  wipe(picks)
  local used = {}
  for i = 1, ns.wheel_segments do
    local segment = town[i]
    local pick
    if type(segment) ~= "table" then
      pick = nil
    elseif segment.track_all then
      if #find_all_tracking(segment.track_all) > 0 then
        local t = tracker(i)
        t.names, t.all = segment.track_all, true
        pick = { track_all = segment.track_all, label = segment.label,
                 icon = segment.icon }
        set_segment(i, "macro", "/click PadKeysTownTrack" .. i)
      end
    elseif segment.track then
      if find_tracking(segment.track) then
        tracker(i).names = segment.track
        pick = { track = segment.track }
        set_segment(i, "macro", "/click PadKeysTownTrack" .. i)
      end
    elseif segment.macro then
      if not segment.addon or addon_loaded(segment.addon) then
        pick = { label = segment.label, icon = segment.icon }
        set_segment(i, "macro", segment.macro)
      end
    elseif segment.menu then
      if ns.menu_macro(segment.menu) then
        pick = { menu = segment.menu }
        set_segment(i, "macro", ns.menu_macro(segment.menu))
      end
    else
      for _, name in ipairs(segment) do
        local info = not used[name] and known(name)
        if info then
          used[name] = true
          pick = { icon = info.iconID, label = info.name }
          set_segment(i, "spell", name)
          break
        end
      end
    end
    picks[i] = pick
    if not pick then
      set_segment(i, nil)
    end
  end
end

ns.ring_add_page("town", "Town", function()
  local entries = {}
  for i, pick in pairs(picks) do
    if pick.track_all then
      local found = find_all_tracking(pick.track_all)
      local on = 0
      for _, t in ipairs(found) do
        if t.info.active then
          on = on + 1
        end
      end
      entries[i] = { icon = pick.icon or (found[1] and found[1].info.texture),
                     label = format("%s (%d/%d on)", pick.label or "Town tracking", on, #found),
                     enabled = true, desaturate = on == 0 }
    elseif pick.track then
      local _, info = find_tracking(pick.track)
      if info then
        entries[i] = { icon = info.texture, label = info.name, enabled = true,
                       desaturate = not info.active }
      end
    elseif pick.menu then
      entries[i] = ns.menu_entry(pick.menu)
    else
      entries[i] = { icon = pick.icon, label = pick.label, enabled = true }
    end
  end
  return entries
end)

local pending = false
local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "SPELLS_CHANGED", "SKILL_LINES_CHANGED",
                         "MINIMAP_UPDATE_TRACKING", "PLAYER_REGEN_ENABLED" }) do
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
