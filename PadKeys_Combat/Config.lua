-- PadKeys_Combat settings. Edit, then /reload.

local ns = PadKeys

ns.config.combat = {
  -- A short text in the middle of the screen when you enter and leave
  -- combat. It uses PadKeys_Bar's font (its Config.lua `font`), or Roboto
  -- Condensed ExtraBold from PadKeys_Bar's folder if that isn't loaded.
  banner = true,
  enter_text = "Combat",
  leave_text = "Out of Combat",
  -- Colours, red/green/blue from 0 to 1.
  enter_color = { 1, 0.25, 0.2 },
  leave_color = { 0.4, 1, 0.4 },
  size = 28,
  -- Offset from the centre of the screen, in pixels (positive is up).
  x = 0,
  y = 120,
  -- Seconds to fade in, stay, and fade out.
  fade_in = 0.15,
  hold = 0.8,
  fade_out = 0.6,
}
