-- In combat, Blizzard's buff frame shows only the short buffs: the long
-- ones fade out until combat ends. Long means over 90 seconds left as
-- combat starts (Blizzard's BUFF_DURATION_WARNING_TIME), or no duration;
-- weapon enchants always count as long.
--
-- Forever has no buff consolidation (the consolidateBuffs setting is gone),
-- and in combat every aura field is secret, already as combat starts. So
-- the long buffs are picked out of combat, on every aura change and each
-- second, by their place in your buff list, and the last pick holds
-- through combat. In combat an icon is known by that place (Blizzard's own
-- buttonInfo.index, a plain number): buffs gained in combat come after the
-- picked ones, so they show. When a picked buff falls off, the places
-- after it move up and can't be told apart, so everything shows again
-- until combat ends.
--
-- Only the icons' alpha changes, as PadKeys_Fade does: they stay where
-- they are, so the long ones leave gaps, and nothing here is secure. A
-- timed icon sets its own alpha every frame (Blizzard's expiry flash,
-- AuraButtonMixin:OnUpdate), so a hook on each icon's SetAlpha puts a
-- hidden one back to 0. Your auras can still be inspected with
-- PadKeys_Auras (Ctrl+C).

local ns = PadKeys
local cfg = ns.config.combat.buffs
if not (cfg and cfg.hide_long_in_combat) then
  return
end

local LONG = BUFF_DURATION_WARNING_TIME or 90

-- long_at[place] for the long buffs, out of `picked` buffs in all.
local long_at, picked = {}, 0
local hiding = false

-- Out of combat only; a failed read keeps the last pick.
local function remember_long()
  if hiding or InCombatLockdown() then
    return
  end
  local now, long, count = GetTime(), {}, 0
  local ok = pcall(function()
    for i = 1, 40 do
      local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
      if not aura then
        break
      end
      count = i
      local expires = aura.expirationTime
      if not expires or expires == 0 or expires - now > LONG then
        long[i] = true
      end
    end
  end)
  if ok then
    long_at, picked = long, count
  end
end

-- How many buffs (not weapon enchants) the buff frame has now.
local function buff_count()
  local n = 0
  for _, info in ipairs(BuffFrame.auraInfo or {}) do
    if info.auraType == "Buff" then
      n = n + 1
    end
  end
  return n
end

local function is_long(icon, places_hold)
  if icon.auraType == "TempEnchant" then
    return true
  end
  local info = icon.buttonInfo
  return places_hold and icon.auraType == "Buff" and info and
    long_at[info.index] or false
end

-- Icons to keep at alpha 0, and the icons already hooked.
local hidden, hooked = {}, {}

local function hold(icon)
  if hidden[icon] and icon:GetAlpha() ~= 0 then
    icon:SetAlpha(0)
  end
end

local function apply()
  if not BuffFrame then
    return
  end
  -- Fewer buffs than picked: one of them fell off, places moved.
  local ok, count = pcall(buff_count)
  local places_hold = ok and count >= picked
  if hiding and not places_hold then
    picked = math.huge -- stays shown until combat ends
  end
  for _, icon in ipairs(BuffFrame.auraFrames or {}) do
    if not hooked[icon] then
      hooked[icon] = true
      hooksecurefunc(icon, "SetAlpha", hold)
    end
    local was = hidden[icon]
    hidden[icon] = hiding and is_long(icon, places_hold) or nil
    if hidden[icon] then
      hold(icon)
    elseif was then
      icon:SetAlpha(1)
    end
  end
end

-- Blizzard reassigns the icons on every aura change; set the alpha after.
-- Hooked on first use too, in case the buff frame loaded after this file.
local frame_hooked = false
local function hook_frame()
  if not frame_hooked and BuffFrame and BuffFrame.UpdateAuraButtons then
    frame_hooked = true
    hooksecurefunc(BuffFrame, "UpdateAuraButtons", apply)
  end
end
hook_frame()

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterUnitEvent("UNIT_AURA", "player")
events:SetScript("OnEvent", function(_, event)
  if event == "UNIT_AURA" or event == "PLAYER_ENTERING_WORLD" then
    remember_long()
    return
  end
  hook_frame()
  hiding = event == "PLAYER_REGEN_DISABLED"
  apply()
  remember_long()
end)

-- Buffs run down below 90 seconds without an aura change.
C_Timer.NewTicker(1, remember_long)
