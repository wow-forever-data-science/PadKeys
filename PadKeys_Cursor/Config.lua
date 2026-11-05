-- PadKeys_Cursor settings: the UI cursor and NPC dialogs. Edit, then
-- /reload (and /padkeys apply if you change the cursor key).

local ns = PadKeys

-- Toggle the cursor by hand.
ns.config.bindings["SHIFT-`"] = "PADKEYS_CURSOR"
-- Open / close the bags; out of combat the cursor lands on the first slot.
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
    click = { "SPACE", "F" },              -- gamepad A, same key as Interact
    rightclick = { "SHIFT-SPACE" },        -- use item, sell to vendor
    pickup = { "CTRL-SPACE" },             -- drag a spell or item
    -- gamepad B: close the window the cursor is in, or leave the cursor
    -- where there is nothing to close. Only taken over while the cursor is
    -- on; otherwise Escape opens the game menu as usual.
    back = { "ESCAPE", "BACKSPACE" },
    -- Jump to the next / previous open window (gamepad "Next Frame").
    next_window = { "TAB" },
    previous_window = { "SHIFT-TAB" },
  },
  -- Start the cursor by itself when these windows open (talk to an NPC
  -- with F, then pick an option with W/S and F or Space).
  -- If the cursor is already on, it moves to the new window.
  autoFrames = {
    "GossipFrame", "QuestFrame", "MerchantFrame", "LootFrame",
    "StaticPopup1", "StaticPopup2", "StaticPopup3", "StaticPopup4",
    "ProfessionsFrame",
  },
  -- Where the cursor lands when one of those opens: a path of child keys,
  -- or a list of paths where the first one shown wins; otherwise the
  -- top-left button. Space or F on a text field lets you type in it;
  -- Escape or Enter goes back to moving. Popups land on their text field
  -- (e.g. "type DELETE") or else on the accept button.
  autoFocus = {
    ProfessionsFrame = "CraftingPage.RecipeList.SearchBox",
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
