-- PadKeys_Combat settings. Edit, then /reload.

local ns = PadKeys

ns.config.combat = {
  -- A short text in the middle of the screen when you enter and leave
  -- combat, in white and the PadKeys font (PadKeys/Config.lua, theme).
  banner = true,
  enter_text = "Combat",
  leave_text = "Out of Combat",
  size = 28,
  -- Offset from the centre of the screen, in pixels (positive is up).
  x = 0,
  y = 120,
  -- Seconds to fade in, stay, and fade out.
  fade_in = 0.15,
  hold = 0.8,
  fade_out = 0.6,
}

-- Buff bar (Buffs.lua): out of combat, a row of icons for what's missing
-- or running out: the long buffs your class and group should have,
-- consumables whose buff you don't have, and your supplies. A red frame
-- is missing, yellow with a time is running out, grey with a number is a
-- supply. Click an icon to fix it: the buff is cast on whoever needs it
-- first, the consumable used, poison put on the weapon, the pet called.
-- Hover for its name and who is missing it (the number on its top right).
-- Combat hides it at once; it fades back in as you leave (fade_in).
ns.config.combat.buffs = {
  enabled = true,
  -- Seconds left under which a buff shows (5 minutes).
  warn_at = 300,
  -- Where the list sits. "center": just below the middle of the screen,
  -- under your character (the combat banner is above it). Or a frame's
  -- name to sit under it, e.g. "PlayerFrame" or "TargetFrame" (party and
  -- pet frames sit under the player frame, so it can cover them).
  -- x, y move it, in pixels (positive y is up).
  anchor = "center",
  x = 0,
  y = -120,
  icon_size = 32,
  size = 14,           -- the numbers on the icons
  max_rows = 10,       -- icons at most
  -- Names listed per buff before "+N", in the hover text.
  max_names = 3,
  -- Rogues: the poison a click puts on each weapon (the first item in your
  -- bags whose name holds this; any poison if none).
  poison_main = "Instant Poison",
  poison_off = "Deadly Poison",
  -- Hide the list while resting (in an inn or a city).
  hide_resting = true,
  -- Buffs to leave out: fortitude, mark, intellect, spirit, blessing,
  -- mage_armor, demon_armor, inner_fire, omen, trueshot, poisons,
  -- lightning_shield, imbue.
  -- e.g. ignore = { spirit = true },
  ignore = {},
  -- Consumables in your bags whose buff you don't have (elixirs, flasks,
  -- scrolls, Well Fed food, sharpening stones and oils), out of combat.
  consumables = true,
  -- In combat, fade out the long buffs in Blizzard's buff frame (over 90
  -- seconds left as combat starts, or no duration) and weapon enchants,
  -- so it shows the short ones (LongBuffs.lua).
  hide_long_in_combat = true,

  -- Supplies, as grey icons with a count, out of combat.
  supplies = {
    ammo_low = 200,        -- arrows or bullets in the ammo slot; 0 is off
    -- Always show your most worn item (its icon and %) and your free bag
    -- slots, at the end of the bar, also while resting; they turn yellow
    -- under the two limits below. false shows them only under the limits.
    always = true,
    durability_low = 0.3,  -- your most worn item under 30%
    bag_free_low = 3,      -- free bag slots under this
    pet = true,            -- hunter and warlock: no pet, or a dead one
    -- Warlocks: the demon a click on the pet icon summons (nil: no click).
    warlock_pet = nil,     -- e.g. "Summon Voidwalker"
    -- Reagents per class, once you know the spell that uses them: shown
    -- under `min`. `match` counts every item whose name holds it.
    reagents = {
      WARLOCK = { { item = "Soul Shard", min = 3, spell = 6201,
                    icon = "Interface\\Icons\\INV_Misc_Gem_Amethyst_02" } },
      ROGUE = {
        { match = "Poison", min = 5, spell = 2842,
          icon = "Interface\\Icons\\Ability_Poisons" },
        { item = "Flash Powder", min = 3, spell = 1856,
          icon = "Interface\\Icons\\INV_Misc_Powder_Purple" },
      },
      PRIEST = { { item = "Sacred Candle", min = 5, spell = 21562,
                   icon = "Interface\\Icons\\INV_Misc_Candle_03" } },
      MAGE = {
        { item = "Arcane Powder", min = 5, spell = 23028,
          icon = "Interface\\Icons\\INV_Misc_Dust_01" },
        { item = "Rune of Teleportation", min = 1, spell = 3561,
          icon = "Interface\\Icons\\INV_Misc_Rune_06" },
      },
      DRUID = { { item = "Wild Thornroot", min = 5, spell = 21849,
                  icon = "Interface\\Icons\\INV_Misc_Root_02" } },
      PALADIN = { { item = "Symbol of Kings", min = 20, spell = 25898,
                    icon = "Interface\\Icons\\INV_Misc_Symbolofkings_01" } },
      SHAMAN = { { item = "Ankh", min = 1, spell = 20608,
                   icon = "Interface\\Icons\\INV_Jewelry_Talisman_06" } },
    },
  },
}
