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
- **NPC dialogs** as on the gamepad: the cursor lands on the first option
  and F takes it, accepts, continues or completes;
- an in-game **key map** (F1), like Blizzard's Controller Map.

It comes as five addons, so you can switch them on one at a time and an
error points at one part:

| Addon | What it adds | Needs |
|---|---|---|
| **PadKeys** | Key layout (action bars, movement, F interact, X sit, G pings, targeting keys), soft targeting, F1 key map, `/padkeys` | — |
| **PadKeys_Cursor** | UI cursor (windows, unit frames, buffs) and NPC dialogs (F = A, Esc = B) | PadKeys |
| **PadKeys_Auras** | Debuff (C) and buff (Option+C) tooltips | PadKeys |
| **PadKeys_Targeting** | Friendly/enemy toggle (\`) and party/raid cycling (Ctrl+Tab) | PadKeys |
| **PadKeys_Radial** | Blizzard's main-menu radial (hold Z) | PadKeys |

It started in the wowforevR R package repository and moved here as a
standalone addon; the history came along.

**Status: untested in game.** It was written before launch against
Forever's UI source (Gethe's mirror, branch `forever`, build 1.60.1 (70532):
<https://github.com/Gethe/wow-ui-source/tree/forever>). The function and
frame names were checked there, and the logic was run against a stubbed API.
Expect small fixes on launch day; see the checklist at the end.

## Key map

Press **F1** in game for this list, read from your live bindings (it lists
only the addons you have loaded). For a
visual version, open `keymap.html` (in this folder) in a browser: a Mac
keyboard with each layer's keys. It's also published at
<https://claude.ai/artifact/6CMswZFmZY5ys9Go17pcsa> (private to the owner).

| Key | Does | Key | Does |
|---|---|---|---|
| 1 2 3 4 Q E R T | Action Bar 1 | W / S | Forward / back |
| Cmd + those | Action Bar 2 | A / D | Strafe |
| Shift + those | Action Bar 3 | Space | Jump |
| Ctrl + those | Pet bar | F | Interact / choose in NPC dialogs |
| \` | Friendly ↔ enemy targeting | Shift+F | Assist |
| Tab / Shift+Tab | Next / previous target (in mode) | Ctrl+F | Last target |
| Ctrl+Tab / Ctrl+Shift+Tab | Next / previous group member | Cmd+F | Last hostile target |
| Z (hold) | Main-menu radial | C | Next debuff tooltip |
| G (hold) | Pings | Option+C | Next buff tooltip |
| Shift+\` | UI cursor | X | Sit / stand |
| F1 | Key map | | |

| Context | Keys |
|---|---|
| UI cursor | WASD / arrows move · Space click · Shift+Space right-click · Ctrl+Space pick up · Tab / Shift+Tab next / previous window · Esc leave |
| Radial | Q / E or mouse wheel: pages · release Z: open |
| NPC dialog | W / S move to an option or reward · F choose, accept, continue, complete · Esc close |
| Aura tooltips | C / Option+C next · Esc close |

## Install

1. Download **PadKeys.zip** from the repository's **Releases** page, release
   "PadKeys (latest)". It's rebuilt every time the addon changes on `main`.
   Unzip it into `<WoW install>/<Forever client folder>/Interface/AddOns/`,
   so you end up with `Interface/AddOns/PadKeys/PadKeys.toc` and the
   `PadKeys_*` folders next to it. If you installed an older PadKeys, delete
   its `PadKeys` folder first. (Without the release: download the
   repository as a ZIP and copy its `PadKeys` and `PadKeys_*` folders into
   `AddOns`.)
2. With the game closed, apply your `wow-settings` (`./wow.sh apply
   <flavor>`): it sets soft targeting (what makes F work), key-down
   casting, auto loot and turns on Action Bars 2 and 3. New characters need
   one more apply after their first login.
3. At character select, enable **PadKeys** (tick **Load out of date
   AddOns** if it is listed as out of date). Enable the `PadKeys_*` addons
   too, or add them one at a time (see the checklist at the end).
4. In game, type `/padkeys preview` to see which keys would change, then
   `/padkeys apply`. `/padkeys restore` puts your old keys back. **Run
   `/padkeys apply` again whenever you enable or disable a `PadKeys_*`
   addon**: it binds the keys of the loaded ones and gives back the keys of
   ones you turned off.
5. Check that **Action Bar 2** and **Action Bar 3** are on (Options or
   Edit Mode; `wow-settings` turns them on). The Cmd and Shift layers fire
   those bars, so their buttons must exist.
6. **On a Mac: turn on Options → Mac → "Disable OS shortcuts"** and allow
   WoW the macOS permission it asks for. Otherwise Cmd+Q (Action Bar 2,
   slot 5) **quits the game**, and other Cmd shortcuts go to macOS.

Commands: `/padkeys preview`, `apply`, `restore`, `cursor`, `map`,
`status` (which PadKeys addons are loaded).
Each addon has its own `Config.lua` with its keys and settings: edit it,
`/reload` and `/padkeys apply`. On Windows, set `MOD = "ALT-"` at the top
of `PadKeys/Config.lua` to use Alt instead of Cmd.

## Key layout

Eight action keys, each with a layer per modifier, like the eight gamepad
action buttons plus the shoulder buttons:

| Keys | Plain | Cmd | Shift | Ctrl |
|---|---|---|---|---|
| 1 2 3 4 Q E R T | Action Bar 1, slots 1–8 | Action Bar 2, slots 1–8 | Action Bar 3, slots 1–8 | Pet bar, slots 1–8 |

Movement is W/S, with **A/D strafing** (turn with the mouse or the arrow
keys). **F interacts** with whatever you face: loot, NPCs, herbs, ore.

F needs soft targeting on for keyboard. PadKeys sets only key bindings;
the console settings live in the `wow-settings` repository
(`settings/account/config-cache.wtf`, applied with `./wow.sh apply`):
`SoftTargetInteract` and `SoftTargetEnemy` at 3 (Blizzard's "Enable
Interact Key" and "Action Targeting" options), the other soft-targeting
settings at the values Blizzard's gamepad mode uses (F reaches 20 yards in
a cone in front of you, and an icon shows over the NPC, herb, ore or chest
it will use), key-down casting and auto loot. Without `wow-settings`, tick
Options → Controls → **Enable Interact Key** and Options → Combat →
**Action Targeting**.

What you lose from WoW's defaults:
- Q/E strafe (now A/D) and R reply to whisper (type `/r`);
- T attack (soft targeting starts attacks), Z sheathe, and C character
  window (it's on the radial, and `wow-settings` binds it to Shift+C);
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
| Esc / Backspace | Close the window the cursor is in (the gamepad's B). Where there's nothing to close (unit frames, auras, popups), leave the cursor. |

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
| C | Tooltip of your next debuff |
| Option+C | Tooltip of your next buff |
| Esc | Close the tooltip view |

Each press moves to the next icon in Blizzard's debuff (or buff) row, in
display order, wrapping around, and shows its tooltip at the icon exactly
as if you hovered it. C and Option+C take over Esc through a secure snippet
(the only way to change a key in combat), and Esc gives it back, so outside
the tooltip view Esc opens the game menu as usual. If you had no debuffs
when you pressed C, the next Esc only gives Esc back; press it again for
the game menu.

## NPC dialogs (gossip and quests)

These work as in Forever's gamepad UI, with F as the gamepad's A button.
Face an NPC and press **F** to talk. Then:

1. When the window shows a list (gossip options and quests, several
   quests, or quest rewards), the UI cursor lands on its **first entry**,
   as Blizzard's gamepad code does. Move with **W / S**.
2. **F** takes the entry under the cursor: a quest, or any option (vendor,
   trainer, innkeeper, banker, flight master, directions). Space does the
   same.
3. On a quest page **F** is Blizzard's own gamepad action: **Accept** →
   **Continue** → **Complete**. If you lack the quest items, F does nothing
   and Esc leaves.
4. With several rewards, move the cursor to one (its tooltip shows) and
   press **F** to choose it; F again completes the quest.
5. **Esc** closes the window.

Vendor, trainer, bank and similar windows are driven with the UI cursor.

## Key map (F1)

**F1** (or `/padkeys map`) opens the key map in a Blizzard-style window. It
reads your live keybindings each time it opens, with Blizzard's own key and
action names, so it always shows your real setup. Esc closes it.

## What is Blizzard's and what is ours

| Feature | Blizzard code used | Our code |
|---|---|---|
| Menu radial | `GamepadRadial` (`Blizzard_Gamepad/UI/Radials`): art, pages, segments and actions | feeding it the mouse as the "stick", page keys and release |
| Pings | the ping system (`TOGGLEPINGLISTENER`, `Blizzard_PingUI`) and its wheel | none, only the key |
| NPC dialogs | `QuestFrame_GeneralProgressAction` (accept/continue/complete) and the gamepad's rules: cursor on the first entry, A clicks it, B closes | our cursor in place of SmartNavigation |
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

Install in stages: enable one addon, `/reload`, `/padkeys apply`, test it,
then add the next. Turn on Lua errors first with `/console scriptErrors 1`.
An error names the file and its folder, so you know which addon broke;
disable that one and carry on with the rest. `/padkeys status` shows what
is loaded.

**Stage 1: PadKeys only**

1. **Loads?** If it says out of date, check the interface number with
   `/dump select(4, GetBuildInfo())` and update `## Interface:` in every
   `.toc` file.
2. **Layout**: `/padkeys apply`, then press 1–T on their own and with Cmd,
   Shift and Ctrl. Check that Cmd+Q casts instead of quitting (install
   step 6). X sits.
3. **Interact and soft targeting**: an icon should show over the NPC, herb
   or chest in front of you; press F. No icon and F does nothing: the
   `wow-settings` apply didn't take (`/dump GetCVar("SoftTargetInteract")`
   should print 3). Tab / Shift+Tab cycle enemies,
   Shift+F assists, Ctrl+F and Cmd+F go back to earlier targets.
