-- Your player portrait shows what you are in, so a hidden buff frame still
-- tells you: the active stance or form (warrior stances, druid forms,
-- rogue stealth), else the active hunter aspect or paladin aura, else your
-- class icon (Config.lua). What you are tracking sits on it as a badge.
--
-- Stances and forms come from the stance bar's own flags
-- (GetShapeshiftFormInfo), plain in combat too. Aspects and auras are
-- buffs: auras are secret in combat, so they are read out of combat only.
-- In combat your own cast of an aspect or aura switches the icon instead
-- (UNIT_SPELLCAST_SUCCEEDED); one cancelled in combat shows as combat ends.
--
-- The icon is a texture of ours on top of Blizzard's portrait, in the same
-- frame and layer; Blizzard's portrait is only made see-through, so its
-- own updates never fight ours. Nothing here is secure.

local ns = PadKeys
local c = ns.config.portrait

local portrait = PlayerFrame and (PlayerFrame.PlayerFrameContainer
  and PlayerFrame.PlayerFrameContainer.PlayerPortrait or PlayerPortrait)
if not portrait then
  return
end

local _, class = UnitClass("player")

-- Buffs that act like a stance, matched by name (every rank shares it).
local BUFF_STANCES = {
  HUNTER = {
    13165, 13163, 5118, 13159, 13161, 20043,          -- Hawk, Monkey, Cheetah, Pack, Beast, Wild
  },
  PALADIN = {
    465, 7294, 19746, 19876, 19888, 19891, 20218,     -- Devotion, Retribution, Concentration,
  },                                                  -- Shadow, Frost, Fire Resistance, Sanctity
}

local function spell_name(id)
  if C_Spell and C_Spell.GetSpellName then
    return C_Spell.GetSpellName(id)
  end
  return GetSpellInfo and (GetSpellInfo(id))
end

local buff_names = {}
for _, id in ipairs(BUFF_STANCES[class] or {}) do
  local name = spell_name(id)
  if name then
    buff_names[name] = true
  end
end

-- The icon, round like the portrait it covers.
local parent = portrait:GetParent()
local layer, sublevel = portrait:GetDrawLayer()
local icon = parent:CreateTexture(nil, layer, nil, sublevel)
icon:SetAllPoints(portrait)
local mask = parent:CreateMaskTexture()
mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask",
                "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
mask:SetAllPoints(portrait)
icon:AddMaskTexture(mask)
icon:Hide()

local function show_icon(texture)
  icon:SetTexture(texture)
  local t = ns.ICON_TRIM
  icon:SetTexCoord(t, 1 - t, t, 1 - t)
  ns.icon(icon)
  icon:Show()
  portrait:SetAlpha(0)
end

local function show_fallback()
  local atlas = c.fallback == "class" and GetClassAtlas and GetClassAtlas(class)
  if atlas then
    icon:SetAtlas(atlas)
    icon:SetDesaturated(false)
    icon:Show()
    portrait:SetAlpha(0)
  else
    icon:Hide()
    portrait:SetAlpha(1)
  end
end

local function stance_icon()
  for i = 1, GetNumShapeshiftForms() do
    local texture, active = GetShapeshiftFormInfo(i)
    if active then
      return texture
    end
  end
end

-- The last aspect or aura seen out of combat; kept through combat.
local buff_icon
local function read_buffs()
  if not (c.buffs and next(buff_names)) or InCombatLockdown() then
    return
  end
  local found
  pcall(function()
    for i = 1, 40 do
      local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
      if not aura then
        break
      end
      if buff_names[aura.name] then
        found = aura.icon
        return
      end
    end
  end)
  buff_icon = found
end

local function is_secret(v)
  return issecretvalue and issecretvalue(v)
end

local function spell_texture(id)
  if C_Spell and C_Spell.GetSpellTexture then
    return C_Spell.GetSpellTexture(id)
  end
  return GetSpellTexture and GetSpellTexture(id)
end

-- A cast of an aspect or aura (any rank) makes it the one shown.
local function read_cast(spell_id)
  if not c.buffs or not spell_id or is_secret(spell_id) then
    return
  end
  local name = spell_name(spell_id)
  if name and not is_secret(name) and buff_names[name] then
    buff_icon = spell_texture(spell_id) or buff_icon
  end
end

local function update()
  local ok, texture = pcall(stance_icon)
  texture = ok and texture or buff_icon
  if texture then
    show_icon(texture)
  else
    show_fallback()
  end
end

-- The tracking badge: a rounded box on the portrait's lower right, above
-- the frame's ring. Hovering shows the name; clicks pass through to the
-- player frame.
local badge
local function tracking()
  if not (C_Minimap and C_Minimap.GetNumTrackingTypes) then
    return
  end
  for i = 1, C_Minimap.GetNumTrackingTypes() do
    local info = C_Minimap.GetTrackingInfo(i)
    if info and info.active and info.type == "spell" then
      return info
    end
  end
end

local function update_tracking()
  local info = tracking()
  badge.name = info and info.name
  if info then
    badge.icon:SetTexture(info.texture)
    ns.icon(badge.icon)
    badge:Show()
  else
    badge:Hide()
  end
end

if c.tracking then
  badge = CreateFrame("Frame", "PadKeysPortraitTracking", parent)
  badge:SetSize(c.tracking_size, c.tracking_size)
  badge:SetPoint("CENTER", portrait, "BOTTOMRIGHT", -6, 6)
  badge:SetFrameLevel(parent:GetFrameLevel() + 5)
  ns.box(badge, 1, true)
  badge.icon = badge:CreateTexture(nil, "ARTWORK")
  ns.fit_icon(badge, badge.icon)
  ns.round(badge, badge.icon, 1)
  badge:SetMouseMotionEnabled(true)
  badge:SetMouseClickEnabled(false)
  badge:SetScript("OnEnter", function(self)
    if self.name then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(self.name, 1, 1, 1)
      GameTooltip:Show()
    end
  end)
  badge:SetScript("OnLeave", GameTooltip_Hide)
  badge:Hide()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
events:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterUnitEvent("UNIT_AURA", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
if badge then
  events:RegisterEvent("MINIMAP_UPDATE_TRACKING")
end
events:SetScript("OnEvent", function(_, event, _, _, spell_id)
  if event == "MINIMAP_UPDATE_TRACKING" then
    update_tracking()
    return
  end
  if event == "UNIT_SPELLCAST_SUCCEEDED" then
    read_cast(spell_id)
  elseif event ~= "UPDATE_SHAPESHIFT_FORM" and event ~= "UPDATE_SHAPESHIFT_FORMS" then
    read_buffs()
  end
  update()
  if event == "PLAYER_ENTERING_WORLD" and badge then
    update_tracking()
  end
end)
