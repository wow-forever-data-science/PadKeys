-- PadKeys core: saved variables, the /padkeys command and binding labels.
-- The PadKeys_* addons reach this addon's table through the PadKeys global.

local addonName, ns = ...
PadKeys = ns

BINDING_HEADER_PADKEYS = "PadKeys"
BINDING_NAME_PADKEYS_KEYMAP = "Show key map"

function ns.say(msg)
  print("|cff33ccffPadKeys|r: " .. msg)
end

local HELP = {
  "/padkeys preview - list the key changes /padkeys apply would make",
  "/padkeys apply - set the key layout and settings from Config.lua",
  "/padkeys restore - put back the keys and settings you had before",
  "/padkeys cursor - toggle the keyboard UI cursor (PadKeys_Cursor)",
  "/padkeys map - show the key map",
  "/padkeys status - which PadKeys addons are loaded",
}

local IsAddOnLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded

-- Which PadKeys addons are loaded: enable them one at a time at character
-- select, so an error points at one of them.
local function status()
  ns.say("PadKeys (base): loaded")
  for _, m in ipairs(ns.modules) do
    ns.say(format("%s: %s - %s", m.addon,
                  IsAddOnLoaded(m.addon) and "|cff33ff33loaded|r" or
                    "|cff999999not loaded|r", m.does))
  end
end

SLASH_PADKEYS1 = "/padkeys"
SlashCmdList.PADKEYS = function(msg)
  local cmd = strtrim(msg or ""):lower()
  if cmd == "preview" then
    ns.preview_layout()
  elseif cmd == "apply" then
    ns.apply_layout()
  elseif cmd == "restore" then
    ns.restore_layout()
  elseif cmd == "cursor" then
    if ns.toggle_cursor then
      ns.toggle_cursor()
    else
      ns.say("the cursor is in PadKeys_Cursor, which isn't loaded.")
    end
  elseif cmd == "status" then
    status()
  elseif cmd == "map" then
    ns.toggle_key_map()
  else
    for _, line in ipairs(HELP) do
      ns.say(line)
    end
  end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, name)
  if name ~= addonName then
    return
  end
  PadKeysDB = PadKeysDB or {}
  ns.db = PadKeysDB
  self:UnregisterEvent("ADDON_LOADED")
end)
