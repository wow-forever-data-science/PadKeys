-- Buff reminder: out of combat, a short list of the long buffs that matter
-- for your class and group and are missing or running out (under 5
-- minutes, Config.lua). It fades out as you enter combat, as fast as the
-- combat banner fades, and comes back as you leave it.
--
-- What counts depends on who is in your party or raid:
-- - group buffs (Fortitude, Mark of the Wild, Arcane Intellect,
--   blessings) when someone of that class is in the group; Intellect only
--   for classes with mana;
-- - if you can cast one yourself, every member in the group who is missing
--   it (or has under 5 minutes left), by name;
-- - your own class buffs (mage and warlock armor, Inner Fire, Omen of
--   Clarity, Trueshot Aura) and, for rogues, poisons on your weapons.
--
-- In combat, Blizzard's own buff consolidation folds the long buffs into
-- one icon (Config.lua `consolidate_in_combat`), so the buff frame only
-- shows the short ones; it goes back to your setting as you leave combat.
-- The target frame's and nameplates' auras are Blizzard's protected frames,
-- so they keep Blizzard's own filters; PadKeys_Auras (C) reads them.
--
-- Auras are read only out of combat (in combat they are secret), and every
-- read is wrapped in pcall. Nothing here is secure: the list is plain
-- textures and font strings that never take the mouse.

local ns = PadKeys
local c = ns.config.combat
local cfg = c.buffs
if not (cfg and cfg.enabled) then
  return
end

local MANA = {
  DRUID = true, HUNTER = true, MAGE = true, PALADIN = true,
  PRIEST = true, SHAMAN = true, WARLOCK = true,
}

-- Each buff, matched by name (every rank and the group version share a
-- family). `caster`: a group buff that class casts; `who = "mana"` only for
-- classes with mana; `own_only`: only when you know it (a talent nobody
-- else can be seen to have); `per_caster`: one each from every caster in
-- the group (blessings). `class`: a buff of your own, shown when you know
-- it. `weapon`: weapon enchants (rogue poisons). Turn one off with
-- `ignore` in Config.lua.
local BUFFS = {
  { key = "fortitude", caster = "PRIEST", who = "all", spells = { 1243, 21562 } },
  { key = "mark", caster = "DRUID", who = "all", spells = { 1126, 21849 } },
  { key = "intellect", caster = "MAGE", who = "mana", spells = { 1459, 23028 } },
  { key = "spirit", caster = "PRIEST", who = "mana", own_only = true, spells = { 14752, 27681 } },
  { key = "blessing", caster = "PALADIN", who = "all", per_caster = true, label = "Blessings",
    spells = { 19740, 19742, 20217, 1038, 19977, 20911,           -- Might, Wisdom, Kings, Salvation, Light, Sanctuary
               25782, 25894, 25898, 25895, 25890, 25899 } },      -- their Greater versions
  { key = "mage_armor", class = "MAGE", label = "Armor", spells = { 168, 7302, 6117 } },
  { key = "demon_armor", class = "WARLOCK", spells = { 687, 706 } },
  { key = "inner_fire", class = "PRIEST", spells = { 588 } },
  { key = "omen", class = "DRUID", spells = { 16864 } },
  { key = "trueshot", class = "HUNTER", spells = { 19506 } },
  { key = "poisons", class = "ROGUE", weapon = true, spells = { 2842 } },
}

-- --- Spells -----------------------------------------------------------------

local function spell_name(id)
  if C_Spell and C_Spell.GetSpellName then
    return C_Spell.GetSpellName(id)
  end
  return GetSpellInfo and (GetSpellInfo(id))
end

local function spell_icon(id)
  if C_Spell and C_Spell.GetSpellTexture then
    return C_Spell.GetSpellTexture(id)
  end
  return GetSpellTexture and GetSpellTexture(id)
end

local function knows(id)
  if IsPlayerSpell and IsPlayerSpell(id) then
    return true
  end
  if C_SpellBook and C_SpellBook.IsSpellKnown then
    return C_SpellBook.IsSpellKnown(id) and true or false
  end
  return IsSpellKnown and IsSpellKnown(id) or false
end

local function knows_any(buff)
  for _, id in ipairs(buff.spells) do
    if knows(id) then
      return true
    end
  end
  return false
end

-- The family's names (localised), filled once the client has them.
local function names_of(buff)
  if not buff.names then
    local names, complete = {}, true
    for _, id in ipairs(buff.spells) do
      local name = spell_name(id)
      if name then
        names[name] = true
      else
        complete = false
      end
    end
    if not complete then
      return names
    end
    buff.names = names
  end
  return buff.names
end

local function label_of(buff)
  return buff.label or spell_name(buff.spells[1]) or buff.key
end

-- --- Group ------------------------------------------------------------------

