# PadKeys (WoW addon)

Gamepad-style play on a keyboard for World of Warcraft: Forever, set up for
a **Mac**. It uses Blizzard's own gamepad code wherever that code runs
without a gamepad, and adds its own code only where Blizzard's doesn't:

- a **key layout** with eight action keys and modifier layers, like a
  gamepad's buttons and shoulders;
- **targeting** like the gamepad: a friendly/enemy mode toggle, enemy and
  group cycling, assist and last target, all usable in combat;
- Blizzard's **main-menu radial** (three pages) and **ping system**;
- a **keyboard UI cursor** that moves through open windows, unit frames and
  your buffs;
- **aura inspection**: step through your debuff and buff tooltips in combat;
- a **smart interact** key that walks through quest dialogs;
- an in-game **key map** (F1), like Blizzard's Controller Map.

It is not part of the R package (`tools/` is in `.Rbuildignore`).

**Status: untested in game.** It was written before launch against
Forever's UI source (Gethe's mirror, branch `forever`, build 1.60.1 (70532):
<https://github.com/Gethe/wow-ui-source/tree/forever>). The function and
frame names were checked there, and the logic was run against a stubbed API.
Expect small fixes on launch day; see the checklist at the end.

## Key map

Press **F1** in game for this list, read from your live bindings. For a
visual version, open `keymap.html` (in this folder) in a browser: a Mac
keyboard with each layer's keys. It's also published at
<https://claude.ai/artifact/6CMswZFmZY5ys9Go17pcsa> (private to the owner).

