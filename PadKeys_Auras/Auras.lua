-- Inspect auras with keys, in combat too. One key per group (Config.lua):
-- your debuffs, your buffs, your target's debuffs, your target's buffs.
-- A press shows the tooltip at the aura, as hovering it would, and it fades
-- after a few seconds (Config.lua). Each press shows the next aura of that
-- group, wrapping around,
-- in Blizzard's own aura tooltip (GameTooltip:SetUnitAura, what hovering
-- an aura shows), with a line saying which one it is ("Target debuff 2/5").
-- Out of combat the shortest time left comes first (the strong effects
-- are usually short), auras without a duration last. In combat the auras
-- are secret to addons, so it steps in Blizzard's order and lets the
-- tooltip read them. After a pause the next press starts at the first
-- again (Config.lua).
--
-- It reads the auras from the unit, not from the aura icons, so it works
-- the same for you and your target (Forever's target aura icons are
-- private frames). Your own auras' tooltips sit at their icon; the
-- target's icons are forbidden frames, so its tooltips sit under the
-- target frame. The key clicks a plain button: showing a tooltip needs
-- nothing secure.
--
-- Your own aura shown is also marked on its icon: a white frame that
-- pulses like the cursor's window glow and fades with the tooltip. The
-- target's icons are forbidden frames, so nothing can be anchored to them;
-- for those the tooltip's label ("Target debuff 2/5") says which one.

local ns = PadKeys

BINDING_HEADER_PADKEYS_AURAS = "PadKeys: auras"
_G["BINDING_NAME_CLICK PadKeysAura:mydebuffs"] = "Inspect your next debuff"
_G["BINDING_NAME_CLICK PadKeysAura:mybuffs"] = "Inspect your next buff"
_G["BINDING_NAME_CLICK PadKeysAura:targetdebuffs"] = "Inspect target's next debuff"
_G["BINDING_NAME_CLICK PadKeysAura:targetbuffs"] = "Inspect target's next buff"

-- The click's button name is the group.
local GROUPS = {
  mydebuffs = { unit = "player", filter = "HARMFUL", name = "Your debuff", none = "You have no debuffs.", anchor = "DebuffFrame" },
  mybuffs = { unit = "player", filter = "HELPFUL", name = "Your buff", none = "You have no buffs.", anchor = "BuffFrame" },
  targetdebuffs = { unit = "target", filter = "HARMFUL", name = "Target debuff", none = "Your target has no debuffs.", anchor = "TargetFrame" },
  targetbuffs = { unit = "target", filter = "HELPFUL", name = "Target buff", none = "Your target has no buffs.", anchor = "TargetFrame" },
}

local MAX_AURAS = 40

-- The last aura shown: its group, its place in the order, when, and the
-- tooltip's owner. Kept after it fades, so the next press steps on.
local shown_group, shown_place, shown_at, shown_owner
-- Counts shows, so a fade timer only hides its own tooltip.
local shows = 0
-- The tooltip's owner, placed at the aura. Blizzard's aura icons refresh
-- a tooltip they own every frame, which would undo the fade, so the icon
-- is only the anchor.
local tooltip_owner = CreateFrame("Frame", nil, UIParent)

-- The marker: four white edges just outside the icon, pulsing. It follows
-- the tooltip's alpha, so it fades with it, and hides when the tooltip
-- goes or shows something else.
local marker = CreateFrame("Frame", nil, UIParent)
marker:SetFrameStrata("TOOLTIP")
marker:Hide()
local EDGE = 2
local function marker_edge(p1, r1, x1, y1, p2, r2, x2, y2)
  local tex = marker:CreateTexture(nil, "OVERLAY")
  tex:SetColorTexture(1, 1, 1)
  tex:SetPoint(p1, marker, r1, x1, y1)
  tex:SetPoint(p2, marker, r2, x2, y2)
end
marker_edge("BOTTOMLEFT", "TOPLEFT", -EDGE, 0, "TOPRIGHT", "TOPRIGHT", EDGE, EDGE)
marker_edge("TOPLEFT", "BOTTOMLEFT", -EDGE, 0, "BOTTOMRIGHT", "BOTTOMRIGHT", EDGE, -EDGE)
marker_edge("TOPRIGHT", "TOPLEFT", 0, 0, "BOTTOMLEFT", "BOTTOMLEFT", -EDGE, 0)
marker_edge("TOPLEFT", "TOPRIGHT", 0, 0, "BOTTOMRIGHT", "BOTTOMRIGHT", EDGE, 0)
local pulse_time = 0
marker:SetScript("OnShow", function() pulse_time = 0 end)
marker:SetScript("OnUpdate", function(self, elapsed)
  if not GameTooltip:IsShown() or GameTooltip:GetOwner() ~= tooltip_owner then
    self:Hide()
    return
  end
  pulse_time = (pulse_time + elapsed) % 1.2
  local pulse = 0.7 + 0.3 * math.cos(pulse_time / 1.2 * 2 * math.pi)
  self:SetAlpha(GameTooltip:GetAlpha() * pulse)
end)

local function mark(icon)
  if not icon then
    marker:Hide()
    return
  end
  marker:ClearAllPoints()
  marker:SetAllPoints(icon.Icon or icon)
  marker:Show()
end

