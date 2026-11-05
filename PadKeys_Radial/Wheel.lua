-- The wheel both radials draw: Blizzard's gamepad radial art (the atlases
-- of GamepadRadial, in Forever's Blizzard_Gamepad addon) at our scale, eight
-- segments, a title, page dots and the picked segment's name in the centre.
-- It only draws and picks; Menu.lua and Ring.lua decide what the segments
-- are and what they do.
--
-- Picking: the direction of the mouse from where the wheel opened, once it
-- is further than the dead zone. Ring.lua's secure snippet picks with the
-- same rule (pick_index), so the highlight and the action agree.

local ns = PadKeys

local SEGMENT_COUNT = 8
local SEGMENT_ANGLE = 360 / SEGMENT_COUNT
-- Blizzard's geometry (GamepadRadial.lua/.xml), before our scale.
local HIGHLIGHT_DISTANCE = 150
local ATLAS_ICON_DISTANCE = 100
local TEXTURE_ICON_DISTANCE = 130
local ATLAS_ICON_SIZE = 57
local TEXTURE_ICON_SIZE = 38
-- The wheel art's size, if its atlas gives none.
local WHEEL_SIZE = 400

ns.wheel_segments = SEGMENT_COUNT

-- Segment for an offset from the opening point, or nil inside the dead
-- zone. Segments go counter-clockwise from east, as in Blizzard's radial.
function ns.pick_index(dx, dy, dead_zone)
  if dx * dx + dy * dy < dead_zone * dead_zone then
    return nil
  end
  local degrees = math.deg(math.atan2(dy, dx)) % 360
  return math.floor(degrees / SEGMENT_ANGLE + 0.5) % SEGMENT_COUNT + 1
end

-- The cursor in UIParent units, the units of the dead zone.
local function cursor()
  local x, y = GetCursorPosition()
  local scale = UIParent:GetEffectiveScale()
  return x / scale, y / scale
end

local function polar(index, distance)
  local radians = math.rad((index - 1) * SEGMENT_ANGLE)
  return distance * math.cos(radians), distance * math.sin(radians)
end

-- Blizzard's highlight art points north; turn it towards the segment.
local function rotation(index)
  return math.rad((index - 1) * SEGMENT_ANGLE - 270)
end

local function play(sound)
  if SOUNDKIT[sound] then
    PlaySound(SOUNDKIT[sound])
  end
end

local Wheel = {}
Wheel.__index = Wheel

function ns.create_wheel(name)
  local w = setmetatable({}, Wheel)

  local frame = CreateFrame("Frame", name, UIParent)
  frame:SetFrameStrata("DIALOG")
  frame:SetSize(WHEEL_SIZE, WHEEL_SIZE)
  frame:Hide()
  w.frame = frame

  -- The art lives on a scaled child; the text stays at its normal size.
  local art = CreateFrame("Frame", nil, frame)
  art:SetPoint("CENTER")
  local background = art:CreateTexture(nil, "ARTWORK", nil, 0)
  background:SetAtlas("gamepad-radial-menu-wheelbg", true)
  background:SetPoint("CENTER")
  local width, height = background:GetSize()
  if not (width and width > 0) then
    width, height = WHEEL_SIZE, WHEEL_SIZE
    background:SetSize(width, height)
  end
  art:SetSize(width, height)
  w.art = art
  w.background = background

  w.highlight = art:CreateTexture(nil, "ARTWORK", nil, 2)
  w.highlight:SetAtlas("gamepad-radial-menu-selected", true)
  w.highlight:Hide()

  w.segments = {}
  for i = 1, SEGMENT_COUNT do
    local disabled = art:CreateTexture(nil, "ARTWORK", nil, 1)
    disabled:SetAtlas("gamepad-radial-menu-disabled", true)
    disabled:SetPoint("CENTER", polar(i, HIGHLIGHT_DISTANCE))
    disabled:SetRotation(rotation(i))
    w.segments[i] = { icon = art:CreateTexture(nil, "OVERLAY"), disabled = disabled }
  end

  w.label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  w.label:SetPoint("CENTER", art)
  w.label:SetWidth(110)

  w.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  w.title:SetTextColor(1, 1, 1)
  w.title:SetPoint("BOTTOM", art, "TOP", 0, 22)

  w.dots = {}
  for i = 1, 3 do
    local dot = frame:CreateTexture(nil, "OVERLAY")
    dot:SetSize(10, 10)
    w.dots[i] = dot
  end
  w.dots[2]:SetPoint("TOP", w.title, "BOTTOM", 0, -6)
  w.dots[1]:SetPoint("RIGHT", w.dots[2], "LEFT", -4, 0)
  w.dots[3]:SetPoint("LEFT", w.dots[2], "RIGHT", 4, 0)

  w.previous_hint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  w.previous_hint:SetPoint("RIGHT", w.dots[1], "LEFT", -6, 0)
  w.next_hint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  w.next_hint:SetPoint("LEFT", w.dots[3], "RIGHT", 6, 0)

  frame:SetScript("OnUpdate", function() w:track() end)
  frame:SetScript("OnHide", function() play("GAMEPAD_RADIAL_MENU_CLOSE") end)
  return w
end

