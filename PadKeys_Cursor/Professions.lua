-- Crafting, done like vendors and trainers (Services.lua): F (or Space) on a
-- recipe takes two presses, a choice and a confirm. The highlight turns gold
-- after the first press; moving away cancels it.
--
-- * The first F on a recipe selects it, as clicking it does
--   (the recipe list's own selection behaviour).
-- * The second F crafts it, as the Create button does
--   (ProfessionsCraftingPageMixin:Create, with the amount in its box).
-- * F on the Create / Create All buttons runs them.
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
