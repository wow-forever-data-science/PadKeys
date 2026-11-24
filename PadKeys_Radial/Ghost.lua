-- A faint copy of the wheels that follows the mouse: each configured page
-- as a ring of small see-through icons around the cursor (Config.lua,
-- `ghost`; by default the G wheel inside, the V wheel outside). The G
-- ring sits exactly where the G wheel's icons will when you press G there,
-- so a glance tells you which way to flick. A lit segment (Lights.lua)
-- shows at full strength with a white frame; the rest stay faint.
--
-- It only draws: no mouse, nothing secure. It hides while you turn with
-- the mouse (the cursor is hidden then) and while a wheel is open.

local ns = PadKeys
local config = ns.config.radial
local c = config.ghost
if not (c and c.enabled) then
  return
end

local frame = CreateFrame("Frame", "PadKeysGhost", UIParent)
frame:SetFrameStrata("DIALOG")
frame:SetSize(1, 1)
frame:EnableMouse(false)
frame:SetAlpha(0)

-- rings[r] = { page = "actions", icons = { [i] = { holder, icon, frame } } }
local rings = {}

local function make_icon(radius_scale, index)
  local x, y, size = ns.wheel_icon_place(index)
  size = size * (c.icon_scale or 0.8)
  local holder = CreateFrame("Frame", nil, frame)
  holder:SetSize(size, size)
  holder:SetPoint("CENTER", frame, "CENTER", x * radius_scale, y * radius_scale)
  -- The white frame of a lit icon, behind it.
  local glow = holder:CreateTexture(nil, "BACKGROUND")
  glow:SetPoint("TOPLEFT", -2, 2)
  glow:SetPoint("BOTTOMRIGHT", 2, -2)
  glow:SetColorTexture(1, 1, 1, 1)
  glow:SetAlpha(0)
  if c.rounded ~= false then
    ns.round(holder, glow, -2)
  end
  local icon = holder:CreateTexture(nil, "ARTWORK")
  ns.fit_icon(holder, icon)
  if c.rounded ~= false then
    ns.round(holder, icon, 1)
  end
  ns.icon(icon)
  return { holder = holder, icon = icon, glow = glow }
end

for r, page in ipairs(c.rings or { "actions" }) do
  local ring = { page = page, icons = {} }
  local radius_scale = 1 + (r - 1) * ((c.spacing or 1.6) - 1)
  for i = 1, ns.wheel_segments do
    ring.icons[i] = make_icon(radius_scale, i)
  end
  rings[r] = ring
end

-- --- What to show -----------------------------------------------------------

local function in_combat()
  return InCombatLockdown() or UnitAffectingCombat("player")
end

local function any_lit()
  for _, ring in ipairs(rings) do
    if ns.page_lit and ns.page_lit(ring.page) then
      return true
    end
  end
  return false
end

-- "combat": in combat, and out of it while a slice is lit; "always"; "lit":
-- only while a slice is lit.
local function wanted()
  if IsMouselooking and IsMouselooking() then
    return false
  end
  if ns.ring_wheel and ns.ring_wheel:is_open() then
    return false
  end
  local mode = c.show or "combat"
  if mode == "always" then
    return true
  elseif mode == "combat" and in_combat() then
    return true
  end
  return any_lit()
end

local function update_icons()
  local idle = c.idle_alpha or 0.25
  for _, ring in ipairs(rings) do
    local entries = ns.ring_entries and ns.ring_entries(ring.page) or {}
    for i, item in ipairs(ring.icons) do
      local entry = entries[i]
      if entry and type(entry.icon) ~= "string" then
        item.icon:SetTexture(entry.icon)
        local v = entry.tint or 1
        item.icon:SetVertexColor(v, v, v)
        item.icon:SetDesaturated(entry.cooling or ns.config.theme.grey_icons or false)
        item.icon:SetAlpha(ns.light_alpha(ring.page, i, idle, 1))
        item.glow:SetAlpha(ns.light_alpha(ring.page, i, 0, 0.9))
        item.holder:Show()
      else
        item.holder:Hide()
      end
    end
  end
end

-- --- Driver -----------------------------------------------------------------

local shown = false
local since_icons = 1
local fade_speed = 1 / (c.fade or 0.2)

frame:SetScript("OnUpdate", function(self, elapsed)
  local x, y = GetCursorPosition()
  local scale = UIParent:GetEffectiveScale()
  self:ClearAllPoints()
  self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)

  since_icons = since_icons + elapsed
  if since_icons >= 0.1 then
    since_icons = 0
    shown = wanted()
    if shown then
      update_icons()
    end
  end

  local target = shown and (c.alpha or 1) or 0
  local a = self:GetAlpha()
  if a ~= target then
    local step = elapsed * fade_speed
    a = target > a and math.min(target, a + step) or math.max(target, a - step)
    self:SetAlpha(a)
  end
end)
