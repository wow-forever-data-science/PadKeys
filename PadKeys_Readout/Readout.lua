-- Fast-changing information beside the mouse, where your eyes already
-- are, and only while it matters:
-- - a ring around the pointer (Ring.lua): your cast, the global cooldown
--   and hits you take;
-- - your big cooldowns that are ready (Big.lua);
-- - your target's cast or channel, to interrupt: icon, drain and name
--   (off by default);
-- - boss abilities from Blizzard's encounter timeline (C_EncounterTimeline)
--   as the timeline highlights them, with their countdown.
--
-- Times, spell names and icons are secret in combat and during an
-- encounter. None is compared here: durations come as duration objects
-- (UnitCastingDuration, C_EncounterTimeline.GetEventTimer) and go to a Cooldown frame's
-- SetCooldownFromDurationObject; names go to SetText and icons to
-- SetTexture, which take secret values. Each is wrapped in pcall, so a
-- refusal hides the piece instead of erroring. What shows when comes from
-- plain events: cast start and stop, the timeline's highlight and removal
-- of an event (its ID is never secret). Nothing here is secure, and
-- nothing takes the mouse.

local ns = PadKeys
local c = ns.config.readout

local frame = CreateFrame("Frame", "PadKeysReadout", UIParent)
frame:SetFrameStrata("DIALOG")
frame:SetSize(1, 1)
frame:EnableMouse(false)

local function is_secret(v)
  return issecretvalue and issecretvalue(v)
end

