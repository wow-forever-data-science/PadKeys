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
  spacing = 6,        -- gap between buttons
  scale = 1,
  -- Name of the layer you hold ("Cmd", "Shift+Ctrl") above the bar.
  -- Nothing shows without a modifier.
  show_layer = true,
  -- Name of the macro on each button, as on Blizzard's bars.
  show_macro_names = true,
  -- Light up a button when the Blizzard button behind it glows: procs from
  -- SpellActivationOverlay or other glow addons, and Blizzard's own.
  glow = true,
}
