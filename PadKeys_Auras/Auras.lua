-- Your target's auras, the ones its nameplate shows, in combat too
-- (Config.lua):
--
-- * A label above the target's nameplate highlights one aura: its name
--   and place ("Debuff 2/5"). A new target highlights its first aura.
-- * C highlights the next one: debuffs first, then buffs, wrapping around.
-- * Holding Shift+C shows the highlighted aura's tooltip (Blizzard's own,
--   GameTooltip:SetUnitAura); letting go fades it out over a second.
--
-- In combat auras are secret to addons, so nothing here reads them. A
-- hidden tooltip of our own is filled with each aura instead: it has lines
-- when there is an aura at that place, and none past the last one. The
-- name comes from the same tooltip; where the client keeps it secret the
-- label shows only the place.
--
-- The nameplate's own choice of auras reads aura fields addons can't
-- compare in combat, so the lists are Blizzard's aura filters that come
-- closest (Config.lua). Without a nameplate (off screen, or nameplates
-- off) the label sits under the target frame. The keys click a plain
-- button: nothing here is secure.

local ns = PadKeys
local c = ns.config.auras

BINDING_HEADER_PADKEYS_AURAS = "PadKeys: auras"
_G["BINDING_NAME_CLICK PadKeysAura:next"] = "Highlight target's next aura"
_G["BINDING_NAME_CLICK PadKeysAura:tooltip"] = "Show highlighted aura (hold)"

local UNIT = "target"
local MAX_AURAS = 40

-- The highlighted aura: a list from c.lists and a place in it.
local list, place

local scan = CreateFrame("GameTooltip", "PadKeysAuraScan", nil, "GameTooltipTemplate")

-- The aura's name if there is an aura at this place, else nil. The name
-- may be a secret value, which only a widget can show.
local function aura_at(filter, index)
  scan:SetOwner(WorldFrame, "ANCHOR_NONE")
  scan:ClearLines()
  local ok = pcall(scan.SetUnitAura, scan, UNIT, index, filter)
  if not (ok and scan:NumLines() > 0) then
    return nil
  end
  return PadKeysAuraScanTextLeft1:GetText() or ""
end

local function count(filter)
  local n = 0
  while n < MAX_AURAS and aura_at(filter, n + 1) do
    n = n + 1
  end
  return n
end

-- The first aura from list `from` on, wrapping around: list and place.
local function first_from(from)
  for step = 0, #c.lists - 1 do
    local i = (from + step - 1) % #c.lists + 1
    if aura_at(c.lists[i].filter, 1) then
      return i, 1
    end
  end
end

-- The label, above the nameplate or under the target frame.
local label = CreateFrame("Frame", "PadKeysAuraLabel", UIParent)
label:SetSize(1, 1)
label:SetFrameStrata("HIGH")
label:Hide()
local name_text = ns.text(label, c.label_size, "white")
name_text:SetPoint("BOTTOM", label, "CENTER")
local place_text = ns.text(label, c.label_size - 2, "light")
place_text:SetPoint("TOP", label, "CENTER", 0, -1)

local function anchor_label()
  label:ClearAllPoints()
  local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, UNIT)
  if ok and plate then
    label:SetPoint("BOTTOM", plate, "TOP", 0, c.label_gap + c.label_size)
  else
    label:SetPoint("TOP", TargetFrame, "BOTTOM", 0, -c.label_size)
  end
end

local function refresh_label()
  if not list then
    label:Hide()
    return
  end
  local entry = c.lists[list]
  local name = aura_at(entry.filter, place)
  -- A secret name can be shown but not checked or joined to other text.
  if not pcall(name_text.SetText, name_text, name) then
    name_text:SetText("")
  end
  place_text:SetText(format("%s %d/%d", entry.name, place, count(entry.filter)))
  anchor_label()
  label:Show()
end

-- Keep the highlighted aura while it lasts; else the first one.
local function update()
  if not UnitExists(UNIT) then
    list, place = nil, nil
  elseif not (list and aura_at(c.lists[list].filter, place)) then
    list, place = first_from(1)
  end
  refresh_label()
end

local function highlight_next()
  if not UnitExists(UNIT) then
    ns.flash("No target.")
    return
  end
  if list and aura_at(c.lists[list].filter, place + 1) then
    place = place + 1
  else
    list, place = first_from(list and list + 1 or 1)
  end
  if not list then
    ns.flash("Your target has no auras.")
  end
  refresh_label()
end

-- The tooltip: shown while the key is held, then faded by alpha. Its
-- owner is the label, so the fade only touches a tooltip it showed.
local fader = CreateFrame("Frame")
fader:Hide()
fader:SetScript("OnUpdate", function(self, elapsed)
  self.left = self.left - elapsed
  if GameTooltip:GetOwner() ~= label then
    self:Hide()
  elseif self.left <= 0 then
    self:Hide()
    GameTooltip:Hide()
    GameTooltip:SetAlpha(1)
  else
    GameTooltip:SetAlpha(self.left / c.fade_time)
  end
end)

local function show_tooltip()
  fader:Hide()
  if not list then
    ns.flash(UnitExists(UNIT) and "Your target has no auras." or "No target.")
    return
  end
  GameTooltip:SetOwner(label, "ANCHOR_NONE")
  GameTooltip:ClearAllPoints()
  GameTooltip:SetPoint("BOTTOM", name_text, "TOP", 0, 4)
  GameTooltip:SetAlpha(1)
  local ok = pcall(GameTooltip.SetUnitAura, GameTooltip, UNIT, place,
                   c.lists[list].filter)
  if ok and GameTooltip:NumLines() > 0 then
    GameTooltip:Show()
  else
    GameTooltip:Hide()
  end
end

local function fade_tooltip()
  if GameTooltip:GetOwner() == label and GameTooltip:IsShown() then
    fader.left = c.fade_time
    fader:Show()
  end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterUnitEvent("UNIT_AURA", UNIT)
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
events:SetScript("OnEvent", function(_, event, unit)
  if event == "PLAYER_TARGET_CHANGED" then
    list, place = nil, nil
    if GameTooltip:GetOwner() == label then
      GameTooltip:Hide()
    end
    update()
  elseif event == "UNIT_AURA" then
    update()
  elseif unit and UnitIsUnit(unit, UNIT) and label:IsShown() then
    -- The target's nameplate came or went: follow it once it has.
    C_Timer.After(0, anchor_label)
  end
end)

-- The click's button name is the action; Shift+C acts on press and release.
local button = CreateFrame("Button", "PadKeysAura", UIParent)
button:RegisterForClicks("AnyDown", "AnyUp")
button:SetScript("OnClick", function(_, action, down)
  if action == "next" and down then
    highlight_next()
  elseif action == "tooltip" then
    if down then
      show_tooltip()
    else
      fade_tooltip()
    end
  end
end)
