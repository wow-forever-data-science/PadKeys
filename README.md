# PadKeys (WoW addon)

Gamepad-style play on a keyboard for World of Warcraft: Forever:

1. a **key layout** with few keys and modifier layers, like a gamepad;
2. a **keyboard UI cursor** that moves through open windows, like the
   gamepad's menu cursor;
3. **radial rings**: hold a key, point with the mouse, release;

plus a **smart interact** key that walks through quest dialogs.

It is not part of the R package (`tools/` is in `.Rbuildignore`).

**Status: untested in game.** It was written before launch against
Forever's UI source (Gethe's mirror, branch `forever`, build 1.60.1 (70532):
<https://github.com/Gethe/wow-ui-source/tree/forever>). The function and
frame names were checked there, and the logic was run against a stubbed API.
Expect small fixes on launch day; see the checklist at the end.

## Install

1. Copy the `PadKeys` folder into
   `<WoW install>/<Forever client folder>/Interface/AddOns/`.
2. Enable *PadKeys* at character select (tick **Load out of date AddOns** if
   it is listed as out of date).
3. In game, type `/padkeys preview` to see which keys would change, then
   `/padkeys apply`. `/padkeys restore` puts your old keys back.
4. Turn on **Action Bar 2** and **Action Bar 3** (Options or Edit Mode). The
   Alt and Shift layers fire those bars, so their buttons must exist.

Everything is set in `Config.lua`: edit it and `/reload`.

## 1. Key layout

Eight "face buttons", each with a layer per modifier, like the eight
gamepad action buttons plus the shoulder buttons.

| Keys | Plain | Alt | Shift | Ctrl |
|---|---|---|---|---|
| 1 2 3 4 Q E R T | Action Bar 1, slots 1–8 | Action Bar 2, slots 1–8 | Action Bar 3, slots 1–8 | Pet bar, slots 1–8 |

| Key | Does |
|---|---|
| W / S | Move forward / back |
| A / D | **Strafe** (turn with the mouse or the arrow keys) |
| F | **Interact** with what you face: loot, NPCs, herbs, ore. Smart quest steps while a quest window is open (below). |
| Shift+F | Assist (cycles rewards while a quest window is open) |
| Z (hold) | Radial ring 1: Menu |
| Shift+Z (hold) | Radial ring 2: Utility |
| G (hold) | Radial ring 3: Ping your target |
| Shift+G (hold) | Blizzard's ping listener: click a spot in the world to ping it |
| \` | Toggle the keyboard UI cursor |

`/padkeys apply` also switches on soft targeting for keyboard
(`SoftTargetInteract` and `SoftTargetEnemy` set to 3), key-down casting and
auto loot.

What you lose from the defaults: Q/E strafe (now on A/D), R reply to whisper
(type `/r`), T attack (soft targeting starts attacks), Z sheathe, G target
last hostile, Shift+1–6
bar paging, and Alt as the self-cast modifier on those eight keys. The pet
bar stays on Ctrl, as in the defaults.

## 2. Keyboard UI cursor

Press \` with any window open. The cursor also starts by itself when a
gossip, quest, merchant, loot window or a popup opens.

| Key | Does |
|---|---|
| W A S D / arrows | Move between buttons |
| Space / Enter | Click (cast from the spellbook, pick a gossip line) |
| Shift+Space / E | Right-click (use or sell an item) |
| Ctrl+Space | Pick up the spell or item (then move to an action bar slot and click to place it) |
| Backspace / Q | Leave cursor mode |

While the cursor is on, W/A/S/D move the cursor, not you, like the gamepad's
UI focus mode. It switches off when the windows close or combat starts.

Clicks go through a secure button bound to the key, so they count as real
key presses, and spells and items work. Moving the cursor is blocked in
combat, so it only works out of combat.

## 3. Radial rings

Hold Z, move the mouse towards a slot, release. Releasing near the centre
cancels. This works in combat.

- **Menu** (Z): Character, Spellbook, Talents, Professions, Legacy, Quests,
  Map, Bags.
- **Utility** (Shift+Z): Hearthstone, sit, dismount, stop casting.
- **Ping** (G): Attack (top), Assist, On my way, Not a threat, Threat,
  Warning, going clockwise. Each slot runs `/ping <n>`, a secure macro
  command in Forever's UI, so it works in combat. The game picks what to
  ping: your target if you have one. To ping a spot on the ground instead,
  hold **Shift+G** (Blizzard's ping listener) and click it.

Add rings or slots in `Config.lua`. A slot can be a `spell`, an `item`, a
`macro` (macro text) or a `binding` (any key binding name).

## Smart interact (quests)

While a quest giver's window is open, each press of **F** does the next step:

1. In the gossip list: pick a quest you can turn in, else a new quest, else
   the only chat option, else close.
2. On a quest page: **Accept** → **Continue** → **Complete**.
3. If there are several rewards, the first press selects one and shows its
   tooltip. **Tab** or **Shift+F** cycles through them, and F takes the one
   shown.
4. When nothing is left, F closes the window.

Each press does exactly one step; nothing is automated. This mirrors the
gamepad's own quest action in Forever's UI code
(`QuestFrame_GeneralProgressAction`).

## Launch-day checklist (Nov 4)

1. **Loads?** Enable it and `/reload`, and watch for Lua errors (`/console
   scriptErrors 1`). If it says out of date, check the interface number with
   `/dump select(4, GetBuildInfo())` and update `## Interface:` in
   `PadKeys.toc`.
2. **Layout**: `/padkeys apply`, then check Options → Keybindings. Press 1–T
   with and without Shift/Ctrl.
3. **Interact**: face a corpse or an NPC and press F.
4. **Rings**: hold Z, point, release. Try it in combat on a training dummy.
5. **Cursor**: open the spellbook, press \`, move with WASD, Space on a spell.
   Then try the bags with Shift+Space.
6. **Quests**: talk to a quest giver with F and keep pressing F.
7. **Pings** (in a group): target a mob, hold G, point at Attack, release.
   Then hold Shift+G and click the ground. Also check what `/ping 1` does
   with no target.

Known risks:
- Tooltips while the cursor moves come from calling Blizzard's own OnEnter
  handlers. If that causes "action blocked" errors, set `tooltips = false`
  under `cursor` in `Config.lua`.
- The cursor finds windows from `UIPanelWindows`, `UISpecialFrames` and a
  short list of names. A window it misses can be added to `EXTRA_ROOTS` in
  `Cursor.lua`.
- Long scroll lists aren't scrolled by the cursor yet; use the mouse wheel.

## Terms of service

It only uses Blizzard's public UI API. Every key press does one thing, and
nothing runs on its own, reads game memory or automates play. That's in
line with Blizzard's UI Add-On Development Policy.
