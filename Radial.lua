-- Blizzard's gamepad main-menu radial (GamepadRadial, in Forever's
-- Blizzard_Gamepad addon, which loads in keyboard mode too), driven from
-- the keyboard and mouse. Blizzard's code draws it, pages it, picks the
-- segment and runs it; this file only feeds it input:
--
-- * hold the radial key: show it;
-- * move the mouse: the offset from where it opened acts as the right
--   stick (GamepadRadialMixin:ProcessInput);
-- * page keys while open: PreviousPage / NextPage (the gamepad shoulders);
-- * release: recentre the "stick", which is how Blizzard triggers the
--   highlighted segment. Releasing with nothing highlighted closes it.
--
-- It opens windows, so like on a gamepad it is meant for out of combat.

local _, ns = ...

local owner = CreateFrame("Frame", "PadKeysRadialOwner", UIParent)
local origin_x, origin_y

local function stick()
  local x, y = GetCursorPosition()
  local reach = ns.config.radial.reach
  x, y = (x - origin_x) / reach, (y - origin_y) / reach
  local length = math.sqrt(x * x + y * y)
  if length > 1 then
    x, y = x / length, y / length
  end
  return x, y, length
end

-- Only push past Blizzard's selection threshold (0.5); a mouse drifting
-- back towards the centre must not count as releasing the stick.
local function on_update()
  local x, y, length = stick()
  if length >= 0.5 then
    GamepadRadial:ProcessInput(x, y)
  end
end

local function page_button(name, func)
  local button = CreateFrame("Button", name, UIParent)
  button:RegisterForClicks("AnyDown")
  button:SetScript("OnClick", func)
end
page_button("PadKeysRadialPrev", function() GamepadRadial:PreviousPage() end)
page_button("PadKeysRadialNext", function() GamepadRadial:NextPage() end)

local function open()
  if not GamepadRadial or GamepadRadial:IsShown() then
    return
  end
  if InCombatLockdown() then
    ns.say("the menu radial works out of combat.")
    return
  end
  origin_x, origin_y = GetCursorPosition()
  GamepadRadial:Show()
  local keys = ns.config.radial.page_keys
  for _, key in ipairs(keys.previous) do
    SetOverrideBindingClick(owner, true, key, "PadKeysRadialPrev")
  end
  for _, key in ipairs(keys.next) do
    SetOverrideBindingClick(owner, true, key, "PadKeysRadialNext")
  end
  owner:SetScript("OnUpdate", on_update)
end

local function release()
  if not (GamepadRadial and GamepadRadial:IsShown()) then
    return
  end
  -- Recentring triggers the highlighted segment (and Blizzard hides the
  -- radial if it ran); with nothing highlighted, close it ourselves.
  GamepadRadial:ProcessInput(0, 0)
  GamepadRadial:Hide()
end

-- Called by the PADKEYS_RADIAL binding on key down and key up.
function ns.radial_key(keystate)
  if keystate == "down" then
    open()
  else
    release()
  end
end

owner:RegisterEvent("PLAYER_LOGIN")
owner:SetScript("OnEvent", function()
  if GamepadRadial then
    GamepadRadial:HookScript("OnHide", function()
      owner:SetScript("OnUpdate", nil)
      if not InCombatLockdown() then
        ClearOverrideBindings(owner)
      end
    end)
  end
end)
