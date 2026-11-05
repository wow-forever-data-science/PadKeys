-- The ring: one secure button with four pages, picked by the key that
-- opens it (Config.lua):
--
-- * actions (G): Action Bar 6, slots 1-8 (drag spells, items, macros there);
-- * pings (Cmd+G): Blizzard's ping types, sent as /ping macros;
-- * markers (Shift+G): target markers, sent as /tm macros;
-- * menu (Ctrl+G): Blizzard's main-menu entries (Menu.lua), several pages
--   turned with Q/E or the mouse wheel while it is open.
--
-- Everything runs through the secure button, so it works in combat and
-- nothing it opens is tainted. The pick happens in a restricted snippet: on
-- key down it notes the mouse position, on key up it turns the direction
-- into a segment (ns.pick_index's rule) and passes the click on as that
-- segment's button ("actions3", "menu2x5"), whose attributes say what to
-- do. The wheel (Wheel.lua) only shows the same pick; it never runs
-- anything.

local ns = PadKeys

BINDING_HEADER_PADKEYS_RADIAL = "PadKeys: radials"
_G["BINDING_NAME_CLICK PadKeysRing:actions"] = "Action radial, Action Bar 6 (hold)"
_G["BINDING_NAME_CLICK PadKeysRing:pings"] = "Ping radial (hold)"
_G["BINDING_NAME_CLICK PadKeysRing:markers"] = "Target marker radial (hold)"
_G["BINDING_NAME_CLICK PadKeysRing:menu"] = "Main menu radial (hold)"

local TITLES = {
  actions = "Actions",
  pings = "Pings",
  markers = "Target markers",
  menu = FRAME_LABEL_MAIN_MENU or MAINMENU_BUTTON,
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
-- button = the page (or a menu page key), down = key down or up. The
-- direction rule is ns.pick_index's.
local ON_CLICK = [[
  if button == "menuprev" or button == "menunext" then
    if down and menu_open then
      local count = self:GetAttribute("menu-pages")
      local step = (button == "menunext") and 1 or -1
      local page = self:GetAttribute("menu-page") + step
      self:SetAttribute("menu-page", (page - 1) % count + 1)
    end
    return false
  end
  if down then
    origin_x, origin_y = owner:GetMousePosition()
    if button == "menu" then
      menu_open = true
      self:SetAttribute("menu-page", self:GetAttribute("menu-start"))
      for key in gmatch(self:GetAttribute("menu-prev-keys"), "[^,]+") do
        owner:SetBindingClick(true, key, "PadKeysRing", "menuprev")
      end
      for key in gmatch(self:GetAttribute("menu-next-keys"), "[^,]+") do
        owner:SetBindingClick(true, key, "PadKeysRing", "menunext")
      end
    end
    return false
  end
  if menu_open then
    menu_open = false
    owner:ClearBindings()
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
  local index = math.floor(degrees / 45 + 0.5) % 8 + 1
  local segment = button .. index
  if button == "menu" then
    segment = "menu" .. self:GetAttribute("menu-page") .. "x" .. index
  end
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
-- doesn't matter. A nil kind empties the segment.
local function set_macro(segment, macro)
  button:SetAttribute("*type-" .. segment, macro and "macro")
  button:SetAttribute("*macrotext-" .. segment, macro)
end

-- The modifier that opened the menu (Ctrl) is still held while paging, so
-- Q arrives as Ctrl+Q: bind each page key with every modifier too.
local MODIFIERS = { "", "CTRL-", "SHIFT-", "ALT-", "META-" }
local function with_modifiers(keys)
  local out = {}
  for _, key in ipairs(keys) do
    for _, modifier in ipairs(MODIFIERS) do
      out[#out + 1] = modifier .. key
    end
  end
  return out
end

local function setup()
  local config = ring_config()
  local menu = ns.config.radial.menu
  header:SetAllPoints(UIParent)
  button:SetAttribute("useOnKeyDown", false)
  button:SetAttribute("dead-zone", ns.config.radial.dead_zone)
  for i = 1, ns.wheel_segments do
    button:SetAttribute("*type-actions" .. i, "action")
    button:SetAttribute("*action-actions" .. i, config.first_slot + i - 1)
    local ping = config.pings[i]
    set_macro("pings" .. i, ping and format(config.ping_macro, ping))
    local marker = config.markers[i]
    set_macro("markers" .. i, marker and format(config.marker_macro, marker))
    for page, names in ipairs(menu.pages) do
      set_macro("menu" .. page .. "x" .. i, names[i] and ns.menu_macro(names[i]))
    end
  end
  button:SetAttribute("menu-start", menu.start_page)
  button:SetAttribute("menu-pages", #menu.pages)
  button:SetAttribute("menu-prev-keys", table.concat(with_modifiers(menu.page_keys.previous), ","))
  button:SetAttribute("menu-next-keys", table.concat(with_modifiers(menu.page_keys.next), ","))
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

local function key_text(keys)
  return keys[1] and GetBindingText(keys[1]) or ""
end

-- The menu page the secure snippet is on.
local function show_menu_page()
  local menu = ns.config.radial.menu
  local page = button:GetAttribute("menu-page") or menu.start_page
  wheel:set_entries(ns.menu_entries(page))
  wheel:set_page(page, #menu.pages, key_text(menu.page_keys.previous),
                 key_text(menu.page_keys.next))
end

local ENTRIES = {
  actions = action_entries,
  pings = ping_entries,
  markers = marker_entries,
}

-- Runs after the secure snippet, with the original button name.
button:HookScript("OnClick", function(_, page, down)
  if page == "menuprev" or page == "menunext" then
    if down and wheel:is_open() then
      show_menu_page()
      if SOUNDKIT.GAMEPAD_RADIAL_MENU_TAB_OVER then
        PlaySound(SOUNDKIT.GAMEPAD_RADIAL_MENU_TAB_OVER)
      end
    end
    return
  end
  if not down then
    wheel:close()
    return
  end
  if page == "menu" then
    wheel:open(TITLES.menu)
    show_menu_page()
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
