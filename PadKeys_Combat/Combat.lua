-- Changes the UI when you enter and leave combat: a short text in the
-- middle of the screen ("Combat" / "Out of Combat") that fades in and out.
-- Buffs.lua adds the out-of-combat buff reminder; boss timers and PvP
-- cooldowns are meant to hang off the same two events later.
--
-- PLAYER_REGEN_DISABLED fires as you enter combat and PLAYER_REGEN_ENABLED
-- as you leave it. Nothing here is secure: a font string's text, colour
-- and alpha can change in combat, and no secret values are read.

local ns = PadKeys
local c = ns.config.combat

local DEFAULT_FONT = "Interface\\AddOns\\PadKeys_Bar\\Fonts\\RobotoCondensed-ExtraBold.ttf"

-- --- Banner ---------------------------------------------------------------

local banner = CreateFrame("Frame", "PadKeysCombatBanner", UIParent)
banner:SetSize(1, 1)
banner:SetPoint("CENTER", UIParent, "CENTER", c.x or 0, c.y or 0)
banner:SetFrameStrata("HIGH")
banner:SetAlpha(0)

-- The action bar's font and look (white with a drop shadow); Blizzard's
-- font object stays if the file can't be loaded.
local label = banner:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
local font = ns.config.bar and ns.config.bar.font or DEFAULT_FONT
label:SetFont(font, c.size or 28, "")
label:SetTextColor(1, 1, 1)
label:SetShadowColor(0, 0, 0, 1)
label:SetShadowOffset(2, -2)
label:SetPoint("CENTER")

-- Fade in, hold, fade out. Restarting it mid-way (leaving combat right
-- after entering) begins again from the start with the new text.
local anim = banner:CreateAnimationGroup()
local fade_in = anim:CreateAnimation("Alpha")
fade_in:SetOrder(1)
fade_in:SetFromAlpha(0)
fade_in:SetToAlpha(1)
fade_in:SetDuration(c.fade_in or 0.15)
local fade_out = anim:CreateAnimation("Alpha")
fade_out:SetOrder(2)
fade_out:SetFromAlpha(1)
fade_out:SetToAlpha(0)
fade_out:SetStartDelay(c.hold or 0.8)
fade_out:SetDuration(c.fade_out or 0.6)
anim:SetScript("OnFinished", function()
  banner:SetAlpha(0)
end)

local function show(text)
  anim:Stop()
  label:SetText(text)
  banner:SetAlpha(0)
  anim:Play()
end

-- --- Events ---------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event)
  local entering = event == "PLAYER_REGEN_DISABLED"
  if c.banner then
    if entering then
      show(c.enter_text)
    else
      show(c.leave_text)
    end
  end
end)
