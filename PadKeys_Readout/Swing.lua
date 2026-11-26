-- Your swing timer around the mouse pointer (Config.lua, readout.swing):
-- a thin ring just outside the cast ring that fills from one auto attack
-- to the next: white for your main hand, orange for Auto Shot, and the off
-- hand if you ask for it.
--
-- Its faint track is the line the readouts sit on: shown all through
-- combat (swing.track = "combat"), with the cast ring inside it and the
-- big cooldowns, tracked buffs, totems, boss rows, debuffs, your pet and
-- the hits you take just outside it.
--
-- The client tells us each swing as it happens (PLAYER_SWING, from
-- C_SwingTimer) with the time to the next one, so nothing is guessed from
-- the combat log or attack speed. The time goes to a Cooldown frame whose
-- swipe is a ring texture, like the cast ring. If the client ever makes
-- that time secret and SetCooldown refuses it, the ring stays empty
-- (pcall) instead of erroring. Nothing here is secure or takes the mouse.

local ns = PadKeys
local c = ns.config.readout
local s = c.swing
local readout = PadKeysReadout
if not (s and s.enabled and readout) then
  return
end

local MEDIA = "Interface\\AddOns\\PadKeys_Readout\\Media\\"
local size = s.size or 70

local types = Enum and Enum.PlayerSwingType or {}
local MAIN, OFF, RANGED = types.MainHand or 0, types.OffHand or 1, types.Ranged or 2

local frame = CreateFrame("Frame", "PadKeysReadoutSwing", readout)
frame:SetSize(size, size)
frame:SetPoint("CENTER")
frame:EnableMouse(false)

-- The faint track: in combat, or only under a filling ring.
local track = frame:CreateTexture(nil, "BACKGROUND")
track:SetAllPoints()
track:SetTexture(MEDIA .. "Thin")
track:SetVertexColor(0.5, 0.5, 0.5, s.track_alpha or 0.2)
track:Hide()

local layers = {}

local function in_combat()
  return InCombatLockdown() or UnitAffectingCombat("player")
end

local function refresh_track()
  local any = s.track == "combat" and in_combat() or false
  for _, layer in pairs(layers) do
    any = any or layer:IsShown()
  end
  track:SetShown(any)
end

local function make_layer(color, layer_size)
  local layer = CreateFrame("Frame", nil, frame)
  layer:SetSize(layer_size, layer_size)
  layer:SetPoint("CENTER")
  local cd = CreateFrame("Cooldown", nil, layer, "CooldownFrameTemplate")
  cd:SetAllPoints()
  cd:SetDrawEdge(false)
  cd:SetDrawBling(false)
  cd:SetHideCountdownNumbers(true)
  -- Reverse: the coloured part is the time gone, so it fills up towards
  -- the next swing.
  cd:SetReverse(s.fill ~= false)
  pcall(cd.SetSwipeTexture, cd, MEDIA .. "Thin")
  pcall(cd.SetUseCircularEdge, cd, true)
  cd:SetSwipeColor(color[1], color[2], color[3], s.alpha or 0.85)
  cd:HookScript("OnCooldownDone", function()
    layer:Hide()
    refresh_track()
  end)
  layer.cd = cd
  layer:Hide()
  return layer
end

if s.main_hand ~= false then
  layers[MAIN] = make_layer(s.main_color or { 1, 1, 1 }, size)
end
if s.ranged ~= false then
  layers[RANGED] = make_layer(s.ranged_color or { 1, 0.6, 0.15 }, size)
end
if s.off_hand then
  -- A little inside the main hand's, so both can show.
  layers[OFF] = make_layer(s.off_color or { 0.7, 0.7, 0.7 }, size - 8)
end

local function on_swing(duration, kind)
  local layer = layers[kind]
  if not layer then
    return
  end
  -- Melee and Auto Shot share the ring: the newest one takes it.
  if kind == MAIN or kind == RANGED then
    local other = layers[kind == MAIN and RANGED or MAIN]
    if other then
      other.cd:Clear()
      other:Hide()
    end
  end
  local ok = pcall(layer.cd.SetCooldown, layer.cd, GetTime(), duration)
  layer:SetShown(ok)
  refresh_track()
end

local function clear()
  for _, layer in pairs(layers) do
    layer.cd:Clear()
    layer:Hide()
  end
  refresh_track()
end

local events = CreateFrame("Frame")
pcall(events.RegisterEvent, events, "PLAYER_SWING")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, event, duration, kind)
  if event == "PLAYER_SWING" then
    on_swing(duration, kind)
  elseif event == "PLAYER_REGEN_DISABLED" then
    if s.track == "combat" then
      track:Show()
    end
  else
    clear()
  end
end)
refresh_track()
