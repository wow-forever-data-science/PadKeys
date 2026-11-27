-- Your totems above right of the pointer, over the tracked buffs
-- (Config.lua, readout.totems): one small icon per totem that is down,
-- side by side outside the swing ring, each draining with its time left and
-- the seconds on it. Gone when none are down. With no tracked buff
-- showing they take the buffs' corner on the swing ring instead of
-- floating above it (above_buffs): the tracked buffs' top is read from
-- their frame, a plain value.
--
-- The time comes as a duration object (GetTotemDuration) into a Cooldown
-- frame's SetCooldownFromDurationObject, the icon from GetTotemInfo into
-- SetTexture: both may be secret and neither is compared. Whether a slot
-- has a totem is GetTotemInfo's haveTotem; if the client hides it, the
-- slot shows while the duration object is accepted. A slot held with no
-- icon or no duration (a summon that never runs out) is left out. Nothing here is
-- secure, and nothing takes the mouse.

local ns = PadKeys
local c = ns.config.readout
local t = c.totems
local readout = PadKeysReadout
if not (t and t.enabled and readout and GetTotemInfo) then
  return
end

local size = t.icon_size or 22
local gap = t.gap or 3
local slots = (GetNumTotemSlots and GetNumTotemSlots()) or 4

local function is_secret(v)
  return issecretvalue and issecretvalue(v)
end

local row = CreateFrame("Frame", nil, readout)
local point = t.point or "BOTTOMLEFT"
row:SetSize(1, size)
row:SetPoint(point, readout, "CENTER", t.x or 62, t.y or 96)
row:EnableMouse(false)

local icons = {}
for i = 1, slots do
  local f = CreateFrame("Frame", nil, row)
  f:SetSize(size, size)
  ns.box(f, 0, c.rounded)
  f.icon = f:CreateTexture(nil, "ARTWORK")
  ns.fit_icon(f, f.icon)
  if c.rounded then
    ns.round(f, f.icon, 1)
  end
  ns.icon(f.icon)
  f.cooldown = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
  f.cooldown:SetPoint("TOPLEFT", 1, -1)
  f.cooldown:SetPoint("BOTTOMRIGHT", -1, 1)
  f.cooldown:SetDrawEdge(false)
  f.cooldown:SetDrawBling(false)
  f.cooldown:SetReverse(true)
  f.cooldown:SetSwipeColor(0, 0, 0, 0.6)
  f.cooldown:SetHideCountdownNumbers(not t.countdown)
  local countdown = f.cooldown.GetCountdownFontString and
    f.cooldown:GetCountdownFontString()
  if countdown then
    ns.style(countdown, t.countdown_size or 11)
  end
  f:Hide()
  icons[i] = f
end

local function update()
  local shown = {}
  for slot = 1, slots do
    local f = icons[slot]
    local ok = pcall(function()
      local have, _, _, duration, icon = GetTotemInfo(slot)
      if not is_secret(have) and not have then
        error("no totem")
      end
      -- A slot held with no icon and no time (a hunter's summoned hawk:
      -- true, nil, start, 0, nil) would be an empty black box.
      if (not is_secret(icon) and not icon) or
         (not is_secret(duration) and duration == 0) then
        error("nothing to show")
      end
      f.icon:SetTexture(icon)
      f.cooldown:SetCooldownFromDurationObject(GetTotemDuration(slot))
    end)
    f:SetShown(ok)
    if ok then
      shown[#shown + 1] = f
    else
      f.cooldown:Clear()
    end
  end
  -- In slot order (earth, fire, water, air), growing right from a LEFT
  -- point, left from a RIGHT one, else centred on it.
  local width = #shown * size + math.max(#shown - 1, 0) * gap
  local start = -width / 2
  if point:find("LEFT") then
    start = 0
  elseif point:find("RIGHT") then
    start = -width
  end
  for i, f in ipairs(shown) do
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", row, "TOPLEFT", start + (i - 1) * (size + gap), 0)
  end
end

-- Whether a frame has a shown descendant within `depth` levels: an empty
-- Cooldown Manager viewer stays shown with its icons hidden.
local function any_shown(frame, depth)
  for _, child in ipairs({ frame:GetChildren() }) do
    if child:IsShown() and (depth <= 1 or child:GetNumChildren() == 0 or
                            any_shown(child, depth - 1)) then
      return true
    end
  end
  return false
end

-- Just above the tracked buffs while one shows, else at x, y.
local viewer = c.buffs and t.above_buffs and BuffIconCooldownViewer
local function place()
  local y = t.y or 96
  if viewer and viewer:IsVisible() and any_shown(viewer, 2) then
    local top = viewer:GetTop()
    local _, cy = readout:GetCenter()
    if top and cy then
      y = top * viewer:GetEffectiveScale() / readout:GetEffectiveScale() - cy + gap
    end
  end
  row:ClearAllPoints()
  row:SetPoint(point, readout, "CENTER", t.x or 62, y)
end

-- Placed again while a totem shows: the tracked buffs come and go on
-- their own.
local PLACE_INTERVAL = 0.1
local since = 0
row:SetScript("OnUpdate", function(_, elapsed)
  since = since + elapsed
  if since >= PLACE_INTERVAL then
    since = 0
    pcall(place)
  end
end)

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_TOTEM_UPDATE", "PLAYER_ENTERING_WORLD" }) do
  pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", update)

-- A totem that runs out may not send an event; its cooldown ending does.
for _, f in ipairs(icons) do
  f.cooldown:HookScript("OnCooldownDone", update)
end
