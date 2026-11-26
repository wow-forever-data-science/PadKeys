-- Usable quest items lit in your open bags (Config.lua,
-- radial.quest_glow): a gold border that pulses on each quest item with a
-- Use: (the ones you'd go looking for), whenever a bag is open, however
-- it was opened. G's outer ring opens the bags holding them (Items.lua,
-- { quest_items = true }).
--
-- Only textures are added to Blizzard's item buttons (no frames, no
-- scripts, nothing written on them: the borders are kept in a table of
-- our own), so their secure use of items isn't touched.

local ns = PadKeys
local glow_config = ns.config.radial.quest_glow
if not (glow_config and glow_config.enabled and ns.usable_quest_item) then
  return
end

local borders = setmetatable({}, { __mode = "k" })

local function border(button)
  local b = borders[button]
  if not b then
    b = button:CreateTexture(nil, "OVERLAY", nil, 7)
    b:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    b:SetBlendMode("ADD")
    b:SetVertexColor(unpack(glow_config.color or { 1, 0.82, 0.1 }))
    b:SetPoint("CENTER")
    local w = button:GetWidth()
    b:SetSize(w * 1.8, w * 1.8)
    borders[button] = b
  end
  return b
end

-- The open bag frames' item buttons: Blizzard's frames list them
-- (EnumerateValidItems); older ones are named ContainerFrameNItemM.
local function each_button(fn)
  local frames = {}
  if ContainerFrameCombinedBags then
    frames[#frames + 1] = ContainerFrameCombinedBags
  end
  for i = 1, (NUM_CONTAINER_FRAMES or 13) do
    local f = _G["ContainerFrame" .. i]
    if f then
      frames[#frames + 1] = f
    end
  end
  for _, frame in ipairs(frames) do
    if frame:IsShown() then
      if frame.EnumerateValidItems then
        for _, button in frame:EnumerateValidItems() do
          fn(button, button:GetBagID(), button:GetID())
        end
      else
        local name = frame:GetName()
        for i = 1, 36 do
          local button = _G[name .. "Item" .. i]
          if button and button:IsShown() then
            fn(button, frame:GetID(), button:GetID())
          end
        end
      end
    end
  end
end

local lit = {}

local function refresh()
  for button in pairs(lit) do
    lit[button] = nil
  end
  each_button(function(button, bag, slot)
    local ok, yes = pcall(function()
      local info = C_Container.GetContainerItemInfo(bag, slot)
      return info and ns.usable_quest_item(bag, slot, info.itemID)
    end)
    if ok and yes then
      lit[button] = true
    end
  end)
  for button, b in pairs(borders) do
    b:SetShown(lit[button] == true)
  end
  for button in pairs(lit) do
    border(button):Show()
  end
end

-- While a bag is open: check now and then, and pulse.
local driver = CreateFrame("Frame")
local since, clock = 1, 0
local period = glow_config.pulse or 1
driver:SetScript("OnUpdate", function(_, elapsed)
  since = since + elapsed
  clock = clock + elapsed
  if since >= 0.3 then
    since = 0
    refresh()
  end
  local a = 0.55 + 0.45 * math.sin(clock * 2 * math.pi / period)
  for button in pairs(lit) do
    borders[button]:SetAlpha(a)
  end
end)

local function any_open()
  local open = false
  each_button(function() open = true end)
  return open
end

-- Bag frames show and hide: run the driver only while one is open.
local watch = CreateFrame("Frame")
local elapsed_total = 0
watch:SetScript("OnUpdate", function(_, elapsed)
  elapsed_total = elapsed_total + elapsed
  if elapsed_total < 0.2 then
    return
  end
  elapsed_total = 0
  local open = any_open()
  if open and not driver:IsShown() then
    since = 1
    driver:Show()
  elseif not open and driver:IsShown() then
    driver:Hide()
    for _, b in pairs(borders) do
      b:Hide()
    end
    wipe(lit)
  end
end)
driver:Hide()
