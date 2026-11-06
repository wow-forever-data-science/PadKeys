-- Key map, like Blizzard's gamepad "Controller Map": a panel listing what
-- each key does. Global keys are read from the live bindings each time it
-- opens (GetBindingKey), so it shows your real setup, with Blizzard's own key
-- names (GetBindingText: "Shift-Tab", "Cmd-1" on a Mac) and action names
-- (BINDING_NAME_*). Context keys (cursor, radial) come from the
-- addons' Config.lua files. Uses Blizzard's ButtonFrameTemplate window;
-- Esc closes it.

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

-- Live keys for slots 1-n of a bar (default 8), e.g. "1 2 3 4 Q E R T".
local function bar_keys(prefix, n)
  local out = {}
  for i = 1, n or 8 do
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

local IsAddOnLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
local function loaded(addon)
  return IsAddOnLoaded(addon) and true or false
end

local function action_row(action, label)
  return { label or _G["BINDING_NAME_" .. action] or action, keys_for(action) }
end

-- Sections in display order, built when the map opens. Sections and rows
-- for PadKeys_* addons only appear when that addon is loaded.
local function sections()
  local c = ns.config
  local targeting = ns.is_friendly_mode ~= nil
  local friendly = targeting and ns.is_friendly_mode()
  local list = {
    { "Action bars", {
      { "Action Bar 1", bar_keys("ACTIONBUTTON") },
      { "Action Bar 2", bar_keys("MULTIACTIONBAR1BUTTON") },
      { "Action Bar 3", bar_keys("MULTIACTIONBAR2BUTTON") },
      { "Action Bar 4 (slots 1-4)", bar_keys("MULTIACTIONBAR3BUTTON", 4) },
      { "Action Bar 5", bar_keys("MULTIACTIONBAR4BUTTON") },
      { "Pet bar (slots 1-4)", bar_keys("BONUSACTIONBUTTON", 4) },
    } },
    { "Moving and interacting", {
      action_row("MOVEFORWARD"), action_row("MOVEBACKWARD"),
      action_row("STRAFELEFT"), action_row("STRAFERIGHT"),
      action_row("JUMP"), action_row("INTERACTTARGET"),
      action_row("SITORSTAND"),
    } },
  }

  local target_rows = {}
  if targeting then
    target_rows[#target_rows + 1] = action_row(
      "CLICK PadKeysTargetMode:LeftButton", "Toggle friendly / enemy targeting")
  end
  target_rows[#target_rows + 1] = {
    not targeting and "Next / previous enemy" or
      (friendly and "Next / previous enemy, else friend (friend in combat)" or
       "Next / previous enemy, else friend"),
    keys_for("TARGETNEARESTENEMY") .. " / " .. keys_for("TARGETPREVIOUSENEMY") }
  if targeting then
    target_rows[#target_rows + 1] = action_row(
      "CLICK PadKeysGroupCycle:LeftButton", "Next group member")
    target_rows[#target_rows + 1] = action_row(
      "CLICK PadKeysGroupCycle:RightButton", "Previous group member")
  end
  target_rows[#target_rows + 1] = action_row("ASSISTTARGET")
  target_rows[#target_rows + 1] = action_row("TARGETLASTTARGET")
  target_rows[#target_rows + 1] = action_row("TARGETLASTHOSTILE")
  list[#list + 1] = {
    "Targeting" .. (friendly and " (friendly mode on)" or ""), target_rows }

  local menu_rows = {}
  if c.radial then
    menu_rows[#menu_rows + 1] = action_row("CLICK PadKeysRing:actions")
    menu_rows[#menu_rows + 1] = action_row("CLICK PadKeysRing:pings")
    menu_rows[#menu_rows + 1] = action_row("CLICK PadKeysRing:markers")
    menu_rows[#menu_rows + 1] = action_row("CLICK PadKeysRing:menu")
  else
    menu_rows[#menu_rows + 1] = action_row("TOGGLEPINGLISTENER")
  end
  menu_rows[#menu_rows + 1] = action_row("TOGGLESHEATH")
  if c.cursor then
    menu_rows[#menu_rows + 1] = action_row("PADKEYS_CURSOR")
    menu_rows[#menu_rows + 1] = action_row("CLICK PadKeysBags:LeftButton")
  end
  if loaded("PadKeys_Auras") then
    menu_rows[#menu_rows + 1] = action_row("CLICK PadKeysAura:mydebuffs")
    menu_rows[#menu_rows + 1] = action_row("CLICK PadKeysAura:mybuffs")
    menu_rows[#menu_rows + 1] = action_row("CLICK PadKeysAura:targetdebuffs")
    menu_rows[#menu_rows + 1] = action_row("CLICK PadKeysAura:targetbuffs")
  end
  menu_rows[#menu_rows + 1] = action_row("PADKEYS_KEYMAP")
  list[#list + 1] = { "Menus and info", menu_rows }

  if c.cursor then
    local k = c.cursor.keys
    list[#list + 1] = { "In the UI cursor", {
      { "Move", config_keys(k.up) .. " / " .. config_keys(k.left) .. " / " ..
          config_keys(k.down) .. " / " .. config_keys(k.right) },
      { "Click", config_keys(k.click) },
      { "Right-click (use, sell, cancel buff)", config_keys(k.rightclick) },
      { "Pick up", config_keys(k.pickup) },
      { "Next / previous window", config_keys(k.next_window) .. " / " ..
          config_keys(k.previous_window) },
      { "Close window / leave", config_keys(k.back) },
      { "NPC dialog: choose / accept / complete", config_keys(c.quest.step) },
      { "Vendor / trainer: choose, then buy / train", config_keys(c.quest.step) },
    } }
  end

  local other = {}
  if c.radial then
    other[#other + 1] = { "Menu radial pages",
      config_keys(c.radial.menu.page_keys.previous) .. " / " ..
        config_keys(c.radial.menu.page_keys.next) }
  end
  if #other > 0 then
    list[#list + 1] = { "In the radial", other }
  end
  return list
end

local frame = CreateFrame("Frame", "PadKeysKeyMap", UIParent,
                          "ButtonFrameTemplate")
frame:SetSize(620, 640)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:Hide()
ButtonFrameTemplate_HidePortrait(frame)
frame:SetTitle("PadKeys Key Map")
-- Blizzard's window in black and white, its title in the PadKeys font.
ns.monochrome(frame)
tinsert(UISpecialFrames, "PadKeysKeyMap")

local strings = {}
local function string_at(i, size, shade)
  local fs = strings[i]
  if not fs then
    fs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    strings[i] = fs
  end
  ns.style(fs, size, shade)
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
    local header = string_at(i, 14, "white")
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
    header:SetText(section[1])
    y = y - 20
    for _, row in ipairs(section[2]) do
      i = i + 1
      local label = string_at(i, 12, "light")
      label:SetPoint("TOPLEFT", frame, "TOPLEFT", x + 6, y)
      label:SetWidth(150)
      label:SetJustifyH("LEFT")
      label:SetText(row[1])
      i = i + 1
      local keys = string_at(i, 12, "white")
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
