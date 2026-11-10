-- The PadKeys button look, shared by PadKeys_Bar's own buttons and the
-- addons that restyle Blizzard's (PadKeys_Cooldowns, PadKeys_Totems):
-- slightly rounded corners, a 1px black border behind the icon, and
-- Blizzard's icon border trimmed off.
--
-- Restyling a Blizzard frame here only calls widget methods on it (new
-- textures, masks, anchors, alpha). Nothing is stored on Blizzard's
-- frames, so their own code stays untainted.

local _, ns = ...

-- Media/RoundedSquare.tga, made by tools/make_rounded_mask.py. It fills the
-- whole square, so an icon keeps its size.
ns.ROUNDED_MASK = "Interface\\AddOns\\PadKeys\\Media\\RoundedSquare"

-- 0.07 and 0.93 trim the border Blizzard draws into its icon files.
ns.ICON_TRIM = 0.07

-- Rounded corners on `texture`: a mask on `frame`, `inset` pixels in from
-- its edges.
function ns.round(frame, texture, inset)
  local mask = frame:CreateMaskTexture()
  mask:SetTexture(ns.ROUNDED_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
  mask:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
  mask:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
  texture:AddMaskTexture(mask)
  return mask
end

-- Takes every mask off a texture (Blizzard's own icon shapes).
function ns.unmask(texture)
  if not (texture.GetNumMaskTextures and texture.RemoveMaskTexture) then
    return
  end
  for i = texture:GetNumMaskTextures(), 1, -1 do
    texture:RemoveMaskTexture(texture:GetMaskTexture(i))
  end
end

-- Puts an icon 1px inside `frame` with its border trimmed. Safe to call
-- again when Blizzard re-anchors the icon.
function ns.fit_icon(frame, icon)
  icon:ClearAllPoints()
  icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
  icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
  local t = ns.ICON_TRIM
  icon:SetTexCoord(t, 1 - t, t, 1 - t)
end

-- A black box behind a frame's contents: the 1px border, and inside it a
-- see-through background (`background_alpha`, 0 for none). Below every
-- other background texture, so Blizzard's icon stays on top.
function ns.box(frame, background_alpha, rounded)
  local border = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
  border:SetAllPoints(frame)
  border:SetColorTexture(0, 0, 0, 1)
  if rounded then
    ns.round(frame, border, 0)
  end
  if background_alpha and background_alpha > 0 then
    local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    bg:SetColorTexture(0, 0, 0, background_alpha)
    if rounded then
      ns.round(frame, bg, 1)
    end
  end
  return border
end

-- An icon of a Blizzard frame in the PadKeys look: Blizzard's mask off,
-- the icon fitted 1px inside `frame` and rounded, the black box behind it.
-- Returns the border texture.
function ns.skin_icon(frame, icon, background_alpha, rounded)
  ns.unmask(icon)
  ns.fit_icon(frame, icon)
  if rounded then
    ns.round(frame, icon, 1)
  end
  return ns.box(frame, background_alpha, rounded)
end

-- Hides a texture for good: Blizzard may set its atlas or texture again,
-- but never its alpha.
function ns.conceal(texture)
  if texture then
    texture:SetAlpha(0)
  end
end
