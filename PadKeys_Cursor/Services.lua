-- Vendors and trainers, done like the NPC dialogs (Dialogs.lua): the cursor
-- lands on the first entry, and F (or Space) on an entry takes two presses,
-- a choice and a confirm, as on the quest reward page. The highlight box
-- turns gold after the first press; moving away cancels it.
--
-- * Vendor: the first F on an item marks it, the second buys one (the
--   gamepad's A, MerchantFrame_SetupGamepad). On the Buyback tab the second
--   F buys it back. Shift-Space still buys at once.
-- * Vendor: gear is repaired from your own money as the window opens.
-- * Trainer: the first F selects a skill and shows its cost, the second
--   trains it (the gamepad's A, ClassTrainerFrameMixin:SetUpGamepad). The
--   cursor then moves to the next skill you can learn.

local ns = PadKeys

local function is_merchant_item(button)
  return button.buttonContext == "ButtonContext_MerchantItemButton"
end

local function is_trainer_skill(button)
  return button.buttonContext == "ButtonContext_TrainerUISkill"
end

-- The trainer's selected skill, as ClassTrainer_SetSelection finds it.
local function selected_skill()
  local index = ClassTrainerFrame.selectedService
  return index and ClassTrainerFrame.ScrollBox:FindFrameByPredicate(
    function(_, data)
      data = data and (data.data or data)
      return data and data.displayIndex == index
    end)
end

local function focus_trainer()
  local button = selected_skill() or
    ClassTrainerFrame.ScrollBox:FindFrameByPredicate(is_trainer_skill)
  ns.cursor_select(button)
end

local function train()
  if not ClassTrainerTrainButton:IsEnabled() then
    ns.say("you can't learn this yet.")
    return
  end
  ClassTrainerTrainButton_OnClick(ClassTrainerTrainButton)
  C_Timer.After(0.3, function()
    ClassTrainer_SelectNearestLearnableSkill()
    focus_trainer()
  end)
end

local function step(_, mouse_button)
  local button = ns.cursor_current()
  if not button then
    return
  end
  if mouse_button ~= "LeftButton" then
    if is_merchant_item(button) then
      MerchantItemButton_OnClick(button, "RightButton")
    end
    return
  end
  if not ns.cursor_armed() then
    if is_trainer_skill(button) then
      button:Click("LeftButton")
    end
    ns.cursor_arm(true)
    return
  end
  ns.cursor_arm(false)
  if is_merchant_item(button) then
    MerchantItemButton_OnClick(button, "RightButton")
  else
    train()
  end
end

local stepper = CreateFrame("Button", "PadKeysServiceStep", UIParent)
stepper:RegisterForClicks("AnyDown")
stepper:SetScript("OnClick", step)

ns.cursor_on_click(function(button)
  if is_merchant_item(button) or is_trainer_skill(button) then
    return stepper
  end
end)

local function repair()
  if not (ns.config.vendor.autoRepair and CanMerchantRepair()) then
    return
  end
  local cost, can_repair = GetRepairAllCost()
  if not can_repair or cost == 0 then
    return
  end
  if GetMoney() < cost then
    ns.say("not enough money to repair (" .. GetMoneyString(cost) .. ").")
    return
  end
  RepairAllItems()
  ns.say("repaired for " .. GetMoneyString(cost) .. ".")
end

-- After the cursor's own start on OnShow, as in Dialogs.lua.
local function focus_later(func)
  C_Timer.After(0.1, func)
end

local owner = CreateFrame("Frame", "PadKeysServicesOwner", UIParent)
owner:RegisterEvent("MERCHANT_SHOW")
owner:RegisterEvent("ADDON_LOADED")
owner:SetScript("OnEvent", function(_, event, addon)
  if event == "MERCHANT_SHOW" then
    repair()
    focus_later(function() ns.cursor_select(MerchantItem1ItemButton) end)
  elseif addon == "Blizzard_TrainerUI" then
    ClassTrainerFrame:HookScript("OnShow", function()
      focus_later(focus_trainer)
    end)
    -- The first trainer visit loads the window while it opens.
    if ClassTrainerFrame:IsShown() then
      focus_later(focus_trainer)
    end
  end
end)
