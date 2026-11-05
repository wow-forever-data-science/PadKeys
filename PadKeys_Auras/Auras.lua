-- Inspect auras with keys, in combat too. One key per group (Config.lua):
-- your debuffs, your buffs, your target's debuffs, your target's buffs.
-- Like hovering: the tooltip shows while the key is held and goes away on
-- release. Each press shows the next aura of that group, wrapping around,
-- in Blizzard's own aura tooltip (GameTooltip:SetUnitAura, what hovering
-- an aura shows), with a line saying which one it is ("Target debuff 2/5").
-- The shortest time left comes first (the strong effects are usually
-- short), auras without a duration last; after a pause the next press
-- starts at the first again (Config.lua).
--
-- It reads the auras from the unit, not from the aura icons, so it works
-- the same for you and your target (Forever's target aura icons are
-- private frames). The key clicks a plain button: showing a tooltip
-- needs nothing secure.

local ns = PadKeys

BINDING_HEADER_PADKEYS_AURAS = "PadKeys: auras"
_G["BINDING_NAME_CLICK PadKeysAura:mydebuffs"] = "Inspect your next debuff"
_G["BINDING_NAME_CLICK PadKeysAura:mybuffs"] = "Inspect your next buff"
_G["BINDING_NAME_CLICK PadKeysAura:targetdebuffs"] = "Inspect target's next debuff"
_G["BINDING_NAME_CLICK PadKeysAura:targetbuffs"] = "Inspect target's next buff"

-- The click's button name is the group.
local GROUPS = {
  mydebuffs = { unit = "player", filter = "HARMFUL", name = "Your debuff", anchor = "DebuffFrame" },
  mybuffs = { unit = "player", filter = "HELPFUL", name = "Your buff", anchor = "BuffFrame" },
  targetdebuffs = { unit = "target", filter = "HARMFUL", name = "Target debuff", anchor = "TargetFrame" },
  targetbuffs = { unit = "target", filter = "HELPFUL", name = "Target buff", anchor = "TargetFrame" },
}

local MAX_AURAS = 40

-- The last aura shown: its group, its place in the order and when. Kept
-- after release, so the next press of the same key steps on.
local shown_group, shown_index, shown_at

-- The unit's aura indexes in the order to show them.
local function ordered_auras(unit, filter)
  local list, data = {}, {}
  while #list < MAX_AURAS do
    local aura = C_UnitAuras.GetAuraDataByIndex(unit, #list + 1, filter)
    if not aura then
      break
    end
    list[#list + 1] = #list + 1
    data[#list] = aura
  end
  if not ns.config.auras.shortest_first then
    return list
  end
  local now = GetTime()
  local function time_left(index)
    local expires = data[index].expirationTime
    return (expires and expires > 0) and expires - now or math.huge
  end
  -- Aura timers may be hidden from addons in combat (secret values), and
  -- comparing those errors; then keep Blizzard's order.
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

local function hide()
  if GameTooltip:GetOwner() == (shown_group and _G[GROUPS[shown_group].anchor]) then
    GameTooltip:Hide()
  end
end

local function close()
  hide()
  shown_group, shown_index, shown_at = nil, nil, nil
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
  local order = ordered_auras(group.unit, group.filter)
  local n = #order
  if n == 0 then
    close()
    UIErrorsFrame:AddMessage("No " .. group.name:lower() .. "s.", 1, 0.82, 0)
    return
  end
  -- The same key steps on, unless it has rested; another key starts its
  -- group at the first aura.
  local place = 1
  local now = GetTime()
  if shown_group == group_name and shown_index
     and now - shown_at < ns.config.auras.reset_after then
    place = shown_index % n + 1
  end
  shown_group, shown_index, shown_at = group_name, place, now

  local anchor = _G[group.anchor] or UIParent
  GameTooltip:SetOwner(anchor, "ANCHOR_BOTTOMLEFT")
  GameTooltip:SetUnitAura(group.unit, order[place], group.filter)
  GameTooltip:AddLine(format("%s %d/%d", group.name, place, n), 0.6, 0.6, 0.6)
  GameTooltip:Show()
end

-- A new target makes a target aura view stale.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:SetScript("OnEvent", function()
  if shown_group and GROUPS[shown_group].unit == "target" then
    close()
  end
end)

-- The click's button name is the group; key down shows, key up hides.
local button = CreateFrame("Button", "PadKeysAura", UIParent)
button:RegisterForClicks("AnyDown", "AnyUp")
button:SetScript("OnClick", function(_, group, down)
  if down then
    show(group)
  else
    hide()
  end
end)
