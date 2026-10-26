# PadKeys (WoW addon)

Gamepad-style play on a keyboard for World of Warcraft: Forever. It uses
Blizzard's own gamepad UI code wherever that code runs without a gamepad,
and adds as little of its own as possible:

1. a **key layout** with few keys and modifier layers, like a gamepad;
2. Blizzard's **gamepad main-menu radial** (three pages), driven by mouse
   and keyboard;
3. Blizzard's **ping system** on one key;
4. a **keyboard UI cursor** that moves through open windows;
5. a **smart interact** key that walks through quest dialogs.

It is not part of the R package (`tools/` is in `.Rbuildignore`).

**Status: untested in game.** It was written before launch against
Forever's UI source (Gethe's mirror, branch `forever`, build 1.60.1 (70532):
<https://github.com/Gethe/wow-ui-source/tree/forever>). The function and
frame names were checked there, and the logic was run against a stubbed API.
Expect small fixes on launch day; see the checklist at the end.

## What is Blizzard's and what is ours

| Feature | Blizzard code used | Our code |
|---|---|---|
| Menu radial | `GamepadRadial` (`Blizzard_Gamepad/UI/Radials`): its art, pages, segments and actions | ~100 lines feeding it the mouse as the "stick", page keys and release |
| Pings | The ping system (`TOGGLEPINGLISTENER` binding, `Blizzard_PingUI`), including its ping wheel | none, only the key |
| Quest steps | `QuestFrame_GeneralProgressAction`, the gamepad's own accept/continue/complete action | gossip and greeting lists, and the reward choice |
| Key layout | Blizzard's binding actions | apply/restore of the bindings |
| Key map | Blizzard's `ButtonFrameTemplate` window, key names (`GetBindingText`) and action names (`BINDING_NAME_*`) | the list of sections |
| Targeting modes | Blizzard's friendly/enemy targeting bindings | a secure toggle that swaps them on Tab |
| Aura inspection | the aura icons' own tooltip code (`AuraButtonMixin:OnEnter`) | ~50 lines choosing which icon is next |
| Group cycling | none: Blizzard's party/raid targeting only runs in gamepad mode | a secure button that targets the next group member |
| UI cursor | none: Blizzard's SmartNavigation only runs in gamepad mode | our own cursor |

Blizzard's menu cursor (SmartNavigation) and group targeting depend on the
gamepad frame manager, which only starts when the interface is in gamepad
mode. Switching Blizzard's code on by hand from an addon would mean forcing
its internal state, which is more fragile than the small cursor we have.

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

Everything is set in `Config.lua`: edit it and `/reload`.

## 1. Key layout

Eight "face buttons", each with a layer per modifier, like the eight
gamepad action buttons plus the shoulder buttons.

| Keys | Plain | Cmd | Shift | Ctrl |
|---|---|---|---|---|
| 1 2 3 4 Q E R T | Action Bar 1, slots 1–8 | Action Bar 2, slots 1–8 | Action Bar 3, slots 1–8 | Pet bar, slots 1–8 |

