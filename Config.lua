-- PadKeys settings. Edit this file to change the key layout, the UI cursor
-- keys and the radial rings, then /reload. Key names are WoW binding strings:
-- "Q", "SHIFT-1", "CTRL-SPACE", "`", "BACKSPACE", "UP".

local _, ns = ...

-- Eight "face buttons", like the eight gamepad action buttons Forever's
-- gamepad bar has. Each modifier is a layer, like the gamepad shoulders.
local FACE_KEYS = { "1", "2", "3", "4", "Q", "E", "R", "T" }
local LAYERS = {
  [""] = "ACTIONBUTTON",                -- main bar (Action Bar 1)
  ["ALT-"] = "MULTIACTIONBAR1BUTTON",   -- Action Bar 2
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
  ["ALT-F"] = "TARGETLASTHOSTILE",    -- last enemy you targeted
  -- Tab cluster: cycle enemies, and cycle your party or raid in frame order
  -- (works in combat).
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
  -- Our own rings (Rings.lua): hold, point with the mouse, release.
  ["SHIFT-Z"] = "CLICK PadKeysRing1:LeftButton", -- Utility
  ["SHIFT-G"] = "CLICK PadKeysRing2:LeftButton", -- Ping your target
  -- Move a cursor through open windows with the keyboard.
  ["`"] = "PADKEYS_CURSOR",
}
for prefix, command in pairs(LAYERS) do
  for i, key in ipairs(FACE_KEYS) do
    bindings[prefix .. key] = command .. i
  end
end
-- false unbinds a key: F1-F5 target yourself and party members by default.
for i = 1, 5 do
  bindings["F" .. i] = false
end

ns.config = {
  -- Console variables set by /padkeys apply (and undone by /padkeys restore).
  cvars = {
    -- Soft targeting: 0 off, 1 gamepad only, 2 keyboard/mouse only, 3 both.
    SoftTargetInteract = 3,
    SoftTargetEnemy = 3,
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
      rightclick = { "SHIFT-SPACE", "E" },   -- use item, sell to vendor
      pickup = { "CTRL-SPACE" },             -- drag a spell or item
      back = { "BACKSPACE", "Q" },           -- gamepad B: leave cursor mode
    },
    -- Start the cursor by itself when these windows open (talk to an NPC
    -- with F, then pick an option with W/S and Space).
    autoFrames = {
      "GossipFrame", "QuestFrame", "MerchantFrame", "LootFrame",
      "StaticPopup1",
    },
  },

  quest = {
    -- While a quest giver's window is open: take the next step (turn in,
    -- accept, continue, complete, close). Same key as Interact.
    step = { "F" },
    -- Cycle through the reward choices on the turn-in page.
    cycle = { "SHIFT-F", "TAB" },
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
  rings = {
    radius = 120,   -- pixels from the ring centre to the slot centres
    deadzone = 30,  -- release closer than this to the centre to cancel
    list = {
      {
        name = "Utility",
        -- Slot types: spell = "Name" or id, item = id or "Name",
        -- macro = "/macro text", binding = "BINDING_NAME".
        slots = {
          { label = "Hearthstone", item = 6948 },
          { label = "Sit / stand", macro = "/sit",
            icon = "Interface\\Icons\\Spell_Nature_Sleep" },
          { label = "Dismount", macro = "/dismount",
            icon = "Interface\\Icons\\Ability_Mount_RidingHorse" },
          { label = "Stop casting", macro = "/stopcasting",
            icon = "Interface\\Icons\\Spell_Shadow_SacrificialShield" },
          -- { label = "Frost Nova", spell = "Frost Nova" },
        },
      },
      {
        name = "Ping",
        -- /ping takes 1 attack, 2 warning, 3 on my way, 4 assist,
        -- 5 not a threat, 6 threat (numbers work in every client language).
        -- With no target the game picks what to ping. Works in combat.
        slots = {
          { label = "Attack", macro = "/ping 1",
            icon = "Interface\\Icons\\Ability_DualWield" },
          { label = "Assist", macro = "/ping 4",
            icon = "Interface\\Icons\\Spell_Holy_HolyBolt" },
          { label = "On my way", macro = "/ping 3",
            icon = "Interface\\Icons\\Ability_Rogue_Sprint" },
          { label = "Not a threat", macro = "/ping 5",
            icon = "Interface\\Icons\\Spell_Holy_Restoration" },
          { label = "Threat", macro = "/ping 6",
            icon = "Interface\\Icons\\Ability_Warrior_Challange" },
          { label = "Warning", macro = "/ping 2",
            icon = "Interface\\Icons\\Spell_Shadow_DeathScream" },
        },
      },
    },
  },
}
