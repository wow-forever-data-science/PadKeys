-- Your big cooldowns that are ready, right of the pointer (Config.lua,
-- readout.big): self-buffs, trinkets, impactful spells. A row of icons,
-- one per spell or item on your action bars (hidden bars count) whose
-- cooldown is long and isn't running. Each pops in as it comes back and
-- goes as you use it. Only while fighting, by default.
--
-- What counts as big is learned, not listed: a cooldown seen to last at
-- least big.min seconds (out of combat Blizzard gives the duration; in
-- combat it is measured with our own clock between Blizzard's plain
-- isActive flag turning on and off), or a spell whose base cooldown is
-- that long (GetSpellBaseCooldown, where the client has it). What was
-- learned is saved (PadKeysDB.big_cooldowns), so it is known after a
-- /reload. big.names adds names before they were ever seen.
--
-- Running or not is Blizzard's plain isActive flag, the global cooldown
-- told apart with isOnGCD (read during SPELL_UPDATE_COOLDOWN). Usable is
-- the plain IsUsableAction: an icon you can't use now (no mana, no
-- target) is dimmed. Nothing secret is compared, nothing is secure, and
-- nothing takes the mouse.

local ns = PadKeys
local c = ns.config.readout
local b = c.big
local readout = PadKeysReadout
if not (b and b.enabled and readout) then
  return
end

local ab = C_ActionBar
local MAX_ACTION_SLOT = 180
local size = b.icon_size or 26
local gap = b.gap or 4

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
local IGNORE = name_set(b.ignore)
local NAMES = name_set(b.names)

-- Learned big cooldowns, by key ("spell:12345"): saved once the base
-- addon's saved variables are loaded, in this table until then.
local early = {}
local function learned()
  if ns.db then
    ns.db.big_cooldowns = ns.db.big_cooldowns or {}
    for key in pairs(early) do
      ns.db.big_cooldowns[key] = true
    end
    wipe(early)
    return ns.db.big_cooldowns
  end
  return early
end

-- --- Icons ------------------------------------------------------------------

local column = CreateFrame("Frame", nil, readout)
column:SetSize(size, size)
column:SetPoint("LEFT", readout, "CENTER", b.x or 92, b.y or 0)
column:EnableMouse(false)

local icons = {}
for i = 1, b.max or 4 do
  local f = CreateFrame("Frame", nil, column)
  f:SetSize(size, size)
  ns.box(f, 0, c.rounded)
  f.icon = f:CreateTexture(nil, "ARTWORK")
  ns.fit_icon(f, f.icon)
  if c.rounded then
    ns.round(f, f.icon, 1)
  end
  ns.icon(f.icon)
  local pop = f:CreateAnimationGroup()
  local grow = pop:CreateAnimation("Scale")
  grow:SetScaleFrom(0.6, 0.6)
  grow:SetScaleTo(1, 1)
  grow:SetDuration(0.15)
  local fade = pop:CreateAnimation("Alpha")
  fade:SetFromAlpha(0)
  fade:SetToAlpha(1)
  fade:SetDuration(0.15)
  f.pop = pop
  f:Hide()
  icons[i] = f
end

-- In action-bar order: a row growing right from x, y (b.grow "right"),
-- or a column centred on the pointer's height, top to bottom.
local function place(count)
  local height = count * size + math.max(count - 1, 0) * gap
  for i, f in ipairs(icons) do
    f:ClearAllPoints()
    if b.grow == "down" then
      f:SetPoint("TOPLEFT", column, "LEFT", 0, height / 2 - (i - 1) * (size + gap))
    else
      f:SetPoint("LEFT", column, "LEFT", (i - 1) * (size + gap), 0)
    end
  end
end

-- --- What is on the bars ----------------------------------------------------

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
  return kind .. ":" .. id, name, kind, id
end

local function fighting()
  return InCombatLockdown() or UnitAffectingCombat("player") or
         (UnitExists("target") and UnitCanAttack("player", "target"))
end

local function long_base(kind, id)
  if kind ~= "spell" or not GetSpellBaseCooldown then
    return false
  end
  local ok, ms = pcall(GetSpellBaseCooldown, id)
  return ok and not is_secret(ms) and type(ms) == "number" and
         ms >= (b.min or 60) * 1000
end

-- --- State ------------------------------------------------------------------

local since = {}   -- key -> when its cooldown was seen to start
local on_gcd = {}
local shown = {}   -- keys showing now

local function read_gcd()
  for action = 1, MAX_ACTION_SLOT do
    local cd = ab.HasAction(action) and ab.GetActionCooldown(action)
    on_gcd[action] = cd and cd.isOnGCD or nil
  end
end

local seen = {}
local function scan()
  wipe(seen)
  local big = learned()
  local now = GetTime()
  local min = b.min or 60
  local want = not b.only_when_fighting or fighting()
  local ready = {}
  for action = 1, MAX_ACTION_SLOT do
    if ab.HasAction(action) then
      local key, name, kind, id = what(action)
      if key and not seen[key] then
        seen[key] = true
        local cd = ab.GetActionCooldown(action)
        local cooling = cd and cd.isActive and not on_gcd[action] or false
        if cooling then
          since[key] = since[key] or now
          local d = cd.duration
          if not is_secret(d) and type(d) == "number" and d >= min then
            big[key] = true
          end
        elseif since[key] then
          if now - since[key] >= min then
            big[key] = true
          end
          since[key] = nil
        end
        local lname = name:lower()
        if not big[key] and (NAMES[lname] or long_base(kind, id)) then
          big[key] = true
        end
        if want and big[key] and not cooling and not IGNORE[lname]
            and #ready < #icons then
          ready[#ready + 1] = { key = key, action = action }
        end
      end
    end
  end
  place(#ready)
  local was = shown
  shown = {}
  for i, f in ipairs(icons) do
    local r = ready[i]
    if r then
      f.icon:SetTexture(ab.GetActionTexture(r.action))
      local v = ab.IsUsableAction(r.action) and 1 or 0.4
      f.icon:SetVertexColor(v, v, v)
      f:Show()
      if not was[r.key] then
        f.pop:Stop()
        f.pop:Play()
      end
      shown[r.key] = true
    else
      f:Hide()
    end
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

local ticker = 0
local slow = CreateFrame("Frame")
slow:SetScript("OnUpdate", function(_, elapsed)
  ticker = ticker + elapsed
  if ticker >= 0.25 then
    ticker = 0
    scan()
  end
end)

local events = CreateFrame("Frame")
for _, event in ipairs({
  "SPELL_UPDATE_COOLDOWN", "ACTIONBAR_UPDATE_COOLDOWN",
  "ACTIONBAR_UPDATE_USABLE", "SPELL_UPDATE_USABLE", "ACTIONBAR_SLOT_CHANGED",
  "PLAYER_TARGET_CHANGED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
  "PLAYER_ENTERING_WORLD",
}) do
  pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event)
  if event == "SPELL_UPDATE_COOLDOWN" then
    read_gcd()
  elseif event == "PLAYER_ENTERING_WORLD" then
    -- Cooldowns running at a loading screen were never seen to start.
    wipe(since)
  end
  pending:Show()
end)
