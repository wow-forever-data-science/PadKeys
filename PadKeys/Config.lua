-- PadKeys base settings: the key layout. Console variables (soft
-- targeting, key-down casting, auto loot) are defaults in the wow-settings
-- repository, not set by this addon. Each
-- PadKeys_* addon has its own Config.lua for its keys. Edit, then /reload
-- and /padkeys apply. Key names are WoW binding strings:
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
}
-- Option is a fifth modifier only a Mac has (on Windows, Alt is MOD): it
-- fires Action Bar 5. WoW's "hold Alt to self-cast" must be off for this
-- layer (wow-settings sets it to None).
if MOD ~= "ALT-" then
  LAYERS["ALT-"] = "MULTIACTIONBAR4BUTTON"
end
-- Ctrl is split: Ctrl+1-4 fire pet bar slots 1-4 on every class (drag
-- Attack, Follow and the pet abilities you press into those slots), and
-- Ctrl+Q E R T fire Action Bar 4, slots 1-4.
local CTRL_KEYS = {
  ["1"] = "BONUSACTIONBUTTON1", ["2"] = "BONUSACTIONBUTTON2",
  ["3"] = "BONUSACTIONBUTTON3", ["4"] = "BONUSACTIONBUTTON4",
  Q = "MULTIACTIONBAR3BUTTON1", E = "MULTIACTIONBAR3BUTTON2",
  R = "MULTIACTIONBAR3BUTTON3", T = "MULTIACTIONBAR3BUTTON4",
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
  -- Next / previous nearest enemy. PadKeys_Targeting adds ` to switch
  -- these to friends, and Ctrl+Tab for your group.
  TAB = "TARGETNEARESTENEMY",
  ["SHIFT-TAB"] = "TARGETPREVIOUSENEMY",
  -- Hold for Blizzard's ping system: click a spot or unit to ping it, or
  -- drag for Blizzard's ping wheel. PadKeys_Radial puts its ring here.
  G = "TOGGLEPINGLISTENER",
  -- Sheathe / draw your weapon, as in WoW's defaults.
  Z = "TOGGLESHEATH",
  -- Sit / stand, as in WoW's defaults.
  X = "SITORSTAND",
  -- This key map (like Blizzard's Controller Map).
  F1 = "PADKEYS_KEYMAP",
}
for prefix, command in pairs(LAYERS) do
  for i, key in ipairs(FACE_KEYS) do
    bindings[prefix .. key] = command .. i
  end
end
for key, command in pairs(CTRL_KEYS) do
  bindings["CTRL-" .. key] = command
end
-- false unbinds a key: F2-F5 target party members by default (F1 is the
-- key map).
for i = 2, 5 do
  bindings["F" .. i] = false
end
-- Shift+wheel and Shift+Up / Down page the main bar by default; Shift is
-- the Action Bar 3 layer, so a scroll or arrow turn while holding it would
-- swap the main bar for another page.
for _, key in ipairs({ "MOUSEWHEELUP", "MOUSEWHEELDOWN", "UP", "DOWN" }) do
  bindings["SHIFT-" .. key] = false
end

ns.config = {
  bindings = bindings,
  face_keys = FACE_KEYS,
  mod = MOD,
}

-- Addons that add to the layout. Each loaded one adds its own keys to
-- ns.config.bindings from its Config.lua; /padkeys status lists them.
ns.modules = {
  { addon = "PadKeys_Cursor", does = "UI cursor and NPC dialogs" },
  { addon = "PadKeys_Auras", does = "Aura highlight: target (C), yours (Ctrl+C), tooltip (Shift+C)" },
  { addon = "PadKeys_Targeting", does = "Friendly/enemy toggle, group cycling" },
  { addon = "PadKeys_Radial", does = "Combat ring (G) and main-menu radial (Ctrl+G)" },
  { addon = "PadKeys_Bar", does = "One bar that shows the layer you hold" },
  { addon = "PadKeys_Fade", does = "Blizzard's bars fade in on mouseover or drag" },
  { addon = "PadKeys_Look", does = "Theme font everywhere, black chat" },
  { addon = "PadKeys_Combat", does = "Combat banner, and missing buffs out of combat" },
  { addon = "PadKeys_Cooldowns", does = "Blizzard's Cooldown Manager in the PadKeys look" },
  { addon = "PadKeys_Totems", does = "Blizzard's totem bar in the PadKeys look" },
  { addon = "PadKeys_Combo", does = "Combo points as black and white pips" },
  { addon = "PadKeys_Debug", does = "Saves errors to SavedVariables (/pkdebug)" },
}

-- The look every PadKeys addon shares: black and white, one font. Roboto
-- Condensed ExtraBold comes with PadKeys (Fonts/, SIL Open Font License);
-- WoW's own fonts work too, e.g. "Fonts\\FRIZQT__.TTF" or
-- "Fonts\\ARIALN.TTF".
ns.config.theme = {
  font = "Interface\\AddOns\\PadKeys\\Fonts\\RobotoCondensed-ExtraBold.ttf",
  -- Spell, item and menu icons keep their own colours; true shows them in
  -- grey as well.
  grey_icons = false,
}
