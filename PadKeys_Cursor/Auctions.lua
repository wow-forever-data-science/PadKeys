-- The auction house: the cursor lands on Search when the window opens, and
-- on Create Auction when the sell tab opens or an item is put up for sale
-- (autoFocus in Config.lua). Blizzard switches tabs with SetDisplayMode,
-- not by opening the window again, so the cursor follows each switch.

local ns = PadKeys

-- Pages the cursor follows; other tabs (your auctions, bids) keep it.
local function followed(mode)
  local modes = AuctionHouseFrameDisplayMode
  return mode == modes.Buy or mode == modes.ItemSell or
    mode == modes.CommoditiesSell
end

local owner = CreateFrame("Frame", "PadKeysAuctionsOwner", UIParent)
owner:RegisterEvent("ADDON_LOADED")
owner:SetScript("OnEvent", function(_, _, addon)
  if addon ~= "Blizzard_AuctionHouseUI" then
    return
  end
  hooksecurefunc(AuctionHouseFrame, "SetDisplayMode", function(self)
    if ns.cursor_current() and followed(self:GetDisplayMode()) then
      ns.cursor_take(self)
    end
  end)
end)
