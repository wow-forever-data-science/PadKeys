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

-- Where the tooltip goes: at your aura's icon, as Blizzard's hover puts
-- it, or under the target frame.
local function place_tooltip(group, index)
  if group.unit == "player" then
    local found, icon = pcall(find_icon, _G[group.anchor], index)
    if found and icon then
      GameTooltip:SetOwner(icon, "ANCHOR_BOTTOMLEFT")
      return icon
    end
  end
  local owner = _G[group.anchor] or UIParent
  GameTooltip:SetOwner(owner, group.unit == "target" and "ANCHOR_BOTTOM" or "ANCHOR_BOTTOMLEFT")
  return owner
end

-- Fill the tooltip with the aura at index; false if there is none there
-- (or the tooltip may not show it). The tooltip reads the aura itself, so
-- this also works in combat.
local function fill_tooltip(group, index, label)
  local owner = place_tooltip(group, index)
  local ok = pcall(GameTooltip.SetUnitAura, GameTooltip, group.unit, index, group.filter)
  if not (ok and GameTooltip:NumLines() > 0) then
    GameTooltip:Hide()
    return false
  end
  GameTooltip:AddLine(label, 0.6, 0.6, 0.6)
  GameTooltip:Show()
  shown_owner = owner
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
    UIErrorsFrame:AddMessage("No target.", 1, 0.82, 0)
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
    UIErrorsFrame:AddMessage(group.none, 1, 0.82, 0)
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
