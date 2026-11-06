-- The shared look: black and white, one font (ns.config.theme). Every
-- PadKeys addon makes its text and tints through these, so the font and
-- greys are set in one place.

local _, ns = ...
local c = ns.config.theme

-- Greys by name, 1 is white. Text is white; grey marks something dimmed
-- (out of range, not loaded, a label next to its key).
ns.grey = {
  white = 1,
  light = 0.75,
  mid = 0.5,
  dark = 0.3,
}

-- "|cffbfbfbftext|r" in a grey from ns.grey (or a number from 0 to 1).
function ns.paint(text, shade)
  local v = math.floor((ns.grey[shade] or shade) * 255 + 0.5)
  return format("|cff%02x%02x%02x%s|r", v, v, v, text)
end

-- Restyle a font string: the theme font at `size`, white (or `shade`), with
-- a drop shadow. A font file that can't be loaded leaves the string's own
-- font object.
function ns.style(fs, size, shade)
  local _, current = fs:GetFont()
  fs:SetFont(c.font, size or current or 12, "")
  local v = ns.grey[shade] or shade or 1
  fs:SetTextColor(v, v, v)
  fs:SetShadowColor(0, 0, 0, 1)
  fs:SetShadowOffset(1, -1)
  return fs
end

-- A new font string in the theme. `template` is Blizzard's font object to
-- fall back on.
function ns.text(parent, size, shade, layer, template)
  local fs = parent:CreateFontString(nil, layer or "OVERLAY",
                                     template or "GameFontHighlight")
  return ns.style(fs, size, shade)
end

-- A texture tinted grey: Blizzard's art loses its colour first.
function ns.tint(tex, shade, alpha)
  local v = ns.grey[shade] or shade or 1
  tex:SetDesaturated(true)
  tex:SetVertexColor(v, v, v, alpha or 1)
end

-- Spell and item icons: grey only when grey_icons is on.
function ns.icon(tex)
  tex:SetDesaturated(c.grey_icons and true or false)
end

-- Every texture in a frame and its children loses its colour, and every
-- font string takes the theme font: for Blizzard templates (a window's
-- border, title and close button).
function ns.monochrome(frame)
  for _, region in ipairs({ frame:GetRegions() }) do
    if region.SetDesaturated then
      region:SetDesaturated(true)
    elseif region.SetFont then
      ns.style(region)
    end
  end
  for _, child in ipairs({ frame:GetChildren() }) do
    ns.monochrome(child)
  end
end

-- UIErrorsFrame:AddMessage in white.
function ns.flash(text)
  UIErrorsFrame:AddMessage(text, 1, 1, 1)
end
