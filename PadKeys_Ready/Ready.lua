-- The opposite of PadKeys_NotReady: a spell flashes above the mouse
-- pointer (just outside the swing ring; or above the middle of the screen) as it
-- becomes ready, so you see it at the moment you can use it.
--
-- - Reactive abilities (Config.lua: Overpower, Revenge, Execute, ...)
--   flash as they become usable and aren't on a cooldown.
-- - Any spell or item on your action bars flashes as its cooldown ends,
--   if the cooldown lasted at least cooldown_min seconds.
--
-- Cooldown numbers are secret in combat, so how long a cooldown lasted is
-- measured with our own clock (GetTime) from when Blizzard's plain
-- isActive flag turned on to when it turned off; the global cooldown is
-- told apart with isOnGCD, read during SPELL_UPDATE_COOLDOWN as on
-- PadKeys_Bar. Usable is Blizzard's plain flag (IsUsableAction). Nothing
-- here is secure: one icon frame that never takes the mouse.

local ns = PadKeys
local c = ns.config.ready

local ab = C_ActionBar
local MAX_ACTION_SLOT = 180

local function is_secret(v)
  return issecretvalue and issecretvalue(v)
end

local function name_set(list)
  local set = {}
  for _, name in ipairs(list or {}) do
    set[name:lower()] = true
  end
  return set
end
local REACTIVE = name_set(c.reactive)
local IGNORE = name_set(c.ignore)

-- --- The flash --------------------------------------------------------------

local frame = CreateFrame("Frame", "PadKeysReady", UIParent)
frame:SetSize(c.size, c.size)
local at_cursor = c.anchor == "cursor"
if at_cursor then
  -- Follows the pointer; turning with the mouse hides it: stay put then.
  frame:SetScript("OnUpdate", function(self)
    if IsMouselooking and IsMouselooking() then
      return
    end
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "BOTTOMLEFT",
                  x / scale + (c.x or 0), y / scale + (c.y or 0))
  end)
else
  frame:SetPoint("CENTER", UIParent, "CENTER", c.x or 0, c.y or 0)
end
frame:SetFrameStrata("HIGH")
frame:SetAlpha(0)
frame:EnableMouse(false)

ns.box(frame, 0, c.rounded)

local icon = frame:CreateTexture(nil, "ARTWORK")
ns.fit_icon(frame, icon)
if c.rounded then
  ns.round(frame, icon, 1)
end
ns.icon(icon)

local label = ns.text(frame, c.label_size or 14, "white", "OVERLAY",
                      "GameFontHighlight")
label:SetShadowOffset(1, -1)
-- Above the icon at the mouse, clear of the radial below it.
if at_cursor then
  label:SetPoint("BOTTOM", frame, "TOP", 0, 4)
else
  label:SetPoint("TOP", frame, "BOTTOM", 0, -4)
end
label:SetShown(c.label and true or false)

-- A short pop as it appears, then the fade.
local anim = frame:CreateAnimationGroup()
local grow = anim:CreateAnimation("Scale")
grow:SetOrder(1)
grow:SetScaleFrom(0.7, 0.7)
grow:SetScaleTo(1, 1)
grow:SetDuration(0.12)
local fade = anim:CreateAnimation("Alpha")
fade:SetOrder(2)
fade:SetFromAlpha(1)
fade:SetToAlpha(0)
fade:SetStartDelay(c.hold or 0.5)
fade:SetDuration(c.fade_out or 0.8)
anim:SetScript("OnFinished", function()
  frame:SetAlpha(0)
end)

local function flash(texture, name)
  anim:Stop()
  icon:SetTexture(texture)
  label:SetText(name or "")
  frame:SetAlpha(1)
  anim:Play()
end

-- --- What is on the bars ----------------------------------------------------