-- The units to look at: the raid, or you and your party.
local function group_units()
  local units = {}
  if IsInRaid() then
    for i = 1, GetNumGroupMembers() do
      units[#units + 1] = "raid" .. i
    end
  else
    units[1] = "player"
    if IsInGroup() then
      for i = 1, GetNumSubgroupMembers() do
        units[#units + 1] = "party" .. i
      end
    end
  end
  return units
end

local function class_of(unit)
  return select(2, UnitClass(unit))
end

-- A member whose buffs can be counted on: online, alive and in sight.
local function present(unit)
  return UnitExists(unit) and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit)
     and (UnitIsUnit(unit, "player") or UnitIsVisible(unit))
end

local function short_name(unit)
  if UnitIsUnit(unit, "player") then
    return "you"
  end
  return (UnitName(unit)) or unit
end

-- --- Auras ------------------------------------------------------------------

-- A unit's buffs as { name, left, source }, read once per refresh; nil if
-- they can't be read. `left` is seconds, math.huge for no duration.
local aura_cache = {}

local function buffs_of(unit)
  local cached = aura_cache[unit]
  if cached ~= nil then
    return cached or nil
  end
  local list = {}
  local now = GetTime()
  local ok = pcall(function()
    for i = 1, 40 do
      local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
      if not aura then
        break
      end
      local expires = aura.expirationTime
      list[#list + 1] = {
        name = aura.name,
        left = (expires and expires > 0) and (expires - now) or math.huge,
        source = aura.sourceUnit,
      }
    end
  end)
  aura_cache[unit] = ok and list or false
  return ok and list or nil
end

-- The most time left on any aura of the family on unit (from `source`
-- only, if given): seconds, math.huge for no duration, or nil if missing.
-- false if the auras can't be read.
local function time_left(unit, buff, source)
  local list = buffs_of(unit)
  if not list then
    return false
  end
  local names = names_of(buff)
  local best
  for _, aura in ipairs(list) do
    if names[aura.name] and (not source or (aura.source and UnitIsUnit(aura.source, source))) then
      if not best or aura.left > best then
        best = aura.left
      end
    end
  end
  return best
end

local function low(left)
  return left == nil or left < cfg.warn_at
end

local function clock(seconds)
  seconds = math.max(0, math.floor(seconds))
  return format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

-- --- Rows -------------------------------------------------------------------

-- Each row: { icon, label, missing = { names }, left = seconds, who = name }.
-- A row is shown when something is missing or a time is under warn_at.

-- Who is missing it (names) and the lowest time under warn_at among the
-- rest, over `units`.
local function survey(buff, units, source)
  local missing, lowest, lowest_who = {}, nil, nil
  for _, unit in ipairs(units) do
    local left = time_left(unit, buff, source)
    if left == nil then
      missing[#missing + 1] = short_name(unit)
    elseif left and left < cfg.warn_at and (not lowest or left < lowest) then
      lowest, lowest_who = left, short_name(unit)
    end
  end
  return missing, lowest, lowest_who
end

local function group_row(buff, units, casters)
  if casters == 0 or (buff.own_only and not knows_any(buff)) then
    return nil
  end
  local eligible = function(unit)
    return buff.who ~= "mana" or MANA[class_of(unit)]
  end
  local row = { icon = spell_icon(buff.spells[1]), label = label_of(buff) }
  if class_of("player") == buff.caster and knows_any(buff) then
    -- You cast it: everyone it is for, and for blessings only your own.
    local targets = {}
    for _, unit in ipairs(units) do
      if present(unit) and eligible(unit) then
        targets[#targets + 1] = unit
      end
    end
    row.missing, row.left, row.who =
      survey(buff, targets, buff.per_caster and "player" or nil)
  elseif eligible("player") then
    if buff.per_caster then
      -- One blessing from each paladin in the group.
      local list = buffs_of("player")
      if not list then
        return nil
      end
      local names, have, lowest = names_of(buff), 0, nil
      for _, aura in ipairs(list) do
        if names[aura.name] then
          have = have + 1
          if not lowest or aura.left < lowest then
            lowest = aura.left
          end
        end
      end
      if have < casters then
        row.count = format("%d/%d", have, casters)
      elseif lowest and lowest < cfg.warn_at then
        row.left = lowest
      end
      return (row.count or row.left) and row or nil
    end
    row.missing, row.left = survey(buff, { "player" })
  else
    return nil
  end
  if #row.missing == 0 and not row.left then
    return nil
  end
  return row
end

local function own_row(buff, my_class)
  if buff.class ~= my_class or not knows_any(buff) then
    return nil
  end
  local left = time_left("player", buff)
  if left == false or not low(left) then
    return nil
  end
  return {
    icon = spell_icon(buff.spells[1]),
    label = label_of(buff),
    missing = left == nil and { "you" } or {},
    left = left,
  }
end

local SLOTS = {
  { name = "Main hand", inv = 16, slot = 0 },
  { name = "Off hand", inv = 17, slot = 1 },
}

local function is_weapon(item)
  if not item then
    return false
  end
  local get = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
  local class_id = get and select(6, get(item))
  return class_id == 2
end

-- Seconds of enchant left on the weapon slot, or nil if none; false if
-- it can't be read.
local function enchant_left(slot)
  local ok, left = pcall(function()
    if C_Item and C_Item.GetWeaponEnchantInfo then
      for _, enchant in pairs(C_Item.GetWeaponEnchantInfo(slot.slot) or {}) do
        if enchant.hasEnchant then
          return (enchant.timeLeft or 0) / 1000
        end
      end
      return nil
    end
    local info = { GetWeaponEnchantInfo() }
    local base = slot.slot == 0 and 1 or 5
    if info[base] then
      return (info[base + 1] or 0) / 1000
    end
    return nil
  end)
  if not ok then
    return false
  end
  return left
end

local function weapon_rows(buff, my_class, rows)
  if buff.class ~= my_class or not knows_any(buff) then
    return
  end
  for _, slot in ipairs(SLOTS) do
    local item = GetInventoryItemID("player", slot.inv)
    if is_weapon(item) then
      local left = enchant_left(slot)
      if left ~= false and low(left) then
        rows[#rows + 1] = {
          icon = GetInventoryItemTexture("player", slot.inv),
          label = slot.name .. " " .. label_of(buff):lower(),
          missing = left == nil and { "you" } or {},
          left = left,
        }
      end
    end
  end
end

local function collect()
  wipe(aura_cache)
  local rows = {}
  local my_class = class_of("player")
  local units = group_units()
  -- How many of each class are in the group (you included).
  local counts = {}
  for _, unit in ipairs(units) do
    local class = UnitExists(unit) and UnitIsConnected(unit) and class_of(unit)
    if class then
      counts[class] = (counts[class] or 0) + 1
    end
  end
  for _, buff in ipairs(BUFFS) do
    if not cfg.ignore[buff.key] then
      local row
      if buff.caster then
        row = group_row(buff, units, counts[buff.caster] or 0)
      elseif buff.weapon then
        weapon_rows(buff, my_class, rows)
      else
        row = own_row(buff, my_class)
      end
      if row then
        rows[#rows + 1] = row
      end
      if #rows >= cfg.max_rows then
        break
      end
    end
  end
  return rows
end

-- In the PadKeys theme: the buff's name in light grey, what is wrong in
-- white.
local function row_text(row)
  local text = ns.paint(row.label, "light") .. "  "
  if row.count then
    return text .. ns.paint(row.count, "white")
  end
  local missing = row.missing or {}
  if #missing > 0 then
    local shown = {}
    for i = 1, math.min(#missing, cfg.max_names) do
      shown[i] = missing[i]
    end
    local who = table.concat(shown, ", ")
    if #missing > cfg.max_names then
      who = who .. format(" +%d", #missing - cfg.max_names)
    end
    if #missing == 1 and missing[1] == "you" then
      return text .. ns.paint("missing", "white")
    end
    return text .. ns.paint("missing: " .. who, "white")
  end
  if row.left == math.huge then
    return text
  end
  text = text .. ns.paint(clock(row.left), "white")
  if row.who and row.who ~= "you" then
    text = text .. " " .. ns.paint(row.who, "light")
  end
  return text
end

-- --- Panel ------------------------------------------------------------------

local panel = CreateFrame("Frame", "PadKeysBuffReminder", UIParent)
panel:SetSize(1, 1)
-- In the middle of the screen (its top centre at the screen's centre, a
-- block of left-aligned rows), or under a frame (its top left at the
-- frame's bottom left), offset by x, y. A named frame is looked up when
-- the list shows, so one moved in Edit Mode is followed.
local function place()
  local frame = cfg.anchor ~= "center" and _G[cfg.anchor]
  panel:ClearAllPoints()
  if frame then
    panel:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", cfg.x, cfg.y)
  else
    panel:SetPoint("TOP", UIParent, "CENTER", cfg.x, cfg.y)
  end
end
place()
panel:SetFrameStrata("MEDIUM")
panel:EnableMouse(false)
panel:SetAlpha(0)
panel:Hide()

local ICON = cfg.size + 6
local lines = {}

local function line(i)
  if lines[i] then
    return lines[i]
  end
  local l = {}
  l.icon = panel:CreateTexture(nil, "ARTWORK")
  l.icon:SetSize(ICON, ICON)
  l.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  ns.icon(l.icon)
  l.text = ns.text(panel, cfg.size)
  l.text:SetJustifyH("LEFT")
  l.icon:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -(i - 1) * (ICON + 4))
  l.text:SetPoint("LEFT", l.icon, "RIGHT", 6, 0)
  lines[i] = l
  return l
end

-- Lays out the rows; returns how many there are.
local function draw(rows)
  local width = 0
  for i, row in ipairs(rows) do
    local l = line(i)
    l.icon:SetTexture(row.icon or 134400) -- question mark
    l.text:SetText(row_text(row))
    l.icon:Show()
    l.text:Show()
    width = math.max(width, ICON + 6 + l.text:GetStringWidth())
  end
  for i = #rows + 1, #lines do
    lines[i].icon:Hide()
    lines[i].text:Hide()
  end
  panel:SetSize(math.max(width, 1), math.max(#rows * (ICON + 4) - 4, 1))
  return #rows
end

-- Fading: the panel's alpha moves to `target` over `duration` seconds;
-- at 0 the panel hides.
local fade_from, fade_to, fade_for, fade_t = 0, 0, 0, 0

local function fade_step(self, elapsed)
  fade_t = fade_t + elapsed
  local done = fade_t >= fade_for
  local p = done and 1 or fade_t / fade_for
  self:SetAlpha(fade_from + (fade_to - fade_from) * p)
  if done then
    self:SetScript("OnUpdate", nil)
    if fade_to == 0 then
      self:Hide()
    end
  end
end

local function fade(target, duration)
  if target > 0 then
    if not panel:IsShown() then
      place()
    end
    panel:Show()
  elseif not panel:IsShown() then
    return
  end
  fade_from, fade_to, fade_for, fade_t = panel:GetAlpha(), target, math.max(duration or 0, 0.01), 0
  panel:SetScript("OnUpdate", fade_step)
end

-- --- Refresh ----------------------------------------------------------------

local in_combat = false
local wanted = false -- the panel has rows to show

local function refresh()
  if in_combat then
    return
  end
  local hide_now = UnitIsDeadOrGhost("player") or UnitOnTaxi("player")
     or (cfg.hide_resting and IsResting())
  local ok, count = pcall(function()
    return hide_now and draw({}) or draw(collect())
  end)
  if not ok then
    count = 0
  end
  local was = wanted
  wanted = count > 0
  if wanted and not was then
    fade(1, c.fade_in or 0.15)
  elseif not wanted and was then
    fade(0, c.fade_out or 0.6)
  end
end

local pending = false
local function refresh_soon()
  if pending or in_combat then
    return
  end
  pending = true
  C_Timer.After(0.2, function()
    pending = false
    refresh()
  end)
end

-- --- Buff consolidation in combat -------------------------------------------

local CVAR = "consolidateBuffs"

local function consolidate(on)
  if not cfg.consolidate_in_combat or not ns.db then
    return
  end
  if on then
    local current = GetCVar(CVAR)
    if current and current ~= "1" then
      ns.db.consolidate_restore = current
      pcall(SetCVar, CVAR, "1")
    end
  elseif ns.db.consolidate_restore then
    pcall(SetCVar, CVAR, ns.db.consolidate_restore)
    ns.db.consolidate_restore = nil
  end
end

-- --- Events -----------------------------------------------------------------

local ticker
local function start_ticker()
  if not ticker then
    ticker = C_Timer.NewTicker(1, refresh)
  end
end
local function stop_ticker()
  if ticker then
    ticker:Cancel()
    ticker = nil
  end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:RegisterEvent("UNIT_AURA")
events:RegisterEvent("UNIT_INVENTORY_CHANGED")
events:RegisterEvent("SPELLS_CHANGED")
events:RegisterEvent("PLAYER_UPDATE_RESTING")
events:RegisterEvent("PLAYER_ALIVE")
events:RegisterEvent("PLAYER_DEAD")
events:RegisterEvent("PLAYER_UNGHOST")
events:SetScript("OnEvent", function(_, event, unit)
  if event == "PLAYER_REGEN_DISABLED" then
    in_combat = true
    stop_ticker()
    fade(0, c.fade_out or 0.6)
    consolidate(true)
  elseif event == "PLAYER_REGEN_ENABLED" then
    in_combat = false
    consolidate(false)
    wanted = false
    panel:SetAlpha(0)
    refresh()
    start_ticker()
  elseif event == "PLAYER_ENTERING_WORLD" then
    in_combat = InCombatLockdown()
    if not in_combat then
      consolidate(false) -- put back a setting left over from a logout in combat
      start_ticker()
      refresh_soon()
    end
  elseif event == "UNIT_AURA" then
    if unit and (unit == "player" or unit:find("^party") or unit:find("^raid")) then
      refresh_soon()
    end
  elseif event == "UNIT_INVENTORY_CHANGED" then
    if unit == "player" then
      refresh_soon()
    end
  else
    refresh_soon()
  end
end)
