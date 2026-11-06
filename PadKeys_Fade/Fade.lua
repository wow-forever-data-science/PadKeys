-- Fades Blizzard's bars out until you need them. Edit Mode can hide most
-- action bars, but not Action Bar 1, the micro menu or the bags, and a
-- hidden bar doesn't come back on mouseover. This keeps every bar shown
-- (set them to "Always" in Edit Mode) and only changes its alpha: a group
-- fades in while the mouse is over one of its frames, while you drag a
-- spell, item or macro, and in Edit Mode.
--
-- Nothing here is secure, and it never shows, hides or moves a Blizzard
-- frame: alpha is all it sets, so it works in combat and the keys keep
-- pressing the buttons as before. It reads the bars' own fields
-- (commandNamePrefix, numButtons) and your live key bindings for the
-- labels.

local ns = PadKeys
local c = ns.config.fade

local HOVER_INTERVAL = 0.05

-- Older names for the same frames.
local ALIASES = { MainActionBar = "MainMenuBar" }

local BAR_NAMES = {
  MainActionBar = "Bar 1", MainMenuBar = "Bar 1",
  MultiBarBottomLeft = "Bar 2", MultiBarBottomRight = "Bar 3",
  MultiBarRight = "Bar 4", MultiBarLeft = "Bar 5",
  MultiBar5 = "Bar 6", MultiBar6 = "Bar 7", MultiBar7 = "Bar 8",
  PetActionBar = "Pet bar", StanceBar = "Stance bar",
}

-- PadKeys_Radial's G and Alt+G wheels show Action Bars 6 and 7 (slots 145
-- and 157).
local WHEELS = {
  MultiBar5 = "CLICK PadKeysRing:actions",
  MultiBar6 = "CLICK PadKeysRing:extra",
}

-- What can be dropped on an action button.
local DRAGGABLE = {
  spell = true, item = true, macro = true, petaction = true, mount = true,
  companion = true, flyout = true, equipmentset = true, battlepet = true,
}

local IS_MAC = IsMacClient and IsMacClient()
local MOD_NAMES = {
  ALT = IS_MAC and "Option" or "Alt", CTRL = "Ctrl", SHIFT = "Shift",
  META = "Cmd",
}

-- --- Labels ---------------------------------------------------------------