4. **Key map**: press F1 and check it matches what the keys do.
5. **Pings** (in a group): hold G and click a mob, then drag for the wheel.

**Stage 2: + PadKeys_Cursor**

6. **Cursor**: open the spellbook and bags, press Shift+\`, move with WASD,
   Tab between the windows, Space on a spell, Shift+Space on a bag item,
   Esc to close the window.
7. **NPC dialogs**: talk to a quest giver with F and keep pressing F; pick a
   reward with S and F. Talk to an innkeeper or banker, move to an option
   with S and press F. Esc closes.

**Stage 3: + PadKeys_Auras**

8. **Aura tooltips in combat**: on a mob that debuffs you, press C a few
   times, then Option+C, then Esc; Esc again should open the game menu.

**Stage 4: + PadKeys_Targeting**

9. **Targeting** (in a group, also in combat): Ctrl+Tab through the party,
   \` then Tab for friends, \` again for enemies. With PadKeys_Cursor on,
   press Shift+\` and move over the raid frames.

**Stage 5: + PadKeys_Radial**

10. **Radial**: hold Z, move the mouse, switch pages with Q/E and the wheel,
    release on a segment. Watch for Lua errors when it opens.
11. **Buffs** (with PadKeys_Cursor on): hold Z, left page, pick Buffs. The
    cursor should land on your buffs; cancel one with Shift+Space.

Known risks:
- The radial is Blizzard's gamepad frame running in keyboard mode. If it
  errors, its open/close steps call gamepad managers that may not be
  running; send the error and it can be fixed or worked around.
- Tooltips while the cursor moves come from calling Blizzard's own OnEnter
  handlers. If that causes "action blocked" errors, set `tooltips = false`
  under `cursor` in `PadKeys_Cursor/Config.lua`.
- Tab is used by targeting and the cursor. If both take Tab at the same
  moment (e.g. toggling friendly mode while the cursor is on), the one that
  took it last wins.
- The cursor finds windows from `UIPanelWindows`, `UISpecialFrames` and a
  short list of names. A window it misses can be added to `EXTRA_ROOTS` in
  `PadKeys_Cursor/Cursor.lua`.
- Long scroll lists aren't scrolled by the cursor yet; use the mouse wheel.

## Related branch

`feat/padkeys-custom-rings` adds our own secure rings on top of this
(to become a sixth addon, PadKeys_Rings):
a Utility ring (Hearthstone, macros, your own spells and items) and a Ping
ring that pings your target in combat without clicking. Blizzard has no ring
for your own spells and items, so those need our code.

## Terms of service

It only uses Blizzard's public UI API. Every key press does one thing, and
nothing runs on its own, reads game memory or automates play. That's in
line with Blizzard's UI Add-On Development Policy.