-- A secret value is there (only nil can't be secret); a plain one is
-- compared as usual.
local function present(v)
  if is_secret(v) then
    return true
  end
  return v ~= nil
end

local function set_duration(cooldown, get, ...)
  local ok = pcall(function(...)
    cooldown:SetCooldownFromDurationObject(get(...))
  end, ...)
  if not ok then
    cooldown:Clear()
  end
  return ok
end

-- --- Rows (target cast, boss abilities) ---------------------------------------

-- side "left": the label left of the icon, for rows left of the pointer.
local function make_row(side, name)
  local size = c.icon_size or 28
  local row = CreateFrame("Frame", name, frame)
  row:SetSize(size, size)
  ns.box(row, 0, c.rounded)
  row.icon = row:CreateTexture(nil, "ARTWORK")
  ns.fit_icon(row, row.icon)
  if c.rounded then
    ns.round(row, row.icon, 1)
  end
  ns.icon(row.icon)
  row.cooldown = CreateFrame("Cooldown", nil, row, "CooldownFrameTemplate")
  row.cooldown:SetPoint("TOPLEFT", 1, -1)
  row.cooldown:SetPoint("BOTTOMRIGHT", -1, 1)
  row.cooldown:SetDrawEdge(false)
  row.cooldown:SetDrawBling(false)
  row.cooldown:SetSwipeColor(0, 0, 0, 0.6)
  local countdown = row.cooldown.GetCountdownFontString and
    row.cooldown:GetCountdownFontString()
  if countdown then
    ns.style(countdown, (c.text_size or 13) + 1)
  end
  row.label = ns.text(row, c.text_size or 13, "white", "OVERLAY",
                      "GameFontHighlight")
  row.label:SetShadowOffset(1, -1)
  if side == "left" then
    row.label:SetPoint("RIGHT", row, "LEFT", -6, 0)
    row.label:SetJustifyH("RIGHT")
  else
    row.label:SetPoint("LEFT", row, "RIGHT", 6, 0)
    row.label:SetJustifyH("LEFT")
  end
  row:Hide()
  return row
end

local cast_row = make_row()
cast_row:SetPoint("TOPLEFT", frame, "CENTER", c.x or 92, (c.y or -80) + (c.icon_size or 28) + 4)
cast_row.cooldown:SetReverse(true)
cast_row.cooldown:SetHideCountdownNumbers(true)
-- A cast that ends without a stop event reaching us still goes away.
cast_row.cooldown:SetScript("OnCooldownDone", function()
  cast_row:Hide()
end)

local function update_target_cast()
  if not c.target_cast or not UnitExists("target") then
    cast_row:Hide()
    return
  end
  local ok = pcall(function()
    local name, _, texture = UnitCastingInfo("target")
    local get = UnitCastingDuration
    if not present(name) then
      name, _, texture = UnitChannelInfo("target")
      get = UnitChannelDuration
    end
    if not present(name) then
      error("not casting")
    end
    cast_row.icon:SetTexture(texture)
    cast_row.label:SetText(name)
    cast_row.cooldown:SetCooldownFromDurationObject(get("target"))
  end)
  cast_row:SetShown(ok)
end

-- Boss rows, upper left of the pointer, stacking upwards:
-- rows[i].event = the timeline event ID.
local boss_rows = {}
for i = 1, c.boss_rows or 3 do
  local row = make_row("left", "PadKeysReadoutBoss" .. i)
  row:SetPoint("BOTTOMRIGHT", frame, "CENTER", c.boss_x or -72,
               (c.boss_y or 44) + (i - 1) * ((c.icon_size or 28) + 4))
  row.cooldown:SetHideCountdownNumbers(false)
  boss_rows[i] = row
end

local timeline = C_EncounterTimeline

local function show_boss_event(id)
  if not (c.boss and timeline) then
    return
  end
  -- Already showing, or the first free row, or the oldest one.
  local row, oldest
  for _, r in ipairs(boss_rows) do
    if r.event == id then
      row = r
      break
    end
    if not row and not r.event then
      row = r
    end
    if not oldest or (r.since or 0) < (oldest.since or 0) then
      oldest = r
    end
  end
  row = row or oldest
  local ok = pcall(function()
    local info = timeline.GetEventInfo(id)
    row.icon:SetTexture(info.iconFileID)
    row.label:SetText(info.spellName)
  end)
  if not ok then
    row.icon:SetTexture(134400) -- the question mark icon
    row.label:SetText("")
  end
  set_duration(row.cooldown, timeline.GetEventTimer, id)
  row.event = id
  row.since = GetTime()
  row:Show()
end

local function remove_boss_event(id)
  for _, row in ipairs(boss_rows) do
    if id == nil or row.event == id then
      row.event = nil
      row.cooldown:Clear()
      row:Hide()
    end
  end
end

-- --- Driver -----------------------------------------------------------------

-- Follows the mouse; while you turn with the mouse the pointer is hidden,
-- so it stays where the pointer was.
frame:SetScript("OnUpdate", function(self)
  if IsMouselooking and IsMouselooking() then
    return
  end
  local x, y = GetCursorPosition()
  local scale = UIParent:GetEffectiveScale()
  self:ClearAllPoints()
  self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
end)

local events = CreateFrame("Frame")
for _, event in ipairs({
  "PLAYER_TARGET_CHANGED", "PLAYER_ENTERING_WORLD",
  "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED",
  "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_DELAYED",
  "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE",
  "UNIT_SPELLCAST_CHANNEL_STOP",
  "ENCOUNTER_TIMELINE_EVENT_HIGHLIGHT", "ENCOUNTER_TIMELINE_EVENT_REMOVED",
  "ENCOUNTER_END",
}) do
  pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event, arg)
  if event == "ENCOUNTER_TIMELINE_EVENT_HIGHLIGHT" then
    show_boss_event(arg)
  elseif event == "ENCOUNTER_TIMELINE_EVENT_REMOVED" then
    remove_boss_event(arg)
  elseif event == "ENCOUNTER_END" or event == "PLAYER_ENTERING_WORLD" then
    remove_boss_event(nil)
  elseif event:find("^UNIT_SPELLCAST") then
    if arg == "target" then
      update_target_cast()
    end
  elseif event == "PLAYER_TARGET_CHANGED" then
    update_target_cast()
  end
end)
