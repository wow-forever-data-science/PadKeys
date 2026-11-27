-- Buff bar: out of combat, a row of icons for the long buffs that matter
-- for your class and group and are missing or running out (under 5
-- minutes, Config.lua), consumables whose buff you don't have, and your
-- supplies (ammo, reagents, durability, bag space, pet). Each icon is a
-- secure button that fixes it on a click. Combat hides it at once; it
-- fades back in as you leave combat.
--
-- What counts depends on who is in your party or raid:
-- - group buffs (Fortitude, Mark of the Wild, Arcane Intellect,
--   blessings) when someone of that class is in the group; Intellect only
--   for classes with mana;
-- - if you can cast one yourself, every member in the group who is missing
--   it (or has under 5 minutes left), by name;
-- - your own class buffs (mage and warlock armor, Inner Fire, Omen of
--   Clarity, Trueshot Aura, Aspect of the Hawk, Lightning Shield) and, for rogues and shamans,
--   poisons or an imbue on your weapons;
-- - consumables in your bags whose buff you don't have: elixirs, flasks,
--   scrolls, food that makes you Well Fed, and sharpening stones or oils
--   while your weapon has no enchant.
--
-- LongBuffs.lua hides the long buffs in Blizzard's buff frame in combat.
-- The target frame's and nameplates' auras are Blizzard's protected frames,
-- so they keep Blizzard's own filters; PadKeys_Auras (C) reads them.
--
-- Auras are read only out of combat (in combat they are secret), and every
-- read is wrapped in pcall. The icons are secure action buttons, set up
-- out of combat only; in combat a state driver keeps the bar hidden.

local ns = PadKeys
local c = ns.config.combat
local cfg = c.buffs
if not (cfg and cfg.enabled) then
  return
end

local MANA = {
  DRUID = true, HUNTER = true, MAGE = true, PALADIN = true,
  PRIEST = true, SHAMAN = true, WARLOCK = true,
}

-- Each buff, matched by name (every rank and the group version share a
-- family). `caster`: a group buff that class casts; `who = "mana"` only for
-- classes with mana; `own_only`: only when you know it (a talent nobody
-- else can be seen to have); `per_caster`: one each from every caster in
-- the group (blessings). `class`: a buff of your own, shown when you know
-- it. `weapon`: weapon enchants (rogue poisons, shaman imbues). `warn_at`:
-- seconds left under which it shows, for buffs shorter than the usual. Turn one off with
-- `ignore` in Config.lua.
local BUFFS = {
  { key = "fortitude", caster = "PRIEST", who = "all", spells = { 1243, 21562 } },
  { key = "mark", caster = "DRUID", who = "all", spells = { 1126, 21849 } },
  { key = "intellect", caster = "MAGE", who = "mana", spells = { 1459, 23028 } },
  { key = "spirit", caster = "PRIEST", who = "mana", own_only = true, spells = { 14752, 27681 } },
  { key = "blessing", caster = "PALADIN", who = "all", per_caster = true, label = "Blessings",
    spells = { 19740, 19742, 20217, 1038, 19977, 20911,           -- Might, Wisdom, Kings, Salvation, Light, Sanctuary
               25782, 25894, 25898, 25895, 25890, 25899 } },      -- their Greater versions
  { key = "mage_armor", class = "MAGE", label = "Armor", spells = { 168, 7302, 6117 } },
  { key = "demon_armor", class = "WARLOCK", spells = { 687, 706 } },
  { key = "inner_fire", class = "PRIEST", spells = { 588 } },
  { key = "omen", class = "DRUID", spells = { 16864 } },
  { key = "trueshot", class = "HUNTER", spells = { 19506 } },
  { key = "aspect_hawk", class = "HUNTER", spells = { 13165 } },
  { key = "poisons", class = "ROGUE", weapon = true, spells = { 2842 } },
  { key = "lightning_shield", class = "SHAMAN", spells = { 324 } },
  -- Rockbiter lasts 5 minutes, so it warns under 1 minute.
  { key = "imbue", class = "SHAMAN", weapon = true, label = "Imbue", warn_at = 60,
    spells = { 8017, 8024, 8033, 8232 } },                      -- Rockbiter, Flametongue, Frostbrand, Windfury
}

-- --- Spells -----------------------------------------------------------------

local function spell_name(id)
  if C_Spell and C_Spell.GetSpellName then
    return C_Spell.GetSpellName(id)
  end
  return GetSpellInfo and (GetSpellInfo(id))
end

local function spell_icon(id)
  if C_Spell and C_Spell.GetSpellTexture then
    return C_Spell.GetSpellTexture(id)
  end
  return GetSpellTexture and GetSpellTexture(id)
end

local function knows(id)
  if IsPlayerSpell and IsPlayerSpell(id) then
    return true
  end
  if C_SpellBook and C_SpellBook.IsSpellKnown then
    return C_SpellBook.IsSpellKnown(id) and true or false
  end
  return IsSpellKnown and IsSpellKnown(id) or false
end

local function knows_any(buff)
  for _, id in ipairs(buff.spells) do
    if knows(id) then
      return true
    end
  end
  return false
