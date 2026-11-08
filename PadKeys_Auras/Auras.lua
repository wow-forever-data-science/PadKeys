-- Inspect auras with keys, in combat too (Config.lua):
--
-- * C highlights your target's first aura (close to what its nameplate
--   shows: debuffs, then buffs); each press after that highlights the
--   next, wrapping around. A label above the nameplate names it and its
--   place ("Debuff 2/5"), and its tooltip shows (tooltip_on_step).
-- * Ctrl+C does the same for your own debuffs; the highlighted one is
--   framed on its icon, with the label under it.
-- * Holding Shift+C shows the highlighted aura's tooltip (Blizzard's own,
--   GameTooltip:SetUnitAura).
-- * The highlight stays a few seconds after the last press, and the
--   tooltip a moment after Shift+C is let go; then both fade. A press
--   after the highlight has faded starts at the first aura again.
--
-- In combat auras are secret to addons, so nothing here reads them. A
-- hidden tooltip of our own is filled with each aura instead: it has lines
-- when there is an aura at that place, and none past the last one. The
-- name comes from the same tooltip; where the client keeps it secret the
-- label shows only the place.
--
-- The nameplate's own choice of auras reads aura fields addons can't
-- compare in combat, so the target's lists are Blizzard's aura filters
-- that come closest. Without a nameplate (off screen, or nameplates off)
-- the label sits under the target frame. The target's aura icons are
-- forbidden frames, so only your own icons get the frame. The keys click a
-- plain button: nothing here is secure.

local ns = PadKeys
local c = ns.config.auras

BINDING_HEADER_PADKEYS_AURAS = "PadKeys: auras"
_G["BINDING_NAME_CLICK PadKeysAura:target"] = "Highlight target's next aura"
_G["BINDING_NAME_CLICK PadKeysAura:mine"] = "Highlight your next debuff"
_G["BINDING_NAME_CLICK PadKeysAura:tooltip"] = "Show highlighted aura (hold)"

-- The click's button name is the group.
local GROUPS = {
  target = { unit = "target", lists = c.target_lists },
  mine = { unit = "player", lists = c.my_lists, icons = "DebuffFrame" },
}

local MAX_AURAS = 40

-- The highlight: its group, a list of that group and a place in it.
local group, list, place

local scan = CreateFrame("GameTooltip", "PadKeysAuraScan", nil, "GameTooltipTemplate")

-- The aura's name if there is an aura at this place, else nil. The name
-- may be a secret value, which only a widget can show.
local function aura_at(unit, filter, index)
  scan:SetOwner(WorldFrame, "ANCHOR_NONE")
  scan:ClearLines()
  local ok = pcall(scan.SetUnitAura, scan, unit, index, filter)
  if not (ok and scan:NumLines() > 0) then
    return nil
  end
  return PadKeysAuraScanTextLeft1:GetText() or ""
end

local function count(unit, filter)
  local n = 0
  while n < MAX_AURAS and aura_at(unit, filter, n + 1) do
    n = n + 1
  end
  return n
end

-- The first aura of g from list `from` on, wrapping around: list, place.
local function first_from(g, from)
  for step = 0, #g.lists - 1 do
    local i = (from + step - 1) % #g.lists + 1
    if aura_at(g.unit, g.lists[i].filter, 1) then
      return i, 1
    end
  end
end

-- Your aura's icon in BuffFrame / DebuffFrame (Blizzard's buttons keep
-- the aura index in buttonInfo.index), or nil.
local function find_icon(frame, index)
  for _, icon in ipairs(frame and frame.auraFrames or {}) do
    local info = icon.buttonInfo
    if icon:IsShown() and info and icon.auraType ~= "TempEnchant"
       and info.index == index then
      return icon
    end
  end
end

-- Everything shown hangs off `view`, so one alpha fades it all.
local view = CreateFrame("Frame", "PadKeysAuraView", UIParent)
view:SetAllPoints()
view:SetFrameStrata("HIGH")
view:Hide()

local label = CreateFrame("Frame", nil, view)
label:SetSize(1, 1)
local name_text = ns.text(label, c.label_size, "white")
name_text:SetPoint("BOTTOM", label, "CENTER")
local place_text = ns.text(label, c.label_size - 2, "light")
place_text:SetPoint("TOP", label, "CENTER", 0, -1)

-- The frame: four white edges just outside your aura's icon.
local marker = CreateFrame("Frame", nil, view)
local EDGE = 2
local function marker_edge(p1, r1, x1, y1, p2, r2, x2, y2)
  local tex = marker:CreateTexture(nil, "OVERLAY")
  tex:SetColorTexture(1, 1, 1)
  tex:SetPoint(p1, marker, r1, x1, y1)
  tex:SetPoint(p2, marker, r2, x2, y2)
end
marker_edge("BOTTOMLEFT", "TOPLEFT", -EDGE, 0, "TOPRIGHT", "TOPRIGHT", EDGE, EDGE)
marker_edge("TOPLEFT", "BOTTOMLEFT", -EDGE, 0, "BOTTOMRIGHT", "BOTTOMRIGHT", EDGE, -EDGE)
marker_edge("TOPRIGHT", "TOPLEFT", 0, 0, "BOTTOMLEFT", "BOTTOMLEFT", -EDGE, 0)
marker_edge("TOPLEFT", "TOPRIGHT", 0, 0, "BOTTOMRIGHT", "BOTTOMRIGHT", EDGE, 0)

