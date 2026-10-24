-- PadKeys core: saved variables, the /padkeys command and binding labels.

local addonName, ns = ...
PadKeys = ns

BINDING_HEADER_PADKEYS = "PadKeys"
BINDING_NAME_PADKEYS_CURSOR = "Toggle keyboard UI cursor"
_G["BINDING_NAME_CLICK PadKeysRing1:LeftButton"] = "Radial ring 1 (hold)"
_G["BINDING_NAME_CLICK PadKeysRing2:LeftButton"] = "Radial ring 2 (hold)"
_G["BINDING_NAME_CLICK PadKeysRing3:LeftButton"] = "Radial ring 3 (hold)"
_G["BINDING_NAME_CLICK PadKeysGroupCycle:LeftButton"] = "Next party/raid member"
_G["BINDING_NAME_CLICK PadKeysGroupCycle:RightButton"] = "Previous party/raid member"

function ns.say(msg)
  print("|cff33ccffPadKeys|r: " .. msg)
end

local HELP = {
  "/padkeys preview - list the key changes /padkeys apply would make",
  "/padkeys apply - set the key layout and settings from Config.lua",
  "/padkeys restore - put back the keys and settings you had before",
  "/padkeys cursor - toggle the keyboard UI cursor",
}

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
    ns.toggle_cursor()
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
