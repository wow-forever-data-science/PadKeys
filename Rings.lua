-- Our own secure rings, for what Blizzard's radials don't offer: your own
-- spells, items and macros, and pings in combat. Hold the ring key, move the
-- mouse towards a slot, release to use it. Releasing near the centre
-- cancels. (The main menu uses Blizzard's own radial, see Radial.lua.)
--
-- Each ring key clicks a hidden secure action button. A secure snippet
-- wrapped around its OnClick runs on key down (show the ring where the mouse
-- is, and suppress the click) and on key up (hide it, work out which slot
-- the mouse points at, and turn the click into "slot<i>"). The button then
-- casts or uses that slot's type-slot<i> action. All of this works in
-- combat; only editing the rings (Config.lua + /reload) needs to be out of
-- combat.

local _, ns = ...

local cfg = ns.config.rings
local SLOT_SIZE = 44
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local header = CreateFrame("Frame", "PadKeysRingHeader", UIParent,
                           "SecureHandlerBaseTemplate")
-- Full-screen protected frame used to read the mouse position securely.
local area = CreateFrame("Frame", "PadKeysRingArea", UIParent,
                         "SecureFrameTemplate")
area:SetAllPoints(UIParent)

-- Runs in the restricted environment, with self = the ring button.
local ON_CLICK = [[
  local ring = self:GetFrameRef("ring")
  local area = self:GetFrameRef("area")
  local x, y = area:GetMousePosition()
  local w, h = area:GetWidth(), area:GetHeight()
  if down then
    x, y = (x or 0.5) * w, (y or 0.5) * h
    ring:SetAttribute("cx", x)
    ring:SetAttribute("cy", y)
    ring:ClearAllPoints()
    ring:SetPoint("CENTER", area, "BOTTOMLEFT", x, y)
    ring:Show()
    return false
  end
  if not ring:IsShown() then
    return false
  end
  ring:Hide()
  if not x then
    return false
  end
  local dx = x * w - ring:GetAttribute("cx")
  local dy = y * h - ring:GetAttribute("cy")
  local n = self:GetAttribute("numslots")
  local dead = self:GetAttribute("deadzone")
  if n == 0 or dx * dx + dy * dy < dead * dead then
    return false
  end
  local step = 360 / n
  local angle = (90 - math.deg(math.atan2(dy, dx))) % 360
  return "slot" .. (math.floor((angle + step / 2) / step) % n + 1)
]]

-- Same maths as the snippet, for the highlight drawn while the key is held.
local function pointed_slot(ring, n)
  local x, y = GetCursorPosition()
  local scale = area:GetEffectiveScale()
  local dx = x / scale - (ring:GetAttribute("cx") or 0)
  local dy = y / scale - (ring:GetAttribute("cy") or 0)
  if n == 0 or dx * dx + dy * dy < cfg.deadzone * cfg.deadzone then
    return nil
  end
  local step = 360 / n
  local angle = (90 - math.deg(math.atan2(dy, dx))) % 360
  return math.floor((angle + step / 2) / step) % n + 1
end

local function slot_icon(slot)
  if slot.icon then
    return slot.icon
  end
  local icon
  if slot.spell then
    icon = C_Spell and C_Spell.GetSpellTexture and
      C_Spell.GetSpellTexture(slot.spell)
  elseif slot.item then
    icon = C_Item and C_Item.GetItemIconByID and
      C_Item.GetItemIconByID(slot.item)
  end
  return icon or DEFAULT_ICON
end

-- Secure action attributes for one slot, read when the button is clicked
-- as "slot<i>".
local function set_slot(button, i, slot)
  local b = "slot" .. i
  if slot.spell then
    button:SetAttribute("type-" .. b, "spell")
    button:SetAttribute("spell-" .. b, slot.spell)
  elseif slot.item then
    local item = slot.item
    if type(item) == "number" then
      item = "item:" .. item
    end
    button:SetAttribute("type-" .. b, "item")
    button:SetAttribute("item-" .. b, item)
  elseif slot.macro then
    button:SetAttribute("type-" .. b, "macro")
    button:SetAttribute("macrotext-" .. b, slot.macro)
  elseif slot.binding then
    button:SetAttribute("type-" .. b, "binding")
    button:SetAttribute("binding-" .. b, slot.binding)
  end
end

-- Handler for the custom "binding" type: run a key binding's action, e.g.
-- TOGGLESPELLBOOK. Opening windows isn't a protected action.
local function run_binding(self, _, button)
  local binding = self:GetAttribute("binding-" .. button)
  if binding then
    RunBinding(binding)
  end
end

local function build_ring(index, ring)
  local name = "PadKeysRing" .. index
  local n = #ring.slots

  local button = CreateFrame("Button", name, UIParent,
                             "SecureActionButtonTemplate")
  button:RegisterForClicks("AnyDown", "AnyUp")
  button:SetAttribute("useOnKeyDown", false)
  button:SetAttribute("numslots", n)
  button:SetAttribute("deadzone", cfg.deadzone)
  button.binding = run_binding

  local frame = CreateFrame("Frame", name .. "Frame", UIParent,
                            "SecureFrameTemplate")
  local size = cfg.radius * 2 + SLOT_SIZE * 2
  frame:SetSize(size, size)
  frame:SetFrameStrata("DIALOG")
  frame:SetPoint("CENTER")
  frame:Hide()

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("CENTER")
  title:SetText(ring.name or name)

  local icons = {}
  for i, slot in ipairs(ring.slots) do
    set_slot(button, i, slot)
    local angle = math.rad(90 - (i - 1) * 360 / n)
    local x, y = math.cos(angle) * cfg.radius, math.sin(angle) * cfg.radius

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(SLOT_SIZE, SLOT_SIZE)
    icon:SetPoint("CENTER", frame, "CENTER", x, y)
    icons[i] = icon

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOP", icon, "BOTTOM", 0, -2)
    label:SetText(slot.label or "")
  end

  local glow = frame:CreateTexture(nil, "BACKGROUND")
  glow:SetSize(SLOT_SIZE + 14, SLOT_SIZE + 14)
  glow:SetColorTexture(0.2, 0.8, 1, 0.5)
  glow:Hide()

  frame:SetScript("OnShow", function()
    for i, slot in ipairs(ring.slots) do
      icons[i]:SetTexture(slot_icon(slot))
    end
  end)
  frame:SetScript("OnUpdate", function(self)
    local i = pointed_slot(self, n)
    if i then
      glow:SetPoint("CENTER", icons[i], "CENTER")
      glow:Show()
    else
      glow:Hide()
    end
  end)

  SecureHandlerSetFrameRef(button, "ring", frame)
  SecureHandlerSetFrameRef(button, "area", area)
  SecureHandlerWrapScript(button, "OnClick", header, ON_CLICK)
end

for i, ring in ipairs(cfg.list) do
  build_ring(i, ring)
end
