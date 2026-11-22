-- Raid picking: in ally mode in a raid, hold F and move the mouse a little
-- to move a highlight over Blizzard's raid frames; release F to target
-- the highlighted member. The mouse can stay wherever you keep it: the
-- pick moves from where it started by how far, and in which direction, the
-- mouse moved while F was held, as a gamepad stick would. A tap without
-- moving targets the member the pick starts on.
--
-- The pick starts on the raid member you last picked, or out of combat on
-- your target when it has a raid frame. In combat the start can't follow a
-- target you changed some other way (a click on a frame, Ctrl+Tab): only
-- the secure button may change its own start then.
--
-- It all runs in the restricted environment, like the radials: the button
-- reads the raid frames' positions and units through frame references set
-- out of combat, and the mouse through a screen-sized header. Raid frames
-- Blizzard creates during combat (a member joining mid-fight) can't be
-- picked until combat ends. The highlight is drawn by insecure code from
-- the same rule; it never targets anything.
--
-- Targeting.lua binds F to this button while ally mode is on in a raid.

local ns = PadKeys

-- Runs in the restricted environment: self = the pick button, owner = the
-- screen-sized header, down = key down or up. Positions are in the
-- header's units. Start and mouse origin live in the snippet's own
-- environment between down and up, as the radial's origin does.
local ON_CLICK = [[
  local count = self:GetAttribute("count") or 0
  local scale = owner:GetEffectiveScale()
  if down then
    local last = self:GetAttribute("last")
    start_unit, fallback_unit = nil, nil
    local fx, fy
    for i = 1, count do
      local f = self:GetFrameRef("u" .. i)
      local unit = f and f:GetAttribute("unit")
      if unit and f:IsVisible() and UnitExists(unit) then
        local l, b, w, h = f:GetRect()
        if l then
          local e = f:GetEffectiveScale() / scale
          local cx, cy = (l + w / 2) * e, (b + h / 2) * e
          if unit == last then
            start_unit, sx, sy, sw, sh = unit, cx, cy, w * e, h * e
          end
          -- No last pick on screen: start top left.
          if not fx or cy > fy + 1 or (cy > fy - 1 and cx < fx) then
            fallback_unit, fx, fy, fw, fh = unit, cx, cy, w * e, h * e
          end
        end
      end
    end
    if not start_unit and fallback_unit then
      start_unit, sx, sy, sw, sh = fallback_unit, fx, fy, fw, fh
    end
    local mx, my = owner:GetMousePosition()
    origin_x = mx and mx * owner:GetWidth()
    origin_y = my and my * owner:GetHeight()
    self:SetAttribute("picking", start_unit)
    return false
  end

  self:SetAttribute("picking", nil)
  local unit = start_unit
  start_unit = nil
  if not unit then
    return false
  end
  local mx, my = owner:GetMousePosition()
  if mx and origin_x then
    local dx = mx * owner:GetWidth() - origin_x
    local dy = my * owner:GetHeight() - origin_y
    local dead_zone = self:GetAttribute("dead-zone")
    if dx * dx + dy * dy >= dead_zone * dead_zone then
      local step = self:GetAttribute("step")
      local tx, ty = sx + dx / step * sw, sy + dy / step * sh
      local best
      for i = 1, count do
        local f = self:GetFrameRef("u" .. i)
        local u = f and f:GetAttribute("unit")
        if u and f:IsVisible() and UnitExists(u) then
          local l, b, w, h = f:GetRect()
          if l then
            local e = f:GetEffectiveScale() / scale
            local cx, cy = (l + w / 2) * e, (b + h / 2) * e
            local d = (cx - tx) * (cx - tx) + (cy - ty) * (cy - ty)
            if not best or d < best then
              best, unit = d, u
            end
          end
        end
      end
    end
  end
  self:SetAttribute("unit", unit)
  self:SetAttribute("last", unit)
]]

local header = CreateFrame("Frame", "PadKeysRaidPickHeader", UIParent,
                           "SecureHandlerBaseTemplate")
header:SetAllPoints(UIParent)

local button = CreateFrame("Button", "PadKeysRaidPick", UIParent,
                           "SecureActionButtonTemplate")
button:RegisterForClicks("AnyDown", "AnyUp")
button:SetAttribute("useOnKeyDown", false)
button:SetAttribute("type", "target")
button:SetAttribute("step", ns.config.interact.raid.step)
button:SetAttribute("dead-zone", ns.config.interact.raid.dead_zone)
SecureHandlerWrapScript(button, "OnClick", header, ON_CLICK)

