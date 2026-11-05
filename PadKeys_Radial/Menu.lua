-- The main-menu page of the ring (Ctrl+G): what each entry looks like and
-- how it opens. The looks (label, icon, enabled state) come from Blizzard's
-- gamepad radial (GamepadRadial's segment handlers in Forever's
-- Blizzard_Gamepad addon). The opening does not call those handlers: from
-- addon code their windows open tainted, and tainted Blizzard code errors
-- on the client's secret values (health and the like). Instead each entry
-- is a /click of Blizzard's own button, run by the ring's secure button.

local ns = PadKeys

-- Entry -> the Blizzard button it clicks. Entries of Blizzard's radial
-- without a button (social, chat, tracking) are left out.
local BUTTONS = {
  bags = "MainMenuBarBackpackButton",
  buffs = "PadKeysRadialBuffs",
  calendar = "GameTimeFrame",
  character = "CharacterMicroButton",
  collections = "CollectionsMicroButton",
  guild = "GuildMicroButton",
  legacy = "LegacyMicroButton",
  lfd = "LFDMicroButton",
  map = "QuestLogMicroButton",
  menu = "MainMenuMicroButton",
  professions = "ProfessionMicroButton",
  spellbook = "SpellbookMicroButton",
  store = "StoreMicroButton",
  talents = "TalentMicroButton",
  time = "TimeManagerClockButton",
}
-- Entries that are a slash command instead.
local COMMANDS = {
  pvp = "/pvp",
}

-- Buffs: Blizzard's entry calls BuffFrame:SetGamepadFocus(), which
-- PadKeys_Cursor turns into the UI cursor on your auras. Our own button,
-- so it can be clicked like the others.
local buffs = CreateFrame("Button", "PadKeysRadialBuffs", UIParent)
buffs:SetScript("OnClick", function()
  if not BuffFrame:SetGamepadFocus() then
    DebuffFrame:SetGamepadFocus()
  end
end)

-- The macro that opens an entry, or nil for an unknown entry.
function ns.menu_macro(name)
  if BUTTONS[name] then
    return "/click " .. BUTTONS[name]
  end
  return COMMANDS[name]
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

-- Wheel entries for one menu page.
function ns.menu_entries(page)
  local handlers = GamepadRadial and GamepadRadial.segmentOptions or {}
  local entries = {}
  for i = 1, ns.wheel_segments do
    local name = ns.config.radial.menu.pages[page][i]
    local handler = name and handlers[name]
    if handler and ns.menu_macro(name) then
      local icon, desaturate = icon_of(handler)
      entries[i] = {
        icon = icon,
        desaturate = desaturate,
        label = handler:GetLabel(),
        enabled = handler:IsEnabled(),
      }
    end
  end
  return entries
end