-- An atlas name or a texture (file ID or path), sized and placed as
-- Blizzard places each kind.
local function draw_icon(tex, index, icon)
  local distance = TEXTURE_ICON_DISTANCE
  if type(icon) == "string" and C_Texture.GetAtlasInfo(icon) then
    local info = C_Texture.GetAtlasInfo(icon)
    tex:SetAtlas(icon)
    if info.width > 0 and info.height > 0 then
      local fit = math.min(ATLAS_ICON_SIZE / info.width, ATLAS_ICON_SIZE / info.height)
      tex:SetSize(info.width * fit, info.height * fit)
    else
      tex:SetSize(ATLAS_ICON_SIZE, ATLAS_ICON_SIZE)
    end
    distance = ATLAS_ICON_DISTANCE
  else
    tex:SetTexture(icon or 134400)
    tex:SetSize(TEXTURE_ICON_SIZE, TEXTURE_ICON_SIZE)
  end
  tex:ClearAllPoints()
  tex:SetPoint("CENTER", polar(index, distance))
end

-- entries[i] is nil (an empty segment) or
-- { icon = atlas or texture, label = text, enabled = bool, desaturate = bool }.
function Wheel:set_entries(entries)
  self.entries = entries
  for i, segment in ipairs(self.segments) do
    local entry = entries[i]
    if entry then
      draw_icon(segment.icon, i, entry.icon)
      segment.icon:SetDesaturated(entry.desaturate or false)
      segment.icon:Show()
      segment.disabled:SetShown(not entry.enabled)
    else
      segment.icon:Hide()
      segment.disabled:Hide()
    end
  end
  if self.current then
    self:select(self.current, true)
  end
end

-- Page dots and the page keys beside them; hidden for a single page.
function Wheel:set_page(index, count, previous_text, next_text)
  local paging = count > 1
  for i, dot in ipairs(self.dots) do
    dot:SetShown(paging and i <= count)
    dot:SetAtlas("gamepad-radialgamemenu-cursorbg-" .. (i == index and "neutral" or "inactive"))
  end
  self.previous_hint:SetText(paging and previous_text or "")
  self.next_hint:SetText(paging and next_text or "")
end

function Wheel:select(index, refresh)
  if index == self.current and not refresh then
    return
  end
  local moved = index ~= self.current
  self.current = index
  local entry = self.entries and self.entries[index]
  if not entry then
    self.highlight:Hide()
    self.label:SetText("")
    return
  end
  self.highlight:ClearAllPoints()
  self.highlight:SetPoint("CENTER", polar(index, HIGHLIGHT_DISTANCE))
  self.highlight:SetRotation(rotation(index))
  self.highlight:SetDesaturated(not entry.enabled)
  self.highlight:Show()
  self.label:SetText(entry.label or "")
  local color = entry.enabled and HIGHLIGHT_FONT_COLOR or DISABLED_FONT_COLOR
  self.label:SetTextColor(color:GetRGB())
  if moved then
    play("GAMEPAD_RADIAL_MENU_HIGHLIGHT")
  end
end

function Wheel:track()
  local x, y = cursor()
  local index = ns.pick_index(x - self.origin_x, y - self.origin_y, ns.config.radial.dead_zone)
  if index then
    self:select(index)
  end
end

-- The picked entry's index, or nil.
function Wheel:picked()
  return self.current and self.entries and self.entries[self.current] and self.current
end

function Wheel:open(title)
  local config = ns.config.radial
  local frame = self.frame
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", UIParent, "CENTER", config.x, config.y)
  self.art:SetScale(config.scale)
  self.title:SetText(title)
  self.origin_x, self.origin_y = cursor()
  self.current = nil
  self.highlight:Hide()
  self.label:SetText("")
  frame:Show()
  play("GAMEPAD_RADIAL_MENU_OPEN")
  self:note_layout()
end

-- Once per session, what the wheel looks like on screen, for
-- PadKeys_Debug: sizes, visibility and whether the atlases exist.
function Wheel:note_layout()
  if self.noted or not PadKeysDebug_Note then
    return
  end
  self.noted = true
  local frame, art = self.frame, self.art
  local function size(region)
    local width, height = region:GetSize()
    return format("%.0fx%.0f", width or -1, height or -1)
  end
  PadKeysDebug_Note(format(
    "%s: frame %s visible=%s alpha=%.2f scale=%.2f strata=%s rect=%s | art %s visible=%s"
      .. " | background %s shown=%s atlas=%s | title %q visible=%s | wheelbg=%s selected=%s",
    frame:GetName() or "?", size(frame), tostring(frame:IsVisible()),
    frame:GetEffectiveAlpha(), frame:GetEffectiveScale(), frame:GetFrameStrata(),
    strjoin(",", tostringall(frame:GetRect())),
    size(art), tostring(art:IsVisible()),
    size(self.background), tostring(self.background:IsShown()),
    tostring(self.background:GetAtlas()),
    self.title:GetText() or "", tostring(self.title:IsVisible()),
    tostring(C_Texture.GetAtlasInfo("gamepad-radial-menu-wheelbg") ~= nil),
    tostring(C_Texture.GetAtlasInfo("gamepad-radial-menu-selected") ~= nil)))
end

function Wheel:close()
  self.frame:Hide()
end

function Wheel:is_open()
  return self.frame:IsShown()
end