-- The unit's aura indexes in the order to show them, or nil when they
-- can't be read: in combat auras are secret, and reading them errors.
local function ordered_auras(unit, filter)
  local list, data = {}, {}
  local readable = pcall(function()
    while #list < MAX_AURAS do
      local aura = C_UnitAuras.GetAuraDataByIndex(unit, #list + 1, filter)
      if not aura then
        break
      end
      list[#list + 1] = #list + 1
      data[#list] = aura
    end
  end)
  if not readable then
    return nil
  end
  if not ns.config.auras.shortest_first then
    return list
  end
  local now = GetTime()
  local function time_left(index)
    local expires = data[index].expirationTime
    return (expires and expires > 0) and expires - now or math.huge
  end
  -- If the timers are secret after all, comparing them errors; then keep
  -- Blizzard's order.
  local sorted = { unpack(list) }
  local ok = pcall(table.sort, sorted, function(a, b)
    local ta, tb = time_left(a), time_left(b)
    if ta ~= tb then
      return ta < tb
    end
    return a < b
  end)
  return ok and sorted or list
end

-- Your aura's icon in BuffFrame / DebuffFrame (Blizzard's buttons keep
-- the aura index in buttonInfo.index), or nil.
local function find_icon(frame, index)
  for _, icon in ipairs(frame and frame.auraFrames or {}) do
    local info = icon.buttonInfo
    if icon:IsShown() and info and icon.auraType ~= "TempEnchant"
       and info.index == index then
      return icon
    end
  end
end

-- Where the tooltip goes: at your aura's icon (below left, as Blizzard's
-- hover puts it), or under the target frame.
-- Returns your aura's icon, if found.
local function place_tooltip(group, index)
  GameTooltip:SetOwner(tooltip_owner, "ANCHOR_NONE")
  GameTooltip:ClearAllPoints()
  if group.unit == "player" then
    local found, icon = pcall(find_icon, _G[group.anchor], index)
    if found and icon then
      GameTooltip:SetPoint("TOPRIGHT", icon, "BOTTOMLEFT")
      return icon
    end
  end
  local anchor = _G[group.anchor] or UIParent
  if group.unit == "target" then
    GameTooltip:SetPoint("TOP", anchor, "BOTTOM")
  else
    GameTooltip:SetPoint("TOPRIGHT", anchor, "BOTTOMLEFT")
  end
end

-- Fill the tooltip with the aura at index; false if there is none there
-- (or the tooltip may not show it). The tooltip reads the aura itself, so
-- this also works in combat.
local function fill_tooltip(group, index, label)
  local icon = place_tooltip(group, index)
  local ok = pcall(GameTooltip.SetUnitAura, GameTooltip, group.unit, index, group.filter)
  if not (ok and GameTooltip:NumLines() > 0) then
    GameTooltip:Hide()
    return false
  end
  GameTooltip:AddLine(label, 0.6, 0.6, 0.6)
  GameTooltip:Show()
  mark(icon)
  shown_owner = tooltip_owner
  return true
end

local function hide()
  if shown_owner and GameTooltip:GetOwner() == shown_owner then
    GameTooltip:Hide()
  end
end

local function close()
  hide()
  shown_group, shown_place, shown_at, shown_owner = nil, nil, nil, nil
end

-- Fade the tooltip after show_for seconds, unless another press came.
local function fade_later()
  shows = shows + 1
  local this_show = shows
  C_Timer.After(ns.config.auras.show_for, function()
    if this_show ~= shows or GameTooltip:GetOwner() ~= shown_owner then
      return
    end
    if GameTooltip.FadeOut then
      GameTooltip:FadeOut()
    else
      GameTooltip:Hide()
    end
  end)
end

-- The place shown, or nil if there was nothing to show.
local function show_next(group, place)
  local order = ordered_auras(group.unit, group.filter)
  if order then
    local n = #order
    if n == 0 then
      return nil
    end
    place = (place - 1) % n + 1
    local label = format("%s %d/%d", group.name, place, n)
    return fill_tooltip(group, order[place], label) and place or nil
  end
  -- Unreadable (combat): Blizzard's order, without a total; past the last
  -- aura the tooltip comes back empty, and it wraps to the first.
  if fill_tooltip(group, place, format("%s %d", group.name, place)) then
    return place
  end
  if place > 1 and fill_tooltip(group, 1, format("%s %d", group.name, 1)) then
    return 1
  end
  return nil
end

local function show(group_name)
  local group = GROUPS[group_name]
  if not group then
    return
  end
  if group.unit == "target" and not UnitExists("target") then
    close()
    ns.flash("No target.")
    return
  end
  -- The same key steps on, unless it has rested; another key starts its
  -- group at the first aura.
  local now = GetTime()
  local place = 1
  if shown_group == group_name and shown_place
     and now - shown_at < ns.config.auras.reset_after then
    place = shown_place + 1
  end
  local shown = show_next(group, place)
  if not shown then
    close()
    ns.flash(group.none)
    return
  end
  shown_group, shown_place, shown_at = group_name, shown, now
  fade_later()
end

-- A new target makes a target aura view stale.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:SetScript("OnEvent", function()
  if shown_group and GROUPS[shown_group].unit == "target" then
    close()
  end
end)

-- The click's button name is the group.
local button = CreateFrame("Button", "PadKeysAura", UIParent)
button:RegisterForClicks("AnyDown")
button:SetScript("OnClick", function(_, group)
  show(group)
end)
