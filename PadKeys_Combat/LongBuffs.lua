-- In combat, Blizzard's buff frame shows only the short buffs: the long
-- ones fade out until combat ends. Long means over 90 seconds left as
-- combat starts (Blizzard's BUFF_DURATION_WARNING_TIME), or no duration;
-- weapon enchants always count as long.
--
-- Forever has no buff consolidation (the consolidateBuffs setting is gone),
-- and in combat aura times are secret, so the long buffs are picked as
-- combat starts, by aura instance. Buffs gained in combat always show.
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

local long_ids = {}
local hiding = false

local function remember_long()
  wipe(long_ids)
  local now = GetTime()
  pcall(function()
    for i = 1, 40 do
      local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
      if not aura then
        break
      end
      local expires = aura.expirationTime
      if not expires or expires == 0 or expires - now > LONG then
        long_ids[aura.auraInstanceID] = true
      end
    end
  end)
end

-- An icon whose aura can't be read counts as short, so it shows.
local function is_long(icon)
  if icon.auraType == "TempEnchant" then
    return true
  end
  local ok, long = pcall(function()
    local info = icon.buttonInfo
    return info and long_ids[info.auraInstanceID] or false
  end)
  return ok and long
end

-- Icons to keep at alpha 0, and the icons already hooked.
local hidden, hooked = {}, {}

local function hold(icon)
  if hidden[icon] and icon:GetAlpha() ~= 0 then
    icon:SetAlpha(0)
  end
end

local function apply()
  for _, icon in ipairs(BuffFrame and BuffFrame.auraFrames or {}) do
    if not hooked[icon] then
      hooked[icon] = true
      hooksecurefunc(icon, "SetAlpha", hold)
    end
    local was = hidden[icon]
    hidden[icon] = hiding and is_long(icon) or nil
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
events:SetScript("OnEvent", function(_, event)
  hook_frame()
  hiding = event == "PLAYER_REGEN_DISABLED"
  if hiding then
    remember_long()
  end
  apply()
end)