-- "META-SHIFT" -> "Cmd+Shift"; "" -> "No modifier".
local function mod_name(mods)
  if mods == "" then
    return "No modifier"
  end
  local names = {}
  for m in mods:gmatch("[^%-]+") do
    names[#names + 1] = MOD_NAMES[m] or m
  end
  return table.concat(names, "+")
end

-- {1, 2, 3, 4, 6} -> "1-4, 6" (with an en dash).
local function ranges(slots)
  table.sort(slots)
  local parts, first, last = {}, nil, nil
  for _, s in ipairs(slots) do
    if last and s == last + 1 then
      last = s
    else
      if first then
        parts[#parts + 1] = first == last and first or (first .. "\226\128\147" .. last)
      end
      first, last = s, s
    end
  end
  if first then
    parts[#parts + 1] = first == last and first or (first .. "\226\128\147" .. last)
  end
  return table.concat(parts, ", ")
end

-- Only PadKeys' eight action keys count: a modifier name says which layer
-- of 1 2 3 4 Q E R T fires the bar. Other keys (Blizzard's 9 0 - = on Bar
-- 1, Ctrl+F1 on the stance bar) are left out.
local FACE = {}
for _, key in ipairs(ns.config.face_keys) do
  FACE[key] = true
end

-- Which modifier layers press this bar's buttons, from the live bindings:
-- "Cmd", "Ctrl · slots 1-4", "G wheel". nil when nothing is bound.
local function keys_for(frame, name)
  local parts = {}
  local prefix = frame.commandNamePrefix
  if prefix then
    local order, slots = {}, {}
    for i = 1, frame.numButtons or 12 do
      local keys = { GetBindingKey(prefix .. "BUTTON" .. i) }
      for _, key in ipairs(keys) do
        local mods, base = key:match("^(.+)%-(.+)$")
        mods, base = mods or "", base or key
        if FACE[base] then
          if not slots[mods] then
            slots[mods] = {}
            order[#order + 1] = mods
          end
          local list = slots[mods]
          if list[#list] ~= i then
            list[#list + 1] = i
          end
        end
      end
    end
    for _, mods in ipairs(order) do
      local list = slots[mods]
      -- All eight face keys (or more) from slot 1: just the layer.
      local whole = #list >= 8 and list[1] == 1 and list[#list] == #list
      parts[#parts + 1] = whole and mod_name(mods) or
        (mod_name(mods) .. " \194\183 slots " .. ranges(list))
    end
  end
  local wheel = WHEELS[name] and GetBindingKey(WHEELS[name])
  if wheel then
    local mods, key = wheel:match("^(.+)%-(.+)$")
    parts[#parts + 1] = (mods and (mod_name(mods) .. "+" .. key) or wheel) .. " wheel"
  end
  return #parts > 0 and table.concat(parts, ", ") or nil
end

local labels = {}

local function make_label(frame, name)
  local holder = CreateFrame("Frame", nil, UIParent)
  holder:SetFrameStrata("MEDIUM")
  holder:SetSize(1, 1)
  holder:SetPoint("RIGHT", frame, "LEFT", -8, 0)
  local text = ns.text(holder, c.label_size or 12, "white", "OVERLAY",
                       "GameFontHighlightSmall")
  text:SetPoint("RIGHT")
  text:SetJustifyH("RIGHT")
  holder.text = text
  holder.bar = frame
  holder.name = name
  holder:SetAlpha(0)
  return holder
end

local function update_labels()
  for _, label in ipairs(labels) do
    local keys = keys_for(label.bar, label.name)
    -- The bar's name in grey, its key in white.
    label.text:SetText(ns.paint(BAR_NAMES[label.name], "light") ..
      (keys and "  " .. ns.paint(keys, "white") or ""))
  end
end

-- --- Groups ---------------------------------------------------------------

local groups = {}

local function resolve()
  wipe(groups)
  wipe(labels)
  for group_name, names in pairs(c.groups) do
    local group = { name = group_name, frames = {}, labels = {}, alpha = 1,
                    last_hover = 0 }
    for _, name in ipairs(names) do
      local frame = _G[name] or (ALIASES[name] and _G[ALIASES[name]])
      if frame and frame.SetAlpha then
        group.frames[#group.frames + 1] = frame
        if c.labels and BAR_NAMES[name] then
          local label = make_label(frame, name)
          group.labels[#group.labels + 1] = label
          labels[#labels + 1] = label
        end
      end
    end
    groups[#groups + 1] = group
  end
  update_labels()
end

local function hovered(group)
  local pad = c.padding or 0
  for _, frame in ipairs(group.frames) do
    if frame:IsVisible() and frame:IsMouseOver(pad, -pad, -pad, pad) then
      return true
    end
  end
  for _, label in ipairs(group.labels) do
    if label.text:IsVisible() and label:GetAlpha() > 0 and
       label.text:IsMouseOver(pad, -pad, -pad, pad) then
      return true
    end
  end
  return false
end

local function set_alpha(group, a)
  group.alpha = a
  for _, frame in ipairs(group.frames) do
    if math.abs(frame:GetAlpha() - a) > 0.001 then
      frame:SetAlpha(a)
    end
  end
  -- Labels fade from nothing, whatever the faded alpha of the bars.
  local faded = c.faded_alpha or 0
  local la = faded < 1 and (a - faded) / (1 - faded) or 1
  for _, label in ipairs(group.labels) do
    label:SetShown(label.bar:IsVisible())
    label:SetAlpha(la)
  end
end

local function editing()
  return EditModeManagerFrame and EditModeManagerFrame.IsEditModeActive and
         EditModeManagerFrame:IsEditModeActive()
end

local function dragging()
  local kind = GetCursorInfo()
  return kind and DRAGGABLE[kind] or false
end

-- --- Driver ---------------------------------------------------------------

local driver = CreateFrame("Frame")
local since_hover_check = HOVER_INTERVAL
local show = {}

driver:SetScript("OnUpdate", function(_, elapsed)
  since_hover_check = since_hover_check + elapsed
  if since_hover_check >= HOVER_INTERVAL then
    since_hover_check = 0
    local now = GetTime()
    local all = ns.db.fade_off or editing()
    local drag = dragging()
    for _, group in ipairs(groups) do
      if hovered(group) then
        group.last_hover = now
      end
      show[group] = all or (drag and c.show_while_dragging and
                                c.show_while_dragging[group.name]) or
                    now - group.last_hover < (c.linger or 0)
    end
  end

  local faded = c.faded_alpha or 0
  for _, group in ipairs(groups) do
    local target = show[group] and 1 or faded
    local a = group.alpha
    if a ~= target then
      local time = target > a and c.fade_in or c.fade_out
      local step = (time and time > 0) and elapsed * (1 - faded) / time or 1
      if target > a then
        a = math.min(target, a + step)
      else
        a = math.max(target, a - step)
      end
    end
    set_alpha(group, a)
  end
end)
driver:Hide()

driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("UPDATE_BINDINGS")
driver:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_LOGIN" then
    resolve()
    self:Show()
  else
    update_labels()
  end
end)

-- /padkeys fade: stop fading (to look at the bars), again to fade.
function ns.toggle_fade()
  ns.db.fade_off = not ns.db.fade_off or nil
  ns.say(ns.db.fade_off and "bars stay shown. /padkeys fade fades them again."
         or "bars fade until you mouse over them or drag a spell.")
end
