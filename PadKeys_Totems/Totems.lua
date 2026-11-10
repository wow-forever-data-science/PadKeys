-- Blizzard's totem bar (MultiCastActionBarFrame) in the PadKeys look:
-- each button gets the PadKeys bar's black border and rounded corners,
-- Blizzard's frame art and gold edges go, and the text takes the theme
-- font. Blizzard's buttons stay: they still cast, page and open their
-- flyouts, and Edit Mode still moves the bar.
--
-- The buttons are secure, so this only changes how they look: new
-- textures, masks, alpha and fonts, which are allowed in combat too. It
-- never moves, resizes, shows or hides a button. Blizzard's art is hidden
-- with alpha, which Blizzard's own updates don't set, so it stays hidden
-- when Blizzard sets the art again.

local ns = PadKeys
local c = ns.config.totems

if not MultiCastActionBarFrame then
  return
end

local SLOTS = 4
local ACTIONS = 12 -- three pages of four (Call of the Elements, ...)

local function style_text(fs, size)
  if fs then
    ns.style(fs, size)
  end
end

local function whiten(texture)
  if texture then
    ns.tint(texture, "white")
  end
end

-- The icon 1px inside the button, Blizzard's mask off. Blizzard's
-- UpdateButtonArt may anchor the icon again, so this runs after it too.
local function fit(button)
  if button.icon then
    ns.unmask(button.icon)
    ns.fit_icon(button, button.icon)
  end
end

-- An action button (ActionButtonTemplate): a totem, or the summon and
-- recall spells.
local function skin_button(button)
  if not button then
    return
  end
  local name = button:GetName()

  if button.icon then
    ns.skin_icon(button, button.icon, 0, c.rounded)
  end
  if button.UpdateButtonArt then
    hooksecurefunc(button, "UpdateButtonArt", fit)
  end

  ns.conceal(button:GetNormalTexture())
  ns.conceal(button.SlotArt)
  ns.conceal(button.SlotBackground)
  ns.conceal(button.Border)
  if not c.element_colors then
    ns.conceal(button.overlayTex) -- the element frame over a totem
  end
  ns.conceal(_G[name .. "Highlight"]) -- summon and recall's gold frame

  -- Pressed, mouseover and active (checked) stay, in white.
  whiten(button:GetPushedTexture())
  whiten(button:GetHighlightTexture())
  whiten(button:GetCheckedTexture())
  whiten(button.SpellHighlightTexture)
  whiten(button.NewActionTexture)

  style_text(button.HotKey or _G[name .. "HotKey"], c.hotkey_size)
  style_text(button.Count, c.count_size)
  style_text(button.Name, c.count_size)
  local cooldown = button.cooldown
  if cooldown and cooldown.GetCountdownFontString then
    style_text(cooldown:GetCountdownFontString(), c.countdown_size)
  end
end

-- An empty slot under the totem buttons: a black box, and Blizzard's
-- element frame only with element_colors.
local function skin_slot(slot)
  if not slot then
    return
  end
  ns.conceal(slot.background)
  if not c.element_colors then
    ns.conceal(slot.overlayTex)
  end
  ns.box(slot, c.background_alpha, c.rounded)
  whiten(slot:GetHighlightTexture())
end

for i = 1, SLOTS do
  skin_slot(_G["MultiCastSlotButton" .. i])
end
for i = 1, ACTIONS do
  skin_button(_G["MultiCastActionButton" .. i])
end
skin_button(MultiCastSummonSpellButton)
skin_button(MultiCastRecallSpellButton)
