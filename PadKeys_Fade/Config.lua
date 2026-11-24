-- PadKeys_Fade settings. Edit, then /reload.

local ns = PadKeys

-- Hold \ to show every group; they fade again as you let go.
ns.config.bindings["\\"] = "CLICK PadKeysFadeAll:LeftButton"

ns.config.fade = {
  -- Frames that fade together: hovering one shows its whole group. Names
  -- are Blizzard's globals; a name that doesn't exist is skipped. Bars
  -- must be set to "Always" (not "Hidden") in Edit Mode to show on hover.
  --
  -- A group can also show by itself:
  -- - show_when: it shows while any of these is true:
  --     combat       you are in combat
  --     no_combat    you are out of combat
  --     target       you have a target
  --     pet          you have a pet out
  --     group        you are in a party or raid
  --     resting      in an inn or a city
  --     mounted      you are mounted
  --     not_full     out of combat, your health or mana isn't full
  --     group_hurt   out of combat, someone in your party isn't at full health
  --     talents      you have talent points to spend
  -- - flash_on: game events that show it for flash_for seconds, then it
  --   fades again (e.g. PLAYER_XP_UPDATE as you gain experience).
  -- Hovering a group always shows it too.
  groups = {
    bars = {
      "MainActionBar",        -- Action Bar 1 (MainMenuBar on older clients)
      "MultiBarBottomLeft",   -- Action Bar 2
      "MultiBarBottomRight",  -- Action Bar 3
      "MultiBarRight",        -- Action Bar 4
      "MultiBarLeft",         -- Action Bar 5
      "MultiBar5",            -- Action Bar 6
      "MultiBar6",            -- Action Bar 7
      "MultiBar7",            -- Action Bar 8
      "PetActionBar",
      "StanceBar",
    },
    -- The micro menu, while you have talent points to spend.
    menu = {
      "MicroMenuContainer",
      show_when = { "talents" },
    },
    -- The bags, for a moment as loot goes into them.
    bags = {
      "BagsBar",
      flash_on = { "ITEM_PUSH" },
      flash_for = 3,
    },
    -- Your own frame and your pet's: in combat, with a target, or while
    -- your health or mana fills back up.
    player = {
      "PlayerFrame",
      "PetFrame",
      show_when = { "combat", "target", "not_full" },
    },
    -- Your buffs, only on hover (debuffs stay). PadKeys_Portrait shows
    -- your stance, form, aspect or aura.
    buffs = {
      "BuffFrame",
    },
    -- Party frames: in combat, or while someone is hurt.
    party = {
      "PartyFrame",
      show_when = { "combat", "group_hurt" },
    },
    -- The experience and reputation bars, for a few seconds as they change.
    status = {
      "MainStatusTrackingBarContainer",
      "SecondaryStatusTrackingBarContainer",
      flash_on = { "PLAYER_XP_UPDATE", "UPDATE_FACTION" },
      flash_for = 4,
    },
    -- The quest tracker, for a few seconds as you take a quest or an
    -- objective moves.
    quests = {
      "QuestWatchFrame",
      "ObjectiveTrackerFrame",
      flash_on = { "QUEST_ACCEPTED", "QUEST_WATCH_UPDATE" },
      flash_for = 5,
    },
  },
  -- Groups that show while you drag a spell, item, macro or pet action.
  show_while_dragging = { bars = true },
  -- Alpha when faded: 0 is invisible.
  faded_alpha = 0,
  -- Seconds to fade in and out, and to stay after the mouse leaves or a
  -- show_when stops being true.
  fade_in = 0.15,
  fade_out = 0.3,
  linger = 0.6,
  -- Extra pixels around each frame that still count as hovering it.
  padding = 10,
  -- A label to the right of each action bar (to its left at the right
  -- edge of the screen): its name and the PadKeys key that fires it
  -- ("Bar 2 · Cmd", "Bar 6 · G wheel · combat").
  labels = true,
  label_size = 12,
  label_gap = 6,      -- pixels between the label and the bar
}
