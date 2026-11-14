-- The ring: one secure button with four pages, picked by the key that
-- opens it (Config.lua):
--
-- * actions (G): Action Bar 6, slots 1-8 (drag spells, items, macros there);
-- * extra (Cmd+G): Action Bar 7, slots 1-8, the same way;
-- * markers (Shift+G): target markers, sent as /tm macros;
-- * menu (Ctrl+G): Blizzard's main-menu entries (Menu.lua), several pages
--   turned with the mouse wheel while it is open.
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
_G["BINDING_NAME_CLICK PadKeysRing:extra"] = "Second action radial, Action Bar 7 (hold)"
_G["BINDING_NAME_CLICK PadKeysRing:markers"] = "Target marker radial (hold)"
_G["BINDING_NAME_CLICK PadKeysRing:menu"] = "Main menu radial (hold)"

local TITLES = {
  actions = "Actions",
  extra = "More actions",
  markers = "Target markers",
  menu = FRAME_LABEL_MAIN_MENU or MAINMENU_BUTTON,
}

-- Runs in the restricted environment: self = the ring button, owner = the
-- header (as large as the screen, so GetMousePosition always answers),
-- button = the page, down = key down or up. The
-- direction rule is ns.pick_index's.
local ON_CLICK = [[
  if down then
    origin_x, origin_y = owner:GetMousePosition()
    if button == "menu" then
      self:SetAttribute("menu-open", true)
      self:SetAttribute("menu-page", self:GetAttribute("menu-start"))
      for key in gmatch(self:GetAttribute("menu-prev-keys"), "[^,]+") do
        owner:SetBindingClick(true, key, "PadKeysRingPage", "previous")
      end
      for key in gmatch(self:GetAttribute("menu-next-keys"), "[^,]+") do
        owner:SetBindingClick(true, key, "PadKeysRingPage", "next")
      end
    end
    return false
  end
  if self:GetAttribute("menu-open") then
    self:SetAttribute("menu-open", false)
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

-- Menu paging: its own button, so a page turn is never a second click on
-- the ring while Ctrl+G still holds it down (paging through the ring
-- itself lost the pick on the turned-to pages). The open menu binds the
-- page keys to it; it only moves the ring's "menu-page".
local PAGE_CLICK = [[
  local ring = self:GetFrameRef("ring")
  if down and ring:GetAttribute("menu-open") then
    local count = ring:GetAttribute("menu-pages")
    local step = (button == "next") and 1 or -1
    local page = ring:GetAttribute("menu-page") + step
    ring:SetAttribute("menu-page", (page - 1) % count + 1)
  end
  return false
]]

local pager = CreateFrame("Button", "PadKeysRingPage", UIParent,
                          "SecureActionButtonTemplate")
pager:RegisterForClicks("AnyDown")
SecureHandlerSetFrameRef(pager, "ring", button)
SecureHandlerWrapScript(pager, "OnClick", header, PAGE_CLICK)

local wheel = ns.create_wheel("PadKeysRingRadial")

local function ring_config()
  return ns.config.radial.ring
end

-- What each segment does, as attributes of its button name ("markers1").
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
    button:SetAttribute("*type-extra" .. i, "action")
    button:SetAttribute("*action-extra" .. i, config.extra_first_slot + i - 1)
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

-- Which ring slots are only on the global cooldown, so a cast doesn't dim
-- the whole page. Blizzard's isOnGCD flag is only right while handling
-- SPELL_UPDATE_COOLDOWN (as PadKeys_Bar found), so it is read then.
local on_gcd = {}
local function read_gcd()
  local config = ring_config()
  for _, first in ipairs({ config.first_slot, config.extra_first_slot }) do
    for slot = first, first + ns.wheel_segments - 1 do
      local cd = ab.HasAction(slot) and ab.GetActionCooldown(slot)
      on_gcd[slot] = cd and cd.isOnGCD or nil
    end
  end
end

-- The countdown, as on the PadKeys bar: the global cooldown alone shows
-- nothing; a spell out of charges is on cooldown (dimmed); one recharging
-- with charges left shows the recharge time but stays solid. Only plain
-- flags (isActive) are tested; the numbers stay in duration objects.
local function slot_cooldown(slot)
  local cd = ab.GetActionCooldown(slot)
  if cd and cd.isActive and not on_gcd[slot] then
    return ab.GetActionCooldownDuration(slot, true), true
  end
  local charges = ab.GetActionCharges and ab.GetActionCharges(slot)
  if charges and charges.isActive then
    return ab.GetActionChargeDuration(slot), false
  end
  return nil, false
end

local function slot_entries(first)
  local entries = {}
  for i = 1, ns.wheel_segments do
    local slot = first + i - 1
    if ab.HasAction(slot) then
      local cooldown, cooling = slot_cooldown(slot)
      entries[i] = {
        icon = ab.GetActionTexture(slot),
        label = action_name(slot),
        enabled = true,
        cooldown = cooldown,
        cooling = cooling,
      }
    end
  end
  return entries
end

local function action_entries()
  return slot_entries(ring_config().first_slot)
end

local function extra_entries()
  return slot_entries(ring_config().extra_first_slot)
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

-- The page hint beside the dots: the first page key, short for the wheel.
local function key_text(keys)
  local key = keys[1]
  if key == "MOUSEWHEELUP" then
    return "Scroll up"
  elseif key == "MOUSEWHEELDOWN" then
    return "Scroll down"
  end
  return key and GetBindingText(key) or ""
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
  extra = extra_entries,
  markers = marker_entries,
}

-- Runs after the paging snippet: show the page it moved to.
pager:HookScript("OnClick", function(_, _, down)
  if down and wheel:is_open() then
    show_menu_page()
    if SOUNDKIT.GAMEPAD_RADIAL_MENU_TAB_OVER then
      PlaySound(SOUNDKIT.GAMEPAD_RADIAL_MENU_TAB_OVER)
    end
  end
end)

-- The page the open wheel shows ("actions"), or nil.
local shown_page

-- Runs after the secure snippet, with the original button name.
button:HookScript("OnClick", function(_, page, down)
  if not down then
    shown_page = nil
    wheel:close()
    return
  end
  shown_page = page
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
  if not next(wheel.entries) then
    if page == "actions" then
      wheel.label:SetText("Put spells, items or macros on Action Bar 6")
    elseif page == "extra" then
      wheel.label:SetText("Put spells, items or macros on Action Bar 7")
    end
  end
end)

-- Cooldowns that start or end while an action page is open (a cast, the
-- end of the global cooldown) show at once.
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("SPELL_UPDATE_COOLDOWN")
watcher:RegisterEvent("SPELL_UPDATE_CHARGES")
watcher:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
watcher:SetScript("OnEvent", function(_, event)
  if event == "SPELL_UPDATE_COOLDOWN" then
    read_gcd()
  end
  if wheel:is_open() and (shown_page == "actions" or shown_page == "extra") then
    wheel:set_entries(ENTRIES[shown_page]())
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
