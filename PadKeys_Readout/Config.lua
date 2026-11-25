-- PadKeys_Readout settings. Edit, then /reload.

local ns = PadKeys

ns.config.readout = {
  -- A ring around the mouse pointer (Ring.lua), empty most of the time.
  ring = {
    enabled = true,
    size = 56,           -- pixels across
    track_alpha = 0.25,  -- the grey track under the fill, while it fills
    -- true: the colour grows round the ring as time passes (fills up);
    -- false: it shrinks (drains).
    fill = true,

    -- Your cast or channel fills it, blue.
    cast_color = { 0.25, 0.6, 1 },
    -- Glowing yellow instead when the cast lands while one of these buffs
    -- (spell IDs) is still on you, e.g. a proc that the cast should
    -- benefit from. Decided as the cast starts. If a buff's time is secret
    -- in combat and the client refuses the comparison, the ring stays blue.
    buffed_color = { 1, 0.85, 0.2 },
    glow_pulse = 0.45,   -- seconds per pulse of the yellow glow
    buffs = {
      12536,  -- Clearcasting (mage)
      16870,  -- Clearcasting (druid)
      16246,  -- Clearcasting (shaman, Elemental Focus)
      16166,  -- Elemental Mastery
      14751,  -- Inner Focus
      10060,  -- Power Infusion
      12042,  -- Arcane Power
      16886,  -- Nature's Grace
    },

    -- Out of a cast, the global cooldown fills it faintly.
    gcd = true,
    gcd_color = { 1, 1, 1 },
    gcd_alpha = 0.35,
    gcd_in_combat_only = true,

    -- A hit you take flashes it red for hit_time seconds. Crits, crushing
    -- blows and bursts (burst_hits hits within burst_window seconds) flash
    -- at full strength; other hits as bright as hit_by_health says, as
    -- { health, alpha } points from 0 to 1 joined by straight lines:
    -- nothing above 80% health, full at 50% and below.
    hits = true,
    hit_color = { 1, 0.1, 0.1 },
    hit_time = 0.35,
    hit_min_gap = 0.12,  -- at most one flash per this many seconds
    burst_hits = 4,
    burst_window = 1.5,
    hit_by_health = { { 0, 1 }, { 0.5, 1 }, { 0.8, 0 }, { 1, 0 } },
  },

  -- Everything below sits outside the G radial (about 84 px from the
  -- pointer at its scale 0.35), so holding G never covers it.

  -- Your big cooldowns that are ready (Big.lua), right of the pointer: a
  -- column of icons for self-buffs, trinkets and impactful spells on any
  -- action bar (hidden bars count; put trinkets on one). Big means a
  -- cooldown of at least `min` seconds, learned as you use them and
  -- saved; `names` adds some before they were ever used. Each pops in as
  -- it comes back and goes as you use it; dimmed while you can't use it.
  big = {
    enabled = true,
    min = 60,
    max = 4,              -- icons at most
    icon_size = 26,
    gap = 4,
    x = 92,               -- left edge of the column, from the pointer
    y = 0,
    only_when_fighting = true,  -- in combat or with an enemy targeted
    names = {},           -- e.g. { "Recklessness", "Innervate" }
    ignore = { "Hearthstone" },
  },

  -- Your pet in trouble (Pet.lua), lower left of the pointer: its
  -- portrait with a pulsing red ring, only for `hold` seconds after it
  -- takes a lot of damage (a crit or crushing blow, or burst_hits hits
  -- within burst_window seconds), and while its health is under `low`.
  -- Otherwise nothing. Out of combat the buff bar tells you it's missing.
  pet = {
    enabled = true,
    size = 30,
    x = -90,             -- its top right, from the pointer
    y = -40,
    low = 0.35,
    burst_hits = 3,
    burst_window = 2,
    hold = 3,
    pulse = 0.35,        -- seconds per pulse
    combat_only = true,
  },

  -- Your target's cast or channel beside the mouse: its icon draining,
  -- and its name. Off: the big cooldowns took its place, and nameplates
  -- show casts too. true shows it above right of the pointer again.
  target_cast = false,

  -- Boss abilities from Blizzard's encounter timeline, upper left of the
  -- pointer, as the timeline highlights them (a few seconds before they
  -- land): icon, countdown and name to the left. Up to this many at once,
  -- stacking upwards from boss_x, boss_y (the lowest row's lower right).
  -- Blizzard's own timeline stays where it is.
  boss = true,
  boss_rows = 3,
  boss_x = -72,
  boss_y = 44,

  -- Your tracked buffs (Blizzard's Cooldown Manager, "Tracked Buffs")
  -- beside the mouse, while they are on you, with their time left. Pick
  -- the buffs in the Cooldown Manager's options. buffs_point is the
  -- viewer's point placed at x, y from the pointer: "BOTTOMLEFT" puts it
  -- above and to the right, outside the radial and above the big
  -- cooldowns. buffs_scale shrinks it against its Edit Mode size while
  -- docked.
  buffs = true,
  buffs_point = "BOTTOMLEFT",
  buffs_x = 62,
  buffs_y = 62,
  buffs_scale = 0.6,

  -- Icon size and text size of the target cast and boss rows, and the
  -- target cast's place against the mouse pointer, in pixels (positive y
  -- is up).
  icon_size = 28,
  text_size = 13,
  x = 92,
  y = -80,
  -- Slightly rounded corners, as on the PadKeys bar; false for square.
  rounded = true,
}
