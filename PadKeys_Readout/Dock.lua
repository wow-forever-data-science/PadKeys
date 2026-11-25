-- Blizzard frames docked to the readout, so they follow the pointer:
-- - your tracked buffs, upper right: the Cooldown Manager's buff icons
--   (BuffIconCooldownViewer, "Tracked Buffs"); which buffs show is the
--   Cooldown Manager's own setting;
-- - your debuffs, left: Blizzard's debuff frame (DebuffFrame), with its
--   own icons, times, dispel-type borders and tooltips.
--
-- Auras are secret in combat and addon code can't read them; these frames
-- read them in Blizzard's own code. This never reads an aura or calls
-- Blizzard's code: it only moves the frame's anchor (ClearAllPoints and
-- SetPoint, plain widget calls) and scale. Blizzard's own anchor is kept
-- and put back while Edit Mode is open, so the frame can still be
-- arranged and saved there; Edit Mode applying it again docks it again
-- afterwards.
--
-- In its default place an Edit Mode frame may be a managed frame:
-- Blizzard's bottom container anchors it again on every layout (a buff
-- icon showing is enough). So it is docked again after each of the
-- container's layouts. A frame that is protected is only moved out of
-- combat.

local ns = PadKeys
local c = ns.config.readout
local readout = PadKeysReadout
if not readout then
  return
end

local function editing()
  return EditModeManagerFrame and EditModeManagerFrame.IsEditModeActive and
         EditModeManagerFrame:IsEditModeActive()
end

local redocks = {}

-- Docks `frame` with its `point` at x, y from the pointer, scaled by
-- `scale` against its Edit Mode size.
local function dock_frame(frame, point, x, y, scale)
  -- Blizzard's anchor, as GetPoint gave it before docking.
  local home = {}
  local docked = false
  -- The widget's own SetScale: Edit Mode replaces the frame's method with
  -- its own, which addon code shouldn't run.
  local set_scale = getmetatable(frame).__index.SetScale
  local home_scale
  local waiting = false

  local function blocked()
    return frame:IsProtected() and InCombatLockdown()
  end

  local function remember()
    wipe(home)
    for i = 1, frame:GetNumPoints() do
      home[i] = { frame:GetPoint(i) }
    end
  end

  local function dock()
    if editing() then
      return
    end
    if blocked() then
      waiting = true
      return
    end
    if not docked then
      remember()
      home_scale = frame:GetScale()
    end
    docked = true
    local s = (home_scale or 1) * (scale or 1)
    set_scale(frame, s)
    -- Offsets count in the frame's own scale.
    frame:ClearAllPoints()
    frame:SetPoint(point, readout, "CENTER", x / s, y / s)
  end

  local function undock()
    if not docked or blocked() then
      return
    end
    docked = false
    if home_scale then
      set_scale(frame, home_scale)
    end
    if not home[1] then
      return
    end
    frame:ClearAllPoints()
    for _, p in ipairs(home) do
      frame:SetPoint(unpack(p))
    end
  end

  -- Blizzard placed the frame again (Edit Mode's saved layout, or a
  -- managed container's layout): that is its new home, docked again
  -- unless Edit Mode is open. The scale goes back first, so the home
  -- scale read is Blizzard's, not ours.
  local function redock()
    if blocked() then
      waiting = true
      return
    end
    if docked and home_scale then
      set_scale(frame, home_scale)
    end
    docked = false
    dock()
  end

  if frame.ApplySystemAnchor then
    hooksecurefunc(frame, "ApplySystemAnchor", redock)
  end
  if frame.OnEditModeEnter then
    hooksecurefunc(frame, "OnEditModeEnter", undock)
  end
  if frame.OnEditModeExit then
    hooksecurefunc(frame, "OnEditModeExit", dock)
  end

  redocks[#redocks + 1] = {
    redock = redock,
    start = function()
      if waiting or not docked then
        waiting = false
        redock()
      end
    end,
  }
end

if c.buffs and BuffIconCooldownViewer then
  dock_frame(BuffIconCooldownViewer, c.buffs_point or "BOTTOMLEFT",
             c.buffs_x or 62, c.buffs_y or 62, c.buffs_scale or 0.6)
end
if c.debuffs and DebuffFrame then
  dock_frame(DebuffFrame, c.debuffs_point or "RIGHT",
             c.debuffs_x or -96, c.debuffs_y or 0, c.debuffs_scale or 0.7)
end

if not redocks[1] then
  return
end

-- The managed frame containers: each layout there places frames again.
local container = GetBottomManagedFrameContainer and
                  GetBottomManagedFrameContainer()
for _, frame in ipairs({ container, container and container.BottomManagedLayoutContainer }) do
  if frame and frame.Layout then
    hooksecurefunc(frame, "Layout", function()
      for _, d in ipairs(redocks) do
        d.redock()
      end
    end)
  end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function()
  for _, d in ipairs(redocks) do
    d.start()
  end
end)
