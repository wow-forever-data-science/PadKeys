-- PadKeys settings. Edit this file to change the key layout, the UI cursor
-- keys and the radial rings, then /reload. Key names are WoW binding strings:
-- "Q", "SHIFT-1", "CTRL-SPACE", "`", "BACKSPACE", "UP". On a Mac, Cmd is
-- "META" ("META-1").

local _, ns = ...

-- Modifier for Action Bar 2 and last hostile target: "META-" is Cmd on a
-- Mac. Use "ALT-" on Windows.
local MOD = "META-"

-- Eight "face buttons", like the eight gamepad action buttons Forever's
-- gamepad bar has. Each modifier is a layer, like the gamepad shoulders.
local FACE_KEYS = { "1", "2", "3", "4", "Q", "E", "R", "T" }
local LAYERS = {
  [""] = "ACTIONBUTTON",                -- main bar (Action Bar 1)
  [MOD] = "MULTIACTIONBAR1BUTTON",      -- Action Bar 2 (Cmd)
  ["SHIFT-"] = "MULTIACTIONBAR2BUTTON", -- Action Bar 3
  ["CTRL-"] = "BONUSACTIONBUTTON",      -- pet bar
}

local bindings = {
  -- Strafe on A/D like a gamepad's left stick; turn with the mouse or the
  -- arrow keys.
  A = "STRAFELEFT",
  D = "STRAFERIGHT",
  -- F cluster: interact and target memory.
  -- Interact with whatever you face: loot, NPCs, herbs, ore, mailboxes.
  F = "INTERACTTARGET",
  ["SHIFT-F"] = "ASSISTTARGET",       -- target your target's target
  ["CTRL-F"] = "TARGETLASTTARGET",    -- swap back to your previous target
  [MOD .. "F"] = "TARGETLASTHOSTILE", -- last enemy you targeted (Cmd+F)
  -- Tab cluster: ` toggles friendly/enemy mode; Tab / Shift+Tab cycle
  -- enemies (or friends in friendly mode); Ctrl+Tab cycles your party or
  -- raid in frame order. All work in combat.
  ["`"] = "CLICK PadKeysTargetMode:LeftButton",
  TAB = "TARGETNEARESTENEMY",
  ["SHIFT-TAB"] = "TARGETPREVIOUSENEMY",
  ["CTRL-TAB"] = "CLICK PadKeysGroupCycle:LeftButton",
  ["CTRL-SHIFT-TAB"] = "CLICK PadKeysGroupCycle:RightButton",
  -- Hold for Blizzard's gamepad main-menu radial; point with the mouse,
  -- release to open. Q/E or the mouse wheel switch between its 3 pages.
  Z = "PADKEYS_RADIAL",
  -- Hold for Blizzard's ping system: click a spot or unit to ping it, or
  -- drag for Blizzard's ping wheel.
  G = "TOGGLEPINGLISTENER",
  -- Sit / stand, as in WoW's defaults.
  X = "SITORSTAND",
  -- Inspect your auras, in combat too: each press shows the next tooltip
  -- (wrapping around); Escape closes the tooltip view. C replaces the
  -- character window (it's on the radial's centre page).
  C = "CLICK PadKeysAuraDebuff:LeftButton",
  ["ALT-C"] = "CLICK PadKeysAuraBuff:LeftButton",
  -- Move a cursor through open windows with the keyboard.
  ["SHIFT-`"] = "PADKEYS_CURSOR",
  -- This key map (like Blizzard's Controller Map).
  F1 = "PADKEYS_KEYMAP",
}
for prefix, command in pairs(LAYERS) do
  for i, key in ipairs(FACE_KEYS) do
    bindings[prefix .. key] = command .. i
  end
end
-- false unbinds a key: F2-F5 target party members by default (F1 is the
-- key map).
for i = 2, 5 do
  bindings["F" .. i] = false
end

ns.config = {
  -- Console variables set by /padkeys apply (and undone by /padkeys restore).
  cvars = {
    -- Soft targeting: 0 off, 1 gamepad only, 2 keyboard/mouse only, 3 both.
    -- Interact is Options > Controls "Enable Interact Key" (what makes F
    -- work); Enemy is Options > Combat "Action Targeting".
    SoftTargetInteract = 3,
    SoftTargetEnemy = 3,
    -- The rest are the values Blizzard's gamepad mode sets
    -- (Blizzard_Gamepad/Core.lua, SetupCVarsForInputMode), so soft
    -- targeting behaves as on the gamepad. Camera settings are left alone.
    SoftTargetFriend = 0,
    SoftTargetWithLocked = 1,
    SoftTargetMatchLocked = 1,
    SoftTargetForce = 0,
    SoftTargetInteractRange = 20,  -- how far F reaches
    SoftTargetInteractArc = 1,     -- cone in front of you that F checks
    SoftTargetEnemyArc = 1,
    SoftTargetFriendArc = 2,
    SoftTargetIconInteract = 1,    -- icon over the NPC F will use
    SoftTargetIconGameObject = 1,  -- icon over herbs, ore, chests, mail
    SoftTargetIconEnemy = 0,
    SoftTargetIconFriend = 0,
    SoftTargetNameplateEnemy = 0,
    SoftTargetNameplateInteract = 0,
    SoftTargetNameplateSize = 20,
    SoftTargetTooltipEnemy = 0,
    SoftTargetTooltipFriend = 0,
    ActionButtonUseKeyDown = 1,
    autoLootDefault = 1,
  },

  bindings = bindings,

  cursor = {
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
      -- gamepad B: leave cursor mode. Escape is only taken over while the
      -- cursor is on; otherwise it opens the game menu as usual.
      back = { "ESCAPE", "BACKSPACE" },
      -- Jump to the next / previous open window (gamepad "Next Frame").
      next_window = { "TAB" },
      previous_window = { "SHIFT-TAB" },
    },
    -- Start the cursor by itself when these windows open (talk to an NPC
    -- with F, then pick an option with W/S and Space).
    autoFrames = {
      "GossipFrame", "QuestFrame", "MerchantFrame", "LootFrame",
      "StaticPopup1",
    },
  },

  -- Keys that cycle targets; friendly mode points them at friends.
  target_mode = { next = "TAB", previous = "SHIFT-TAB" },

  quest = {
    -- While an NPC's gossip or quest window is open, the gamepad's A button:
    -- click the entry under the cursor, or Accept / Continue / Complete.
    -- Same key as Interact.
    step = { "F" },
  },

  radial = {
    -- Mouse distance (pixels) that counts as pushing the stick all the way.
    reach = 120,
    -- Page keys while the radial is open, like the gamepad shoulders.
    page_keys = {
      previous = { "Q", "MOUSEWHEELUP" },
      next = { "E", "MOUSEWHEELDOWN" },
    },
  },
}
