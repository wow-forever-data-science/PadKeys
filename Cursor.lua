-- Keyboard UI cursor, modelled on Forever's gamepad "SmartNavigation": while
-- it is active the movement keys move a highlight between the buttons of the
-- open windows and Space clicks the highlighted one.
--
-- Clicks go through a secure proxy button bound with an override binding,
-- so they count as real key presses: spells in the spellbook can be cast and
-- items in bags used. Pointing the proxy at a new button is blocked in
-- combat, so the cursor switches off when combat starts.

local _, ns = ...

local EXTRA_ROOTS = {
  "LootFrame", "GossipFrame", "QuestFrame", "MerchantFrame",
  "ContainerFrameCombinedBags",
  "StaticPopup1", "StaticPopup2", "StaticPopup3", "StaticPopup4",
}
for i = 1, 13 do
  EXTRA_ROOTS[#EXTRA_ROOTS + 1] = "ContainerFrame" .. i
end
-- Action bars become targets while a spell or item is on the cursor.
local BAR_ROOTS = {
  "MainActionBar", "MultiBarBottomLeft", "MultiBarBottomRight",
  "MultiBarLeft", "MultiBarRight", "PetActionBar",
}
local DIRECTIONS = {
  up = { 0, 1 }, down = { 0, -1 }, left = { -1, 0 }, right = { 1, 0 },
}

local owner = CreateFrame("Frame", "PadKeysCursorOwner", UIParent)
local active, current = false, nil

-- Highlight box drawn around the current button.
local box = CreateFrame("Frame", nil, UIParent)
box:SetFrameStrata("TOOLTIP")
box:Hide()
local function edge(from, to, horizontal)
  local tex = box:CreateTexture(nil, "OVERLAY")
  tex:SetColorTexture(0.2, 0.8, 1, 0.9)
  tex:SetPoint(from)
  tex:SetPoint(to)
  if horizontal then
    tex:SetHeight(2)
  else
    tex:SetWidth(2)
  end
end
edge("TOPLEFT", "TOPRIGHT", true)
edge("BOTTOMLEFT", "BOTTOMRIGHT", true)
edge("TOPLEFT", "BOTTOMLEFT", false)
edge("TOPRIGHT", "BOTTOMRIGHT", false)

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

local function clickable(frame)
  if not (frame:IsObjectType("Button") and frame:IsVisible() and
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
  return names
end

local function candidates()
  local out, seen = {}, {}
  for _, name in ipairs(root_names()) do
    local frame = _G[name]
    if type(frame) == "table" and frame.IsVisible and not seen[frame] and
      frame:IsVisible() then
      seen[frame] = true
      collect(frame, out, 0)
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

local function select_button(frame)
  if current and current ~= frame then
    run_script(current, "OnLeave", true)
  end
  current = frame
  box:ClearAllPoints()
  box:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
  box:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
  box:Show()
  if ns.config.cursor.tooltips ~= false then
    run_script(frame, "OnEnter", true)
  end
  proxy:SetAttribute("clickbutton", frame)
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
  box:Hide()
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
nav_button("PadKeysNavUp", function() move("up") end)
nav_button("PadKeysNavDown", function() move("down") end)
nav_button("PadKeysNavLeft", function() move("left") end)
nav_button("PadKeysNavRight", function() move("right") end)
nav_button("PadKeysNavPickup", pickup)
nav_button("PadKeysNavBack", stop)

local function bind(keys, name, mouse_button)
  for _, key in ipairs(keys or {}) do
    SetOverrideBindingClick(owner, true, key, name, mouse_button)
  end
end

local function start(quiet)
  if active or InCombatLockdown() then
    return
  end
  local cands = candidates()
  if #cands == 0 then
    if not quiet then
      ns.say("no open window to move through.")
    end
    return
  end
  active = true
  local keys = ns.config.cursor.keys
  bind(keys.up, "PadKeysNavUp")
  bind(keys.down, "PadKeysNavDown")
  bind(keys.left, "PadKeysNavLeft")
  bind(keys.right, "PadKeysNavRight")
  bind(keys.click, "PadKeysCursorClick", "LeftButton")
  bind(keys.rightclick, "PadKeysCursorClick", "RightButton")
  bind(keys.pickup, "PadKeysNavPickup")
  bind(keys.back, "PadKeysNavBack")
  select_button(first(cands))
end

function ns.toggle_cursor()
  if active then
    stop()
  else
    start(false)
  end
end

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

owner:RegisterEvent("PLAYER_LOGIN")
owner:RegisterEvent("PLAYER_REGEN_DISABLED")
owner:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_REGEN_DISABLED" then
    -- Fires just before combat lockdown, so bindings can still be cleared.
    stop()
  elseif event == "PLAYER_LOGIN" then
    for _, name in ipairs(ns.config.cursor.autoFrames or {}) do
      local frame = _G[name]
      if frame and frame.HookScript then
        frame:HookScript("OnShow", function()
          C_Timer.After(0.05, function() start(true) end)
        end)
      end
    end
  end
end)
