-- Blizzard's Cooldown Manager in the PadKeys look. All four viewers:
-- Essential and Utility cooldowns, buff icons and buff bars. Each icon
-- gets the PadKeys bar's black border and rounded corners in place of
-- Blizzard's round mask and ring, and the text takes the theme font.
-- Settings below are in Config.lua.
--
-- The viewers keep icons in a frame pool, so each icon is restyled once,
-- when a viewer first hands it out (OnAcquireItemFrame). Blizzard sets the
-- swipe and tint again on every refresh, so those changes run right after
-- Blizzard's own (hooksecurefunc on the icon's methods).
--
-- The Cooldown Manager handles secret aura data in secure code. This only
-- calls widget methods on its frames and keeps its own notes in a table of
-- its own, never on Blizzard's frames, so Blizzard's code stays untainted.
-- It never reads a cooldown or aura value: it only reads back the colour
-- Blizzard just gave an icon (plain constants).

local ns = PadKeys
local c = ns.config.cooldowns

local RING = "UI-HUD-CoolDownManager-IconOverlay"
local FLAT = "Interface\\Buttons\\WHITE8X8"

-- Which viewer an icon belongs to decides the swipe it keeps.
local VIEWERS = {
  EssentialCooldownViewer = "cooldown",
  UtilityCooldownViewer = "cooldown",
  BuffIconCooldownViewer = "buff",
  BuffBarCooldownViewer = "bar",
}

local skinned = setmetatable({}, { __mode = "k" })
local hooked = {}

local function is_secret(v)
  return issecretvalue and issecretvalue(v)
end

-- Blizzard's ring around an icon has no key: found by its atlas.
local function hide_ring(frame)
  for _, region in ipairs({ frame:GetRegions() }) do
    if region.GetAtlas and region:GetAtlas() == RING then
      region:SetAlpha(0)
    end
  end
end

local function style_text(fs, size)
  if fs then
    ns.style(fs, size)
  end
end

-- After Blizzard's RefreshIconColor: its red, blue or dark tint as a grey.
local function grey_tint(item)
  local icon = item:GetIconTexture()
  local r, g, b = icon:GetVertexColor()
  if is_secret(r) or (r > 0.99 and g > 0.99 and b > 0.99) then
    return
  end
  local v = b > r + 0.2 and 0.6 or 0.35 -- blue is "not enough mana"
  icon:SetVertexColor(v, v, v)
end

-- After Blizzard's RefreshSpellCooldownInfo: our swipe.
local function swipe_for(kind)
  return function(item)
    local cooldown = item:GetCooldownFrame()
    if not cooldown then
      return
    end
    cooldown:SetDrawEdge(false)
    if kind == "cooldown" then
      cooldown:SetDrawSwipe(c.cooldown_swipe and true or false)
    elseif c.buff_swipe then
      cooldown:SetSwipeColor(0, 0, 0, 0.7)
    else
      cooldown:SetDrawSwipe(false)
    end
  end
end

local swipes = {
  cooldown = swipe_for("cooldown"),
  buff = swipe_for("buff"),
}

local function skin_bar(item)
  local bar = item.Bar
  if not bar then
    return
  end
  style_text(bar.Name)
  style_text(bar.Duration)
  if not c.grey_bars then
    return
  end
  bar:SetStatusBarTexture(FLAT)
  bar:SetStatusBarColor(ns.grey.light, ns.grey.light, ns.grey.light)
  if bar.BarBG then
    bar.BarBG:SetColorTexture(0, 0, 0, 0.75)
    bar.BarBG:ClearAllPoints()
    bar.BarBG:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
    bar.BarBG:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
  end
  ns.conceal(bar.Pip)
end

local function skin(item, kind, viewer_name)
  if skinned[item] then
    return
  end
  skinned[item] = true

  -- A buff bar's icon is a frame of its own; the others are the item.
  local holder = item
  if kind == "bar" then
    holder = item.Icon
  end
  local icon = item:GetIconTexture()
  if holder and icon then
    hide_ring(holder)
    ns.skin_icon(holder, icon, 0, c.rounded)
  end

  local cooldown = item.GetCooldownFrame and item:GetCooldownFrame()
  if cooldown and cooldown.GetCountdownFontString then
    -- The other viewers keep Blizzard's size, in the theme font.
    local essential = viewer_name == "EssentialCooldownViewer"
    style_text(cooldown:GetCountdownFontString(),
               essential and c.countdown_size or nil)
  end
  if item.ChargeCount then
    style_text(item.ChargeCount.Current)
  end
  if item.Applications then
    style_text(item.Applications.Applications)
  end
  if kind == "bar" and item.Icon then
    style_text(item.Icon.Applications)
  end
  if item.CooldownFlash and item.CooldownFlash.Flipbook then
    ns.tint(item.CooldownFlash.Flipbook, "white")
  end
  skin_bar(item)

  if swipes[kind] and item.RefreshSpellCooldownInfo then
    hooksecurefunc(item, "RefreshSpellCooldownInfo", swipes[kind])
    swipes[kind](item)
  end
  if c.grey_tints and kind == "cooldown" and item.RefreshIconColor then
    hooksecurefunc(item, "RefreshIconColor", grey_tint)
    grey_tint(item)
  end
end

local function hook_viewers()
  for name, kind in pairs(VIEWERS) do
    local viewer = _G[name]
    if viewer and viewer.OnAcquireItemFrame and not hooked[name] then
      hooked[name] = true
      hooksecurefunc(viewer, "OnAcquireItemFrame", function(_, item)
        skin(item, kind, name)
      end)
      -- Icons already handed out before this loaded.
      if viewer.itemFramePool then
        for item in viewer.itemFramePool:EnumerateActive() do
          skin(item, kind, name)
        end
      end
    end
  end
end

hook_viewers()

-- The Cooldown Manager may load after this addon.
local owner = CreateFrame("Frame")
owner:RegisterEvent("ADDON_LOADED")
owner:SetScript("OnEvent", function(_, _, addon)
  if addon == "Blizzard_CooldownViewer" then
    hook_viewers()
  end
end)
