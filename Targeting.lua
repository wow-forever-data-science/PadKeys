-- Group cycling, the keyboard version of the gamepad's party/raid targeting:
-- each press targets the next (left button) or previous (right button) group
-- member, in raid frame order. It is a secure button whose wrapped OnClick
-- picks the next unit that exists, so it works in combat.

local _, ns = ...

-- Runs in the restricted environment, with self = the cycle button.
local ON_CLICK = [[
  local prefix, max = "party", 4
  if UnitExists("raid1") then
    prefix, max = "raid", 40
  end
  local step = (button == "RightButton") and -1 or 1
  local idx = self:GetAttribute("idx") or 0
  for _ = 0, max do
    idx = idx + step
    if idx > max then
      idx = 0
    elseif idx < 0 then
      idx = max
    end
    -- In a raid you are one of raid1-40, so slot 0 (player) is skipped.
    local unit = (idx == 0) and "player" or (prefix .. idx)
    if not (prefix == "raid" and idx == 0) and UnitExists(unit) then
      self:SetAttribute("idx", idx)
      self:SetAttribute("unit", unit)
      return
    end
  end
  return false
]]

local header = CreateFrame("Frame", "PadKeysHeader", UIParent,
                           "SecureHandlerBaseTemplate")

local button = CreateFrame("Button", "PadKeysGroupCycle", UIParent,
                           "SecureActionButtonTemplate")
button:RegisterForClicks("AnyDown")
button:SetAttribute("useOnKeyDown", true)
button:SetAttribute("type", "target")
SecureHandlerWrapScript(button, "OnClick", header, ON_CLICK)

ns.group_cycle = button
