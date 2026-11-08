-- Crafting, done like vendors and trainers (Services.lua): F (or Space) on a
-- recipe takes two presses, a choice and a confirm. The highlight turns gold
-- after the first press; moving away cancels it.
--
-- * The first F on a recipe selects it, as clicking it does
--   (the recipe list's own selection behaviour).
-- * The second F crafts it, as the Create button does
--   (ProfessionsCraftingPageMixin:Create, with the amount in its box).
-- * F on the Create / Create All buttons runs them.
-- * F on a side tab (a profession, or the overview) opens it, and the
--   cursor moves to the first recipe. The window opens with the cursor on
--   the first tab (autoFocus in Config.lua).
-- * The all key (Option+F) on a selected recipe, or on either button,
--   creates all; on another recipe it selects it first.
--
-- These call Blizzard's functions instead of clicking: the cursor's click
-- did nothing on the professions window's buttons.

local ns = PadKeys

local function crafting_page()
  return ProfessionsFrame and ProfessionsFrame.CraftingPage
end

-- The recipe row a frame is, or is inside (its skill-up and lock icons
-- forward their clicks to the row).
local function recipe_row(frame)
  local mixin = ProfessionsRecipeListRecipeMixin
  if not mixin then
    return nil
  end
  for _, candidate in ipairs({ frame, frame:GetParent() }) do
    if candidate and candidate.Init == mixin.Init then
      return candidate
    end
  end
end

local function create_button(frame)
  local page = crafting_page()
  if not page then
    return nil
  end
  if frame == page.CreateButton then
    return "Create"
  elseif frame == page.CreateAllButton then
    return "CreateAll"
  end
end

local function run(method)
  local page = crafting_page()
  local button = method == "Create" and page.CreateButton or page.CreateAllButton
  if not button:IsEnabled() then
    ns.say("you can't craft this now.")
    return
  end
  page[method](page)
end

local function step(_, mouse_button)
  local frame = ns.cursor_current()
  if not frame or mouse_button ~= "LeftButton" then
    return
  end
  local method = create_button(frame)
  if method then
    run(method)
    return
  end
  local row = recipe_row(frame)
  if not row then
    return
  end
  if not ns.cursor_armed() then
    crafting_page().RecipeList.selectionBehavior:Select(row)
    ns.cursor_arm(true)
    return
  end
  ns.cursor_arm(false)
  run("Create")
end

local stepper = CreateFrame("Button", "PadKeysCraftStep", UIParent)
stepper:RegisterForClicks("AnyDown")
stepper:SetScript("OnClick", step)

ns.cursor_on_click(function(frame)
  if recipe_row(frame) or create_button(frame) then
    return stepper
  end
end)

-- Crafting must run in the key press itself (a timer after it is
-- blocked), and the Create All button only updates a moment after a recipe
-- is selected: on a recipe that isn't selected yet, the first press
-- selects it and the second creates all.
ns.cursor_on_all(function(frame)
  local row = recipe_row(frame)
  if row then
    ns.cursor_arm(false)
    local selection = crafting_page().RecipeList.selectionBehavior
    if selection:IsSelected(row) then
      run("CreateAll")
    else
      selection:Select(row)
      ns.flash("Press again to create all.")
    end
    return true
  elseif create_button(frame) then
    run("CreateAll")
    return true
  end
end)

-- The side tabs are frames, not buttons, so the cursor only stops on them
-- because they are named here. A profession tab's click casts the
-- profession's spell (ProfessionsFrameRightTabMixin:OnClick), which addon
-- code may not do: a secure button casts it, then runs the rest of the
-- tab's click. The overview tab casts nothing, so its own click runs.
local function side_tab(frame)
  local professions = ProfessionsFrame
  if not professions then
    return nil
  end
  if frame == professions.ProfessionsOverviewTab or
    tContains(professions.rightProfessionTabs or {}, frame) then
    return frame
  end
end

local tab
local caster = CreateFrame("Button", "PadKeysProfessionTab", UIParent,
                           "SecureActionButtonTemplate")
caster:SetAttribute("useOnKeyDown", false)
-- Cast only when the tab isn't the open profession: casting it again
-- would close it (ProfessionsLargeRightTabMixin:CastProfessionSpell).
caster:SetScript("PreClick", function(self)
  local spell
  if tab and tab.spellOffsetIndex and
    not Professions.IsSelectedProfession(tab.skillLine) then
    local info = C_SpellBook.GetSpellBookItemInfo(tab.spellOffsetIndex + 1,
                                                  Enum.SpellBookSpellBank.Player)
    spell = info and info.spellID
  end
  self:SetAttribute("type", spell and "spell" or nil)
  self:SetAttribute("spell", spell)
end)
caster:SetScript("PostClick", function()
  if not tab then
    return
  end
  if tab == ProfessionsFrame.ProfessionsOverviewTab then
    tab:OnClick()
    return
  end
  ProfessionsFrame.BookPage:Hide()
  ProfessionsFrame.CraftingPage:Show()
  ProfessionsFrame:RightTabSelected(tab)
  -- Into the recipes once the list has filled.
  C_Timer.After(0.2, function()
    ns.cursor_focus_in(ProfessionsFrame.CraftingPage.RecipeList.ScrollBox)
  end)
end)

ns.cursor_on_target(side_tab)

ns.cursor_on_click(function(frame)
  tab = side_tab(frame)
  if tab then
    return caster
  end
end)