| Key | Does |
|---|---|
| W / S | Move forward / back |
| A / D | **Strafe** (turn with the mouse or the arrow keys) |
| F | **Interact** with what you face: loot, NPCs, herbs, ore. Smart quest steps while a quest window is open (below). |
| Shift+F | Assist: target your target's target (cycles rewards while a quest window is open) |
| Ctrl+F | Last target: swap back to your previous target |
| Cmd+F | Last hostile target |
| \` | **Toggle friendly / enemy targeting** (works in combat) |
| Tab / Shift+Tab | Next / previous enemy, or friend in friendly mode |
| Ctrl+Tab / Ctrl+Shift+Tab | Next / previous party or raid member, in raid frame order (works in combat) |
| Z (hold) | Blizzard's main-menu radial |
| G (hold) | Blizzard's ping system |
| X | Inspect your **debuffs**: next tooltip each press, in combat too |
| Alt+X | Inspect your buffs |
| Esc | Closes the debuff/buff tooltip view (only while it's open) |
| Shift+\` | Toggle the keyboard UI cursor |
| F1 | **Key map**: what every key does |

F2–F5 are unbound.

`/padkeys apply` also switches on soft targeting for keyboard
(`SoftTargetInteract` and `SoftTargetEnemy` set to 3), key-down casting and
auto loot.

What you lose from the defaults:
- Q/E strafe (now on A/D) and R reply to whisper (type `/r`);
- X sit/stand (type `/sit`);
- T attack (soft targeting starts attacks) and Z sheathe;
- G target last hostile (now Cmd+F) and Ctrl+Tab nearest friend;
- F1–F5 targeting yourself and party members (F1 is now the key map);
- Shift+1–6 bar paging.

The pet bar stays on Ctrl, as in the defaults, and Alt stays free for
self-cast. The layouts are for a Mac, where Cmd is `META` in WoW's key
names; on Windows set `MOD = "ALT-"` at the top of `Config.lua`.

## 2. Main-menu radial (Blizzard's)

Hold **Z**. Blizzard's gamepad radial opens with its three pages, centre page
first:

- **Left:** Group Finder, Legacy, Shop, Guild, Social, Buffs, Tracking,
  Collections.
- **Centre:** Bags, Professions, Character, Talents, Map, Chat, Menu,
  Spellbook.
- **Right:** Clock, Calendar, PvP.

Move the mouse towards a segment; the mouse acts as the right stick. Switch
pages with **Q / E** or the **mouse wheel** (the gamepad's shoulder buttons).
Release Z to open the highlighted segment, or release with nothing
highlighted to close.

It opens windows, so it is for out of combat, as on a gamepad.

The **Buffs** item (left page) only works in gamepad mode in Blizzard's
code. On keyboard, PadKeys hooks it to open the cursor on your buffs (or
debuffs, if you have no buffs). The page
hints show gamepad button icons, because it is Blizzard's gamepad art.

## 3. Pings (Blizzard's)

Hold **G**: Blizzard's ping system. Click a unit or a spot to send a
contextual ping, or drag for Blizzard's ping wheel (Attack, Warning, On my
way, Assist). This is Blizzard's code and art.

## 4. Keyboard UI cursor

Press **Shift+\`** with any window open. The cursor also starts by itself when a
gossip, quest, merchant, loot window or a popup opens.

| Key | Does |
|---|---|
| W A S D / arrows | Move between buttons |
| Space / Enter | Click (cast from the spellbook, pick a gossip line) |
| Shift+Space | Right-click (use or sell an item) |
| Ctrl+Space | Pick up the spell or item (then move to an action bar slot and click to place it) |
| Tab / Shift+Tab | Jump to the next / previous open window (the gamepad's "Next Frame") |
| Esc / Backspace | Leave cursor mode (a second Esc then closes windows or opens the game menu as usual) |

While the cursor is on, W/A/S/D move the cursor, not you, like the gamepad's
UI focus mode. These keys (and Esc) are only taken over while the cursor is
on; your spell keys and Esc work normally the rest of the time. It switches off when combat starts.

- **Started with Shift+\`:** it also reaches the player, target and focus frames
  and the party and raid frames, where Space targets that unit, and your
  **buffs and debuffs**: the highlighted one shows its tooltip, and
  **Shift+Space cancels a buff** (the same right-click Blizzard's gamepad
  uses). Debuffs can't be cancelled, only inspected. Leave with Esc.
- **Started by a window opening:** it only covers windows, and switches off
  when they close.

Clicks go through a secure button bound to the key, so they count as real
key presses, and spells and items work. Moving the cursor is blocked in
combat, so it only works out of combat.

## 5. Targeting modes (works in combat)

The gamepad has a "Target Friendly" and a "Target Hostile" button. PadKeys
turns that into a mode:

- **\`** toggles between enemy mode (default) and friendly mode. Friendly
  mode shows "Friendly targeting" near the top of the screen.
- **Tab / Shift+Tab** cycle the nearest enemies, or the nearest friendly
  players and NPCs in friendly mode (Blizzard's `TARGETNEARESTFRIEND`).
- **Ctrl+Tab / Ctrl+Shift+Tab** always cycle your party or raid.

The toggle is a secure button that rebinds Tab and Shift+Tab, so it works
in combat. If the cursor or a quest window is using Tab at the same time,
the one that took Tab last wins.

## 6. Key map (F1)

Press **F1** (or `/padkeys map`) for a key map, like Blizzard's Controller
Map: action bars, movement, targeting, menus, and the keys inside the
cursor, radial, quests and aura view. It reads your live keybindings each
time it opens, with Blizzard's own key and action names, so it always shows
your real setup. Esc closes it.

## 7. Inspecting debuffs and buffs (works in combat)

| Key | Does |
|---|---|
| X | Tooltip of your next debuff |
| Alt+X (Option+X on a Mac) | Tooltip of your next buff |
| Esc | Close the tooltip view |

Each press moves to the next icon in Blizzard's debuff (or buff) row, in
the order they're shown, wrapping around, and shows its tooltip at the
icon, exactly as if you hovered it with the mouse. Tooltips aren't
restricted in combat, so this works mid-fight.

**Esc** closes the tooltip view, in combat too. X and Alt+X take over Esc
through a secure snippet (the only way to change a key in combat), and Esc
gives it back, so outside the tooltip view Esc opens the game menu as
usual. If you had no debuffs when you pressed X, the next Esc only gives
Esc back; press it again for the game menu.

## 8. Smart interact (quests)

While a quest giver's window is open, each press of **F** does the next step:

1. In the gossip list: pick a quest you can turn in, else a new quest, else
   the only chat option, else close.
2. On a quest page: **Accept** → **Continue** → **Complete**, using
   Blizzard's gamepad action.
3. If there are several rewards, the first press selects one and shows its
   tooltip. **Tab** or **Shift+F** cycles through them, and F takes the one
   shown.
4. When nothing is left, F closes the window.

Each press does exactly one step; nothing is automated.

## Launch-day checklist (Nov 4)

1. **Loads?** Enable it and `/reload`, and watch for Lua errors (`/console
   scriptErrors 1`). If it says out of date, check the interface number with
   `/dump select(4, GetBuildInfo())` and update `## Interface:` in
   `PadKeys.toc`.
