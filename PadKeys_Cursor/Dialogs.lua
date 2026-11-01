-- NPC dialogs (gossip and quest windows), done the way Forever's gamepad UI
-- does them, with F as the gamepad's A button:
--
-- * When a dialog shows a list (gossip options and quests, a quest greeting,
--   quest rewards), the UI cursor lands on its first entry, as
--   GossipFrameMixin:Update and QuestFrame.FocusGamepad do with
--   SmartNavigation. Move it with W/S (or the arrows).
-- * F clicks the entry under the cursor (the gamepad's select prompt and
--   QuestFrame_SelectFocusedButton), so every gossip option works: vendor,
--   trainer, innkeeper, banker, directions.
-- * On quest pages F is Blizzard's own QuestFrame_GeneralProgressAction:
--   Accept, Continue, Complete. On the reward page, F on a reward you
--   haven't chosen chooses it; once one is chosen, F completes the quest.
-- * Esc closes the window (the cursor's "back", the gamepad's B).
--
-- Space does the same as F on list entries, since both are the cursor's
-- click. With no dialog open, F is the normal "Interact with Target".

local ns = PadKeys

local owner = CreateFrame("Frame", "PadKeysQuestOwner", UIParent)

local function focused_in(root)
  local button = ns.cursor_current()
  local frame = button
  while frame do
    if frame == root then
      return button
    end
    frame = frame:GetParent()
  end
end

-- Click the list entry under the cursor, as Blizzard's gamepad select does.
local function click_focused(root)
  local button = focused_in(root)
  if button and button:IsEnabled() then
    button:Click()
  end
end

-- The quest reward page: IsSelectRewardValid / IsQuestCompleteValid in
-- Blizzard's QuestFrame.lua.
local function reward_step()
  local button = focused_in(QuestFrameRewardPanel)
  if button and button.type == "choice" and
    not QuestInfoItem_IsSelected(button) then
    button:Click()
    return
  end
  local choices = GetNumQuestChoices()
  if choices == 1 then
    QuestInfoFrame.itemChoice = 1
  end
  if choices > 1 and QuestInfoFrame.itemChoice == 0 then
    ns.say("move the cursor to a reward and press F to choose it.")
    return
  end
  QuestFrame_GeneralProgressAction(QuestFrame)
end

local function quest_step()
  if QuestFrameGreetingPanel:IsVisible() then
    click_focused(QuestFrameGreetingPanel)
  elseif QuestFrameRewardPanel:IsVisible() then
    reward_step()
  elseif QuestFrameProgressPanel:IsVisible() and not IsQuestCompletable() then
    -- Blizzard greys out the gamepad's Continue here; Esc leaves.
    ns.say("you don't have what this quest needs yet. Esc to leave.")
  else
    QuestFrame_GeneralProgressAction(QuestFrame)
  end
end

local function step()
  if QuestFrame:IsVisible() then
    quest_step()
  elseif GossipFrame and GossipFrame:IsVisible() then
    click_focused(GossipFrame)
  end
end

local button = CreateFrame("Button", "PadKeysQuestStep", UIParent)
button:RegisterForClicks("AnyDown")
button:SetScript("OnClick", step)

-- Land the cursor on a list's first entry once the window has drawn it
-- (after the cursor's own start on OnShow).
local function focus_later(root)
  C_Timer.After(0.1, function() ns.cursor_focus_in(root) end)
end

local function dialog_open()
  return QuestFrame:IsShown() or (GossipFrame and GossipFrame:IsShown())
end

-- F is the step key only while a dialog is open. Override bindings can't
-- change in combat; then F stays plain interact.
local function update_bindings()
  if InCombatLockdown() then
    return
  end
  ClearOverrideBindings(owner)
  if dialog_open() then
    for _, key in ipairs(ns.config.quest.step) do
      SetOverrideBindingClick(owner, true, key, "PadKeysQuestStep")
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
    if GossipFrame and GossipFrame.Update then
      hooksecurefunc(GossipFrame, "Update", function(self)
        focus_later(self.GreetingPanel.ScrollBox)
      end)
    end
    QuestFrameGreetingPanel:HookScript("OnShow", function(self)
      focus_later(self)
    end)
    QuestFrameRewardPanel:HookScript("OnShow", function(self)
      focus_later(self)
    end)
  end
  update_bindings()
end)
