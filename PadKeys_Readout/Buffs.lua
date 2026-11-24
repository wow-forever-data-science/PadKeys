-- Your tracked buffs beside the mouse: Blizzard's Cooldown Manager buff
-- icons (BuffIconCooldownViewer, "Tracked Buffs") are docked to the
-- readout, so they follow the pointer. Which buffs show is the Cooldown
-- Manager's own setting; the icons only show while the buff is on you,
-- with its time left.
--
-- Auras are secret in combat and addon code can't read them; the Cooldown
-- Manager reads them in Blizzard's own code. This never reads an aura or
-- calls Blizzard's code: it only moves the viewer's anchor (ClearAllPoints
-- and SetPoint, plain widget calls). Blizzard's own anchor is kept and put
-- back while Edit Mode is open, so the viewer can still be arranged and
-- saved there; Edit Mode applying it again docks it again afterwards.
--
-- In its default place the viewer is a managed frame: Blizzard's bottom
-- container anchors it again on every layout (a buff icon showing is
-- enough). So it is docked again after each of the container's layouts.

local ns = PadKeys
local c = ns.config.readout

local viewer = BuffIconCooldownViewer
local readout = PadKeysReadout
if not (c.buffs and viewer and readout) then
  return
end

-- Blizzard's anchor, as GetPoint gave it before docking.
local home = {}

local function editing()
  return EditModeManagerFrame and EditModeManagerFrame.IsEditModeActive and
         EditModeManagerFrame:IsEditModeActive()
end

local function remember()
  wipe(home)
  for i = 1, viewer:GetNumPoints() do
    home[i] = { viewer:GetPoint(i) }
  end
end

local docked = false

local function dock()
  if editing() then
    return
  end
  if not docked then
    remember()
  end
  docked = true
  viewer:ClearAllPoints()
  viewer:SetPoint(c.buffs_point or "RIGHT", readout, "CENTER",
                  c.buffs_x or -30, c.buffs_y or 0)
end

local function undock()
  if not docked then
    return
  end
  docked = false
  if not home[1] then
    return
  end
  viewer:ClearAllPoints()
  for _, point in ipairs(home) do
    viewer:SetPoint(unpack(point))
  end
end

-- Edit Mode places the viewer from its saved layout; that is the new
-- home, docked again unless Edit Mode is open.
if viewer.ApplySystemAnchor then
  hooksecurefunc(viewer, "ApplySystemAnchor", function()
    docked = false
    dock()
  end)
end
if viewer.OnEditModeEnter then
  hooksecurefunc(viewer, "OnEditModeEnter", undock)
end
if viewer.OnEditModeExit then
  hooksecurefunc(viewer, "OnEditModeExit", dock)
end

-- The managed frame containers: each layout there places the viewer
-- again, which is its new home.
local function redock()
  docked = false
  dock()
end
local container = GetBottomManagedFrameContainer and
                  GetBottomManagedFrameContainer()
for _, frame in ipairs({ container, container and container.BottomManagedLayoutContainer }) do
  if frame and frame.Layout then
    hooksecurefunc(frame, "Layout", redock)
  end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function()
  if not docked then
    dock()
  end
end)
