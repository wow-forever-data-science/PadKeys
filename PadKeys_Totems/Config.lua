-- PadKeys_Totems settings. Edit, then /reload. Move or resize the totem
-- bar in Blizzard's Edit Mode, as before.

local ns = PadKeys

ns.config.totems = {
  -- Slightly rounded corners, as on the PadKeys bar; false for square.
  rounded = true,
  -- Behind an empty totem slot; 0 is see-through, 1 is solid black.
  background_alpha = 0.75,
  -- Blizzard's coloured frame around each slot (earth, fire, water, air).
  -- Off: black and white only; the slots stay in Blizzard's order.
  element_colors = false,
  -- Text sizes: key label, stack count, cooldown countdown.
  hotkey_size = 10,
  count_size = 10,
  countdown_size = 13,
}
