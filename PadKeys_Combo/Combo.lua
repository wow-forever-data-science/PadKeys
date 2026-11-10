-- Combo points as a row of pips in the PadKeys look: black boxes that fill
-- white, one per point on your target. For rogues, and druids while in
-- Cat Form (any form that uses energy). It shows in combat and while you
-- have points (Config.lua).
--
-- Blizzard's combo points (ComboFrame, around the target's portrait) are
-- moved into a hidden frame of ours with hide_blizzard. That frame isn't
-- secure, so moving it is allowed in combat too.
--
-- GetComboPoints may be a secret value where the client restricts unit
-- power. Addon code can't compare a secret, so then the pips stay empty
-- and the count shows as a number instead (a font string takes a secret).
-- Nothing here is secure.

local ns = PadKeys
local c = ns.config.combo

local _, class = UnitClass("player")
if class ~= "ROGUE" and class ~= "DRUID" then
  return
end

local MAX_PIPS = 5
local COMBO = Enum and Enum.PowerType and Enum.PowerType.ComboPoints or 4
local ENERGY = Enum and Enum.PowerType and Enum.PowerType.Energy or 3

local function is_secret(v)
  return issecretvalue and issecretvalue(v)
end

local row = CreateFrame("Frame", "PadKeysCombo", UIParent)
row:SetScale(c.scale or 1)
row:SetPoint(c.point, UIParent, c.point, c.x, c.y)
row:SetSize(MAX_PIPS * c.size + (MAX_PIPS - 1) * c.spacing, c.height)
row:EnableMouse(false)

local pips = {}
for i = 1, MAX_PIPS do
  local pip = CreateFrame("Frame", nil, row)
  pip:SetSize(c.size, c.height)
  ns.box(pip, c.background_alpha, c.rounded)
  pip.fill = pip:CreateTexture(nil, "ARTWORK")
  pip.fill:SetPoint("TOPLEFT", 1, -1)
  pip.fill:SetPoint("BOTTOMRIGHT", -1, 1)
  pip.fill:SetColorTexture(1, 1, 1)
  if c.rounded then
    ns.round(pip, pip.fill, 1)
  end
  pip.fill:Hide()
  pips[i] = pip
end

local number = ns.text(row, c.number_size, "white", "OVERLAY", "GameFontHighlight")
number:SetPoint("CENTER")

-- Pips laid out for `count` points, centred on the row.
local shown_max
local function layout(count)
  if count == shown_max then
    return
  end
  shown_max = count
  local width = count * c.size + (count - 1) * c.spacing
  for i, pip in ipairs(pips) do
    pip:ClearAllPoints()
    pip:SetPoint("LEFT", row, "CENTER",
                 -width / 2 + (i - 1) * (c.size + c.spacing), 0)
    pip:SetShown(i <= count)
  end
end

local function max_points()
  local n = UnitPowerMax("player", COMBO)
  if is_secret(n) or type(n) ~= "number" or n < 1 then
    return MAX_PIPS
  end
  return math.min(n, MAX_PIPS)
end

local in_combat = InCombatLockdown()

local function uses_points()
  if class == "ROGUE" then
    return true
  end
  return UnitPowerType("player") == ENERGY -- Cat Form
end

local function update()
  if not uses_points() then
    row:Hide()
    return
  end
  layout(max_points())

  local points = GetComboPoints("player", "target")
  local have
  if is_secret(points) then
    for _, pip in ipairs(pips) do
      pip.fill:Hide()
    end
    number:SetText(points)
    have = true
  else
    points = points or 0
    for i, pip in ipairs(pips) do
      pip.fill:SetShown(i <= points)
    end
    number:SetText("")
    have = points > 0
  end
  row:SetShown(c.always or in_combat or have)
end

if c.hide_blizzard and ComboFrame then
  local hidden = CreateFrame("Frame")
  hidden:Hide()
  ComboFrame:SetParent(hidden)
end

row:RegisterEvent("PLAYER_ENTERING_WORLD")
row:RegisterEvent("PLAYER_TARGET_CHANGED")
row:RegisterEvent("PLAYER_REGEN_DISABLED")
row:RegisterEvent("PLAYER_REGEN_ENABLED")
row:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
row:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
row:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
row:RegisterUnitEvent("UNIT_MAXPOWER", "player")
row:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
-- Points moving to a new target keep their count, so no power event fires.
pcall(row.RegisterEvent, row, "COMBO_TARGET_CHANGED")
row:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_REGEN_DISABLED" then
    in_combat = true
  elseif event == "PLAYER_REGEN_ENABLED" then
    in_combat = false
  end
  update()
end)

update()