-- Blizzard's raid frames: CompactRaidFrameN with groups apart, and
-- CompactRaidGroupNMemberM with "Keep Groups Together".
local frames = {}

local function collect()
  wipe(frames)
  local i = 1
  while _G["CompactRaidFrame" .. i] do
    frames[#frames + 1] = _G["CompactRaidFrame" .. i]
    i = i + 1
  end
  for group = 1, 8 do
    for member = 1, 5 do
      local f = _G["CompactRaidGroup" .. group .. "Member" .. member]
      if f then
        frames[#frames + 1] = f
      end
    end
  end
end

-- Out of combat only: frame references and the start are protected.
local pending = false

local function sync_target()
  for _, f in ipairs(frames) do
    local unit = f:GetAttribute("unit")
    if unit and f:IsVisible() and UnitIsUnit(unit, "target") then
      button:SetAttribute("last", unit)
      return
    end
  end
end

local function refresh()
  if InCombatLockdown() then
    pending = true
    return
  end
  pending = false
  collect()
  local n = 0
  for _, f in ipairs(frames) do
    if f:IsProtected() then
      n = n + 1
      SecureHandlerSetFrameRef(button, "u" .. n, f)
    end
  end
  button:SetAttribute("count", n)
  sync_target()
end

-- The highlight: a white frame over the picked raid frame, following the
-- same rule as the snippet, from insecure code.
local mark = CreateFrame("Frame", nil, UIParent)
mark:SetFrameStrata("DIALOG")
mark:Hide()
local function edge(p1, p2, horizontal)
  local t = mark:CreateTexture(nil, "OVERLAY")
  t:SetColorTexture(1, 1, 1, 1)
  t:SetPoint(p1)
  t:SetPoint(p2)
  if horizontal then
    t:SetHeight(2)
  else
    t:SetWidth(2)
  end
end
edge("TOPLEFT", "TOPRIGHT", true)
edge("BOTTOMLEFT", "BOTTOMRIGHT", true)
edge("TOPLEFT", "BOTTOMLEFT", false)
edge("TOPRIGHT", "BOTTOMRIGHT", false)

-- Each usable raid frame as centre and size in UIParent units.
local function frame_rect(f)
  local unit = f:GetAttribute("unit")
  if not (unit and f:IsVisible() and UnitExists(unit)) then
    return nil
  end
  local l, b, w, h = f:GetRect()
  if not l then
    return nil
  end
  local e = f:GetEffectiveScale() / UIParent:GetEffectiveScale()
  return unit, (l + w / 2) * e, (b + h / 2) * e, w * e, h * e
end

local start, origin_x, origin_y

local function cursor()
  local x, y = GetCursorPosition()
  local e = UIParent:GetEffectiveScale()
  return x / e, y / e
end

local function show_on(cx, cy, w, h)
  mark:ClearAllPoints()
  mark:SetSize(w + 4, h + 4)
  mark:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)
  mark:Show()
end

local function update()
  if not start then
    return
  end
  local x, y = cursor()
  local dx, dy = x - origin_x, y - origin_y
  local c = ns.config.interact.raid
  local tx, ty = start.x, start.y
  if dx * dx + dy * dy >= c.dead_zone * c.dead_zone then
    tx = start.x + dx / c.step * start.w
    ty = start.y + dy / c.step * start.h
  end
  local best, bx, by, bw, bh
  for _, f in ipairs(frames) do
    local unit, cx, cy, w, h = frame_rect(f)
    if unit then
      local d = (cx - tx) ^ 2 + (cy - ty) ^ 2
      if not best or d < best then
        best, bx, by, bw, bh = d, cx, cy, w, h
      end
    end
  end
  if best then
    show_on(bx, by, bw, bh)
  end
end

mark:SetScript("OnUpdate", update)

button:HookScript("OnAttributeChanged", function(_, name, value)
  if name ~= "picking" then
    return
  end
  start = nil
  if value then
    for _, f in ipairs(frames) do
      local unit, cx, cy, w, h = frame_rect(f)
      if unit == value then
        start = { x = cx, y = cy, w = w, h = h }
        break
      end
    end
  end
  if start then
    origin_x, origin_y = cursor()
    show_on(start.x, start.y, start.w, start.h)
  else
    mark:Hide()
  end
end)

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_TARGET_CHANGED" then
    if not InCombatLockdown() then
      sync_target()
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if pending then
      refresh()
    end
  else
    -- Blizzard builds its raid frames on the same event: look after it.
    C_Timer.After(0.2, refresh)
  end
end)
