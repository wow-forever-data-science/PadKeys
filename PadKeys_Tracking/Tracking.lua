-- What you are tracking (Find Herbs, Track Beasts, ...) as a round badge
-- on the minimap's rim; hover it for the name. Blizzard's own tracking
-- button shows a magnifier only.
--
-- The minimap's tracking list is secret in combat, so it is read out of
-- combat only. In combat your own cast of a tracking spell switches the
-- badge instead (UNIT_SPELLCAST_SUCCEEDED); tracking turned off in combat
-- shows as combat ends.
--
-- The ring is the circle behind the level on the player frame. Clicks
-- pass through to the minimap; nothing here is secure.

local ns = PadKeys
local c = ns.config.tracking

if not (Minimap and C_Minimap and C_Minimap.GetNumTrackingTypes) then
  return
end

local RING = "UI-HUD-UnitFrame-SmallCircle"

local function is_secret(v)
  return issecretvalue and issecretvalue(v)
end

local function spell_name(id)
  if C_Spell and C_Spell.GetSpellName then
    return C_Spell.GetSpellName(id)
  end
  return GetSpellInfo and (GetSpellInfo(id))
end

local function spell_texture(id)
  if C_Spell and C_Spell.GetSpellTexture then
    return C_Spell.GetSpellTexture(id)
  end
  return GetSpellTexture and GetSpellTexture(id)
end

local badge = CreateFrame("Frame", "PadKeysTracking", Minimap)
badge:SetSize(c.size, c.size)
badge:SetPoint("CENTER", Minimap, c.point, c.x, c.y)
badge:SetFrameLevel(Minimap:GetFrameLevel() + 5)
badge.icon = badge:CreateTexture(nil, "ARTWORK")
if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(RING) then
  -- The ring's dark middle sits under the icon, so only its edge shows.
  local ring = badge:CreateTexture(nil, "BORDER")
  ring:SetAtlas(RING)
  ring:SetAllPoints(badge)
  local inset = c.ring_width
  badge.icon:SetPoint("TOPLEFT", inset, -inset)
  badge.icon:SetPoint("BOTTOMRIGHT", -inset, inset)
  local t = ns.ICON_TRIM
  badge.icon:SetTexCoord(t, 1 - t, t, 1 - t)
  local round = badge:CreateMaskTexture()
  round:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask",
                   "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
  round:SetAllPoints(badge.icon)
  badge.icon:AddMaskTexture(round)
else
  ns.box(badge, 1, true)
  ns.fit_icon(badge, badge.icon)
  ns.round(badge, badge.icon, 1)
end
badge:SetMouseMotionEnabled(true)
badge:SetMouseClickEnabled(false)
badge:SetScript("OnEnter", function(self)
  if self.name then
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(self.name, 1, 1, 1)
    GameTooltip:Show()
  end
end)
badge:SetScript("OnLeave", GameTooltip_Hide)
badge:Hide()

-- Names of the tracking spells seen out of combat, so a cast in combat can
-- be told apart.
local tracking_names = {}

local function active_tracking()
  local active
  for i = 1, C_Minimap.GetNumTrackingTypes() do
    local info = C_Minimap.GetTrackingInfo(i)
    if info and info.type == "spell" then
      tracking_names[info.name] = true
      if info.active then
        active = active or info
      end
    end
  end
  return active
end

local function show(name, texture)
  badge.name = name
  if texture then
    badge.icon:SetTexture(texture)
    ns.icon(badge.icon)
    badge:Show()
  else
    badge:Hide()
  end
end

local function read_list()
  if InCombatLockdown() then
    return
  end
  local ok, info = pcall(active_tracking)
  if ok then
    show(info and info.name, info and info.texture)
  end
end

-- A cast of a tracking spell makes it the one shown.
local function read_cast(spell_id)
  if not spell_id or is_secret(spell_id) then
    return
  end
  local name = spell_name(spell_id)
  if name and not is_secret(name) and tracking_names[name] then
    show(name, spell_texture(spell_id))
  end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("MINIMAP_UPDATE_TRACKING")
events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
events:SetScript("OnEvent", function(_, event, _, _, spell_id)
  if event == "UNIT_SPELLCAST_SUCCEEDED" then
    read_cast(spell_id)
  else
    read_list()
  end
end)
