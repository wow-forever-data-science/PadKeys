-- PadKeys_Cursor settings: the UI cursor and NPC dialogs. Edit, then
-- /reload (and /padkeys apply if you change the cursor key).

local ns = PadKeys

-- Toggle the cursor by hand.
ns.config.bindings["SHIFT-`"] = "PADKEYS_CURSOR"

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
    click = { "SPACE", "ENTER" },          -- gamepad A
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
  autoFrames = {
    "GossipFrame", "QuestFrame", "MerchantFrame", "LootFrame",
    "StaticPopup1",
  },
}

ns.config.quest = {
  -- While an NPC's gossip or quest window is open, the gamepad's A button:
  -- click the entry under the cursor, or Accept / Continue / Complete.
  -- Same key as Interact.
  step = { "F" },
}
