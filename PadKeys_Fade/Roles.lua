-- Group frames by role (Config.lua, fade.roles): two Edit Mode layouts
-- that you make, one for healing and one for everything else (party and
-- raid frames bottom centre as a healer, at the left otherwise), and this
-- switches between them as your role changes. Edit Mode places the
-- frames, so nothing here moves a Blizzard frame.
--
-- It only switches while one of the two layouts is the active one: pick
-- one of them once in Edit Mode to opt in; any other layout is left
-- alone, and so is a layout you pick by hand until your role next
-- changes. Out of combat only (the layout re-anchors protected frames), and
-- never while Edit Mode is open.
--
-- The switch is C_EditMode.SetActiveLayout, the call Blizzard's own
-- layout dropdown makes; the client then sends EDIT_MODE_LAYOUTS_UPDATED
-- and Blizzard's own handler lays the frames out. Its index counts the
-- preset layouts (Modern, Classic) first, as Blizzard's list does.
--
-- Healer: the role you hold in the group (dungeon finder or the leader's
-- pick), else your talents: most points in Holy (priest, paladin),
-- Discipline (priest) or Restoration (druid, shaman).

local ns = PadKeys
local c = ns.config.fade and ns.config.fade.roles
if not (c and c.enabled and C_EditMode and C_EditMode.SetActiveLayout) then
  return
end

local HEAL_TREES = {
  PRIEST = { [1] = true, [2] = true },
  PALADIN = { [1] = true },
  DRUID = { [3] = true },
  SHAMAN = { [3] = true },
}
local _, class = UnitClass("player")

local function is_secret(v)
  return issecretvalue and issecretvalue(v)
end

-- Points spent in talent tab i, whichever form GetTalentTabInfo returns
-- (classic: name, icon, points; newer: id, name, description, icon,
-- points).
local function tab_points(i)
  local ok, a, _, b, _, d = pcall(GetTalentTabInfo, i)
  if not ok then
    return 0
  end
  local points = type(a) == "number" and d or b
  if type(points) ~= "number" or is_secret(points) then
    return 0
  end
  return points
end

local function healer_by_talents()
  local trees = HEAL_TREES[class]
  if not (trees and GetNumTalentTabs and GetTalentTabInfo) then
    return false
  end
  local best, best_points = nil, 0
  for i = 1, GetNumTalentTabs() do
    local points = tab_points(i)
    if points > best_points then
      best, best_points = i, points
    end
  end
  return best ~= nil and trees[best] == true
end

local function is_healer()
  if c.role == "healer" then
    return true
  elseif c.role == "other" then
    return false
  end
  local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned("player")
  if role == "HEALER" then
    return true
  elseif role == "TANK" or role == "DAMAGER" then
    return false
  end
  return healer_by_talents()
end

-- The Edit Mode index of the layout called `name`, or nil.
local function layout_index(layouts, name)
  local presets = Enum and Enum.EditModePresetLayoutsMeta and
                  Enum.EditModePresetLayoutsMeta.NumValues or 2
  for i, layout in ipairs(layouts.layouts or {}) do
    if layout.layoutName == name then
      return presets + i
    end
  end
  return nil
end

local function editing()
  return EditModeManagerFrame and EditModeManagerFrame.IsEditModeActive and
         EditModeManagerFrame:IsEditModeActive()
end

local pending = false

local function update()
  if InCombatLockdown() then
    pending = true
    return
  end
  pending = false
  if editing() then
    return
  end
  local ok, layouts = pcall(C_EditMode.GetLayouts)
  if not (ok and layouts) then
    return
  end
  local healer = layout_index(layouts, c.healer_layout)
  local other = layout_index(layouts, c.other_layout)
  local active = layouts.activeLayout
  if not (healer and other) or (active ~= healer and active ~= other) then
    return
  end
  local want = is_healer() and healer or other
  if want ~= active then
    C_EditMode.SetActiveLayout(want)
    if c.announce then
      ns.say(format("layout %s (%s).", want == healer and c.healer_layout or c.other_layout,
                    want == healer and "healer" or "not healing"))
    end
  end
end

-- Several of these come at once (talents, group, login): one check.
local queued = false
local function update_soon()
  if queued then
    return
  end
  queued = true
  C_Timer.After(1, function()
    queued = false
    update()
  end)
end

local events = CreateFrame("Frame")
for _, event in ipairs({
  "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "PLAYER_ROLES_ASSIGNED",
  "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE",
  "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_REGEN_ENABLED",
}) do
  pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_REGEN_ENABLED" and not pending then
    return
  end
  update_soon()
end)
