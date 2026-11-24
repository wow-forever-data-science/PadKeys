-- PadKeys_Readout settings. Edit, then /reload.

local ns = PadKeys

ns.config.readout = {
  -- A faint disc around the mouse pointer that drains with the global
  -- cooldown, or with your cast or channel while you cast.
  disc = true,
  disc_size = 44,
  disc_alpha = 0.3,
  -- Only in combat (your casts out of combat still show).
  disc_in_combat_only = true,

  -- Your target's cast or channel beside the mouse: its icon draining,
  -- and its name. Only while it casts.
  target_cast = true,

  -- Boss abilities from Blizzard's encounter timeline, beside the mouse,
  -- as the timeline highlights them (a few seconds before they land): icon,
  -- countdown and name. Up to this many at once.
  boss = true,
  boss_rows = 3,

  -- Your tracked buffs (Blizzard's Cooldown Manager, "Tracked Buffs")
  -- beside the mouse, while they are on you, with their time left. Pick
  -- the buffs in the Cooldown Manager's options. buffs_point is the
  -- viewer's point placed at x, y from the pointer: "BOTTOMLEFT" puts it
  -- above and to the right, clear of the arrow and of the rows below
  -- right. buffs_scale shrinks it against its Edit Mode size while docked.
  buffs = true,
  buffs_point = "BOTTOMLEFT",
  buffs_x = 8,
  buffs_y = 4,
  buffs_scale = 0.6,

  -- Icon size and text size of the target cast and boss rows, and their
  -- place against the mouse pointer, in pixels (positive y is up).
  icon_size = 28,
  text_size = 13,
  x = 34,
  y = -6,
  -- Slightly rounded corners, as on the PadKeys bar; false for square.
  rounded = true,
}
