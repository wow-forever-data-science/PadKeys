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
--
-- Debuffs in debuffs_hide (Recently Bandaged) are made invisible there:
-- their icon gets alpha 0, so Blizzard's filter is never replaced. Its
-- slot stays, a gap when other debuffs show. Which icon it is comes from
-- the aura's instance ID, read with pcall; in combat the read may be
-- refused, and then the icon shows until combat ends.

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

-- --- Hidden debuffs ---------------------------------------------------------

local function is_secret(v)
  return issecretvalue and issecretvalue(v)
end

local hide_ids = c.debuffs_hide or {}
if c.debuffs and DebuffFrame and DebuffFrame.auraFrames and hide_ids[1] and
   C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
  -- hidden[auraInstanceID] = true for the debuffs not shown.
  local hidden = {}

  local function read_hidden()
    wipe(hidden)
    for _, id in ipairs(hide_ids) do
      local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, id)
      local instance = ok and aura and aura.auraInstanceID
      if instance and not is_secret(instance) then
        hidden[instance] = true
      end
    end
  end

  local function is_hidden(button)
    local info = button.buttonInfo
    local instance = button.hasValidInfo and info and info.auraInstanceID
    return instance ~= nil and not is_secret(instance) and
           hidden[instance] or false
  end

  -- The widget's own SetAlpha, so the hook below doesn't call itself.
  local buttons = {}
  for _, button in ipairs(DebuffFrame.auraFrames) do
    if not button.isAuraAnchor then
      buttons[#buttons + 1] = button
    end
  end
  local set_alpha = buttons[1] and getmetatable(buttons[1]).__index.SetAlpha

  -- Blizzard sets each icon's alpha as it nears expiry (its warning
  -- flash): a hidden one is set back to 0 right after.
  for _, button in ipairs(buttons) do
    hooksecurefunc(button, "SetAlpha", function(self)
      if is_hidden(self) then
        set_alpha(self, 0)
      end
    end)
  end

  -- After each update of the icons: hide the listed ones, show again an
  -- icon hidden before that now holds another debuff.
  hooksecurefunc(DebuffFrame, "UpdateAuraButtons", function()
    read_hidden()
    for _, button in ipairs(buttons) do
      if is_hidden(button) then
        button.padkeys_hidden = true
        set_alpha(button, 0)
      elseif button.padkeys_hidden then
        button.padkeys_hidden = nil
        set_alpha(button, 1)
      end
    end
  end)
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