2. **Layout**: `/padkeys apply`, then check Options → Keybindings. Press 1–T
   on their own and with Cmd, Shift and Ctrl. Check that Cmd+Q casts
   instead of quitting (the Mac setting in install step 5).
3. **Key map**: press F1 and check it matches what the keys do.
4. **Interact**: face a corpse or an NPC and press F.
5. **Radial**: hold Z, move the mouse, switch pages with Q/E and the wheel,
   release on a segment. Watch for Lua errors when it opens: it is
   Blizzard's gamepad frame running in keyboard mode.
6. **Cursor**: open the spellbook and bags, press Shift+\`, move with WASD,
   Tab to jump between them, Space on a spell.
   Then try the bags with Shift+Space.
7. **Debuffs in combat**: on a mob that debuffs you, press X a few times,
   then Alt+X, then Esc to close; Esc again should open the game menu.
8. **Buffs**: hold Z, left page, pick Buffs. The cursor should land on your
   buffs; check the tooltips and cancel one with Shift+Space.
9. **Quests**: talk to a quest giver with F and keep pressing F.
10. **Targeting** (in a group): Ctrl+Tab through the party, Ctrl+F back to
   the previous target, Shift+F to assist, \` then Tab for friends, \` back
   for enemies (also in combat). Press Shift+\` and move over the raid
   frames.
11. **Pings** (in a group): hold G and click a mob, then drag for the wheel.

Known risks:
- The radial is Blizzard's gamepad frame. If it errors in keyboard mode, its
  open/close steps call gamepad managers that may not be running; send the
  error and it can be fixed or worked around.
- Tooltips while the cursor moves come from calling Blizzard's own OnEnter
  handlers. If that causes "action blocked" errors, set `tooltips = false`
  under `cursor` in `Config.lua`.
- The cursor finds windows from `UIPanelWindows`, `UISpecialFrames` and a
  short list of names. A window it misses can be added to `EXTRA_ROOTS` in
  `Cursor.lua`.
- Long scroll lists aren't scrolled by the cursor yet; use the mouse wheel.

## Not included any more

Earlier versions had our own secure rings (a utility ring with Hearthstone
and macros, and a ping ring that worked in combat). They were replaced by
Blizzard's radial and ping system to avoid duplicating Blizzard's code.
Blizzard has no ring for your own spells and items, so that would need our
code again if you want it.

## Terms of service

It only uses Blizzard's public UI API. Every key press does one thing, and
nothing runs on its own, reads game memory or automates play. That's in
line with Blizzard's UI Add-On Development Policy.
