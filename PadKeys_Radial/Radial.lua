-- The main-menu radial: our own frame in the style of Blizzard's gamepad
-- radial (GamepadRadial, in Forever's Blizzard_Gamepad addon), smaller and
-- driven from the keyboard and mouse. The entries are Blizzard's: their
-- labels, icons, enabled state and actions come from GamepadRadial's own
-- table of segment handlers, so they do what the gamepad's do. The frame,
-- the pages and the input are ours, so nothing waits on gamepad managers or
-- the shoulder buttons:
--
-- * hold the radial key: show it, on the start page;
-- * move the mouse: the direction from where it opened picks a segment, as
--   soon as it leaves a small dead zone;
-- * page keys while open: previous / next page;
-- * release: close, and run the picked segment.
--
-- It opens windows and sets key overrides, so it is meant for out of combat.

local ns = PadKeys

BINDING_HEADER_PADKEYS_RADIAL = "PadKeys: radial"
BINDING_NAME_PADKEYS_RADIAL = "Main menu radial (hold)"

-- Blizzard's geometry (GamepadRadial.lua/.xml), before our scale.
local SEGMENT_COUNT = 8
local SEGMENT_ANGLE = 360 / SEGMENT_COUNT
local HIGHLIGHT_DISTANCE = 150
local ATLAS_ICON_DISTANCE = 100
local TEXTURE_ICON_DISTANCE = 130
local ATLAS_ICON_SIZE = 57
local TEXTURE_ICON_SIZE = 38

local owner = CreateFrame("Frame", "PadKeysRadialOwner", UIParent)
local radial = CreateFrame("Frame", "PadKeysRadialFrame", UIParent)
radial:SetFrameStrata("DIALOG")
radial:SetSize(1, 1)
radial:Hide()

-- The art lives on a scaled child; the text stays at its normal size.
local wheel = CreateFrame("Frame", nil, radial)
wheel:SetPoint("CENTER")
local background = wheel:CreateTexture(nil, "ARTWORK", nil, 0)
background:SetAtlas("gamepad-radial-menu-wheelbg", true)
background:SetPoint("CENTER")
wheel:SetSize(background:GetSize())

local highlight = wheel:CreateTexture(nil, "ARTWORK", nil, 2)
highlight:SetAtlas("gamepad-radial-menu-selected", true)
highlight:Hide()

local function polar(index, distance)
  local radians = math.rad((index - 1) * SEGMENT_ANGLE)
  return distance * math.cos(radians), distance * math.sin(radians)
end

-- Blizzard's highlight art points north; turn it towards the segment.
local function highlight_rotation(index)
  return math.rad((index - 1) * SEGMENT_ANGLE - 270)
end

local segments = {}
for i = 1, SEGMENT_COUNT do
  local disabled = wheel:CreateTexture(nil, "ARTWORK", nil, 1)
  disabled:SetAtlas("gamepad-radial-menu-disabled", true)
  disabled:SetPoint("CENTER", polar(i, HIGHLIGHT_DISTANCE))
  disabled:SetRotation(highlight_rotation(i))
  segments[i] = { icon = wheel:CreateTexture(nil, "OVERLAY"), disabled = disabled }
end

local label = radial:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
label:SetPoint("CENTER", wheel)
label:SetWidth(110)

local header = radial:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
header:SetText(FRAME_LABEL_MAIN_MENU or MAINMENU_BUTTON)
header:SetTextColor(1, 1, 1)
header:SetPoint("BOTTOM", wheel, "TOP", 0, 22)

local dots = {}
for i = 1, 3 do
  local dot = radial:CreateTexture(nil, "OVERLAY")
  dot:SetSize(10, 10)
  dots[i] = dot
end
dots[2]:SetPoint("TOP", header, "BOTTOM", 0, -6)
dots[1]:SetPoint("RIGHT", dots[2], "LEFT", -4, 0)
dots[3]:SetPoint("LEFT", dots[2], "RIGHT", 4, 0)

local previous_hint = radial:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
previous_hint:SetPoint("RIGHT", dots[1], "LEFT", -6, 0)
local next_hint = radial:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
next_hint:SetPoint("LEFT", dots[3], "RIGHT", 6, 0)

local page, current, origin_x, origin_y

local function play(sound)
  if SOUNDKIT[sound] then
    PlaySound(SOUNDKIT[sound])
  end
end

local function handlers()
  return GamepadRadial and GamepadRadial.segmentOptions
end

-- The icon Blizzard's segment would show (BasicSegmentHandler:UpdateIcon).
local function icon_of(handler)
  local icons = handler.icons
  if not icons then
    return handler.icon or 132311, not handler:IsEnabled()
  end
  if not handler:IsEnabled() then
    return icons.disabled or icons.up, icons.disabled == nil
  elseif handler:IsDown() then
    return icons.down or icons.up, false
  end
  return icons.up, false
end

local function draw_icon(index, handler)
  local tex = segments[index].icon
  local icon, desaturate = icon_of(handler)
  local size, distance = TEXTURE_ICON_SIZE, TEXTURE_ICON_DISTANCE
  if type(icon) == "string" then
    tex:SetAtlas(icon)
    local info = C_Texture.GetAtlasInfo(icon)
    local fit = info and math.min(ATLAS_ICON_SIZE / info.width, ATLAS_ICON_SIZE / info.height)
    if fit and fit < math.huge then
      tex:SetSize(info.width * fit, info.height * fit)
    else
      tex:SetSize(ATLAS_ICON_SIZE, ATLAS_ICON_SIZE)
    end
    distance = ATLAS_ICON_DISTANCE
  else
    tex:SetTexture(icon)
    tex:SetSize(size, size)
  end
  tex:SetDesaturated(desaturate)
  tex:ClearAllPoints()
  tex:SetPoint("CENTER", polar(index, distance))
  tex:Show()
end

local function select_segment(index, refresh)
  if index == current and not refresh then
    return
  end
  local moved = index ~= current
  current = index
  local handler = segments[index].handler
  if not handler then
    highlight:Hide()
    label:SetText("")
    return
  end
  highlight:ClearAllPoints()
  highlight:SetPoint("CENTER", polar(index, HIGHLIGHT_DISTANCE))
  highlight:SetRotation(highlight_rotation(index))
  highlight:SetDesaturated(not handler:IsEnabled())
  highlight:Show()
  label:SetText(handler:GetLabel() or "")
  local color = handler:IsEnabled() and HIGHLIGHT_FONT_COLOR or DISABLED_FONT_COLOR
  label:SetTextColor(color:GetRGB())
  if moved then
    play("GAMEPAD_RADIAL_MENU_HIGHLIGHT")
  end
end

local function show_page(index)
  local pages = ns.config.radial.pages
  page = (index - 1) % #pages + 1
  local options = handlers()
  for i, segment in ipairs(segments) do
    local name = pages[page][i]
    local handler = name and options[name]
    segment.handler = handler
    if handler then
      draw_icon(i, handler)
      segment.disabled:SetShown(not handler:IsEnabled())
    else
      segment.icon:Hide()
      segment.disabled:Hide()
    end
  end
  for i, dot in ipairs(dots) do
    dot:SetShown(#pages > 1 and pages[i] ~= nil)
    dot:SetAtlas("gamepad-radialgamemenu-cursorbg-" .. (i == page and "neutral" or "inactive"))
  end
  if current then
    select_segment(current, true)
  end
end

-- The direction of the mouse from the opening point picks the segment.
-- Past `reach` the opening point follows the mouse, so turning back to
-- another segment never needs a long way back.
local function on_update()
  local config = ns.config.radial
  local x, y = GetCursorPosition()
  local dx, dy = x - origin_x, y - origin_y
  local distance = math.sqrt(dx * dx + dy * dy)
  if distance < config.dead_zone then
    return
  end
  if distance > config.reach then
    local pull = (distance - config.reach) / distance
    origin_x, origin_y = origin_x + dx * pull, origin_y + dy * pull
  end
  local degrees = math.deg(math.atan2(dy, dx)) % 360
  select_segment(math.floor(degrees / SEGMENT_ANGLE + 0.5) % SEGMENT_COUNT + 1)
end

local function page_button(name, step)
  local button = CreateFrame("Button", name, UIParent)
  button:RegisterForClicks("AnyDown")
  button:SetScript("OnClick", function()
    show_page(page + step)
    play("GAMEPAD_RADIAL_MENU_TAB_OVER")
  end)
end
page_button("PadKeysRadialPrev", -1)
page_button("PadKeysRadialNext", 1)

local function key_text(keys)
  return keys[1] and GetBindingText(keys[1]) or ""
end

local function open()
  if radial:IsShown() then
    return
  end
  if not handlers() then
    ns.say("the radial needs Blizzard's gamepad UI (Blizzard_Gamepad), which isn't loaded.")
    return
  end
  if InCombatLockdown() then
    ns.say("the menu radial works out of combat.")
    return
  end
  local config = ns.config.radial
  radial:ClearAllPoints()
  radial:SetPoint("CENTER", UIParent, "CENTER", config.x, config.y)
  wheel:SetScale(config.scale)
  previous_hint:SetText(key_text(config.page_keys.previous))
  next_hint:SetText(key_text(config.page_keys.next))
  origin_x, origin_y = GetCursorPosition()
  current = nil
  highlight:Hide()
  label:SetText("")
  show_page(config.start_page)
  radial:Show()
  for _, key in ipairs(config.page_keys.previous) do
    SetOverrideBindingClick(owner, true, key, "PadKeysRadialPrev")
  end
  for _, key in ipairs(config.page_keys.next) do
    SetOverrideBindingClick(owner, true, key, "PadKeysRadialNext")
  end
  owner:SetScript("OnUpdate", on_update)
  play("GAMEPAD_RADIAL_MENU_OPEN")
end

local function release()
  if not radial:IsShown() then
    return
  end
  local handler = current and segments[current].handler
  radial:Hide()
  if handler then
    handler:Trigger()
  end
end

radial:SetScript("OnHide", function()
  owner:SetScript("OnUpdate", nil)
  if not InCombatLockdown() then
    ClearOverrideBindings(owner)
  end
  play("GAMEPAD_RADIAL_MENU_CLOSE")
end)

-- Called by the PADKEYS_RADIAL binding on key down and key up.
function ns.radial_key(keystate)
  if keystate == "down" then
    open()
  else
    release()
  end
end
