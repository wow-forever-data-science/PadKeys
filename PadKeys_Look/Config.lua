-- PadKeys_Look settings. Edit, then /reload. The font itself is
-- ns.config.theme.font in PadKeys/Config.lua.

local ns = PadKeys

ns.config.look = {
  -- Every font in the game (windows, chat, tooltips, names and damage
  -- numbers above heads) in the theme font. Sizes and outlines stay as
  -- Blizzard set them. Names and damage numbers change after a relog.
  game_font = true,
  -- Chat windows on a black background; 0 is see-through, 1 is solid.
  -- Blizzard's own default is 0.25.
  chat_alpha = 0.6,
}
