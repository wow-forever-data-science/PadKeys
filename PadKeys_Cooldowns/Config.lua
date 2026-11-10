-- PadKeys_Cooldowns settings. Edit, then /reload. Which spells show, the
-- layout, size and the timer are Blizzard's Cooldown Manager settings
-- (Edit Mode, and the Cooldown Manager's own options).

local ns = PadKeys

ns.config.cooldowns = {
  -- Slightly rounded corners, as on the PadKeys bar; false for square.
  rounded = true,
  -- The clock-hand shadow over a spell on cooldown. Off, as on the PadKeys
  -- bar: Blizzard greys the icon and the countdown shows the seconds
  -- (turn on "Show timer" in the Cooldown Manager's options).
  cooldown_swipe = false,
  -- The shadow on a buff icon that shrinks as the buff runs out. On, in
  -- black instead of Blizzard's yellow.
  buff_swipe = true,
  -- Blizzard tints an icon red out of range, blue without mana and dark
  -- grey when it can't be used. On: grey instead (light grey without
  -- mana, dark grey otherwise), as on the PadKeys bar.
  grey_tints = true,
  -- Buff bars: the bar in light grey on black instead of orange.
  grey_bars = true,
  -- Countdown size on the Essential icons. The other viewers' countdowns,
  -- charges and stacks keep Blizzard's sizes, in the theme font.
  countdown_size = 18,
}
