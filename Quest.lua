-- Smart interact for quest givers. While a gossip or quest window is open,
-- the interact key (F) takes the next quest step: pick a quest that is ready
-- to turn in (or a new one), accept, continue, complete, then close the
-- window when nothing is left. A second key cycles quest reward choices.
-- With no window open, F is the normal "Interact with Target" binding.
--
-- On quest pages it calls the gamepad's own QuestFrame_GeneralProgressAction
-- (Blizzard_UIPanels_Game/Mainline/QuestFrame.lua), which clicks Blizzard's
-- buttons, so their checks (reward chosen, expensive quest confirmation)
-- still apply. Each press does one step.

local _, ns = ...

local owner = CreateFrame("Frame", "PadKeysQuestOwner", UIParent)

local function close_window()
  if QuestFrame:IsVisible() then
    HideUIPanel(QuestFrame)
  elseif GossipFrame and GossipFrame:IsVisible() then
    C_GossipInfo.CloseGossip()
  end
end

-- Gossip window: turn-ins first, then new quests, then a lone chat option.
local function gossip_step()
  for _, quest in ipairs(C_GossipInfo.GetActiveQuests() or {}) do
    if quest.isComplete then
      C_GossipInfo.SelectActiveQuest(quest.questID)
      return
    end
  end
  local available = C_GossipInfo.GetAvailableQuests() or {}
  if available[1] then
    C_GossipInfo.SelectAvailableQuest(available[1].questID)
    return
  end
  local options = C_GossipInfo.GetOptions() or {}
  if #options == 1 then
    C_GossipInfo.SelectOptionByIndex(options[1].orderIndex)
    return
  end
  close_window()
end

-- Quest greeting (an NPC with several quests and no gossip).
local function greeting_step()
  local active = GetNumActiveQuests()
  for i = 1, active do
    local _, is_complete = GetActiveTitle(i)
    if is_complete then
      SelectActiveQuest(i)
      return
    end
  end
  if GetNumAvailableQuests() > 0 then
    SelectAvailableQuest(1)
    return
  end
  close_window()
end

local function choice_buttons()
  local out = {}
  local rewards = QuestInfoFrame.rewardsFrame
  for _, button in ipairs(rewards and rewards.RewardButtons or {}) do
    if button.type == "choice" and button:IsVisible() then
      out[button:GetID()] = button
    end
  end
  return out
end

local function show_choice(index)
  local button = choice_buttons()[index]
  if not button then
    return
  end
  QuestInfoItem_OnClick(button)
  GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
  GameTooltip:SetQuestItem("choice", index)
  GameTooltip:Show()
end

local function cycle_reward()
  local n = GetNumQuestChoices()
  if not QuestFrameRewardPanel:IsVisible() or n < 2 then
    return
  end
  show_choice(QuestInfoFrame.itemChoice % n + 1)
end

-- Accept, continue and complete are Blizzard's own gamepad action. Only the
-- cases it leaves to the gamepad cursor are handled here: picking from the
-- greeting list, a quest you can't hand in yet, and no reward chosen.
local function quest_step()
  if QuestFrameGreetingPanel:IsVisible() then
    greeting_step()
  elseif QuestFrameProgressPanel:IsVisible() and not IsQuestCompletable() then
    close_window()
  elseif QuestFrameRewardPanel:IsVisible() and GetNumQuestChoices() > 1 and
    QuestInfoFrame.itemChoice == 0 then
    show_choice(1)
    ns.say("choose a reward (cycle with " ..
             table.concat(ns.config.quest.cycle, " or ") ..
             "), then press again.")
  else
    QuestFrame_GeneralProgressAction(QuestFrame)
  end
end

local function smart_step()
  if QuestFrame:IsVisible() then
    quest_step()
  elseif GossipFrame and GossipFrame:IsVisible() then
    gossip_step()
  end
end

local function button(name, func)
  local b = CreateFrame("Button", name, UIParent)
  b:RegisterForClicks("AnyDown")
  b:SetScript("OnClick", func)
end
button("PadKeysQuestStep", smart_step)
button("PadKeysQuestCycle", cycle_reward)

local function dialog_open()
  return QuestFrame:IsShown() or (GossipFrame and GossipFrame:IsShown())
end

-- Point the keys at the quest buttons only while a dialog is open. Override
-- bindings can't change in combat; then F stays plain interact.
local function update_bindings()
  if InCombatLockdown() then
    return
  end
  ClearOverrideBindings(owner)
  if dialog_open() then
    for _, key in ipairs(ns.config.quest.step) do
      SetOverrideBindingClick(owner, true, key, "PadKeysQuestStep")
    end
    for _, key in ipairs(ns.config.quest.cycle) do
      SetOverrideBindingClick(owner, true, key, "PadKeysQuestCycle")
    end
  end
end

owner:RegisterEvent("PLAYER_LOGIN")
owner:RegisterEvent("PLAYER_REGEN_ENABLED")
owner:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    for _, frame in ipairs({ QuestFrame, GossipFrame }) do
      if frame then
        frame:HookScript("OnShow", update_bindings)
        frame:HookScript("OnHide", update_bindings)
      end
    end
  end
  update_bindings()
end)
