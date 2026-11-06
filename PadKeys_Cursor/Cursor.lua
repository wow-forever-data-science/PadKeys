-- Keyboard UI cursor, modelled on Forever's gamepad "SmartNavigation": while
-- it is active the movement keys move a highlight between the buttons of the
-- open windows, Space clicks the highlighted one and Esc closes its window.
-- The mouse wheel steps through entries one at a time. A window that opens
-- takes the cursor (followWindows, autoFrames in Config.lua).
--
-- Clicks go through a secure proxy button bound with an override binding,
-- so they count as real key presses: spells in the spellbook can be cast and
-- items in bags used. Pointing the proxy at a new button is blocked in
-- combat, so the cursor switches off when combat starts.

local ns = PadKeys

BINDING_HEADER_PADKEYS_CURSOR = "PadKeys: cursor"
BINDING_NAME_PADKEYS_CURSOR = "Toggle keyboard UI cursor"
_G["BINDING_NAME_CLICK PadKeysBags:LeftButton"] = "Open bags with the cursor inside"

local EXTRA_ROOTS = {
  "LootFrame", "GossipFrame", "QuestFrame", "MerchantFrame",
  "ContainerFrameCombinedBags",
  "StaticPopup1", "StaticPopup2", "StaticPopup3", "StaticPopup4",
}
for i = 1, 13 do
  EXTRA_ROOTS[#EXTRA_ROOTS + 1] = "ContainerFrame" .. i
end
-- Unit and group frames (clicking one targets that unit). They are always
-- shown, so they're only included when the cursor was started by hand;
-- otherwise the cursor would never switch itself off.
local UNIT_ROOTS = {
  "PlayerFrame", "TargetFrame", "FocusFrame", "PartyFrame",
  "CompactPartyFrame", "CompactRaidFrameContainer",
  -- Your buffs and debuffs: the cursor shows their tooltips, and right-click
  -- cancels a buff, as the gamepad does (BuffFrameMixin:CancelSelectedBuff).
  "BuffFrame", "DebuffFrame",
}
-- Action bars become targets while a spell or item is on the cursor.
local BAR_ROOTS = {
  "MainActionBar", "MultiBarBottomLeft", "MultiBarBottomRight",
  "MultiBarLeft", "MultiBarRight", "PetActionBar",
}
local DIRECTIONS = {
  up = { 0, 1 }, down = { 0, -1 }, left = { -1, 0 }, right = { 1, 0 },
}

local owner = CreateFrame("Frame", "PadKeysCursorOwner", UIParent)
local active, manual, current = false, false, nil

-- What marks the current button, after the gamepad UI: a white arrow that
-- bobs at the button's left, the soft additive glow the quest log uses for
-- its rows (in grey), and a pulsing white glow around the window the
-- button is in.
local box = CreateFrame("Frame", nil, UIParent)
box:SetFrameStrata("TOOLTIP")
box:Hide()
local glow = box:CreateTexture(nil, "OVERLAY")
glow:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
glow:SetBlendMode("ADD")
glow:SetAllPoints()
glow:SetDesaturated(true)

local arrow = box:CreateTexture(nil, "OVERLAY")
arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
arrow:SetSize(16, 16)
arrow:SetDesaturated(true)
arrow:SetPoint("RIGHT", box, "LEFT", 2, 0)
-- The game draws textures on whole screen pixels, so a 3-pixel bob moved
-- in three jumps. Let the arrow sit between pixels and move it along a
-- sine wave each frame instead: 3 pixels left and back once a second.
arrow:SetSnapToPixelGrid(false)
arrow:SetTexelSnappingBias(0)
local BOB_DISTANCE, BOB_PERIOD = 3, 1
local bob_time = 0
box:SetScript("OnUpdate", function(_, dt)
  bob_time = (bob_time + dt) % BOB_PERIOD
  local x = 2 - BOB_DISTANCE * (1 - math.cos(bob_time / BOB_PERIOD * 2 * math.pi)) / 2
  arrow:SetPoint("RIGHT", box, "LEFT", x, 0)
end)
box:SetScript("OnShow", function() bob_time = 0 end)

local frame_glow = CreateFrame("Frame", nil, UIParent)
frame_glow:SetFrameStrata("TOOLTIP")
frame_glow:Hide()
local GLOW = 10
local glow_edges = {}
-- A strip just outside each side of the window: its inner edge on the
-- window's edge. The top and bottom strips also run over the corners.
local function glow_edge(outward, p1, r1, x1, y1, p2, r2, x2, y2)
  local tex = frame_glow:CreateTexture(nil, "OVERLAY")
  tex:SetColorTexture(1, 1, 1)
  tex:SetBlendMode("ADD")
  tex:SetPoint(p1, frame_glow, r1, x1, y1)
  tex:SetPoint(p2, frame_glow, r2, x2, y2)
  glow_edges[#glow_edges + 1] = { tex = tex, outward = outward }
end
glow_edge("up", "BOTTOMLEFT", "TOPLEFT", -GLOW, 0,
          "TOPRIGHT", "TOPRIGHT", GLOW, GLOW)
glow_edge("down", "TOPLEFT", "BOTTOMLEFT", -GLOW, 0,
          "BOTTOMRIGHT", "BOTTOMRIGHT", GLOW, -GLOW)
glow_edge("left", "TOPRIGHT", "TOPLEFT", 0, 0,
          "BOTTOMLEFT", "BOTTOMLEFT", -GLOW, 0)
glow_edge("right", "TOPLEFT", "TOPRIGHT", 0, 0,
          "BOTTOMRIGHT", "BOTTOMRIGHT", GLOW, 0)
local pulse = frame_glow:CreateAnimationGroup()
pulse:SetLooping("BOUNCE")
local fade = pulse:CreateAnimation("Alpha")
fade:SetFromAlpha(1)
fade:SetToAlpha(0.45)
fade:SetDuration(1.2)
fade:SetSmoothing("IN_OUT")
frame_glow:SetScript("OnShow", function() pulse:Play() end)
frame_glow:SetScript("OnHide", function() pulse:Stop() end)

local function tint(armed)
  -- Light grey; white while armed.
  local v = armed and 1 or ns.grey.light
  local r, g, b = v, v, v
  glow:SetVertexColor(r, g, b, armed and 1 or 0.85)
  arrow:SetVertexColor(r, g, b)
  local edge, clear = CreateColor(r, g, b, 0.6), CreateColor(r, g, b, 0)
  for _, e in ipairs(glow_edges) do
    -- Brightest at the window's edge, fading outward.
    if e.outward == "up" then
      e.tex:SetGradient("VERTICAL", edge, clear)
    elseif e.outward == "down" then
      e.tex:SetGradient("VERTICAL", clear, edge)
    elseif e.outward == "left" then
      e.tex:SetGradient("HORIZONTAL", clear, edge)
    else
      e.tex:SetGradient("HORIZONTAL", edge, clear)
    end
  end
end
tint(false)

local proxy = CreateFrame("Button", "PadKeysCursorClick", UIParent,
                          "SecureActionButtonTemplate")
proxy:RegisterForClicks("AnyDown")
proxy:SetAttribute("useOnKeyDown", true)
proxy:SetAttribute("type", "click")

local function center(frame)
  local x, y = frame:GetCenter()
  if not x then
    return nil
  end
  local scale = frame:GetEffectiveScale()
  return x * scale, y * scale
end

local function contains(frame, x, y)
  local left, bottom, width, height = frame:GetRect()
  if not left then
    return false
  end
  local scale = frame:GetEffectiveScale()
  return x >= left * scale and x <= (left + width) * scale and
    y >= bottom * scale and y <= (bottom + height) * scale
end

-- False if a clipping parent (a scroll list) hides the frame's centre.
local function unclipped(frame, x, y)
  local parent = frame:GetParent()
  while parent and parent ~= UIParent do
    if parent.DoesClipChildren and parent:DoesClipChildren() and
      not contains(parent, x, y) then
      return false
    end
    parent = parent:GetParent()
  end
  return true
end

-- Buttons, and text fields (a search box): the cursor can type in those.
local function clickable(frame)
  if frame:IsObjectType("EditBox") then
    if not (frame:IsVisible() and frame:IsMouseEnabled() and
              (not frame.IsEnabled or frame:IsEnabled())) then
      return false
    end
  elseif not (frame:IsObjectType("Button") and frame:IsVisible() and
                frame:IsEnabled() and frame:IsMouseClickEnabled()) then
    return false
  end
  local width, height = frame:GetSize()
  return width >= 8 and height >= 8 and width <= 500 and height <= 200
end

local function collect(frame, out, depth)
  if depth > 15 or frame:IsForbidden() or not frame:IsVisible() then
    return
  end
  if clickable(frame) then
    local x, y = center(frame)
    if x and unclipped(frame, x, y) then
      out[#out + 1] = frame
    end
  end
  for _, child in ipairs({ frame:GetChildren() }) do
    collect(child, out, depth + 1)
  end
end

local function root_names()
  local names = {}
  for name in pairs(UIPanelWindows or {}) do
    names[#names + 1] = name
  end
  for _, name in ipairs(UISpecialFrames or {}) do
    names[#names + 1] = name
  end
  for _, name in ipairs(EXTRA_ROOTS) do
    names[#names + 1] = name
  end
  if GetCursorInfo() then
    for _, name in ipairs(BAR_ROOTS) do
      names[#names + 1] = name
    end
  end
  if manual then
    for _, name in ipairs(UNIT_ROOTS) do
      names[#names + 1] = name
    end
  end
  return names
end

-- Windows Blizzard opened with ShowUIPanel, in case one isn't listed in
-- UIPanelWindows (see the ShowUIPanel hook below).
local panels = {}

-- Which window (root) each candidate button belongs to, for next/previous
-- window. Rebuilt by candidates().
local root_of = {}

local function candidates()
  local out, seen = {}, {}
  root_of = {}
  local roots = {}
  for _, name in ipairs(root_names()) do
    roots[#roots + 1] = _G[name]
  end
  for _, frame in ipairs(panels) do
    roots[#roots + 1] = frame
  end
  for _, frame in ipairs(roots) do
    if type(frame) == "table" and frame.IsVisible and not seen[frame] and
      frame:IsVisible() then
      seen[frame] = true
      local start = #out
      collect(frame, out, 0)
      for i = start + 1, #out do
        root_of[out[i]] = frame
      end
    end
  end
  return out
end

-- Top-left button: the natural starting point.
local function first(cands)
  local best, bx, by
  for _, frame in ipairs(cands) do
    local x, y = center(frame)
    if not best or y > by + 4 or (math.abs(y - by) <= 4 and x < bx) then
      best, bx, by = frame, x, y
    end
  end
  return best
end

-- Nearest button in a direction, preferring ones in line with the current.
local function nearest(cands, direction)
  local cx, cy = center(current)
  local ux, uy = DIRECTIONS[direction][1], DIRECTIONS[direction][2]
  local best, best_score
  for _, frame in ipairs(cands) do
    local x, y = center(frame)
    if frame ~= current and x then
      local dx, dy = x - cx, y - cy
      local along = dx * ux + dy * uy
      if along > 1 then
        local score = along + 2 * math.abs(dx * uy - dy * ux)
        if not best_score or score < best_score then
          best, best_score = frame, score
        end
      end
    end
  end
  return best
end

local function run_script(frame, script, ...)
  local handler = frame and frame:GetScript(script)
  if handler then
    pcall(handler, frame, ...)
  end
end

-- The glow turns deep gold while an entry waits for a second press to confirm
-- (Services.lua: buy, train). Moving the cursor away cancels it.
local armed
local function set_armed(frame)
  armed = frame
  tint(frame ~= nil)
end

-- Windows can take over the click on some of their buttons (Services.lua:
-- vendor items, trainer skills). Each handler gets the button under the
-- cursor and returns the button to click instead, or nil.
local click_handlers = {}
function ns.cursor_on_click(handler)
  click_handlers[#click_handlers + 1] = handler
end

local function click_target(frame)
  for _, handler in ipairs(click_handlers) do
    local target = handler(frame)
    if target then
      return target
    end
  end
  return frame
end

-- A text field under the cursor: the click key puts the text caret in it,
-- so you can type. While it has the caret it takes the keys; Escape or
-- Enter (the field's own handlers) give them back to the cursor.
local field
local focus = CreateFrame("Button", "PadKeysCursorFocus", UIParent)
focus:SetScript("OnClick", function()
  if field and field:IsVisible() then
    field:SetFocus()
  end
end)
ns.cursor_on_click(function(frame)
  if frame:IsObjectType("EditBox") then
    field = frame
    return focus
  end
end)

local function select_button(frame)
  if current and current ~= frame then
    run_script(current, "OnLeave", true)
  end
  if armed and armed ~= frame then
    set_armed(nil)
  end
  current = frame
  box:ClearAllPoints()
  box:SetAllPoints(frame)
  box:Show()
  local root = root_of[frame]
  if root then
    frame_glow:SetAllPoints(root)
    frame_glow:Show()
  else
    frame_glow:Hide()
  end
  if ns.config.cursor.tooltips ~= false then
    run_script(frame, "OnEnter", true)
  end
  proxy:SetAttribute("clickbutton", click_target(frame))
end

local function stop()
  if not active then
    return
  end
  active = false
  if not InCombatLockdown() then
    ClearOverrideBindings(owner)
  end
  run_script(current, "OnLeave", true)
  current = nil
  set_armed(nil)
  box:Hide()
  frame_glow:Hide()
end

-- Re-check after windows change: keep the current button if it is still
-- there, else jump to the first one, or stop when no window is left.
local function refresh()
  if not active or InCombatLockdown() then
    return
  end
  local cands = candidates()
  if #cands == 0 then
    stop()
    return
  end
  for _, frame in ipairs(cands) do
    if frame == current then
      return
    end
  end
  select_button(first(cands))
end

local function move(direction)
  if not active or InCombatLockdown() then
    return
  end
  local cands = candidates()
  if not current or not current:IsVisible() then
    refresh()
    return
  end
  local target = nearest(cands, direction)
  if target then
    select_button(target)
  end
end

-- Pick up the current spell or item, as if dragging it with the mouse.
local function pickup()
  if active and current and not InCombatLockdown() then
    run_script(current, "OnDragStart", "LeftButton")
  end
end

local function nav_button(name, func)
  local button = CreateFrame("Button", name, UIParent)
  button:RegisterForClicks("AnyDown")
  button:SetScript("OnClick", func)
end
-- Scrolling the mouse wheel steps through entries one at a time, in reading
-- order (left to right, then down), as the gamepad's shoulder buttons page:
--
-- * Windows can take a step over (Services.lua: vendor items turn the page
--   at the end of one). Each handler gets the button and the step (1 next,
--   -1 previous) and returns true if it handled it.
-- * In a scrolling list (trainer skills, recipes, gossip) the next row,
--   scrolling the list to bring it into view.
-- * Elsewhere the next button of the same size in the same window (bag
--   slots, spells), else the nearest button down or up.
local scroll_handlers = {}
function ns.cursor_on_scroll(handler)
  scroll_handlers[#scroll_handlers + 1] = handler
end

-- The ScrollBox list a button is a row of (or is inside a row of): the
-- list and the row.
local function list_row(frame)
  local child, parent = frame, frame:GetParent()
  while parent and parent ~= UIParent do
    local list = parent:GetParent()
    if list and list.FindFrameElementDataIndex and list.GetScrollTarget and
      list:GetScrollTarget() == parent then
      return list, child
    end
    child, parent = parent, list
  end
end

-- A row's own button, else its top-left button.
local function button_in(frame)
  if clickable(frame) then
    return frame
  end
  local out = {}
  collect(frame, out, 0)
  return first(out)
end

local function select_found(frame)
  candidates() -- so the window glow follows
  select_button(frame)
end

local function scroll_list(list, row, delta)
  local index = list:FindFrameElementDataIndex(row)
  local size = list.GetDataProviderSize and list:GetDataProviderSize()
  if not (index and size) then
    return false
  end
  local align = ScrollBoxConstants and ScrollBoxConstants.AlignNearest
  -- Skip rows with nothing to click (dividers), but not forever.
  local i = index + delta
  for _ = 1, 20 do
    if i < 1 or i > size then
      break
    end
    list:ScrollToElementDataIndex(i, align, 0, true)
    local data = list:FindElementData(i)
    local frame = data and list:FindFrame(data)
    local target = frame and button_in(frame)
    if target then
      select_found(target)
      break
    end
    i = i + delta
  end
  return true
end

local function same_size(a, b)
  local aw, ah = a:GetSize()
  local bw, bh = b:GetSize()
  return math.abs(aw - bw) <= 2 and math.abs(ah - bh) <= 2
end

local function reads_before(a, b)
  local ax, ay = center(a)
  local bx, by = center(b)
  if math.abs(ay - by) > 4 then
    return ay > by
  end
  return ax < bx
end

local function scroll(delta)
  if not active or InCombatLockdown() then
    return
  end
  local cands = candidates()
  if not current or not current:IsVisible() then
    refresh()
    return
  end
  for _, handler in ipairs(scroll_handlers) do
    if handler(current, delta) then
      return
    end
  end
  local list, row = list_row(current)
  if list and scroll_list(list, row, delta) then
    return
  end
  local root, peers = root_of[current], {}
  for _, frame in ipairs(cands) do
    if root_of[frame] == root and same_size(frame, current) then
      peers[#peers + 1] = frame
    end
  end
  if #peers > 1 then
    table.sort(peers, reads_before)
    for i, frame in ipairs(peers) do
      if frame == current then
        if peers[i + delta] then
          select_button(peers[i + delta])
        end
        return
      end
    end
  end
  move(delta > 0 and "down" or "up")
end

nav_button("PadKeysNavUp", function() move("up") end)
nav_button("PadKeysNavScrollUp", function() scroll(-1) end)
nav_button("PadKeysNavScrollDown", function() scroll(1) end)
nav_button("PadKeysNavDown", function() move("down") end)
nav_button("PadKeysNavLeft", function() move("left") end)
nav_button("PadKeysNavRight", function() move("right") end)
nav_button("PadKeysNavPickup", pickup)

-- The window's close button, found as Blizzard's gamepad "back" finds it
-- (SmartNavigationMixin:AttemptClose): its CloseButton key, else a visible
-- button named "...CloseButton".
local function close_button(root)
  local button = root.CloseButton
  if button and button.IsVisible and button:IsVisible() then
    return button
  end
  for frame, frame_root in pairs(root_of) do
    local name = frame_root == root and frame:GetName()
    if name and name:match("CloseButton") and frame:IsVisible() then
      return frame
    end
  end
end

-- Gamepad B: close the window the cursor is in. With no close button (unit
-- frames, auras, popups) it leaves the cursor instead.
local function back()
  if not active or InCombatLockdown() or not current then
    stop()
    return
  end
  candidates()
  local root = root_of[current]
  local button = root and close_button(root)
  if button then
    button:Click()
    C_Timer.After(0.1, refresh)
  else
    stop()
  end
end
nav_button("PadKeysNavBack", back)

-- Jump to the first button of the next (delta 1) or previous (-1) window,
-- like the gamepad's "Next Frame" in UI mode.
local function jump_window(delta)
  if not active or InCombatLockdown() then
    return
  end
  local cands = candidates()
  local roots, index = {}, {}
  for _, frame in ipairs(cands) do
    local root = root_of[frame]
    if root and not index[root] then
      roots[#roots + 1] = root
      index[root] = #roots
    end
  end
  if #roots == 0 then
    return
  end
  local here = current and index[root_of[current]] or 0
  local target = roots[(here - 1 + delta) % #roots + 1]
  local in_root = {}
  for _, frame in ipairs(cands) do
    if root_of[frame] == target then
      in_root[#in_root + 1] = frame
    end
  end
  select_button(first(in_root))
end
nav_button("PadKeysNavNextWindow", function() jump_window(1) end)
nav_button("PadKeysNavPrevWindow", function() jump_window(-1) end)

-- A key shared with the NPC dialog step (F) binds without priority, so
-- Dialogs.lua's priority binding wins while a gossip or quest window is open.
local function is_step_key(key)
  return tContains(ns.config.quest.step, key)
end

local function bind(keys, name, mouse_button)
  for _, key in ipairs(keys or {}) do
    SetOverrideBindingClick(owner, not is_step_key(key), key, name,
      mouse_button)
  end
end

local function inside(frame, root)
  while frame do
    if frame == root then
      return true
    end
    frame = frame:GetParent()
  end
  return false
end

-- by_hand: started with the cursor key (also reaches unit frames and auras).
-- root: optional frame to start on, e.g. BuffFrame.
local function start(by_hand, root)
  if active or InCombatLockdown() then
    return
  end
  manual = by_hand
  local cands = candidates()
  if #cands == 0 then
    if by_hand then
      ns.say("nothing to move through.")
    end
    return
  end
  active = true
  local keys = ns.config.cursor.keys
  bind(keys.up, "PadKeysNavUp")
  bind(keys.down, "PadKeysNavDown")
  bind(keys.left, "PadKeysNavLeft")
  bind(keys.right, "PadKeysNavRight")
  bind(keys.scroll_up, "PadKeysNavScrollUp")
  bind(keys.scroll_down, "PadKeysNavScrollDown")
  bind(keys.click, "PadKeysCursorClick", "LeftButton")
  bind(keys.rightclick, "PadKeysCursorClick", "RightButton")
  bind(keys.pickup, "PadKeysNavPickup")
  bind(keys.back, "PadKeysNavBack")
  bind(keys.next_window, "PadKeysNavNextWindow")
  bind(keys.previous_window, "PadKeysNavPrevWindow")
  local in_root = {}
  for _, frame in ipairs(cands) do
    if root and inside(frame, root) then
      in_root[#in_root + 1] = frame
    end
  end
  select_button(first(#in_root > 0 and in_root or cands))
end

-- For the NPC dialogs (Quest.lua), like Blizzard's gamepad code calling
-- SmartNavigation:SelectButton / GetCurrentButton.
function ns.cursor_current()
  return active and current or nil
end

-- Arm the button under the cursor for a confirming second press, or disarm.
function ns.cursor_arm(on)
  set_armed(on and current or nil)
end

function ns.cursor_armed()
  return armed ~= nil and armed == current
end

-- Put the cursor on this button, starting the cursor if it is off.
function ns.cursor_select(frame)
  if InCombatLockdown() or not (frame and frame:IsVisible()) then
    return
  end
  if active then
    select_button(frame)
  else
    start(false, frame)
  end
end

-- Put the cursor on the first (top-left) button inside root, starting the
-- cursor if it is off.
function ns.cursor_focus_in(root)
  if InCombatLockdown() or not (root and root:IsVisible()) then
    return
  end
  if not active then
    start(false, root)
    return
  end
  local in_root = {}
  for _, frame in ipairs(candidates()) do
    if inside(frame, root) then
      in_root[#in_root + 1] = frame
    end
  end
  if #in_root > 0 then
    select_button(first(in_root))
  end
end

function ns.toggle_cursor()
  if active then
    stop()
  else
    start(true)
  end
end

-- The bags key: opens the bags by clicking Blizzard's backpack button
-- through a secure button (opened from addon code they would be tainted),
-- then puts the cursor on the first slot. In combat the cursor is off, so
-- it only opens the bags; a second press closes them.
local function open_bag()
  if ContainerFrameCombinedBags and ContainerFrameCombinedBags:IsVisible() then
    return ContainerFrameCombinedBags
  end
  for i = 1, 13 do
    local frame = _G["ContainerFrame" .. i]
    if frame and frame:IsVisible() then
      return frame
    end
  end
end

local bags = CreateFrame("Button", "PadKeysBags", UIParent,
                         "SecureActionButtonTemplate")
bags:RegisterForClicks("AnyDown")
bags:SetAttribute("useOnKeyDown", true)
bags:SetAttribute("type", "macro")
bags:SetAttribute("macrotext", "/click MainMenuBarBackpackButton")
bags:HookScript("OnClick", function()
  C_Timer.After(0.05, function()
    local root = open_bag()
    if root then
      ns.cursor_focus_in(root)
    end
  end)
end)

-- A click often opens a new page or closes the window.
proxy:HookScript("PostClick", function()
  C_Timer.After(0.1, refresh)
end)

local elapsed = 0
owner:SetScript("OnUpdate", function(_, dt)
  elapsed = elapsed + dt
  if active and elapsed > 0.25 then
    elapsed = 0
    refresh()
  end
end)

-- The child of a window that autoFocus names ("CraftingPage.SearchBox",
-- or a list of paths: the first one shown), if it is shown.
local function focus_child(name)
  local paths = (ns.config.cursor.autoFocus or {})[name]
  if type(paths) ~= "table" then
    paths = { paths }
  end
  for _, path in ipairs(paths) do
    local frame = _G[name]
    for key in path:gmatch("[^.]+") do
      frame = frame and frame[key]
    end
    if frame and frame.IsVisible and frame:IsVisible() then
      return frame
    end
  end
end

-- Take the cursor into a window that just opened: start it, or move it
-- there if it is on; to its autoFocus child, or its top-left button.
-- Waits a moment for the window to lay itself out. One window opening can
-- call this twice (its OnShow and ShowUIPanel); that only moves once.
local pending = {}
local function take_cursor(frame)
  local name = frame:GetName()
  if pending[frame] or (name and
      tContains(ns.config.cursor.ignoreWindows or {}, name)) then
    return
  end
  pending[frame] = true
  C_Timer.After(0.05, function()
    pending[frame] = nil
    if not frame:IsVisible() then
      return
    end
    local child = name and focus_child(name)
    if child then
      ns.cursor_select(child)
    else
      ns.cursor_focus_in(frame)
    end
  end)
end

-- Start the cursor when an autoFrames window opens. Some windows
-- (professions) belong to Blizzard addons that load later, so this runs
-- again on every ADDON_LOADED; such a window can already be open by then
-- (the first visit loads it while it opens), so take the cursor now.
local hooked = {}
local function hook_auto_frames()
  for _, name in ipairs(ns.config.cursor.autoFrames or {}) do
    local frame = _G[name]
    if frame and frame.HookScript and not hooked[frame] then
      hooked[frame] = true
      frame:HookScript("OnShow", take_cursor)
      if frame:IsVisible() then
        take_cursor(frame)
      end
    end
  end
end

-- followWindows: every window Blizzard opens through its panel manager
-- (character, spellbook, talents, quest log, professions, trainers, ...)
-- takes the cursor, so the cursor is always in the window you just opened.
hooksecurefunc("ShowUIPanel", function(frame)
  if not (ns.config.cursor.followWindows and type(frame) == "table" and
          frame.IsVisible) then
    return
  end
  if not tContains(panels, frame) then
    panels[#panels + 1] = frame
  end
  take_cursor(frame)
end)

owner:RegisterEvent("PLAYER_LOGIN")
owner:RegisterEvent("ADDON_LOADED")
owner:RegisterEvent("PLAYER_REGEN_DISABLED")
owner:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_REGEN_DISABLED" then
    -- Fires just before combat lockdown, so bindings can still be cleared.
    stop()
  elseif event == "ADDON_LOADED" then
    hook_auto_frames()
  elseif event == "PLAYER_LOGIN" then
    hook_auto_frames()
    -- Blizzard's radial "Buffs" item calls BuffFrame:SetGamepadFocus(), which
    -- only works in gamepad mode. On keyboard, open our cursor on the auras.
    if BuffFrame and BuffFrame.SetGamepadFocus then
      hooksecurefunc(BuffFrame, "SetGamepadFocus", function(self)
        if InputUtil.IsGamepadUIEnabled() then
          return
        end
        local root = self:HasActiveAura() and self or DebuffFrame
        C_Timer.After(0, function() start(true, root) end)
      end)
    end
  end
end)
