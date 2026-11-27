-- Your totems above right of the pointer, over the tracked buffs
-- (Config.lua, readout.totems): one small icon per totem that is down,
-- side by side outside the swing ring, each draining with its time left and
-- the seconds on it. Gone when none are down.
--
-- The time comes as a duration object (GetTotemDuration) into a Cooldown
-- frame's SetCooldownFromDurationObject, the icon from GetTotemInfo into
-- SetTexture: both may be secret and neither is compared. Whether a slot
-- has a totem is GetTotemInfo's haveTotem; if the client hides it, the
-- slot shows while the duration object is accepted. Nothing here is
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
      local have, _, _, _, icon = GetTotemInfo(slot)
      if not is_secret(have) and not have then
        error("no totem")
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

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_TOTEM_UPDATE", "PLAYER_ENTERING_WORLD" }) do
  pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", update)

-- A totem that runs out may not send an event; its cooldown ending does.
for _, f in ipairs(icons) do
  f.cooldown:HookScript("OnCooldownDone", update)
end
