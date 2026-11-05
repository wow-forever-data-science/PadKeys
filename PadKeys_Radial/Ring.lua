-- The combat ring: one secure button with three pages, picked by the key
-- that opens it (G, Cmd+G, Shift+G in Config.lua):
--
-- * actions: Action Bar 6, slots 1-8 (drag spells, items, macros there);
-- * pings: Blizzard's ping types, sent as /ping macros;
-- * markers: target markers, sent as /tm macros.
--
-- Spells and macros in combat must go through a secure button, so the pick
-- happens in a restricted snippet: on key down it notes the mouse position,
-- on key up it turns the direction into a segment (ns.pick_index's rule)
-- and passes the click on as that segment's button ("actions3"), whose
-- attributes say what to do. The wheel (Wheel.lua) only shows the same
-- pick; it never casts anything.

local ns = PadKeys

_G["BINDING_NAME_CLICK PadKeysRing:actions"] = "Action radial, Action Bar 6 (hold)"
_G["BINDING_NAME_CLICK PadKeysRing:pings"] = "Ping radial (hold)"
_G["BINDING_NAME_CLICK PadKeysRing:markers"] = "Target marker radial (hold)"

local TITLES = {
  actions = "Actions",
  pings = "Pings",
  markers = "Target markers",
}

-- Ping names in Config.lua -> Enum.PingSubjectType key and label global.
local PINGS = {
  attack = { "Attack", "PING_TYPE_ATTACK" },
  warning = { "Warning", "PING_TYPE_WARNING" },
  assist = { "Assist", "PING_TYPE_ASSIST" },
  onmyway = { "OnMyWay", "PING_TYPE_ON_MY_WAY" },
}

-- Runs in the restricted environment: self = the ring button, owner = the
-- header (as large as the screen, so GetMousePosition always answers),
-- button = the page, down = key down or up. Same rule as ns.pick_index.
local ON_CLICK = [[
  if down then
    origin_x, origin_y = owner:GetMousePosition()
    return false
  end
  local x, y = owner:GetMousePosition()
  local ox, oy = origin_x, origin_y
  origin_x, origin_y = nil, nil
  if not (x and ox) then
    return false
  end
  local dx = (x - ox) * owner:GetWidth()
  local dy = (y - oy) * owner:GetHeight()
  local dead_zone = self:GetAttribute("dead-zone")
  if dx * dx + dy * dy < dead_zone * dead_zone then
    return false
  end
  local degrees = math.deg(math.atan2(dy, dx)) % 360
  local segment = button .. (math.floor(degrees / 45 + 0.5) % 8 + 1)
  if not self:GetAttribute("*type-" .. segment) then
    return false
  end
  return segment
]]

local header = CreateFrame("Frame", "PadKeysRingHeader", UIParent,
                           "SecureHandlerBaseTemplate")
local button = CreateFrame("Button", "PadKeysRing", UIParent,
                           "SecureActionButtonTemplate")
button:RegisterForClicks("AnyDown", "AnyUp")
SecureHandlerWrapScript(button, "OnClick", header, ON_CLICK)

local wheel = ns.create_wheel("PadKeysRingRadial")

local function ring_config()
  return ns.config.radial.ring
end

-- What each segment does, as attributes of its button name ("pings1").
-- The "*" matches any modifier, so Cmd or Shift still held on release
-- doesn't matter.
local function set_segment(segment, kind, key, value)
  button:SetAttribute("*type-" .. segment, kind)
  if key then
    button:SetAttribute("*" .. key .. "-" .. segment, value)
  end
end

local function setup()
  local config = ring_config()
  header:SetAllPoints(UIParent)
  button:SetAttribute("useOnKeyDown", false)
  button:SetAttribute("dead-zone", ns.config.radial.dead_zone)
  for i = 1, ns.wheel_segments do
    set_segment("actions" .. i, "action", "action", config.first_slot + i - 1)
    local ping = config.pings[i]
    if ping then
      set_segment("pings" .. i, "macro", "macrotext", format(config.ping_macro, ping))
    else
      set_segment("pings" .. i, nil)
    end
    local marker = config.markers[i]
    if marker then
      set_segment("markers" .. i, "macro", "macrotext", format(config.marker_macro, marker))
    else
      set_segment("markers" .. i, nil)
    end
  end
end

-- Wheel entries per page.

local ab = C_ActionBar

local function action_name(slot)
  local kind, id = GetActionInfo(slot)
  if kind == "spell" and id then
    return C_Spell.GetSpellName(id)
  elseif kind == "item" and id then
    return C_Item.GetItemNameByID(id)
  end
  return ab.GetActionText(slot)
end

-- No usable or cooldown state yet: icon and name only.
local function action_entries()
  local entries = {}
  local first = ring_config().first_slot
  for i = 1, ns.wheel_segments do
    local slot = first + i - 1
    if ab.HasAction(slot) then
      entries[i] = {
        icon = ab.GetActionTexture(slot),
        label = action_name(slot),
        enabled = true,
      }
    end
  end
  return entries
end

local function ping_icon(enum_key)
  local kind = Enum.PingSubjectType and Enum.PingSubjectType[enum_key]
  if not (kind and C_Ping and C_Ping.GetDefaultPingOptions) then
    return nil
  end
  for _, option in ipairs(C_Ping.GetDefaultPingOptions()) do
    if option.type == kind then
      return "Ping_Wheel_Icon_" .. tostring(option.uiTextureKitID or "")
    end
  end
end

local function ping_entries()
  local entries = {}
  for i, name in pairs(ring_config().pings) do
    local ping = name and PINGS[name]
    if ping then
      entries[i] = { icon = ping_icon(ping[1]), label = _G[ping[2]] or name, enabled = true }
    end
  end
  return entries
end

local function marker_entries()
  local entries = {}
  for i, marker in pairs(ring_config().markers) do
    if marker then
      entries[i] = {
        icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. marker,
        label = _G["RAID_TARGET_" .. marker],
        enabled = true,
      }
    end
  end
  return entries
end

local ENTRIES = {
  actions = action_entries,
  pings = ping_entries,
  markers = marker_entries,
}

-- Runs after the secure snippet, with the original page name.
button:HookScript("OnClick", function(_, page, down)
  if not down then
    wheel:close()
    return
  end
  local entries = ENTRIES[page]
  if not entries then
    return
  end
  wheel:open(TITLES[page])
  wheel:set_entries(entries())
  wheel:set_page(1, 1)
  if page == "actions" and not next(wheel.entries) then
    wheel.label:SetText("Put spells, items or macros on Action Bar 6")
  end
end)

-- Attributes of protected frames can't change in combat, e.g. after a
-- /reload mid-fight.
if InCombatLockdown() then
  header:RegisterEvent("PLAYER_REGEN_ENABLED")
  header:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    setup()
  end)
else
  setup()
end
