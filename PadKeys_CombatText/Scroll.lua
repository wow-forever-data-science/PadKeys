-- A small scroll of combat text lines, shared by Target.lua and
-- Incoming.lua: at most `lines` lines. Each line starts at the anchor,
-- drifts `rise` pixels in `direction` over its life and fades out after
-- `hold` seconds. A new line that would overlap the one before glides
-- the older ones further along instead of snapping them a row.
--
-- Damage amounts are secret in combat: addon code may show them but not
-- compare them, do arithmetic on them or join them to other text. So a
-- line is the amount alone, abbreviated by AbbreviateNumbers (which takes
-- secrets), and its colour and size come from the event's plain flags.

local ns = PadKeys
local c = ns.config.combattext

local M = {}
ns.combattext = M

function M.is_secret(v)
  return issecretvalue and issecretvalue(v)
end

-- "12.3K" for a number, secret or not; the number itself if that fails.
function M.amount_text(amount)
  if AbbreviateNumbers then
    local ok, text = pcall(AbbreviateNumbers, amount)
    if ok then
      return text
    end
  end
  return amount
end

-- The words for a hit that did no damage, from UNIT_COMBAT's event and
-- flag.
M.MISS_WORDS = {
  MISS = "Miss", DODGE = "Dodge", PARRY = "Parry", BLOCK = "Block",
  RESIST = "Resist", ABSORB = "Absorb", IMMUNE = "Immune", EVADE = "Evade",
  DEFLECT = "Deflect", REFLECT = "Reflect",
}

local Scroll = {}
Scroll.__index = Scroll

local function release(scroll, row)
  row:Hide()
  for i, r in ipairs(scroll.rows) do
    if r == row then
      table.remove(scroll.rows, i)
      break
    end
  end
  scroll.free[#scroll.free + 1] = row
end

local function new_row(scroll)
  local s = scroll.settings
  local row = CreateFrame("Frame", nil, scroll.frame)
  row:SetSize(1, s.size)
  row:Hide()

  if scroll.icons then
    row.box = CreateFrame("Frame", nil, row)
    row.box:SetSize(s.size + 2, s.size + 2)
    row.box:SetPoint("LEFT")
    row.icon = row.box:CreateTexture(nil, "ARTWORK")
    ns.skin_icon(row.box, row.icon, 0, true)
    ns.icon(row.icon)
    row.text = ns.text(row, s.size)
    row.text:SetPoint("LEFT", row.box, "RIGHT", 3, 0)
  else
    row.text = ns.text(row, s.size)
    row.text:SetPoint("CENTER")
  end

  return row
end

local function life()
  return (c.hold or 1.2) + (c.fade or 0.5)
end

-- How far a line has drifted by itself, `age` seconds after it came.
local function drift(age)
  return (c.rise or 40) * math.min(age / life(), 1)
end

-- Each frame: every line drifts, glides toward its push, and fades.
local GLIDE = 14 -- how fast a pushed line catches up; higher is snappier
function Scroll:update(elapsed)
  local now = GetTime()
  local sign = self.settings.direction == "down" and -1 or 1
  local point = self.icons and "LEFT" or "CENTER"
  local hold, fade = c.hold or 1.2, c.fade or 0.5
  local catch = math.min(elapsed * GLIDE, 1)
  for i = #self.rows, 1, -1 do
    local row = self.rows[i]
    local age = now - row.born
    if age >= hold + fade then
      release(self, row)
    else
      row.shown_push = row.shown_push + (row.push - row.shown_push) * catch
      row:ClearAllPoints()
      row:SetPoint(point, self.frame, point, 0,
                   sign * (drift(age) + row.shown_push))
      row:SetAlpha(age <= hold and 1 or 1 - (age - hold) / fade)
    end
  end
  if not self.rows[1] then
    self.driver:Hide()
  end
end

-- Older lines make room for the newest: each sits at least a line's
-- height past the one after it (where it is headed, not where it is).
function Scroll:make_room()
  local s = self.settings
  local step = math.floor(s.size * (c.crit_scale or 1.3) + 3)
  local now = GetTime()
  local before
  for _, row in ipairs(self.rows) do
    local at = drift(now - row.born) + row.push
    if before and at < before + step then
      row.push = row.push + before + step - at
      at = before + step
    end
    before = at
  end
end

-- Adds a line: `text` (an amount from amount_text, or a word), `kind`
-- ("normal", "crit" or "special"), and an icon texture (nil for none).
function Scroll:add(text, kind, texture)
  local s = self.settings
  local row = table.remove(self.free) or new_row(self)
  while #self.rows >= (s.lines or 4) do
    release(self, self.rows[#self.rows])
  end
  table.insert(self.rows, 1, row)

  local crit = kind == "crit"
  ns.style(row.text, crit and math.floor(s.size * (c.crit_scale or 1.3) + 0.5)
                     or s.size)
  local color = c.colors[kind] or c.colors.normal
  row.text:SetTextColor(color[1], color[2], color[3])
  if not pcall(row.text.SetText, row.text, text) then
    row.text:SetText("?")
  end
  if row.box then
    if texture then
      row.icon:SetTexture(texture)
      row.box:Show()
    else
      row.box:Hide()
    end
  end

  row.born = GetTime()
  row.push, row.shown_push = 0, 0
  self:make_room()
  row:ClearAllPoints()
  row:SetPoint(self.icons and "LEFT" or "CENTER", self.frame)
  row:SetAlpha(1)
  row:Show()
  self.driver:Show()
end

function Scroll:clear()
  while self.rows[1] do
    release(self, self.rows[1])
  end
end

-- A scroll with `settings` (size, lines, direction). `icons`: room for an
-- icon left of each line; without it lines are centred.
function M.new_scroll(settings, icons)
  local frame = CreateFrame("Frame", nil, UIParent)
  frame:SetSize(1, 1)
  frame:SetFrameStrata("MEDIUM")
  local scroll = setmetatable({
    frame = frame, settings = settings, icons = icons, rows = {}, free = {},
  }, Scroll)
  -- Its own frame for the motion: the scroll's frame may have an OnUpdate
  -- of its own (Incoming.lua follows the cursor with it).
  scroll.driver = CreateFrame("Frame", nil, frame)
  scroll.driver:Hide()
  scroll.driver:SetScript("OnUpdate", function(_, elapsed)
    scroll:update(elapsed)
  end)
  return scroll
end