| Key | Does | Key | Does |
|---|---|---|---|
| 1 2 3 4 Q E R T | Action Bar 1 | W / S | Forward / back |
| Cmd + those | Action Bar 2 | A / D | Strafe |
| Shift + those | Action Bar 3 | Space | Jump |
| Ctrl + those | Pet bar | F | Interact / quest step |
| \` | Friendly ↔ enemy targeting | Shift+F | Assist |
| Tab / Shift+Tab | Next / previous target (in mode) | Ctrl+F | Last target |
| Ctrl+Tab / Ctrl+Shift+Tab | Next / previous group member | Cmd+F | Last hostile target |
| Z (hold) | Main-menu radial | X | Next debuff tooltip |
| G (hold) | Pings | Option+X | Next buff tooltip |
| Shift+\` | UI cursor | F1 | Key map |

| Context | Keys |
|---|---|
| UI cursor | WASD / arrows move · Space click · Shift+Space right-click · Ctrl+Space pick up · Tab / Shift+Tab next / previous window · Esc leave |
| Radial | Q / E or mouse wheel: pages · release Z: open |
| Quest window | F next step · Tab or Shift+F cycle rewards |
| Aura tooltips | X / Option+X next · Esc close |

## Install

1. Download **PadKeys.zip** from the repository's **Releases** page, release
   "PadKeys (latest)". It's rebuilt every time the addon changes on `main`.
   Unzip it into `<WoW install>/<Forever client folder>/Interface/AddOns/`,
   so you end up with `Interface/AddOns/PadKeys/PadKeys.toc`. (Without the
   release: download the repository as a ZIP and copy `tools/PadKeys`
   there instead.)
2. Enable *PadKeys* at character select (tick **Load out of date AddOns** if
   it is listed as out of date).
3. In game, type `/padkeys preview` to see which keys would change, then
   `/padkeys apply`. `/padkeys restore` puts your old keys back.
4. Turn on **Action Bar 2** and **Action Bar 3** (Options or Edit Mode). The
   Cmd and Shift layers fire those bars, so their buttons must exist.
5. **On a Mac: turn on Options → Mac → "Disable OS shortcuts"** and allow
   WoW the macOS permission it asks for. Otherwise Cmd+Q (Action Bar 2,
   slot 5) **quits the game**, and other Cmd shortcuts go to macOS.

Commands: `/padkeys preview`, `apply`, `restore`, `cursor`, `map`.
Everything is set in `Config.lua`: edit it and `/reload`. On Windows, set
`MOD = "ALT-"` at the top of `Config.lua` to use Alt instead of Cmd.

## Key layout

Eight action keys, each with a layer per modifier, like the eight gamepad
action buttons plus the shoulder buttons:

| Keys | Plain | Cmd | Shift | Ctrl |
|---|---|---|---|---|
| 1 2 3 4 Q E R T | Action Bar 1, slots 1–8 | Action Bar 2, slots 1–8 | Action Bar 3, slots 1–8 | Pet bar, slots 1–8 |

Movement is W/S, with **A/D strafing** (turn with the mouse or the arrow
keys). **F interacts** with whatever you face: loot, NPCs, herbs, ore.

`/padkeys apply` also switches on soft targeting for keyboard
(`SoftTargetInteract` and `SoftTargetEnemy` set to 3), key-down casting and
auto loot.

What you lose from WoW's defaults:
- Q/E strafe (now A/D) and R reply to whisper (type `/r`);
- T attack (soft targeting starts attacks), Z sheathe and X sit (type
  `/sit`);
- G target last hostile (now Cmd+F) and Ctrl+Tab nearest friend (now
  friendly mode);
- F1–F5 targeting yourself and party members (F1 is now the key map);
- Shift+1–6 bar paging.

The pet bar stays on Ctrl, as in the defaults, and Alt stays free for
self-cast. Cmd is `META` in WoW's key names.

## Targeting (works in combat)

The gamepad has "Target Friendly" and "Target Hostile" buttons. PadKeys
turns them into a mode:

| Key | Does |
|---|---|
| \` | Toggle enemy mode (default) / friendly mode. Friendly mode shows "Friendly targeting" near the top of the screen. |
| Tab / Shift+Tab | Next / previous nearest enemy, or friendly player or NPC in friendly mode |
| Ctrl+Tab / Ctrl+Shift+Tab | Next / previous party or raid member, in raid frame order |
| Shift+F | Assist: target your target's target |
| Ctrl+F | Last target |
| Cmd+F | Last hostile target |

The mode toggle and group cycling are secure buttons, so they work in
combat: the toggle rebinds Tab and Shift+Tab, and group cycling picks the
next group member that exists.

## Main-menu radial (Blizzard's)

Hold **Z**. Blizzard's gamepad radial opens with its three pages, centre page
first:

- **Left:** Group Finder, Legacy, Shop, Guild, Social, Buffs, Tracking,
  Collections.
- **Centre:** Bags, Professions, Character, Talents, Map, Chat, Menu,
  Spellbook.
- **Right:** Clock, Calendar, PvP.

Move the mouse towards a segment (the mouse acts as the right stick).
Switch pages with **Q / E** or the **mouse wheel** (the gamepad's
shoulders). Release Z to open the highlighted segment, or release with
nothing highlighted to close. It opens windows, so it's for out of combat,
as on a gamepad. The page hints show gamepad button icons, because it's
Blizzard's gamepad art.

The **Buffs** segment only works in gamepad mode in Blizzard's code. On
keyboard, PadKeys hooks it to open the UI cursor on your buffs (or debuffs,
if you have no buffs).

## Pings (Blizzard's)

Hold **G**: Blizzard's ping system. Click a unit or a spot to send a
contextual ping, or drag for Blizzard's ping wheel.

## UI cursor (out of combat)

Press **Shift+\`**. The cursor also starts by itself when a gossip, quest,
merchant or loot window or a popup opens.

| Key | Does |
|---|---|
| W A S D / arrows | Move between buttons |
| Space / Enter | Click: cast from the spellbook, pick a gossip line |
| Shift+Space | Right-click: use or sell an item, cancel a buff |
| Ctrl+Space | Pick up a spell or item; move to an action bar slot and click to place it |
| Tab / Shift+Tab | Jump to the next / previous open window (the gamepad's "Next Frame") |
| Esc / Backspace | Leave the cursor. A second Esc closes windows or opens the game menu as usual. |

While the cursor is on, these keys drive it instead of moving you, like the
gamepad's UI focus mode. They're only taken over while it's on.

- **Started with Shift+\`:** it also reaches the player, target, focus,
  party and raid frames (Space targets that unit) and your **buffs and
  debuffs** (the highlighted one shows its tooltip; Shift+Space cancels a
  buff, the same right-click Blizzard's gamepad uses).
- **Started by a window opening:** it only covers windows, and switches off
  when they close.

Clicks go through a secure button bound to the key, so they count as real
key presses, and spells and items work. Moving the cursor is blocked in
combat, so it switches off when combat starts.

## Aura tooltips (works in combat)

| Key | Does |
|---|---|
| X | Tooltip of your next debuff |
| Option+X | Tooltip of your next buff |
| Esc | Close the tooltip view |

Each press moves to the next icon in Blizzard's debuff (or buff) row, in
display order, wrapping around, and shows its tooltip at the icon exactly
as if you hovered it. X and Option+X take over Esc through a secure snippet
(the only way to change a key in combat), and Esc gives it back, so outside
the tooltip view Esc opens the game menu as usual. If you had no debuffs
when you pressed X, the next Esc only gives Esc back; press it again for
the game menu.

## Smart interact (quests)

While a quest giver's window is open, each press of **F** does the next step:

1. In the gossip list: pick a quest you can turn in, else a new quest, else
   the only chat option, else close.
2. On a quest page: **Accept** → **Continue** → **Complete**, using
   Blizzard's gamepad action.
3. With several rewards, the first press selects one and shows its tooltip.
   **Tab** or **Shift+F** cycles through them, and F takes the one shown.
4. When nothing is left, F closes the window.

Each press does exactly one step; nothing is automated.

## Key map (F1)

**F1** (or `/padkeys map`) opens the key map in a Blizzard-style window. It
reads your live keybindings each time it opens, with Blizzard's own key and
action names, so it always shows your real setup. Esc closes it.

## What is Blizzard's and what is ours

| Feature | Blizzard code used | Our code |
|---|---|---|
| Menu radial | `GamepadRadial` (`Blizzard_Gamepad/UI/Radials`): art, pages, segments and actions | feeding it the mouse as the "stick", page keys and release |
| Pings | the ping system (`TOGGLEPINGLISTENER`, `Blizzard_PingUI`) and its wheel | none, only the key |
| Quest steps | `QuestFrame_GeneralProgressAction`, the gamepad's accept/continue/complete | gossip and greeting lists, and the reward choice |
| Key layout | Blizzard's binding actions | apply/restore of the bindings |
| Targeting modes | Blizzard's friendly/enemy targeting bindings | a secure toggle that swaps them on Tab |
| Aura tooltips | the aura icons' own tooltip code (`AuraButtonMixin:OnEnter`) | choosing which icon is next |
| Buff cancelling | the aura icons' right-click (as `BuffFrameMixin:CancelSelectedBuff`) | reaching the icons with the cursor |
| Key map | `ButtonFrameTemplate` window, `GetBindingText` key names, `BINDING_NAME_*` action names | the list of sections |
| Group cycling | none: Blizzard's party/raid targeting only runs in gamepad mode | a secure button |
| UI cursor | none: Blizzard's SmartNavigation only runs in gamepad mode | our own cursor |

Blizzard's menu cursor and group targeting depend on the gamepad frame
manager, which only starts when the interface is in gamepad mode. Turning
them on from an addon would mean forcing Blizzard's internal state, which is
more fragile than the small versions here.

## Launch-day checklist (Nov 4)

1. **Loads?** Enable it and `/reload`, and watch for Lua errors (`/console
   scriptErrors 1`). If it says out of date, check the interface number with
   `/dump select(4, GetBuildInfo())` and update `## Interface:` in
   `PadKeys.toc`.