-- An action slot's spell or item: a key that is the same wherever it sits
-- ("spell:12345"), and its name. nil for macros and empty slots.
local function what(action)
  local ok, kind, id = pcall(GetActionInfo, action)
  if not ok or is_secret(kind) or is_secret(id) or not id then
    return nil
  end
  local name
  if kind == "spell" then
    name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id) or
           (GetSpellInfo and GetSpellInfo(id))
  elseif kind == "item" then
    name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id) or
           (GetItemInfo and GetItemInfo(id))
  else
    return nil
  end
  if not name or is_secret(name) then
    return nil
  end
  return kind .. ":" .. id, name
end

local function fighting()
  return InCombatLockdown() or UnitAffectingCombat("player") or
         (UnitExists("target") and UnitCanAttack("player", "target") and
          not UnitIsDead("target"))
end

-- --- State ------------------------------------------------------------------

-- Per spell or item (its key): cooling_since = when its cooldown was seen
-- to start, usable = last usable flag (reactive ones only).
local state = {}
local on_gcd = {}

local function read_gcd()
  for action = 1, MAX_ACTION_SLOT do
    local cd = ab.HasAction(action) and ab.GetActionCooldown(action)
    on_gcd[action] = cd and cd.isOnGCD or nil
  end
end

-- One pass over the bars. Each spell or item is looked at once, from the
-- first slot it sits in.
local seen = {}
local function scan()
  wipe(seen)
  local now = GetTime()
  local want = not c.only_when_fighting or fighting()
  local ready
  for action = 1, MAX_ACTION_SLOT do
    if ab.HasAction(action) then
      local key, name = what(action)
      if key and not seen[key] then
        seen[key] = true
        local s = state[key]
        if not s then
          s = {}
          state[key] = s
        end
        local cd = ab.GetActionCooldown(action)
        local cooling = ns.cooling(cd, on_gcd[action])
        local lname = name:lower()

        -- A cooldown that ends after lasting long enough.
        if cooling then
          s.cooling_since = s.cooling_since or now
        elseif s.cooling_since then
          local lasted = now - s.cooling_since
          s.cooling_since = nil
          if (c.cooldown_min or 0) > 0 and lasted >= c.cooldown_min and
             not IGNORE[lname] and want then
            ready = ready or action
          end
        end

        -- A reactive ability that lights up.
        if REACTIVE[lname] then
          local usable = ab.IsUsableAction(action) and not cooling or false
          if usable and s.usable == false and fighting() then
            ready = action
          end
          s.usable = usable
        end
      end
    end
  end
  if ready then
    local _, name = what(ready)
    flash(ab.GetActionTexture(ready), name)
  end
end

-- Many events come at once; one scan on the next frame covers them. A
-- cooldown can also end without an event, so a slow scan runs as well.
local pending = CreateFrame("Frame")
pending:Hide()
pending:SetScript("OnUpdate", function(self)
  self:Hide()
  scan()
end)
local function soon()
  pending:Show()
end

local ticker = 0
local slow = CreateFrame("Frame")
slow:SetScript("OnUpdate", function(_, elapsed)
  ticker = ticker + elapsed
  if ticker >= 0.25 then
    ticker = 0
    scan()
  end
end)

-- --- Events -----------------------------------------------------------------

local events = CreateFrame("Frame")
for _, event in ipairs({
  "SPELL_UPDATE_COOLDOWN", "ACTIONBAR_UPDATE_COOLDOWN",
  "ACTIONBAR_UPDATE_USABLE", "SPELL_UPDATE_USABLE",
  "ACTIONBAR_SLOT_CHANGED", "PLAYER_TARGET_CHANGED", "PLAYER_ENTERING_WORLD",
}) do
  pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event)
  if event == "SPELL_UPDATE_COOLDOWN" then
    read_gcd()
  elseif event == "PLAYER_ENTERING_WORLD" then
    -- Cooldowns running at a loading screen were never seen to start;
    -- count them from now, and don't flash what is usable already.
    wipe(state)
  end
  soon()
end)