-- Place the label (and the frame, for your own auras).
local function anchor()
  label:ClearAllPoints()
  marker:Hide()
  local g = GROUPS[group]
  if g.icons then
    local found, icon = pcall(find_icon, _G[g.icons], place)
    if found and icon then
      marker:ClearAllPoints()
      marker:SetAllPoints(icon.Icon or icon)
      marker:Show()
      label:SetPoint("TOP", icon, "BOTTOM", 0, -c.label_size)
    else
      label:SetPoint("TOP", _G[g.icons] or UIParent, "BOTTOM", 0, -c.label_size)
    end
    return
  end
  local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, g.unit)
  if ok and plate then
    label:SetPoint("BOTTOM", plate, "TOP", 0, c.label_gap + c.label_size)
  else
    label:SetPoint("TOP", TargetFrame, "BOTTOM", 0, -c.label_size)
  end
end

local function refresh()
  if not list then
    view:Hide()
    return
  end
  local g = GROUPS[group]
  local entry = g.lists[list]
  local name = aura_at(g.unit, entry.filter, place)
  -- A secret name can be shown but not checked or joined to other text.
  if not pcall(name_text.SetText, name_text, name) then
    name_text:SetText("")
  end
  place_text:SetText(format("%s %d/%d", entry.name, place,
                            count(g.unit, entry.filter)))
  anchor()
end

-- The view and tooltip stay `wait` seconds, then fade over fade_time.
-- The tooltip's owner is the label, so the fade only touches a tooltip
-- it showed.
local held = false
local fader = CreateFrame("Frame")
fader:Hide()

local function own_tooltip()
  return GameTooltip:GetOwner() == label and GameTooltip:IsShown()
end

local function set_alpha(alpha)
  view:SetAlpha(alpha)
  if own_tooltip() then
    GameTooltip:SetAlpha(alpha)
  end
end

local function close()
  fader:Hide()
  view:Hide()
  if own_tooltip() then
    GameTooltip:Hide()
  end
  GameTooltip:SetAlpha(1)
  group, list, place = nil, nil, nil
end

fader:SetScript("OnUpdate", function(self, elapsed)
  self.left = self.left - elapsed
  if self.left <= 0 then
    close()
  elseif self.left < c.fade_time then
    set_alpha(self.left / c.fade_time)
  end
end)

local function fade_after(wait)
  set_alpha(1)
  fader.left = wait + c.fade_time
  fader:Show()
end

-- The highlighted aura's tooltip, at the label.
local function fill_tooltip()
  local g = GROUPS[group]
  GameTooltip:SetOwner(label, "ANCHOR_NONE")
  GameTooltip:ClearAllPoints()
  if g.icons then
    GameTooltip:SetPoint("TOP", place_text, "BOTTOM", 0, -4)
  else
    GameTooltip:SetPoint("BOTTOM", name_text, "TOP", 0, 4)
  end
  GameTooltip:SetAlpha(1)
  local ok = pcall(GameTooltip.SetUnitAura, GameTooltip, g.unit, place,
                   g.lists[list].filter)
  if ok and GameTooltip:NumLines() > 0 then
    GameTooltip:Show()
  else
    GameTooltip:Hide()
  end
end

local function highlight(group_name)
  local g = GROUPS[group_name]
  if g.unit == "target" and not UnitExists("target") then
    close()
    ns.flash("No target.")
    return
  end
  if group == group_name and list and
     aura_at(g.unit, g.lists[list].filter, place + 1) then
    place = place + 1
  elseif group == group_name and list then
    list, place = first_from(g, list + 1)
  else
    group, list, place = group_name, first_from(g, 1)
  end
  if not list then
    close()
    ns.flash(g.unit == "target" and "Your target has no auras." or
             "You have no debuffs.")
    return
  end
  refresh()
  view:Show()
  if c.tooltip_on_step or held then
    fill_tooltip()
  end
  if not held then
    fade_after(c.show_for)
  end
end

local function show_tooltip()
  if not list then
    highlight("target")
    if not list then
      return
    end
  end
  held = true
  fader:Hide()
  view:Show()
  set_alpha(1)
  fill_tooltip()
end

local function release_tooltip()
  held = false
  if list then
    fade_after(c.linger)
  end
end

-- Keep the highlight on its place while an aura is there, else go back
-- to the first; a new target ends a target highlight.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterUnitEvent("UNIT_AURA", "target", "player")
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
events:SetScript("OnEvent", function(_, event, unit)
  if not list then
    return
  end
  local g = GROUPS[group]
  if event == "PLAYER_TARGET_CHANGED" then
    if g.unit == "target" then
      close()
    end
  elseif event == "UNIT_AURA" then
    if unit == g.unit then
      if not aura_at(g.unit, g.lists[list].filter, place) then
        list, place = first_from(g, 1)
      end
      if list then
        refresh()
        if own_tooltip() then
          local alpha = GameTooltip:GetAlpha()
          fill_tooltip()
          GameTooltip:SetAlpha(alpha)
        end
      else
        close()
      end
    end
  elseif g.unit == "target" and unit and UnitIsUnit(unit, "target") then
    -- The target's nameplate came or went: follow it once it has.
    C_Timer.After(0, function()
      if list then
        anchor()
      end
    end)
  end
end)

-- The click's button name is the action; Shift+C acts on press and release.
local button = CreateFrame("Button", "PadKeysAura", UIParent)
button:RegisterForClicks("AnyDown", "AnyUp")
button:SetScript("OnClick", function(_, action, down)
  if action == "tooltip" then
    if down then
      show_tooltip()
    else
      release_tooltip()
    end
  elseif GROUPS[action] and down then
    highlight(action)
  end
end)