2. **Layout**: `/padkeys apply`, then press 1–T on their own and with Cmd,
   Shift and Ctrl. Check that Cmd+Q casts instead of quitting (install
   step 5).
3. **Key map**: press F1 and check it matches what the keys do.
4. **Interact**: face a corpse or an NPC and press F.
5. **Radial**: hold Z, move the mouse, switch pages with Q/E and the wheel,
   release on a segment. Watch for Lua errors when it opens.
6. **Cursor**: open the spellbook and bags, press Shift+\`, move with WASD,
   Tab between the windows, Space on a spell, Shift+Space on a bag item.
7. **Aura tooltips in combat**: on a mob that debuffs you, press X a few
   times, then Option+X, then Esc; Esc again should open the game menu.
8. **Buffs**: hold Z, left page, pick Buffs. The cursor should land on your
   buffs; cancel one with Shift+Space.
9. **Quests**: talk to a quest giver with F and keep pressing F.
10. **Targeting** (in a group, also in combat): Ctrl+Tab through the party,
    Ctrl+F back to the previous target, Shift+F to assist, \` then Tab for
    friends, \` again for enemies. Press Shift+\` and move over the raid
    frames.
11. **Pings** (in a group): hold G and click a mob, then drag for the wheel.

Known risks:
- The radial is Blizzard's gamepad frame running in keyboard mode. If it
  errors, its open/close steps call gamepad managers that may not be
  running; send the error and it can be fixed or worked around.
- Tooltips while the cursor moves come from calling Blizzard's own OnEnter
  handlers. If that causes "action blocked" errors, set `tooltips = false`
  under `cursor` in `Config.lua`.
- Tab is used by targeting, the cursor and quest rewards. If two of them
  take Tab at the same moment (e.g. toggling friendly mode while the cursor
  is on), the one that took it last wins.
- The cursor finds windows from `UIPanelWindows`, `UISpecialFrames` and a
  short list of names. A window it misses can be added to `EXTRA_ROOTS` in
  `Cursor.lua`.
- Long scroll lists aren't scrolled by the cursor yet; use the mouse wheel.

## Related branch

`feat/padkeys-custom-rings` adds our own secure rings on top of this:
a Utility ring (Hearthstone, macros, your own spells and items) and a Ping
ring that pings your target in combat without clicking. Blizzard has no ring
for your own spells and items, so those need our code.

## Terms of service

It only uses Blizzard's public UI API. Every key press does one thing, and
nothing runs on its own, reads game memory or automates play. That's in
line with Blizzard's UI Add-On Development Policy.
