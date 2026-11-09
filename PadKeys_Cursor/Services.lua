-- Vendors and trainers, done like the NPC dialogs (Dialogs.lua): the cursor
-- lands on the first entry, and F (or Space) on an entry takes two presses,
-- a choice and a confirm, as on the quest reward page. The highlight
-- turns gold after the first press; moving away cancels it.
--
-- * Vendor: the first F on an item marks it, the second buys one (the
--   gamepad's A, MerchantFrame_SetupGamepad). On the Buyback tab the second
--   F buys it back. Shift-Space still buys at once.
-- * Vendor: the all key (Cmd+F) buys a full stack, or as many as you
--   can afford, as Shift-click's stack split would (or one, for items that
--   don't stack). On the Buyback tab it buys back.
-- * Mailbox: the all key (Cmd+F) opens all mail, and on the Send Mail tab
--   sends the letter.
-- * Vendor: the mouse wheel steps through the items, turning the page at
--   the end of one.
-- * Vendor: gear is repaired from your own money, and junk (grey items)
--   is sold, as the window opens.
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

-- The most of a vendor item you can buy at once: the stack size, capped by
-- your money and the items it costs (MerchantItemButton_OnModifiedClick).
local function most_affordable(index)
  local most = GetMerchantItemMaxStack(index)
  local _, _, price, stack_count, _, _, _, extended_cost = GetMerchantItemInfo(index)
  if price and price > 0 then
    most = min(most, floor(GetMoney() / (price / stack_count)))
  end
  if extended_cost then
    for i = 1, MAX_ITEM_COST do
      local _, value, link, currency = GetMerchantItemCostItem(index, i)
      if link and not currency then
        local owned = C_Item.GetItemCount(link, false, false, true)
        most = min(most, floor(owned / (value / stack_count)))
      end
    end
  end
  return most
end

-- SplitStack is the stack split's buy, with Blizzard's confirmations for
-- items that cost other items or can't be refunded.
ns.cursor_on_all(function(button)
  if not is_merchant_item(button) then
    return false
  end
  ns.cursor_arm(false)
  local most = MerchantFrame.selectedTab == 1 and most_affordable(button:GetID())
  if most and most > 1 then
    button.SplitStack(button, most)
  else
    MerchantItemButton_OnClick(button, "RightButton")
  end
  return true
end)

-- The mailbox: the all key opens all mail, as Blizzard's Open All button
-- (and the gamepad's X) does; on the Send Mail tab it sends, as the Send
-- button does.
ns.cursor_on_all(function()
  for _, button in ipairs({ OpenAllMail, SendMailMailButton }) do
    if button and button:IsVisible() and button:IsEnabled() then
      button:OnClick()
      return true
    end
  end
  return false
end)

-- The mouse wheel on a vendor item: the next or previous item, turning the
-- page past the first or last one on a page (MerchantFrame_OnMouseWheel).
local function merchant_slot(button)
  for i = 1, BUYBACK_ITEMS_PER_PAGE or 12 do
    if _G["MerchantItem" .. i .. "ItemButton"] == button then
      return i
    end
  end
end

local function last_merchant_item()
  for i = BUYBACK_ITEMS_PER_PAGE or 12, 1, -1 do
    local button = _G["MerchantItem" .. i .. "ItemButton"]
    if button and button:IsVisible() then
      return button
    end
  end
end

ns.cursor_on_scroll(function(button, delta)
  local slot = is_merchant_item(button) and merchant_slot(button)
  if not slot then
    return false
  end
  local nearby = _G["MerchantItem" .. (slot + delta) .. "ItemButton"]
  if nearby and nearby:IsVisible() then
    ns.cursor_select(nearby)
    return true
  end
  local page = delta > 0 and MerchantNextPageButton or MerchantPrevPageButton
  if page and page:IsVisible() and page:IsEnabled() then
    page:Click()
    C_Timer.After(0.05, function()
      ns.cursor_select(delta > 0 and MerchantItem1ItemButton or
                         last_merchant_item())
    end)
  end
  return true
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

-- What Blizzard's "Sell All Junk" does, without its confirmation.
local function sell_junk()
  local merchant = C_MerchantFrame
  if not (ns.config.vendor.autoSellJunk and merchant and merchant.SellAllJunkItems) then
    return
  end
  local count = merchant.GetNumJunkItems()
  if count == 0 or not merchant.IsSellAllJunkEnabled() then
    return
  end
  merchant.SellAllJunkItems()
  ns.say(format("sold %d junk item%s.", count, count == 1 and "" or "s"))
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
    sell_junk()
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
