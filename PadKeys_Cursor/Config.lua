-- PadKeys_Cursor settings: the UI cursor and NPC dialogs. Edit, then
-- /reload (and /padkeys apply if you change the cursor key).

local ns = PadKeys

-- Toggle the cursor by hand.
ns.config.bindings["SHIFT-`"] = "PADKEYS_CURSOR"
-- Open / close the bags; out of combat the cursor lands on sort bags.
ns.config.bindings.B = "CLICK PadKeysBags:LeftButton"

ns.config.cursor = {
  -- Show each button's tooltip as the cursor reaches it. Set to false if
  -- it causes "action blocked" errors.
  tooltips = true,
  -- While the cursor is active these keys drive it instead of moving you,
  -- like the gamepad's "UI focus" mode.
  keys = {
    up = { "W", "UP" },
    down = { "S", "DOWN" },
    left = { "A", "LEFT" },
    right = { "D", "RIGHT" },
    -- Step through entries one at a time (vendor items, trainer skills,
    -- recipes, gossip options, bag slots); a vendor turns the page at the
    -- end of one, lists scroll along.
    scroll_up = { "MOUSEWHEELUP" },
    scroll_down = { "MOUSEWHEELDOWN" },
    click = { "SPACE", "F" },              -- gamepad A, same key as Interact
    -- While the cursor is on, these take over Shift+F (assist) and Ctrl+F
    -- (previous target) from PadKeys/Config.lua.
    rightclick = { "SHIFT-F" },            -- use item, sell to vendor
    pickup = { "CTRL-F" },                 -- drag a spell or item
    -- The most at once: a vendor item buys a full stack (or what you can
    -- afford), a recipe or the Create button creates all, the mailbox
    -- opens all mail or sends the letter. Cmd+F on a Mac
    -- (the base MOD); takes over last hostile target while the cursor is on.
    all = { ns.config.mod .. "F" },
    -- gamepad B: close the window the cursor is in, or leave the cursor
    -- where there is nothing to close. Only taken over while the cursor is
    -- on; otherwise Escape opens the game menu as usual.
    back = { "ESCAPE", "BACKSPACE" },
    -- Jump to the next / previous open window (gamepad "Next Frame").
    next_window = { "TAB" },
    previous_window = { "SHIFT-TAB" },
  },
  -- Every window Blizzard opens as a panel (character, spellbook, talents,
  -- quest log, professions, trainers, ...) takes the cursor when it opens,
  -- starting it if it is off. While it is on, W/A/S/D move the cursor, not
  -- you; Esc closes the window and gives them back. Set to false to have
  -- only the autoFrames below do this.
  followWindows = true,
  -- Windows that never take the cursor by themselves (you can still Tab to
  -- them with the cursor on). The map stays out so you can walk with it open.
  ignoreWindows = { "WorldMapFrame" },
  -- Start the cursor by itself when these windows open (talk to an NPC
  -- with F, then pick an option with W/S and F or Space).
  -- If the cursor is already on, it moves to the new window.
  autoFrames = {
    "GossipFrame", "QuestFrame", "MerchantFrame", "LootFrame",
    "StaticPopup1", "StaticPopup2", "StaticPopup3", "StaticPopup4",
    "ProfessionsFrame", "MailFrame",
  },
  -- Where the cursor lands when one of those opens: a path of child keys
  -- (a number is a list index), or a list of paths where the first one
  -- shown wins; otherwise the top-left button. Vendors land on the first
  -- item and trainers on the next skill you can learn (Services.lua).
  -- Professions land on the first profession tab on the right, to pick one
  -- with W/S and F; the cursor then moves into its recipes. Space or F on a text field lets you type in it;
  -- Escape or Enter goes back to moving. Popups land on their text field
  -- (e.g. "type DELETE") or else on the accept button. The auction house
  -- lands on Search, and its sell tab on Create Auction, or on the item
  -- slot while there is nothing to post (Auctions.lua). A greyed-out button
  -- is skipped.
  autoFocus = {
    AuctionHouseFrame = { "ItemSellFrame.PostButton",
                          "CommoditiesSellFrame.PostButton",
                          "ItemSellFrame.ItemDisplay",
                          "CommoditiesSellFrame.ItemDisplay",
                          "SearchBar.SearchButton" },
    ProfessionsFrame = { "rightProfessionTabs.1",
                         "CraftingPage.RecipeList.SearchBox" },
    StaticPopup1 = { "EditBox", "ButtonContainer.Button1" },
    StaticPopup2 = { "EditBox", "ButtonContainer.Button1" },
    StaticPopup3 = { "EditBox", "ButtonContainer.Button1" },
    StaticPopup4 = { "EditBox", "ButtonContainer.Button1" },
  },
}

ns.config.vendor = {
  -- Repair all gear from your own money when a vendor window opens.
  autoRepair = true,
  -- Sell junk (grey items) when a vendor window opens.
  autoSellJunk = true,
}

ns.config.quest = {
  -- While an NPC's gossip or quest window is open, the gamepad's A button:
  -- click the entry under the cursor, or Accept / Continue / Complete.
  -- Same key as Interact.
  step = { "F" },
}
