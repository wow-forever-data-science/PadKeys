-- The main-menu radial (Ctrl+G). The entries are Blizzard's: their labels,
-- icons, enabled state and actions come from GamepadRadial's own table of
-- segment handlers (Forever's Blizzard_Gamepad addon), so they do what the
-- gamepad's do. The wheel is ours (Wheel.lua):
--
-- * hold the menu key: show it, on the start page;
-- * move the mouse: the direction picks a segment;
-- * page keys while open (out of combat): previous / next page;
-- * release: close, and run the picked segment.
--
-- In combat it opens on the start page only: the page keys are override
-- bindings, which combat blocks. Entries Blizzard blocks in combat show
-- greyed out.

local ns = PadKeys

BINDING_HEADER_PADKEYS_RADIAL = "PadKeys: radials"
BINDING_NAME_PADKEYS_RADIAL = "Main menu radial (hold)"

local wheel = ns.create_wheel("PadKeysMenuRadial")
local owner = CreateFrame("Frame", "PadKeysRadialOwner", UIParent)
local page

local function handlers()
  return GamepadRadial and GamepadRadial.segmentOptions
end

-- The icon Blizzard's segment would show (BasicSegmentHandler:UpdateIcon).
local function icon_of(handler)
  local icons = handler.icons
  if not icons then
    return handler.icon, not handler:IsEnabled()
  end
  if not handler:IsEnabled() then
    return icons.disabled or icons.up, icons.disabled == nil
  elseif handler:IsDown() then
    return icons.down or icons.up, false
  end
  return icons.up, false
end

local function key_text(keys)
  return keys[1] and GetBindingText(keys[1]) or ""
end

local function show_page(index)
  local config = ns.config.radial.menu
  local pages = config.pages
  page = (index - 1) % #pages + 1
  local options = handlers()
  local entries = {}
  for i = 1, ns.wheel_segments do
    local name = pages[page][i]
    local handler = name and options[name]
    if handler then
      local icon, desaturate = icon_of(handler)
      entries[i] = {
        icon = icon,
        desaturate = desaturate,
        label = handler:GetLabel(),
        enabled = handler:IsEnabled(),
        handler = handler,
      }
    end
  end
  wheel:set_entries(entries)
  local count = InCombatLockdown() and 1 or #pages
  wheel:set_page(page, count, key_text(config.page_keys.previous),
                 key_text(config.page_keys.next))
end

local function page_button(name, step)
  local button = CreateFrame("Button", name, UIParent)
  button:RegisterForClicks("AnyDown")
  button:SetScript("OnClick", function()
    show_page(page + step)
    PlaySound(SOUNDKIT.GAMEPAD_RADIAL_MENU_TAB_OVER)
  end)
end
page_button("PadKeysRadialPrev", -1)
page_button("PadKeysRadialNext", 1)

local function open()
  if wheel:is_open() then
    return
  end
  if not handlers() then
    ns.say("the menu radial needs Blizzard's gamepad UI (Blizzard_Gamepad), which isn't loaded.")
    return
  end
  local config = ns.config.radial.menu
  wheel:open(FRAME_LABEL_MAIN_MENU or MAINMENU_BUTTON)
  show_page(config.start_page)
  if not InCombatLockdown() then
    for _, key in ipairs(config.page_keys.previous) do
      SetOverrideBindingClick(owner, true, key, "PadKeysRadialPrev")
    end
    for _, key in ipairs(config.page_keys.next) do
      SetOverrideBindingClick(owner, true, key, "PadKeysRadialNext")
    end
  end
end

local function release()
  if not wheel:is_open() then
    return
  end
  local index = wheel:picked()
  local handler = index and wheel.entries[index].handler
  wheel:close()
  if handler then
    handler:Trigger()
  end
end

wheel.frame:HookScript("OnHide", function()
  if not InCombatLockdown() then
    ClearOverrideBindings(owner)
  end
end)

-- Combat starting with the radial open must not leave Q/E paging it:
-- PLAYER_REGEN_DISABLED comes just before the lockdown, so the page keys
-- can still be cleared then.
owner:RegisterEvent("PLAYER_REGEN_DISABLED")
owner:SetScript("OnEvent", function()
  ClearOverrideBindings(owner)
  if wheel:is_open() then
    show_page(page)
  end
end)

-- Called by the PADKEYS_RADIAL binding on key down and key up.
function ns.radial_key(keystate)
  if keystate == "down" then
    open()
  else
    release()
  end
end
