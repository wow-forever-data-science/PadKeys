-- A small scroll of combat text lines, shared by Target.lua and
-- Incoming.lua: at most `lines` lines, the newest at the anchor and older
-- ones moved one step in `direction`, each fading after `hold` seconds.
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
  row.anim:Stop()
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

  row.anim = row:CreateAnimationGroup()
  local fade = row.anim:CreateAnimation("Alpha")
  fade:SetFromAlpha(1)
  fade:SetToAlpha(0)
  fade:SetStartDelay(c.hold or 1.2)
  fade:SetDuration(c.fade or 0.5)
  row.anim:SetScript("OnFinished", function()
    release(scroll, row)
  end)
  return row
end

function Scroll:layout()
  local s = self.settings
  local step = math.floor(s.size * (c.crit_scale or 1.3) + 3)
  local sign = s.direction == "down" and -1 or 1
  local point = self.icons and "LEFT" or "CENTER"
  for i, row in ipairs(self.rows) do
    row:ClearAllPoints()
    row:SetPoint(point, self.frame, point, 0, sign * (i - 1) * step)
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

  self:layout()
  row.anim:Stop()
  row:SetAlpha(1)
  row:Show()
  row.anim:Play()
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
  return setmetatable({
    frame = frame, settings = settings, icons = icons, rows = {}, free = {},
  }, Scroll)
end