end

-- The family's names (localised), filled once the client has them.
local function names_of(buff)
  if not buff.names then
    local names, complete = {}, true
    for _, id in ipairs(buff.spells) do
      local name = spell_name(id)
      if name then
        names[name] = true
      else
        complete = false
      end
    end
    if not complete then
      return names
    end
    buff.names = names
  end
  return buff.names
end

local function label_of(buff)
  return buff.label or spell_name(buff.spells[1]) or buff.key
end

-- --- Group ------------------------------------------------------------------

-- The units to look at: the raid, or you and your party.
local function group_units()
  local units = {}
  if IsInRaid() then
    for i = 1, GetNumGroupMembers() do
      units[#units + 1] = "raid" .. i
    end
  else
    units[1] = "player"
    if IsInGroup() then
      for i = 1, GetNumSubgroupMembers() do
        units[#units + 1] = "party" .. i
      end
    end
  end
  return units
end

local function class_of(unit)
  return select(2, UnitClass(unit))
end

-- A member whose buffs can be counted on: online, alive and in sight.
local function present(unit)
  return UnitExists(unit) and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit)
     and (UnitIsUnit(unit, "player") or UnitIsVisible(unit))
end

local function short_name(unit)
  if UnitIsUnit(unit, "player") then
    return "you"
  end
  return (UnitName(unit)) or unit
end

-- --- Auras ------------------------------------------------------------------

-- A unit's buffs as { name, left, source, spell }, read once per refresh; nil if
-- they can't be read. `left` is seconds, math.huge for no duration.
local aura_cache = {}

local function buffs_of(unit)
  local cached = aura_cache[unit]
  if cached ~= nil then
    return cached or nil
  end
  local list = {}
  local now = GetTime()
  local ok = pcall(function()
    for i = 1, 40 do
      local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
      if not aura then
        break
      end
      local expires = aura.expirationTime
      list[#list + 1] = {
        name = aura.name,
        left = (expires and expires > 0) and (expires - now) or math.huge,
        source = aura.sourceUnit,
        spell = aura.spellId,
        icon = aura.icon,
        stacks = aura.applications,
        instance = aura.auraInstanceID,
      }
    end
  end)
  aura_cache[unit] = ok and list or false
  return ok and list or nil
end

-- The most time left on any aura of the family on unit (from `source`
-- only, if given): seconds, math.huge for no duration, or nil if missing.
-- false if the auras can't be read.
local function time_left(unit, buff, source)
  local list = buffs_of(unit)
  if not list then
    return false
  end
  local names = names_of(buff)
  local best
  for _, aura in ipairs(list) do
    if names[aura.name] and (not source or (aura.source and UnitIsUnit(aura.source, source))) then
      if not best or aura.left > best then
        best = aura.left
      end
    end
  end
  return best
end

local function low(left, warn_at)
  return left == nil or left < (warn_at or cfg.warn_at)
end

local function clock(seconds)
  seconds = math.max(0, math.floor(seconds))
  return format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

-- Time left in one unit, short enough for an icon: 2h, 45m, 30s.
local function short_clock(seconds)
  seconds = math.max(0, math.floor(seconds))
  if seconds >= 3600 then
    return format("%dh", math.floor(seconds / 3600))
  elseif seconds >= 60 then
    return format("%dm", math.floor(seconds / 60))
  end
  return format("%ds", seconds)
end

-- --- Rows -------------------------------------------------------------------

-- Each row: { icon, label, missing = { names }, left = seconds, who = name }.
-- A row is shown when something is missing or a time is under warn_at.

-- Who is missing it (names) and the lowest time under warn_at among the
-- rest, over `units`.
-- Also returns the unit to cast on first: the first missing it, else the
-- one with the least time left.
local function survey(buff, units, source)
  local missing, lowest, lowest_who = {}, nil, nil
  local first, lowest_unit
  for _, unit in ipairs(units) do
    local left = time_left(unit, buff, source)
    if left == nil then
      missing[#missing + 1] = short_name(unit)
      first = first or unit
    elseif left and left < cfg.warn_at and (not lowest or left < lowest) then
      lowest, lowest_who, lowest_unit = left, short_name(unit), unit
    end
  end
  return missing, lowest, lowest_who, first or lowest_unit
end

-- The best rank you know of a family, by name: the last spell of the list
-- you know (single-target versions come first in the lists above).
local function best_known(buff)
  local best
  for _, id in ipairs(buff.spells) do
    if knows(id) then
      best = id
    end
  end
  return best and spell_name(best)
end

local function group_row(buff, units, casters)
  if casters == 0 or (buff.own_only and not knows_any(buff)) then
    return nil
  end
  local eligible = function(unit)
    return buff.who ~= "mana" or MANA[class_of(unit)]
  end
  local row = { icon = spell_icon(buff.spells[1]), label = label_of(buff) }
  if class_of("player") == buff.caster and knows_any(buff) then
    -- You cast it: everyone it is for, and for blessings only your own.
    local targets = {}
    for _, unit in ipairs(units) do
      if present(unit) and eligible(unit) then
        targets[#targets + 1] = unit
      end
    end
    local unit
    row.missing, row.left, row.who, unit =
      survey(buff, targets, buff.per_caster and "player" or nil)
    -- Click: the single-target spell on whoever needs it first.
    local spell = spell_name(buff.spells[1])
    if unit and spell then
      row.click = { type = "spell", spell = spell, unit = unit }
    end
  elseif eligible("player") then
    if buff.per_caster then
      -- One blessing from each paladin in the group.
      local list = buffs_of("player")
      if not list then
        return nil
      end
      local names, have, lowest = names_of(buff), 0, nil
      for _, aura in ipairs(list) do
        if names[aura.name] then
          have = have + 1
          if not lowest or aura.left < lowest then
            lowest = aura.left
          end
        end
      end
      if have < casters then
        row.count = format("%d/%d", have, casters)
      elseif lowest and lowest < cfg.warn_at then
        row.left = lowest
      end
      return (row.count or row.left) and row or nil
    end
    row.missing, row.left = survey(buff, { "player" })
  else
    return nil
  end
  if #row.missing == 0 and not row.left then
    return nil
  end
  return row
end

local function own_row(buff, my_class)
  if buff.class ~= my_class or not knows_any(buff) then
    return nil
  end
  local left = time_left("player", buff)
  if left == false or not low(left, buff.warn_at) then
    return nil
  end
  local spell = best_known(buff)
  return {
    icon = spell_icon(buff.spells[1]),
    label = label_of(buff),
    missing = left == nil and { "you" } or {},
    left = left,
    click = spell and { type = "spell", spell = spell, unit = "player" },
  }
end

local SLOTS = {
  { name = "Main hand", inv = 16, slot = 0 },
  { name = "Off hand", inv = 17, slot = 1 },
}

local function is_weapon(item)
  if not item then
    return false
  end
  local get = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
  local class_id = get and select(6, get(item))
  return class_id == 2
end

-- Seconds of enchant left on the weapon slot, or nil if none; false if
-- it can't be read.
local function enchant_left(slot)
  local ok, left = pcall(function()
    if C_Item and C_Item.GetWeaponEnchantInfo then
      for _, enchant in pairs(C_Item.GetWeaponEnchantInfo(slot.slot) or {}) do
        if enchant.hasEnchant then
          return (enchant.timeLeft or 0) / 1000
        end
      end
      return nil
    end
    local info = { GetWeaponEnchantInfo() }
    local base = slot.slot == 0 and 1 or 5
    if info[base] then
      return (info[base + 1] or 0) / 1000
    end
    return nil
  end)
  if not ok then
    return false
  end
  return left
end

local function weapon_rows(buff, my_class, rows)
  if buff.class ~= my_class or not knows_any(buff) then
    return
  end
  for _, slot in ipairs(SLOTS) do
    local item = GetInventoryItemID("player", slot.inv)
    if is_weapon(item) then
      local left = enchant_left(slot)
      if left ~= false and low(left, buff.warn_at) then
        local click
        if my_class == "ROGUE" then
          -- A poison from your bags onto this weapon.
          local poison = ns.bag_item_named and
            ns.bag_item_named(slot.inv == 16 and cfg.poison_main or cfg.poison_off)
          if poison then
            click = { type = "macro",
                      macrotext = format("/use %s\n/use %d", poison, slot.inv) }
          end
        elseif slot.inv == 16 then
          -- A shaman's imbue: the best one you know, on the main hand.
          local spell = best_known(buff)
          if spell then
            click = { type = "spell", spell = spell, unit = "player" }
          end
        end
        rows[#rows + 1] = {
          icon = GetInventoryItemTexture("player", slot.inv),
          label = slot.name .. " " .. label_of(buff):lower(),
          missing = left == nil and { "you" } or {},
          left = left,
          click = click,
        }
      end
    end
  end
end

-- --- Consumables ------------------------------------------------------------

local WELL_FED = 19705

local function item_icon_class(id)
  local get = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
  local _, _, _, _, icon, class_id, subclass_id = get(id)
  return icon, class_id, subclass_id
end

-- Consumable subclasses that give a buff: elixir, flask, scroll.
local BUFF_SUBCLASS = { [2] = true, [3] = true, [4] = true }

local function item_name(id)
  if C_Item and C_Item.GetItemNameByID then
    return C_Item.GetItemNameByID(id)
  end
  return (GetItemInfo(id))
end

-- What a consumable gives, from its use spell's description (the "Use:"
-- line), remembered per item: "food" (Well Fed), "weapon" (a temporary
-- weapon enchant: stones, oils), "buff" (anything lasting 10 minutes or
-- more: elixirs, flasks, scrolls), or false (potions, bandages, plain
-- food). Classic item data files many of these as plain consumables, so
-- an elixir, flask or scroll subclass counts as "buff" too, whatever the
-- description says. English descriptions only.
-- Also returns the use spell's name and ID, to match against your auras.
local kinds = {}
local function consumable_kind(id, subclass_id)
  local known = kinds[id]
  if known ~= nil then
    return known.kind, known.name, known.spell
  end
  local get = C_Item and C_Item.GetItemSpell or GetItemSpell
  local name, spell = get(id)
  if not spell then
    return false -- not loaded yet, or no use spell; asked again next time
  end
  if BUFF_SUBCLASS[subclass_id] then
    kinds[id] = { kind = "buff", name = name, spell = spell }
    return "buff", name, spell
  end
  local describe = C_Spell and C_Spell.GetSpellDescription or GetSpellDescription
  local text = describe and describe(spell)
  if not text or text == "" then
    if C_Spell and C_Spell.RequestLoadSpellData then
      C_Spell.RequestLoadSpellData(spell)
    end
    return false
  end
  text = text:lower()
  local minutes = 0
  for n in text:gmatch("(%d+) ho?u?rs?") do
    minutes = math.max(minutes, tonumber(n) * 60)
  end
  for n in text:gmatch("(%d+) min") do
    minutes = math.max(minutes, tonumber(n))
  end
  local kind = false
  if text:find("well fed", 1, true) then
    kind = "food"
  elseif minutes >= 10 and text:find("weapon", 1, true) then
    kind = "weapon"
  elseif minutes >= 10 then
    kind = "buff"
  end
  kinds[id] = { kind = kind, name = name, spell = spell }
  return kind, name, spell
end

-- A buff on you by spell ID or name.
local function has_buff(name, spell)
  for _, aura in ipairs(buffs_of("player") or {}) do
    if (spell and aura.spell == spell) or aura.name == name then
      return true
    end
  end
  return false
end

-- Each consumable in your bags (once per item) whose buff you don't have.
local function consumable_rows(rows)
  if not cfg.consumables or not buffs_of("player") then
    return
  end
  local seen, counts, found = {}, {}, {}
  for bag = 0, NUM_BAG_SLOTS or 4 do
    for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
      local id = C_Container.GetContainerItemID(bag, slot)
      if id then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        counts[id] = (counts[id] or 0) + (info and info.stackCount or 1)
        if not seen[id] then
          seen[id] = true
          local icon, class_id, subclass_id = item_icon_class(id)
          local wanted
          if class_id == 0 then
            local kind, buff, spell = consumable_kind(id, subclass_id)
            if kind == "buff" then
              wanted = not has_buff(buff, spell)
            elseif kind == "food" then
              wanted = not has_buff(spell_name(WELL_FED) or "Well Fed", WELL_FED)
            elseif kind == "weapon" then
              wanted = is_weapon(GetInventoryItemID("player", SLOTS[1].inv)) and
                enchant_left(SLOTS[1]) == nil
            end
          end
          if wanted then
            found[#found + 1] = { id = id, icon = icon,
                                  weapon = consumable_kind(id, subclass_id) == "weapon" }
          end
        end
      end
    end
  end
  for _, item in ipairs(found) do
    local name = item_name(item.id)
    if name then
      rows[#rows + 1] = {
        icon = item.icon,
        label = format("%s (%d)", name, counts[item.id]),
        missing = { "you" },
        count = counts[item.id] > 1 and tostring(counts[item.id]) or nil,
        -- Stones and oils go on the main hand.
        click = item.weapon and
          { type = "macro", macrotext = format("/use %s\n/use 16", name) } or
          { type = "item", item = name },
      }
    end
  end
end

-- --- Supplies ---------------------------------------------------------------

-- Every item in your bags: counts by name, and free slots.
local function bag_counts()
  local counts, free = {}, 0
  for bag = 0, NUM_BAG_SLOTS or 4 do
    free = free + (C_Container.GetContainerNumFreeSlots(bag) or 0)
    for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
      local id = C_Container.GetContainerItemID(bag, slot)
      local name = id and item_name(id)
      if name then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        counts[name] = (counts[name] or 0) + (info and info.stackCount or 1)
      end
    end
  end
  return counts, free
end

-- The first item in your bags whose name holds `part` (e.g. "Instant
-- Poison"), or any poison; nil if none. For the poison click.
function ns.bag_item_named(part)
  local counts = bag_counts()
  local fallback
  for name in pairs(counts) do
    if part and name:find(part, 1, true) then
      return name
    end
    if name:find("Poison", 1, true) and not name:find("Antidote", 1, true) then
      fallback = fallback or name
    end
  end
  return fallback
end

local function is_secret(v)
  return issecretvalue and issecretvalue(v)
end

local AMMO_SLOT = 0
-- Classes that can fire a bow, gun or crossbow.
local AMMO_CLASSES = { HUNTER = true, ROGUE = true, WARRIOR = true }

-- The ammo you have equipped, or nil: slot 0 is checked for an ammo
-- item, as the slot is not ammo for every class on this client.
local function equipped_ammo()
  local id = GetInventoryItemID("player", AMMO_SLOT)
  local _, _, _, equip_loc = C_Item.GetItemInfoInstant(id or 0)
  return equip_loc == "INVTYPE_AMMO" and id or nil
end
local CALL_PET, REVIVE_PET = 883, 982

-- Ammo, reagents, durability, bag space and your pet: out of combat only.
local function supply_rows(rows, my_class)
  local s = cfg.supplies
  if not s then
    return
  end
  local counts = bag_counts()

  -- Ammo: what is in the ammo slot, counted across your bags.
  if s.ammo_low and s.ammo_low > 0 and AMMO_CLASSES[my_class] then
    if equipped_ammo() then
      local n = GetInventoryItemCount("player", AMMO_SLOT) or 0
      if n < s.ammo_low then
        rows[#rows + 1] = { icon = GetInventoryItemTexture("player", AMMO_SLOT),
                            label = "Ammo", count = tostring(n), supply = true,
                            missing = {} }
      end
    elseif my_class == "HUNTER" then
      rows[#rows + 1] = { icon = "Interface\\Icons\\INV_Ammo_Arrow_02", label = "No ammo", missing = { "you" },
                          supply = true }
    end
  end

  -- Reagents for spells you know; `match` sums every item holding it.
  for _, r in ipairs((s.reagents or {})[my_class] or {}) do
    if not r.spell or knows(r.spell) then
      local n = 0
      for name, count in pairs(counts) do
        if name == r.item or (r.match and name:find(r.match, 1, true)) then
          n = n + count
        end
      end
      if n < (r.min or 1) then
        rows[#rows + 1] = { icon = r.icon or 134400, label = r.item or r.match,
                            count = tostring(n), supply = true, missing = {} }
      end
    end
  end


  -- Your pet, if you have one to call: missing or dead.
  if s.pet and (my_class == "HUNTER" or my_class == "WARLOCK") then
    local dead = UnitExists("pet") and UnitIsDead("pet")
    if not UnitExists("pet") or dead then
      local click
      if my_class == "HUNTER" then
        local id = (dead or not knows(CALL_PET)) and REVIVE_PET or CALL_PET
        if knows(id) then
          click = { type = "spell", spell = spell_name(id) }
        end
      elseif s.warlock_pet then
        click = { type = "spell", spell = s.warlock_pet }
      end
      if click or my_class == "WARLOCK" then
        rows[#rows + 1] = { icon = "Interface\\Icons\\Ability_Hunter_BeastCall",
                            label = dead and "Pet dead" or "No pet",
                            missing = { "you" }, click = click }
      end
    end
  end

  -- Your pet under full health: its percent on your pet heal's icon,
  -- click to heal it (Mend Pet, Health Funnel). Health is plain out of
  -- combat, when this bar shows; a secret one is skipped.
  local heal = (s.pet_heal or {})[my_class]
  if heal and knows(heal) and UnitExists("pet") and not UnitIsDead("pet") then
    local ok, cur, max = pcall(function()
      return UnitHealth("pet"), UnitHealthMax("pet")
    end)
    if ok and cur and max and not is_secret(cur) and not is_secret(max) and
       max > 0 and cur < max then
      rows[#rows + 1] = {
        icon = spell_icon(heal), label = "Pet health",
        count = format("%d%%", cur / max * 100), supply = true, warn = true,
        missing = {},
        click = { type = "spell", spell = spell_name(heal), unit = "pet" },
      }
    end
  end
end

-- --- Watched buffs ----------------------------------------------------------

local function max_level()
  local ok, level = pcall(function()
    return GetMaxPlayerLevel and GetMaxPlayerLevel() or MAX_PLAYER_LEVEL
  end)
  return ok and level or 60
end

-- Whether `name` holds any of `parts`, ignoring case.
local function holds(name, parts)
  if not name then
    return false
  end
  name = name:lower()
  for _, part in ipairs(parts or {}) do
    if name:find(part:lower(), 1, true) then
      return true
    end
  end
  return false
end

-- The first item in your bags whose name holds any of `parts`: its name
-- and icon.
local function bag_item_holding(parts)
  if not parts then
    return nil
  end
  for bag = 0, NUM_BAG_SLOTS or 4 do
    for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
      local id = C_Container.GetContainerItemID(bag, slot)
      local name = id and item_name(id)
      if holds(name, parts) then
        return name, (item_icon_class(id))
      end
    end
  end
  return nil
end

-- The text of an aura's tooltip under its name: what it gives now, so a
-- buff that grows (Camp Benefits) reads its current state. Out of combat
-- only (the buff bar's time); nil if the client can't give it.
local function tooltip_text(aura)
  local tip = C_TooltipInfo and C_TooltipInfo.GetUnitBuffByAuraInstanceID
  if not (tip and aura.instance) then
    return nil
  end
  local ok, data = pcall(tip, "player", aura.instance)
  if not ok or not data or not data.lines then
    return nil
  end
  local lines = {}
  for i = 2, #data.lines do
    local text = data.lines[i].leftText
    if text and text ~= "" and not (issecretvalue and issecretvalue(text)) then
      lines[#lines + 1] = text
    end
  end
  return lines[1] and table.concat(lines, "\n") or nil
end

-- What an aura gives: its tooltip, else its spell's description with the
-- numbers filled in ("Stamina and Spirit increased by 12."), or nil until
-- the client has it.
local function aura_description(aura)
  local tooltip = tooltip_text(aura)
  if tooltip then
    return tooltip
  end
  local spell = aura.spell
  local describe = C_Spell and C_Spell.GetSpellDescription or GetSpellDescription
  local text = spell and describe and describe(spell)
  if not text or text == "" then
    if spell and C_Spell and C_Spell.RequestLoadSpellData then
      C_Spell.RequestLoadSpellData(spell)
    end
    return nil
  end
  return text
end

-- `text` without its sentences that hold any of `parts` (any case), line
-- by line; nil if nothing is left.
local function without_sentences(text, parts)
  if not text or not parts then
    return text
  end
  local lines = {}
  for line in text:gmatch("[^\n]+") do
    local kept = {}
    for sentence in line:gmatch("[^%.]+%.?") do
      sentence = sentence:match("^%s*(.-)%s*$")
      if sentence ~= "" and not holds(sentence, parts) then
        kept[#kept + 1] = sentence
      end
    end
    if kept[1] then
      lines[#lines + 1] = table.concat(kept, " ")
    end
  end
  return lines[1] and table.concat(lines, "\n") or nil
end

-- Buffs you want to keep an eye on out of combat (cfg.watch), e.g. the
-- sleeping bag's: its time left and stacks, also while resting. Shown
-- while you carry the item, know the spell or have the buff (and only
-- while levelling, for leveling = true). Red while missing (click uses
-- the item, else casts the spell), yellow under warn_at, grey otherwise.
local function watch_rows(rows)
  local level = UnitLevel("player") or 0
  for _, w in ipairs(cfg.watch or {}) do
    if not w.leveling or level < max_level() then
      local best
      for _, aura in ipairs(buffs_of("player") or {}) do
        if holds(aura.name, w.buff) and (not best or aura.left > best.left) then
          best = aura
        end
      end
      local item, item_icon = bag_item_holding(w.item)
      local spell = w.spell and knows(w.spell) and spell_name(w.spell)
      if best or item or spell then
        local click = item and { type = "item", item = item } or
                      spell and { type = "spell", spell = spell, unit = "player" } or nil
        local row = {
          icon = best and best.icon or item_icon or
                 (spell and spell_icon(w.spell)) or w.icon,
          label = w.label or (best and best.name) or item,
          missing = best and {} or { "you" },
          left = best and best.left or nil,
          badge = best and best.stacks and best.stacks > 1 and
            tostring(best.stacks) or nil,
          click = click,
          detail = w.describe and best and
            without_sentences(aura_description(best), w.drop) or nil,
        }
        if best and best.left >= (w.warn_at or cfg.warn_at) then
          row.supply = true
        end
        rows[#rows + 1] = row
      end
    end
  end
end

-- Your most worn item, with its icon and durability, and your free bag
-- slots: always out of combat (supplies.always), or only under their
-- limits. Yellow under their limits, grey otherwise.
local function fixed_rows()
  local s = cfg.supplies
  local rows = {}
  pcall(watch_rows, rows)
  if not s then
    return rows
  end
  local worst, worst_slot
  for slot = 1, 18 do
    local cur, max = GetInventoryItemDurability(slot)
    if cur and max and max > 0 and (not worst or cur / max < worst) then
      worst, worst_slot = cur / max, slot
    end
  end
  if worst then
    local id = GetInventoryItemID("player", worst_slot)
    rows[#rows + 1] = {
      icon = GetInventoryItemTexture("player", worst_slot),
      label = format("Most worn: %s", id and item_name(id) or "item"),
      count = format("%d%%", worst * 100), supply = true, missing = {},
      warn = worst < (s.durability_low or 0),
    }
  end
  local _, free = bag_counts()
  rows[#rows + 1] = {
    icon = "Interface\\Icons\\INV_Misc_Bag_08", label = "Free bag slots",
    count = tostring(free), supply = true, missing = {},
    warn = free < (s.bag_free_low or 0),
  }
  if not s.always then
    -- Only under their limits (watched buffs always stay).
    for i = #rows, 1, -1 do
      if rows[i].supply and not rows[i].warn and rows[i].count then
        table.remove(rows, i)
      end
    end
  end
  return rows
end

local function collect()
  wipe(aura_cache)
  local rows = {}
  local my_class = class_of("player")
  local units = group_units()
  -- How many of each class are in the group (you included).
  local counts = {}
  for _, unit in ipairs(units) do
    local class = UnitExists(unit) and UnitIsConnected(unit) and class_of(unit)
    if class then
      counts[class] = (counts[class] or 0) + 1
    end
  end
  for _, buff in ipairs(BUFFS) do
    if not cfg.ignore[buff.key] then
      local row
      if buff.caster then
        row = group_row(buff, units, counts[buff.caster] or 0)
      elseif buff.weapon then
        weapon_rows(buff, my_class, rows)
      else
        row = own_row(buff, my_class)
      end
      if row then
        rows[#rows + 1] = row
      end
      if #rows >= cfg.max_rows then
        break
      end
    end
  end
  if #rows < cfg.max_rows then
    pcall(consumable_rows, rows)
  end
  if #rows < cfg.max_rows then
    pcall(supply_rows, rows, my_class)
  end
  local fixed = fixed_rows()
  for i = #rows, cfg.max_rows - #fixed + 1, -1 do
    rows[i] = nil
  end
  for _, row in ipairs(fixed) do
    rows[#rows + 1] = row
  end
  return rows
end

-- In the PadKeys theme: the buff's name in light grey, what is wrong in
-- white.
local function row_text(row)
  local text = ns.paint(row.label, "light") .. "  "
  if row.detail then
    -- What the buff gives, on a line of its own below.
    return row_text({ label = row.label, left = row.left, badge = row.badge,
                      missing = row.missing, who = row.who }) ..
      "\n" .. ns.paint(row.detail, "white")
  end
  if row.count then
    return text .. ns.paint(row.count, "white")
  end
  local missing = row.missing or {}
  if #missing > 0 then
    local shown = {}
    for i = 1, math.min(#missing, cfg.max_names) do
      shown[i] = missing[i]
    end
    local who = table.concat(shown, ", ")
    if #missing > cfg.max_names then
      who = who .. format(" +%d", #missing - cfg.max_names)
    end
    if #missing == 1 and missing[1] == "you" then
      return text .. ns.paint("missing", "white")
    end
    return text .. ns.paint("missing: " .. who, "white")
  end
  if row.badge then
    text = text .. ns.paint(row.badge .. " stacks", "white") .. "  "
  end
  if row.left == math.huge then
    return text
  end
  text = text .. ns.paint(clock(row.left), "white")
  if row.who and row.who ~= "you" then
    text = text .. " " .. ns.paint(row.who, "light")
  end
  return text
end

-- --- Bar --------------------------------------------------------------------

-- One icon per row, side by side: a red frame when something is missing,
-- yellow with the time when it runs out, grey with a number for supplies.
-- Each icon is a secure button: clicking it casts the buff on whoever
-- needs it first, uses the consumable, puts poison on the weapon or calls
-- the pet. Its name and who is missing it show on hover. Secure buttons
-- can only change out of combat, so the bar is set up out of combat and a
-- state driver hides it as combat starts (and shows it after).
local bar = CreateFrame("Frame", "PadKeysBuffReminder", UIParent,
                        "SecureHandlerStateTemplate")
bar:SetSize(1, 1)
-- Centred under the middle of the screen, or under a frame (its top left
-- at the frame's bottom left), offset by x, y. A named frame is looked up
-- as the bar is set up, so one moved in Edit Mode is followed.
local function place()
  local frame = cfg.anchor ~= "center" and _G[cfg.anchor]
  bar:ClearAllPoints()
  if frame then
    bar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", cfg.x, cfg.y)
  else
    bar:SetPoint("TOP", UIParent, "CENTER", cfg.x, cfg.y)
  end
end
place()
bar:SetFrameStrata("MEDIUM")
bar:SetAlpha(0)
RegisterStateDriver(bar, "visibility", "[combat] hide; show")

local ICON = cfg.icon_size or 32
local GAP = 4
local buttons = {}

local SHADES = {
  missing = { 0.9, 0.15, 0.15 },
  low = { 1, 0.8, 0.2 },
  supply = { 0.45, 0.45, 0.45 },
}

local function on_enter(self)
  if not self.row then
    return
  end
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:SetText(row_text(self.row), 1, 1, 1, 1, true)
  if self.row.click then
    GameTooltip:AddLine("Click to fix", 0.6, 0.6, 0.6)
  end
  GameTooltip:Show()
end

local function button(i)
  if buttons[i] then
    return buttons[i]
  end
  local b = CreateFrame("Button", "PadKeysBuffReminderButton" .. i, bar,
                        "SecureActionButtonTemplate")
  b:SetSize(ICON, ICON)
  -- Down and up: the secure template acts on the one ActionButtonUseKeyDown
  -- picks, so an up-only click does nothing while that is on.
  b:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
  b.edge = b:CreateTexture(nil, "BACKGROUND")
  b.edge:SetPoint("TOPLEFT", -2, 2)
  b.edge:SetPoint("BOTTOMRIGHT", 2, -2)
  b.edge:SetColorTexture(1, 1, 1, 1)
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetAllPoints()
  b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  ns.icon(b.icon)
  b.text = ns.text(b, cfg.size, "white", "OVERLAY", "NumberFontNormal")
  b.text:SetPoint("BOTTOMRIGHT", -1, 2)
  b.badge = ns.text(b, cfg.size - 2, "white", "OVERLAY", "NumberFontNormal")
  b.badge:SetPoint("TOPRIGHT", -1, -2)
  -- A black outline: the shadow alone is lost on a light icon.
  for _, fs in ipairs({ b.text, b.badge }) do
    local font, size = fs:GetFont()
    fs:SetFont(font, size, "OUTLINE")
  end
  b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  b:SetScript("OnEnter", on_enter)
  b:SetScript("OnLeave", GameTooltip_Hide)
  buttons[i] = b
  return b
end

-- What a click does; nil clears it.
local function set_click(b, click)
  b:SetAttribute("type", click and click.type or nil)
  b:SetAttribute("spell", click and click.spell or nil)
  b:SetAttribute("unit", click and click.unit or nil)
  b:SetAttribute("item", click and click.item or nil)
  b:SetAttribute("macrotext", click and click.macrotext or nil)
end

-- Out of combat only. Returns how many icons show.
local function draw(rows)
  if InCombatLockdown() then
    return 0
  end
  place()
  local n = #rows
  local width = n * ICON + math.max(n - 1, 0) * GAP
  for i, row in ipairs(rows) do
    local b = button(i)
    b.row = row
    b:ClearAllPoints()
    if cfg.anchor == "center" then
      b:SetPoint("TOPLEFT", bar, "TOP", -width / 2 + (i - 1) * (ICON + GAP), 0)
    else
      b:SetPoint("TOPLEFT", bar, "TOPLEFT", (i - 1) * (ICON + GAP), 0)
    end
    b.icon:SetTexture(row.icon or 134400) -- question mark
    local missing = row.missing and #row.missing or 0
    local shade = row.supply and (row.warn and "low" or "supply") or
                  (missing > 0 and "missing") or "low"
    b.edge:SetVertexColor(unpack(SHADES[shade]))
    b.icon:SetDesaturated(shade == "missing")
    -- Bottom right: a count, or the time left; top right: how many miss it.
    local text = row.count
    if not text and row.left and row.left ~= math.huge then
      text = short_clock(row.left)
    end
    b.text:SetText(text or "")
    local others = missing > 1 or (missing == 1 and row.missing[1] ~= "you")
    -- A watched buff's stacks, or how many miss it.
    b.badge:SetText(row.badge or (others and tostring(missing)) or "")
    set_click(b, row.click)
    b:Show()
  end
  for i = n + 1, #buttons do
    buttons[i].row = nil
    set_click(buttons[i], nil)
    buttons[i]:Hide()
  end
  return n
end

-- Fading in and out out of combat; combat itself hides the bar at once.
local fade_from, fade_to, fade_for, fade_t = 0, 0, 0, 0

local function fade_step(self, elapsed)
  fade_t = fade_t + elapsed
  local done = fade_t >= fade_for
  local p = done and 1 or fade_t / fade_for
  self:SetAlpha(fade_from + (fade_to - fade_from) * p)
  if done then
    self:SetScript("OnUpdate", nil)
  end
end

local function fade(target, duration)
  fade_from, fade_to, fade_for, fade_t = bar:GetAlpha(), target, math.max(duration or 0, 0.01), 0
  bar:SetScript("OnUpdate", fade_step)
end

-- --- Refresh ----------------------------------------------------------------

local in_combat = false
local wanted = false -- the panel has rows to show

local function refresh()
  if in_combat then
    return
  end
  local hide_now = UnitIsDeadOrGhost("player") or UnitOnTaxi("player")
  -- Resting: only durability and bag space.
  local resting = cfg.hide_resting and IsResting()
  local ok, count = pcall(function()
    if hide_now then
      return draw({})
    end
    wipe(aura_cache)
    return draw(resting and fixed_rows() or collect())
  end)
  if not ok then
    count = 0
  end
  local was = wanted
  wanted = count > 0
  if wanted and not was then
    fade(1, c.fade_in or 0.15)
  elseif not wanted and was then
    fade(0, c.fade_out or 0.6)
  end
end

local pending = false
local function refresh_soon()
  if pending or in_combat then
    return
  end
  pending = true
  C_Timer.After(0.2, function()
    pending = false
    refresh()
  end)
end

-- --- Events -----------------------------------------------------------------

local ticker
local function start_ticker()
  if not ticker then
    ticker = C_Timer.NewTicker(1, refresh)
  end
end
local function stop_ticker()
  if ticker then
    ticker:Cancel()
    ticker = nil
  end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:RegisterEvent("UNIT_AURA")
events:RegisterEvent("UNIT_INVENTORY_CHANGED")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("SPELLS_CHANGED")
events:RegisterEvent("PLAYER_UPDATE_RESTING")
events:RegisterEvent("PLAYER_ALIVE")
events:RegisterEvent("PLAYER_DEAD")
events:RegisterEvent("PLAYER_UNGHOST")
events:SetScript("OnEvent", function(_, event, unit)
  if event == "PLAYER_REGEN_DISABLED" then
    in_combat = true
    stop_ticker()
    bar:SetAlpha(0)
  elseif event == "PLAYER_REGEN_ENABLED" then
    in_combat = false
    wanted = false
    bar:SetAlpha(0)
    refresh()
    start_ticker()
  elseif event == "PLAYER_ENTERING_WORLD" then
    in_combat = InCombatLockdown()
    if not in_combat then
      start_ticker()
      refresh_soon()
    end
  elseif event == "UNIT_AURA" then
    if unit and (unit == "player" or unit:find("^party") or unit:find("^raid")) then
      refresh_soon()
    end
  elseif event == "UNIT_INVENTORY_CHANGED" then
    if unit == "player" then
      refresh_soon()
    end
  else
    refresh_soon()
  end
end)
