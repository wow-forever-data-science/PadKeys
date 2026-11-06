-- PadKeys_Bar settings. Edit, then /reload. Move the bar in game with
-- /padkeys bar (drag it, then /padkeys bar again to lock it).

local ns = PadKeys

ns.config.bar = {
  -- Where the bar sits until you drag it: a point on the bar, anchored to
  -- the same point of the screen, plus an offset in pixels.
  point = "BOTTOM",
  x = 0,
  y = 60,
  size = 44,          -- button size
  spacing = 3,        -- gap between buttons
  scale = 1,
  -- Behind each button; 0 is see-through, 1 is solid black.
  background_alpha = 0.75,
  -- Slightly rounded corners (Media/RoundedSquare.tga); false for square.
  rounded = true,
  -- A see-through black box behind each key label, so it reads on bright
  -- icons. Alpha: 0 is see-through, 1 is solid black. The outline is a
  -- darker 1px edge on the box's open sides; false for none.
  hotkey_background = true,
  hotkey_background_alpha = 0.55,
  hotkey_outline = true,
  hotkey_outline_alpha = 0.9,
  -- On cooldown the icon turns see-through (0 is invisible) with the
  -- seconds left on top in this size; out of range it turns grey and a
  -- little see-through. No cooldown swipe.
  cooldown_alpha = 0.35,
  range_alpha = 0.6,
  countdown_size = 20,
  -- Name of the layer you hold ("Cmd", "Shift+Ctrl") above the bar.
  -- Nothing shows without a modifier. Off: the key labels are enough.
  show_layer = false,
  -- Name of the macro on each button, as on Blizzard's bars.
  show_macro_names = true,
  -- Light up a button when the Blizzard button behind it glows: procs from
  -- SpellActivationOverlay or other glow addons, and Blizzard's own.
  glow = true,
}
