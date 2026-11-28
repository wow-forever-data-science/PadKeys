-- PadKeys_Readout settings. Edit, then /reload.

local ns = PadKeys

ns.config.readout = {
  -- A ring around the mouse pointer (Ring.lua), empty most of the time.
  ring = {
    enabled = true,
    size = 28,           -- pixels across
    track_alpha = 0.25,  -- the grey track under the fill, while it fills
    -- true: the colour grows round the ring as time passes (fills up);
    -- false: it shrinks (drains).
    fill = true,

    -- Your cast or channel fills it: blue for a damaging spell, green for
    -- a healing (or other helpful) one.
    cast_color = { 0.25, 0.6, 1 },
    heal_color = { 0.3, 0.9, 0.4 },
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

    -- Off: the hits you take show lower right of the mouse instead
    -- (PadKeys_CombatText). true: a hit you take flashes it red for
    -- hit_time seconds. Crits, crushing
    -- blows and bursts (burst_hits hits within burst_window seconds) flash
    -- at full strength; other hits as bright as hit_by_health says, as
    -- { health, alpha } points from 0 to 1 joined by straight lines:
    -- nothing above 80% health, full at 50% and below.
    hits = false,
    hit_color = { 1, 0.1, 0.1 },
    hit_time = 0.35,
    hit_min_gap = 0.12,  -- at most one flash per this many seconds
    burst_hits = 4,
    burst_window = 1.5,
    hit_by_health = { { 0, 1 }, { 0.5, 1 }, { 0.8, 0 }, { 1, 0 } },
  },

  -- Your swing timer (Swing.lua): a thin ring just outside the cast ring
  -- that fills from one auto attack to the next, white for melee, orange
  -- for Auto Shot. Its faint track stays on all through combat
  -- (track = "combat"; "swing" shows it only while it fills): it is the
  -- line the icons below sit on.
  swing = {
    enabled = true,
    size = 35,           -- pixels across: 25% over the cast ring (28)
    alpha = 0.85,
    track = "combat",
    track_alpha = 0.2,
    fill = true,         -- as the cast ring: true fills up, false drains
    main_hand = true,
    main_color = { 1, 1, 1 },
    ranged = true,       -- Auto Shot, Shoot (wands)
    ranged_color = { 1, 0.6, 0.15 },
    off_hand = false,    -- true: a second ring just inside for the off hand
    off_color = { 0.7, 0.7, 0.7 },
  },

  -- Everything below sits outside the swing ring with some room (about
  -- 28 px from the pointer). Holding G covers it while the wheel is open.

  -- Your big cooldowns that are ready (Big.lua), right of the pointer: a
  -- row of icons for self-buffs, trinkets and impactful spells on any
  -- action bar (hidden bars count; put trinkets on one). Big means a
  -- cooldown of at least `min` seconds, learned as you use them and
  -- saved; `names` adds some before they were ever used. Each pops in as
  -- it comes back and goes as you use it; dimmed while you can't use it.
  -- A cooldown that only starts when its buff ends (Rapid Fire) counts as
  -- used from the press, so it goes at once.
  big = {
    enabled = true,
    -- Your race's spells (Racial on their tooltip) always show here,
    -- first in the row, whatever their cooldown: press them early in a
    -- fight. They must be on an action bar, as the rest.
    racials = true,
    min = 60,
    max = 4,              -- icons at most
    icon_size = 34,
    gap = 3,
    grow = "right",       -- a row growing right; "down": a column
    x = 28,               -- left edge of the first icon, from the pointer
    y = 0,
    only_when_fighting = true,  -- in combat or with an enemy targeted
    names = {},           -- e.g. { "Recklessness", "Innervate" }
    -- Items only while worn (trinkets): potions, a sleeping bag and other
    -- items in your bags are left out (the G ring's copy at the mouse
    -- lights the potions by health). true counts bag items again.
    bag_items = false,
    -- Never shown, racials too (full names, any case): no use in a fight.
    ignore = {
      "Hearthstone",
      "Track Treasure", "Find Treasure",  -- dwarf
      "Read Leyline", "Walk on Air",      -- sky elf
    },
  },

  -- Your pet in trouble (Pet.lua), below the pointer (the bottom of the
  -- wheel is health: yours lower right, your pet's below): its
  -- portrait with a pulsing red ring, only for `hold` seconds after it
  -- takes a lot of damage (a crit or crushing blow, or burst_hits hits
  -- within burst_window seconds), and while its health is under `low`.
  -- Otherwise nothing. Out of combat the buff bar tells you it's missing.
  pet = {
    enabled = true,
    -- false: no portrait; the hits are still read, and the G wheel's pet
    -- heal slice at the mouse pulses red instead (PadKeys_Radial lights).
    portrait = false,
    size = 40,
    x = 20,              -- its top right, from the pointer
    y = -28,
    low = 0.35,
    burst_hits = 3,
    burst_window = 2,
    hold = 3,
    pulse = 0.35,        -- seconds per pulse
    combat_only = true,
  },

  -- Your debuffs, left of the pointer: Blizzard's debuff frame (Dock.lua),
  -- with its icons, times and dispel-type borders. debuffs_point is the
  -- frame's point placed at x, y from the pointer ("RIGHT": it grows
  -- leftwards from there). debuffs_scale against its Edit Mode size. Edit
  -- Mode still shows it where Blizzard keeps it.
  debuffs = true,
  debuffs_point = "RIGHT",
  debuffs_x = -28,
  debuffs_y = 0,
  debuffs_scale = 0.92,
  -- Debuffs never shown there (spell IDs, or names as the tooltip shows
  -- them, in your client's language): invisible, their slot stays.
  -- Pressing a bandage under Recently Bandaged flashes it above the
  -- pointer instead (PadKeys_NotReady).
  debuffs_hide = {
    11196,           -- Recently Bandaged
    "Boosted Rest",  -- no more rested experience from a Camp Tent
  },

  -- Your totems above right of the pointer, over the tracked buffs
  -- (Totems.lua): timers running on you, like them. One icon per totem
  -- that is down, draining with its time left, the seconds on it. point
  -- is the row's point placed at x, y from the pointer: "BOTTOMLEFT"
  -- grows right from there, "TOP" centres the row under it.
  -- beside_buffs: on the tracked buffs' line, right after the last one
  -- showing; x, y (the buffs' corner) while none does. For one line, set
  -- Tracked Buffs to horizontal in Edit Mode (a wow-settings layout).
  totems = {
    enabled = true,
    icon_size = 29,
    gap = 3,
    point = "BOTTOMLEFT",
    x = 22,
    y = 22,
    beside_buffs = true,
    countdown = true,
    countdown_size = 12,
  },

  -- A buff you need that is missing, in combat, just above the pointer
  -- (Missing.lua): its icon with a red frame. Per class: `spell` the buff
  -- to have, `group` the buffs that replace each other (any rank). Buffs
  -- are secret in combat: what is on you is read as combat starts and
  -- followed by your own casts. Out of combat the buff bar shows it.
  missing = {
    enabled = true,
    size = 29,
    point = "BOTTOM",    -- the icon's point placed at x, y from the pointer
    x = 0,
    y = 28,
    buffs = {
      HUNTER = {
        spell = 13165,   -- Aspect of the Hawk
        group = { 13165, 13163, 5118, 13159, 20043, 13161 },  -- Hawk, Monkey,
                         -- Cheetah, Pack, Wild, Beast
      },
    },
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
  boss_x = -22,
  boss_y = 22,

  -- Your tracked buffs (Blizzard's Cooldown Manager, "Tracked Buffs")
  -- beside the mouse, while they are on you, with their time left. Pick
  -- the buffs in the Cooldown Manager's options. buffs_point is the
  -- viewer's point placed at x, y from the pointer: "BOTTOMLEFT" puts it
  -- above and to the right, on the swing ring and above the big
  -- cooldowns. buffs_scale shrinks it against its Edit Mode size while
  -- docked.
  buffs = true,
  buffs_point = "BOTTOMLEFT",
  buffs_x = 22,
  buffs_y = 22,
  buffs_scale = 0.8,

  -- Icon size and text size of the target cast and boss rows, and the
  -- target cast's place against the mouse pointer, in pixels (positive y
  -- is up).
  icon_size = 37,
  text_size = 13,
  x = 92,
  y = -80,
  -- Slightly rounded corners, as on the PadKeys bar; false for square.
  rounded = true,
}
