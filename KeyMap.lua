-- Key map, like Blizzard's gamepad "Controller Map": a panel listing what
-- each key does. Global keys are read from the live bindings each time it
-- opens (GetBindingKey), so it shows your real setup, with Blizzard's own key
-- names (GetBindingText: "Shift-Tab", "Cmd-1" on a Mac) and action names
-- (BINDING_NAME_*). Context keys (cursor, radial, quests) come from
-- Config.lua. Uses Blizzard's ButtonFrameTemplate window; Esc closes it.

local _, ns = ...

local function key_text(key)
  return key and GetBindingText(key) or "-"
end

-- Live keys for one binding action, e.g. "Tab".
local function keys_for(action)
  local k1, k2 = GetBindingKey(action)
  if not k1 then
    return "-"
  end
  return key_text(k1) .. (k2 and (", " .. key_text(k2)) or "")
end

-- Live keys for slots 1-8 of a bar, e.g. "1 2 3 4 Q E R T".
local function bar_keys(prefix)
  local out = {}
  for i = 1, 8 do
    out[i] = key_text((GetBindingKey(prefix .. i)))
  end
  return table.concat(out, " ")
end

local function config_keys(list)
  local out = {}
  for i, key in ipairs(list or {}) do
    out[i] = key_text(key)
  end
  return table.concat(out, ", ")
end

local function action_row(action, label)
  return { label or _G["BINDING_NAME_" .. action] or action, keys_for(action) }
end

-- Sections in display order. Built when the map opens.
local function sections()
  local c = ns.config
  local friendly = ns.is_friendly_mode and ns.is_friendly_mode()
  return {
    { "Action bars", {
      { "Action Bar 1", bar_keys("ACTIONBUTTON") },
      { "Action Bar 2", bar_keys("MULTIACTIONBAR1BUTTON") },
      { "Action Bar 3", bar_keys("MULTIACTIONBAR2BUTTON") },
      { "Pet bar", bar_keys("BONUSACTIONBUTTON") },
    } },
    { "Moving and interacting", {
      action_row("MOVEFORWARD"), action_row("MOVEBACKWARD"),
      action_row("STRAFELEFT"), action_row("STRAFERIGHT"),
      action_row("JUMP"), action_row("INTERACTTARGET"),
      action_row("SITORSTAND"),
    } },
    { "Targeting" .. (friendly and " (friendly mode on)" or ""), {
      action_row("CLICK PadKeysTargetMode:LeftButton",
                 "Toggle friendly / enemy targeting"),
      { friendly and "Next / previous friend" or "Next / previous enemy",
        keys_for("TARGETNEARESTENEMY") .. " / " ..
          keys_for("TARGETPREVIOUSENEMY") },
      action_row("CLICK PadKeysGroupCycle:LeftButton", "Next group member"),
      action_row("CLICK PadKeysGroupCycle:RightButton",
                 "Previous group member"),
      action_row("ASSISTTARGET"), action_row("TARGETLASTTARGET"),
      action_row("TARGETLASTHOSTILE"),
    } },
    { "Menus and info", {
      action_row("PADKEYS_RADIAL"), action_row("TOGGLEPINGLISTENER"),
      action_row("PADKEYS_CURSOR"),
      action_row("CLICK PadKeysAuraDebuff:LeftButton"),
      action_row("CLICK PadKeysAuraBuff:LeftButton"),
      action_row("PADKEYS_KEYMAP"),
    } },
    { "In the UI cursor", {
      { "Move", config_keys(c.cursor.keys.up) .. " / " ..
          config_keys(c.cursor.keys.left) .. " / " ..
          config_keys(c.cursor.keys.down) .. " / " ..
          config_keys(c.cursor.keys.right) },
      { "Click", config_keys(c.cursor.keys.click) },
      { "Right-click (use, sell, cancel buff)",
        config_keys(c.cursor.keys.rightclick) },
      { "Pick up", config_keys(c.cursor.keys.pickup) },
      { "Next / previous window", config_keys(c.cursor.keys.next_window) ..
          " / " .. config_keys(c.cursor.keys.previous_window) },
      { "Close window / leave", config_keys(c.cursor.keys.back) },
    } },
    { "In the radial, NPC dialogs and aura view", {
      { "Radial pages", config_keys(c.radial.page_keys.previous) .. " / " ..
          config_keys(c.radial.page_keys.next) },
      { "NPC dialog: choose / accept / complete", config_keys(c.quest.step) },
      { "Close aura view", key_text("ESCAPE") },
    } },
  }
end

local frame = CreateFrame("Frame", "PadKeysKeyMap", UIParent,
                          "ButtonFrameTemplate")
frame:SetSize(620, 640)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:Hide()
ButtonFrameTemplate_HidePortrait(frame)
frame:SetTitle("PadKeys Key Map")
tinsert(UISpecialFrames, "PadKeysKeyMap")

local strings = {}
local function string_at(i, template)
  local fs = strings[i]
  if not fs then
    fs = frame:CreateFontString(nil, "OVERLAY", template)
    strings[i] = fs
  end
  fs:SetFontObject(template)
  fs:ClearAllPoints()
  fs:Show()
  return fs
end

-- Two columns of sections, each a header and "label ........ keys" rows.
local function layout()
  local i, col, y = 0, 0, -36
  local list = sections()
  local half = math.ceil(#list / 2)
  for s, section in ipairs(list) do
    if s == half + 1 then
      col, y = 1, -36
    end
    local x = 20 + col * 300
    i = i + 1
    local header = string_at(i, "GameFontNormal")
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
    header:SetText(section[1])
    y = y - 20
    for _, row in ipairs(section[2]) do
      i = i + 1
      local label = string_at(i, "GameFontHighlightSmall")
      label:SetPoint("TOPLEFT", frame, "TOPLEFT", x + 6, y)
      label:SetWidth(150)
      label:SetJustifyH("LEFT")
      label:SetText(row[1])
      i = i + 1
      local keys = string_at(i, "GameFontNormalSmall")
      keys:SetPoint("TOPLEFT", frame, "TOPLEFT", x + 160, y)
      keys:SetWidth(130)
      keys:SetJustifyH("LEFT")
      keys:SetText(row[2])
      y = y - math.max(label:GetStringHeight(), keys:GetStringHeight(), 12) - 4
    end
    y = y - 10
  end
  for j = i + 1, #strings do
    strings[j]:Hide()
  end
end

frame:SetScript("OnShow", layout)

function ns.toggle_key_map()
  frame:SetShown(not frame:IsShown())
end
