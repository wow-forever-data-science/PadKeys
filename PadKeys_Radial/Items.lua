-- The items page (5): consumables from your bags, picked for you. Each
-- segment is a family (Config.lua: healing potions best first, or "any
-- Drink"), and the best one you carry goes in it.
--
-- What a segment does is an attribute of the secure ring button, which
-- can't change in combat. So the picks are made out of combat, whenever
-- your bags or level change, and hold through combat; a used-up item stays
-- on its segment, greyed with a count of 0, until combat ends. Each set
-- (fight, rest, ...) has its own segments ("itemsfight1"); the ring's
-- snippet picks the set with the "items-pick" macro condition, which can
-- change in combat (Ring.lua).
--
-- { quest_items = true } is a segment of its own: shown while you carry a
-- quest item with a use, it opens the bags that hold them (by /clicking
-- Blizzard's bag buttons), and QuestItems.lua lights them up there.
--
-- Item counts and cooldowns are only read for display; a secret one is
-- never compared (the cooldown goes to SetCooldown in a pcall, the count
-- to SetText).

local ns = PadKeys
local button = ns.ring_button
local config = ns.config.radial.items
if not (button and config) then
  return
end

local function is_secret(v)
  return issecretvalue and issecretvalue(v)
end

local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
local GetItemSpell = C_Item and C_Item.GetItemSpell or GetItemSpell
local GetItemCount = C_Item and C_Item.GetItemCount or GetItemCount
local GetItemIcon = C_Item and C_Item.GetItemIconByID or GetItemIcon
local IsUsableItem = C_Item and C_Item.IsUsableItem or IsUsableItem
local NUM_BAGS = NUM_BAG_SLOTS or 4

-- picks[set][i] = { id, name } for the item on that segment, or nil.
local picks = {}

local QUEST_CLASS = Enum and Enum.ItemClass and Enum.ItemClass.Questitem or 12

-- A quest item you can use (it has a Use: spell), in bag, slot.
function ns.usable_quest_item(bag, slot, id)
  if not (id and GetItemSpell(id)) then
    return false
  end
  local quest = C_Container.GetContainerItemQuestInfo and
                C_Container.GetContainerItemQuestInfo(bag, slot)
  if quest and (quest.isQuestItem or quest.questID) then
    return true
  end
  local _, _, _, _, _, class_id = C_Item.GetItemInfoInstant(id)
  return class_id == QUEST_CLASS
end

-- Everything in your bags: by_name[name] = itemID, and by_use[spell] =
-- { itemID, ... } for items whose use is that spell.
local function read_bags()
  local by_name, by_use = {}, {}
  local seen = {}
  local missing = false
  -- Usable quest items: the first item, how many kinds, which bags.
  local quest = { bags = {}, count = 0 }
  for bag = 0, NUM_BAGS do
    for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      local id = info and info.itemID
      if id and not seen[id] and ns.usable_quest_item(bag, slot, id) then
        quest.first = quest.first or id
        quest.count = quest.count + 1
        quest.bags[bag] = true
      end
      if id and not seen[id] then
        seen[id] = true
        local name = GetItemInfo(id)
        if name then
          by_name[name] = id
        else
          missing = true -- not cached yet; GET_ITEM_INFO_RECEIVED reads again
        end
        local use = GetItemSpell(id)
        if use then
          by_use[use] = by_use[use] or {}
          table.insert(by_use[use], id)
        end
      end
    end
  end
  return by_name, by_use, missing, quest
end

-- The bags holding usable quest items, opened by Blizzard's own buttons:
-- the backpack (all bags with Combined Bags on), then each other bag.
local function quest_macro(quest)
  local lines = { "/click MainMenuBarBackpackButton" }
  for bag = 1, NUM_BAGS do
    if quest.bags[bag] then
      lines[#lines + 1] = "/click CharacterBag" .. (bag - 1) .. "Slot"
    end
  end
  return table.concat(lines, "\n")
end

-- The best item for "use = spell": the highest item level your level allows.
local function best_by_use(ids)
  local level = UnitLevel("player")
  local best, best_level
  for _, id in ipairs(ids or {}) do
    local _, _, _, item_level, min_level = GetItemInfo(id)
    if item_level and (not min_level or min_level <= level) and
       (not best_level or item_level > best_level) then
      best, best_level = id, item_level
    end
  end
  return best
end

local function pick(family, by_name, by_use)
  if not family then
    return nil
  end
  if family.use then
    return best_by_use(by_use[family.use])
  end
  for _, name in ipairs(family) do
    if by_name[name] then
      return by_name[name]
    end
  end
  return nil
end

-- Set names are lower-case letters, so a segment name can't be confused
-- with another page's ("itemsfight3").
local function set_names()
  local names = {}
  for name in pairs(config.sets) do
    if name:match("^%l+$") then
      names[#names + 1] = name
    end
  end
  return names
end

local dirty = true
-- An item in the bags wasn't cached yet at the last fill.
local incomplete = false

local function fill()
  if InCombatLockdown() then
    dirty = true
    return
  end
  dirty = false
  local by_name, by_use, missing, quest = read_bags()
  incomplete = missing
  button:SetAttribute("items-pick", config.pick)
  wipe(picks)
  for _, set in ipairs(set_names()) do
    picks[set] = {}
    for i = 1, ns.wheel_segments do
      local family = config.sets[set][i]
      local segment = "items" .. set .. i
      local id = not (family and family.quest_items) and pick(family, by_name, by_use)
      if family and family.quest_items and quest.first then
        picks[set][i] = { id = quest.first, quest = quest.count,
                          name = format("Quest items (%d)", quest.count) }
        button:SetAttribute("*type-" .. segment, "macro")
        button:SetAttribute("*macrotext-" .. segment, quest_macro(quest))
      elseif id then
        picks[set][i] = { id = id, name = GetItemInfo(id) }
        button:SetAttribute("*type-" .. segment, "macro")
        button:SetAttribute("*macrotext-" .. segment, "/use item:" .. id)
      else
        button:SetAttribute("*type-" .. segment, nil)
        button:SetAttribute("*macrotext-" .. segment, nil)
      end
    end
  end
end

-- --- The wheel --------------------------------------------------------------

local function entry(item)
  if item.quest then
    return { icon = GetItemIcon(item.id), label = item.name, enabled = true,
             count = item.quest }
  end
  local count = GetItemCount(item.id)
  local start, duration = C_Container.GetItemCooldown(item.id)
  local cooling = false
  if duration and not is_secret(duration) and not is_secret(start) then
    cooling = duration > 1.5
  end
  local usable, no_mana = IsUsableItem(item.id)
  local tint = 1
  if is_secret(usable) then
    tint = 1
  elseif not usable then
    tint = no_mana and 0.6 or 0.35
  end
  return {
    icon = GetItemIcon(item.id),
    label = item.name,
    enabled = true,
    cooldown = { start, duration },
    cooling = cooling,
    tint = tint,
    count = count,
  }
end

-- The set the snippet will use: the same macro condition, read now.
function ns.item_entries()
  local set = SecureCmdOptionParse(config.pick or "") or ""
  local entries = {}
  for i, item in pairs(picks[set] or {}) do
    entries[i] = entry(item)
  end
  return entries
end

-- --- Events -----------------------------------------------------------------

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "BAG_UPDATE_DELAYED",
                         "PLAYER_LEVEL_UP", "PLAYER_REGEN_ENABLED",
                         "GET_ITEM_INFO_RECEIVED" }) do
  events:RegisterEvent(event)
end
local pending = false
events:SetScript("OnEvent", function(self, event)
  if (event == "PLAYER_REGEN_ENABLED" and not dirty) or
     (event == "GET_ITEM_INFO_RECEIVED" and not incomplete) then
    return
  end
  -- Many bag events come at once; one fill on the next frame covers them.
  if not pending then
    pending = true
    C_Timer.After(0, function()
      pending = false
      fill()
    end)
  end
  if event == "PLAYER_LOGIN" then
    self:UnregisterEvent("PLAYER_LOGIN")
  end
end)
