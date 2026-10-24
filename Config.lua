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
  -- Interact with whatever you face: loot, NPCs, herbs, ore, mailboxes.
  F = "INTERACTTARGET",
  ["SHIFT-F"] = "ASSISTTARGET",
  -- Hold to open a ring, point with the mouse, release to use.
  Z = "CLICK PadKeysRing1:LeftButton",
  ["SHIFT-Z"] = "CLICK PadKeysRing2:LeftButton",
  -- Move a cursor through open windows with the keyboard.
  ["`"] = "PADKEYS_CURSOR",
}
for prefix, command in pairs(LAYERS) do
  for i, key in ipairs(FACE_KEYS) do
    bindings[prefix .. key] = command .. i
  end
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
    radius = 120,   -- pixels from the ring centre to the slot centres
    deadzone = 30,  -- release closer than this to the centre to cancel
    rings = {
      {
        name = "Menu",
        slots = {
          { label = "Character", binding = "TOGGLECHARACTER0",
            icon = "Interface\\Icons\\INV_Chest_Cloth_17" },
          { label = "Spellbook", binding = "TOGGLESPELLBOOK",
            icon = "Interface\\Icons\\INV_Misc_Book_09" },
          { label = "Talents", binding = "TOGGLETALENTS",
            icon = "Interface\\Icons\\Ability_Marksmanship" },
          { label = "Professions", binding = "TOGGLEPROFESSIONBOOK",
            icon = "Interface\\Icons\\Trade_BlackSmithing" },
          { label = "Legacy", binding = "TOGGLELEGACYSYSTEM",
            icon = "Interface\\Icons\\INV_Misc_Book_11" },
          { label = "Quests", binding = "TOGGLEQUESTLOG",
            icon = "Interface\\Icons\\INV_Misc_Note_01" },
          { label = "Map", binding = "TOGGLEWORLDMAP",
            icon = "Interface\\Icons\\INV_Misc_Map_01" },
          { label = "Bags", binding = "OPENALLBAGS",
            icon = "Interface\\Icons\\INV_Misc_Bag_08" },
        },
      },
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
    },
  },
}
