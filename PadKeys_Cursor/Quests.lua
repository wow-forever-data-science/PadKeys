-- The quest you just accepted goes to the top of Blizzard's quest
-- tracker (Config.lua, quest.newest_first), and so does a quest whose
-- objective just moved, a looted quest item or a kill (quest.progress_first),
-- tracked if it wasn't. The tracker lists quests in
-- the order of the watch list, and a new watch goes to its end, so the
-- watches are taken off and put back with the new quest first, the rest
-- in their old order.
--
-- Quest IDs are plain values and C_QuestLog's watch functions take them
-- from addon code. Only the tracker changes, not the quest log window.

local ns = PadKeys
local c = ns.config.quest
if not (c and (c.newest_first or c.progress_first) and C_QuestLog and
        C_QuestLog.AddQuestWatch) then
  return
end

local log = C_QuestLog

local function watched()
  local ids = {}
  for i = 1, log.GetNumQuestWatches() do
    local id = log.GetQuestIDForQuestWatchIndex(i)
    if id then
      ids[#ids + 1] = id
    end
  end
  return ids
end

local function to_top(quest_id)
  local ids = watched()
  if ids[1] == quest_id then
    return
  end
  for _, id in ipairs(ids) do
    log.RemoveQuestWatch(id)
  end
  log.AddQuestWatch(quest_id)
  for _, id in ipairs(ids) do
    if id ~= quest_id then
      log.AddQuestWatch(id)
    end
  end
end

-- Our own watch changes fire QUEST_WATCH_UPDATE too; a quest already on
-- top is left alone, so they end there.
local events = CreateFrame("Frame")
if c.newest_first then
  events:RegisterEvent("QUEST_ACCEPTED")
end
if c.progress_first then
  events:RegisterEvent("QUEST_WATCH_UPDATE")
end
events:SetScript("OnEvent", function(_, _, quest_id)
  if type(quest_id) ~= "number" then
    return
  end
  -- After Blizzard's own handler has added or updated the watch.
  C_Timer.After(0.2, function()
    pcall(to_top, quest_id)
  end)
end)
