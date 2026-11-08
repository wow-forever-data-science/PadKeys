# PadKeys (WoW addon)

Gamepad-style play on a keyboard for World of Warcraft: Forever, set up for
a **Mac**. It uses Blizzard's own gamepad code wherever that code runs
without a gamepad, and adds its own code only where Blizzard's doesn't:

- a **key layout** with eight action keys and modifier layers, like a
  gamepad's buttons and shoulders;
- **targeting** like the gamepad: a friendly/enemy mode toggle, enemy and
  group cycling, assist and last target, all usable in combat;
- **radials** in the style of Blizzard's gamepad radial: actions, pings and
  target markers in combat, and Blizzard's main-menu entries;
- a **keyboard UI cursor** that moves through open windows, unit frames and
  your buffs;
- **aura inspection**: step through your target's nameplate auras and your own debuffs in combat, with a tooltip on hold;
- **NPC dialogs** as on the gamepad: the cursor lands on the first option
  and F takes it, accepts, continues or completes;
- an in-game **key map** (F1), like Blizzard's Controller Map;
- **one action bar** that shows the layer you hold, like a gamepad's
  skill panel, so Blizzard's bars can be hidden;
- **fading bars**: Blizzard's bars, micro menu and bags stay out of sight
  until you mouse over them or drag a spell, each labelled with its key;
- a **combat banner**: "Combat" / "Out of Combat" fades in and out in the
  middle of the screen as you enter and leave combat;
- a **buff reminder**: out of combat, the long buffs your class and group
  are missing or about to lose; it fades away as combat starts;
- one **look** for the whole game: every font in Roboto Condensed, and
  black chat windows.

It comes as several addons, so you can switch them on one at a time and an
error points at one part:

| Addon | What it adds | Needs |
|---|---|---|
| **PadKeys** | Key layout (action bars, movement, F interact, X sit, G pings, targeting keys), soft targeting, F1 key map, `/padkeys` | — |
| **PadKeys_Cursor** | UI cursor (windows, unit frames, buffs) and NPC dialogs (F = A, Esc = B) | PadKeys |
| **PadKeys_Auras** | Aura highlight: your target's nameplate auras (C), your debuffs (Ctrl+C); hold Shift+C for the tooltip | PadKeys |
| **PadKeys_Targeting** | Friendly/enemy toggle (\`) and party/raid cycling (Ctrl+Tab) | PadKeys |
| **PadKeys_Radial** | Radials: actions (G, Alt+G), pings (Cmd+G), markers (Shift+G), main menu (Ctrl+G) | PadKeys |
| **PadKeys_Bar** | One bar that shows the layer you hold (Cmd, Shift, Option, Ctrl) | PadKeys (SpellActivationOverlay optional, for its proc glows) |
| **PadKeys_Fade** | Blizzard's action bars, micro menu and bags fade out until you mouse over them or drag a spell; each bar is labelled with its PadKeys key (Cmd, Shift, G wheel) | PadKeys |
| **PadKeys_Look** | Every font in the game in the theme font (Roboto Condensed), and chat windows on a black background | PadKeys |
| **PadKeys_Combat** | "Combat" / "Out of Combat" fades in the middle of the screen as you enter and leave combat, in white; out of combat, a list of missing or expiring long buffs for your class and group | PadKeys |
| **PadKeys_Debug** | Saves Lua errors and blocked actions to a file, to send or read outside the game (`/pkdebug`) | — |

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
| Option + those | Action Bar 5 (Mac only) | F | Interact / choose in NPC dialogs |
| Ctrl + 1 2 3 4 | Pet bar, slots 1–4 | Shift+F | Assist |
| Ctrl + Q E R T | Action Bar 4, slots 1–4 | | |
| \` | Friendly ↔ enemy targeting | | |
| Tab / Shift+Tab | Next / previous target (in mode) | Ctrl+F | Last target |
| Ctrl+Tab / Ctrl+Shift+Tab | Next / previous group member | Cmd+F | Last hostile target |
| G (hold) | Action radial (Bar 6); with Cmd: pings, Shift: markers, Ctrl: main menu | C | Target's next debuff tooltip |
| Z | Sheathe / draw weapon | Cmd / Shift / Ctrl+C | Target buff / your debuff / your buff |
| Shift+\` | UI cursor | X | Sit / stand |
| F1 | Key map | B | Bags, with the UI cursor inside |

| Context | Keys |
|---|---|
| UI cursor | WASD / arrows move · F / Space click (uses a bag item) · Shift+F right-click · Ctrl+F pick up · Option+F buy a stack / create all · Tab / Shift+Tab next / previous window · Esc leave |
| Radials | point with the mouse · release G: run · Ctrl+G only: mouse wheel pages |
| NPC dialog | W / S move to an option or reward · F choose, accept, continue, complete · Esc close |
| Auras | C: target's first aura, then the next · Ctrl+C: your debuffs · hold Shift+C: tooltip |

## Install

1. Download **PadKeys.zip** from the repository's **Releases** page, release
   "PadKeys (latest)". It's rebuilt every time the addon changes on `main`,
   and every day with the newest stable **SpellActivationOverlay**, which
   comes in the zip (see below). Unzip it into
   `<WoW install>/<Forever client folder>/Interface/AddOns/`, so you end up
   with `Interface/AddOns/PadKeys/PadKeys.toc` and the `PadKeys_*` and
   `SpellActivationOverlay` folders next to it. To update, delete those
   folders and unzip the new release the same way. If you installed an
   older PadKeys, delete its `PadKeys` folder first. (Without the release: download the
   repository as a ZIP and copy its `PadKeys` and `PadKeys_*` folders into
   `AddOns`.)
2. With the game closed, apply your `wow-settings` (`./wow.sh apply
   <flavor>`): it sets soft targeting (what makes F work), key-down
   casting, auto loot and turns on Action Bars 2 to 5. New characters need
   one more apply after their first login.
3. At character select, enable **PadKeys** (tick **Load out of date
   AddOns** if it is listed as out of date). Enable the `PadKeys_*` addons
   too, or add them one at a time (see the checklist at the end).
   **SpellActivationOverlay** is optional: enable it if you want its proc
   glows and effects, or leave it off.
4. In game, type `/padkeys preview` to see which keys would change, then
   `/padkeys apply`. `/padkeys restore` puts your old keys back. **Run
   `/padkeys apply` again whenever you enable or disable a `PadKeys_*`
   addon**: it binds the keys of the loaded ones and gives back the keys of
   ones you turned off.
5. Check that **Action Bars 2, 3, 4 and 5** are on (Options or Edit Mode;
   `wow-settings` turns them on). The Cmd, Shift, Ctrl and Option layers
   fire those bars, so their buttons must exist. Only the first four
   buttons of Bar 4 have keys, so you can shrink it to 4 buttons in Edit
   Mode.
6. **On a Mac: turn on Options → Mac → "Disable OS shortcuts"** and allow
   WoW the macOS permission it asks for. Otherwise Cmd+Q (Action Bar 2,
   slot 5) **quits the game**, and other Cmd shortcuts go to macOS.

Commands: `/padkeys preview`, `apply`, `restore`, `cursor`, `map`, `bar`,
`fade`, `status` (which PadKeys addons are loaded).
Each addon has its own `Config.lua` with its keys and settings: edit it,
`/reload` and `/padkeys apply`. On Windows, set `MOD = "ALT-"` at the top
of `PadKeys/Config.lua` to use Alt instead of Cmd. Windows has no fifth
modifier, so there's no Action Bar 5 layer there.

## Look: black and white, one font

Everything PadKeys draws is black, white and grey, in one font: Roboto
Condensed ExtraBold, shipped in `PadKeys/Fonts/` with its SIL Open Font
License. That covers the bar, the fade labels, the radial wheels (Blizzard's
art in grey), the UI cursor's arrow and glow, the key map window, the
friendly-targeting label, the combat banner and PadKeys' messages. Grey
means dimmed: out of range, not usable, a bar's name next to its key.

Set the font once in the `theme` block at the end of `PadKeys/Config.lua`
(WoW's own fonts work too, e.g. `Fonts\\FRIZQT__.TTF`). Spell, item and menu
icons keep their colours so you can tell them apart; `grey_icons = true`
there shows them in grey too. Blizzard's own windows and tooltips (the
aura tooltips included) keep Blizzard's look.

## Key layout

Eight action keys, each with a layer per modifier, like the eight gamepad
action buttons plus the shoulder buttons:

| Keys | Plain | Cmd | Shift | Option | Ctrl |
|---|---|---|---|---|---|
| 1 2 3 4 | Action Bar 1, slots 1–4 | Action Bar 2, slots 1–4 | Action Bar 3, slots 1–4 | Action Bar 5, slots 1–4 | Pet bar, slots 1–4 |
| Q E R T | Action Bar 1, slots 5–8 | Action Bar 2, slots 5–8 | Action Bar 3, slots 5–8 | Action Bar 5, slots 5–8 | Action Bar 4, slots 1–4 |

That's 36 slots for your own spells and items, and the pet on four fixed
keys for every class. Pet bar buttons can be dragged around: put Attack,
Follow and the pet abilities you press in slots 1–4, and leave Stay, the
stance buttons and autocast abilities in slots 5–10 to click. (A priest's
Mind Control also puts the controlled mob's spells on the pet bar.)

**Option** is a fifth modifier that only a Mac has (WoW can't bind the
Windows key, and Windows uses Alt where the Mac uses Cmd). It suits rank 1
spells: put a buff on 1 and its rank 1 on Option+1, the same spot with one
more key held.

Movement is W/S, with **A/D strafing** (turn with the mouse or the arrow
keys). **F interacts** with whatever you face: loot, NPCs, herbs, ore.

The keys bound to Blizzard's own actions are in both places: PadKeys binds
them, and `wow-settings` binds them too
(`settings/account/bindings-cache.wtf`), so they work even with PadKeys
disabled. That's the plain, Shift, Option and Ctrl layers, F, Shift+F, Ctrl+F,
Cmd+F, Tab / Shift+Tab, A/D, X and G. Only PadKeys binds the Cmd layer
(Cmd+Q quits the game until install step 6 is done), F2–F5 and the keys
for PadKeys' own actions.

F needs soft targeting on for keyboard. PadKeys sets only key bindings;
the console settings live in the `wow-settings` repository
(`settings/account/config-cache.wtf`, applied with `./wow.sh apply`):
`SoftTargetInteract` and `SoftTargetEnemy` at 3 (Blizzard's "Enable
Interact Key" and "Action Targeting" options). `SoftTargetEnemy` and
`SoftTargetEnemyArc` are per character, so they sit in
`settings/characters/_default/config-cache.wtf`; a new character needs one
more apply after its first login. `SoftTargetWithLocked` is 0, so a
locked target stays until Tab, even with other mobs in front of you. The other soft-targeting
settings at the values Blizzard's gamepad mode uses (F reaches 20 yards in
a cone in front of you, and an icon shows over the NPC, herb, ore or chest
it will use), key-down casting and auto loot. Without `wow-settings`, tick
Options → Controls → **Enable Interact Key** and Options → Combat →
**Action Targeting**.

What you lose from WoW's defaults:
- Q/E strafe (now A/D) and R reply to whisper (type `/r`);
- T attack (soft targeting starts attacks), Z sheathe, and C character
  window (it's on the Ctrl+G menu radial; PadKeys_Auras takes Shift+C,
  where `wow-settings` binds it);
- G target last hostile (now Cmd+F) and Ctrl+Tab nearest friend (now
  friendly mode);
- F1–F5 targeting yourself and party members (F1 is now the key map);
- Shift+1–4 jumping to bar pages 1–4 (Shift+5/6, Shift+mouse wheel and
  the page arrows still page the main bar).

The pet bar stays on Ctrl, as in the defaults. Option takes the place of
WoW's "hold Alt to self-cast" key, so the self-cast key must be off:
`wow-settings` turns it off, and without it set Options → Combat → **Self
Cast Key** to None. Otherwise friendly spells on Bar 5 always land on you.
Cmd is `META` and Option is `ALT` in WoW's key names.

## One bar for every layer (PadKeys_Bar)

A single row of eight slightly rounded buttons on a dark background, with
white key labels in the PadKeys font (see [Look](#look-black-and-white-one-font)), that shows what
1 2 3 4 Q E R T
do **with the modifiers you hold right now**: Bar 1 with none, Bar 2 while
you hold Cmd, Bar 3 with Shift, Bar 5 with Option, and the pet bar plus
Bar 4 with Ctrl. Like a gamepad's skill panel, the bar changes the moment
you press or let go of a modifier, in combat too. The layer name ("Cmd")
shows above it while a modifier is held.

Each button shows the icon, charges or item count, macro name, a dim icon
when the spell can't be used now (a little less dim: not enough mana), a
grey border while the action is active (casting, auto attack, a pet
stance) and a white border while its key is down. Cooldown and range
show on the icon itself, and the key label stays white:

- **On cooldown** the icon turns see-through with the seconds left in
  the middle. There's no swipe, and the global cooldown alone shows
  nothing. A spell recharging with charges left shows its recharge time
  but stays solid; pet cooldowns show the time but don't fade.
- **Out of range** the icon turns grey and a little see-through.

How see-through, and the countdown's size, are in `PadKeys_Bar/Config.lua`. Stance and form paging of Bar 1 carries over.

**Proc glow:** when a Blizzard button lights up, the bar's button for that
key lights up too, on whichever layer you hold. That covers
**SpellActivationOverlay** and other addons that glow buttons with
LibButtonGlow, including its custom events, and Blizzard's own proc alerts.
Those addons keep lighting up Blizzard's buttons while their bars are
hidden; the bar copies the glow as a pulsing white ring. Turn it off with `glow = false` in
`PadKeys_Bar/Config.lua`. Pet buttons don't glow.

SpellActivationOverlay is **optional**: PadKeys_Bar works without it, and
Blizzard's own proc alerts still glow. It comes in `PadKeys.zip` for
convenience: the release is rebuilt daily with its newest stable version
(not alphas or betas), so reinstalling PadKeys also updates it. Enable or
disable it at character select. It is ennvina's addon
(<https://github.com/ennvina/spellactivationoverlay>, MIT licence, the
licence file is in its folder), set up in its own options
(`/sao`); bugs in it go to that project. The release notes name the
version included.

It reads your live key bindings, so it follows whatever you bind, and it
only **shows** the actions: your keys still press Blizzard's buttons. That
lets you hide Blizzard's bars:

1. Enable PadKeys_Bar, `/reload`.
2. Open **Edit Mode** and set **Bar Visible: Hidden** on every action bar
   and the pet bar. The keys keep working: Blizzard's key handlers press
   hidden buttons just the same.
   With PadKeys_Fade, set them to **Always** instead: they fade out and
   come back when you point at them (see Fading bars).
3. To put a spell on a bar, drag it out of the spellbook: Blizzard shows
   the hidden bars while you drag. Drop it on the bar and slot the key
   should fire (for example Bar 2, slot 5 for Cmd+Q).
4. Log out and `./wow.sh snapshot <flavor>` in `wow-settings`, so every
   character gets the same Edit Mode layout.

`/padkeys bar` unlocks the bar so you can drag it; `/padkeys bar` again
locks it, and the spot is saved. `/padkeys bar reset` goes back to the
position in `PadKeys_Bar/Config.lua`, which also has the button size and
height (70% of the width by default, for a flatter bar), text sizes,
spacing, scale, and switches for the layer name and macro names.

You can't click it with the mouse: it is a display, so it can't be blocked
in combat. Its tooltips and right-click menus are on Blizzard's bars.

## Fading bars (PadKeys_Fade)

Edit Mode can hide most action bars, but not Action Bar 1, the micro menu
or the bags, and a hidden bar doesn't come back when you point at it.
PadKeys_Fade keeps Blizzard's frames and makes them invisible instead:

- **Hover** any action bar and all of them fade in, each with a label
  above its top left corner: the bar and the PadKeys key that fires it, read from your live
  bindings: `Bar 1 No modifier`, `Bar 2 Cmd`, `Bar 3 Shift`, `Bar 5
  Option`, `Bar 4 Ctrl · slots 1–4`, `Pet bar Ctrl · slots 1–4`, `Bar 6 G
  wheel` (with PadKeys_Radial).
- **Drag** a spell, item or macro and the action bars fade in until you
  drop it.
- The **micro menu and bags** are their own group: hover them to see them.
  The experience and reputation bars don't fade: they always show.
- **Edit Mode** shows everything, labels included.

Set up:

1. Enable PadKeys_Fade, `/reload`.
2. In **Edit Mode**, set **Bar Visible: Always** on every bar you want to
   reach by mouse (a bar set to Hidden stays hidden), and stack them at the
   bottom of the screen. Leave about 18 pixels between stacked bars for
   the labels above them.
3. `/padkeys fade` keeps them shown while you arrange things; again to fade.

It only changes the frames' alpha, so it works in combat and the keys
press the buttons as before. Invisible buttons still take clicks where
they sit, which is why the bottom of the screen is the place for them.
Groups, timings, the faded alpha (0 is invisible) and the labels are in
`PadKeys_Fade/Config.lua`.

## Look (PadKeys_Look)

Every font object in the game takes the theme font (Roboto Condensed
ExtraBold, `ns.config.theme.font` in `PadKeys/Config.lua`), keeping
Blizzard's sizes and outlines. Names and damage numbers above heads change
after a relog. Chat windows get a black background through Blizzard's own
chat window settings, so they still fade with the mouse as before.
`game_font` and `chat_alpha` are in `PadKeys_Look/Config.lua`.

## Combat banner (PadKeys_Combat)

As you enter combat, **Combat** fades in above the middle of the screen in
white and fades out a second later; as you leave it, **Out of Combat** does
the same, in the PadKeys font.
Texts, size, position and timings are in
`PadKeys_Combat/Config.lua`; `banner = false` turns it off.

It only sets a text's alpha, so it works in combat. Later this addon is
meant to show boss timers or, in PvP, enemy cooldowns.

### Buff reminder

Long buffs matter before a pull, not during it. Out of combat, a short list
just below the middle of the screen (under your character; the combat
banner is above) shows the long buffs that are **missing** or
have **under 5 minutes** left; when nothing is, it isn't there. As you enter
combat it fades out as fast as the banner does (`fade_out`), and it fades
back in as you leave combat (`fade_in`).

What it lists depends on your class and who is in your party or raid:

- **Group buffs** — Power Word: Fortitude, Mark of the Wild, Arcane
  Intellect (only for classes with mana) and paladin blessings — once
  someone who casts them is in the group. Blessings count one per paladin
  ("Blessings 1/2"). Divine Spirit only if you know it.
- **If you cast one yourself**, it lists every member missing it, by name
  ("Power Word: Fortitude missing: you, Bob, Cid +2"), or the lowest time
  left. Members who are offline, dead or out of sight are skipped. For
  blessings it counts only yours.
- **Your own buffs**: mage armor, warlock armor, Inner Fire, Omen of
  Clarity, Trueshot Aura, and poisons on a rogue's weapons, once you know
  the spell.

In combat, the reminder turns on Blizzard's buff consolidation
(`consolidateBuffs`): buffs with no duration or a long one fold into one
icon, so the buff frame shows the short ones (procs, cooldowns, debuffs are
untouched). Your own setting comes back as you leave combat. The target
frame's and nameplates' auras are Blizzard's protected frames, so they keep
Blizzard's own filters; inspect them with PadKeys_Auras (C).

Settings are under `ns.config.combat.buffs` in `PadKeys_Combat/Config.lua`:
the 5-minute limit (`warn_at`), position (`anchor = "PlayerFrame"` puts it
under the player frame instead), size, `ignore` to drop a buff,
`hide_resting`, `consolidate_in_combat = false` to leave the buff frame
alone, and `enabled = false` to turn the reminder off.

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

## Radials (PadKeys_Radial)

Hold **G** (with or without a modifier), point with the mouse, release G.
The wheel opens centred on the mouse, the direction picks a segment as soon
as the mouse leaves a small dead zone (8 px, so a flick is enough), and its
name shows below the wheel. The wheel is Blizzard's gamepad radial art at
about a third of its size. The modifier you press with G picks the radial:

| Key | Radial | In combat |
|---|---|---|
| G | Action Bar 6, slots 1-8: drag spells, items and macros there | yes |
| Alt+G | Action Bar 7, slots 1-8, the same way | yes |
| Cmd+G | Pings: attack (top), assist (right), warning (left), on my way (bottom) | yes |
| Shift+G | Target markers on your target, skull at the top | yes |
| Ctrl+G | Blizzard's main-menu entries, three pages | yes |

- **Action Bar 6** is Blizzard's bar 6; it can stay hidden in Edit Mode.
  The radial shows icons and names only, not cooldowns or usability yet.
- All four are one **secure button**: on release, a secure snippet
  turns the mouse direction into a segment and fires its action, so
  spells, macros and windows work in combat and nothing is tainted. The
  modifier only matters on press.
- Hold-G for Blizzard's ping system is gone; without PadKeys_Radial, G
  is Blizzard's ping system again. **Z** is sheathe / draw again.

### Main menu (Ctrl+G)

Three pages, centre page first:

- **Left:** Group Finder, Legacy, Shop, Guild, Buffs, Collections.
- **Centre:** Bags, Professions, Character, Talents, Map, Menu, Spellbook.
- **Right:** Clock, Calendar, PvP.

Switch pages with the **mouse wheel** (up: left, down: right) while it is open, in
combat too (the secure snippet binds the wheel until release). Release Ctrl+G
with nothing highlighted to close.

The labels, icons and enabled state come from Blizzard's gamepad radial
(`GamepadRadial`'s handlers). Each entry opens by `/click`ing Blizzard's
own button (`CharacterMicroButton` and so on), not by calling those
handlers: from addon code their windows open tainted, and tainted Blizzard
code errors on the client's secret values. Social, Chat and Tracking have
no button to click, so they are left out. Size, position, dead zone, the
pages, the pings and the marker order are in `PadKeys_Radial/Config.lua`.

**Buffs** opens the UI cursor on your buffs (or debuffs, if you have no
buffs) when PadKeys_Cursor is on.

## Pings (Blizzard's)

Hold **G**: Blizzard's ping system. Click a unit or a spot to send a
contextual ping, or drag for Blizzard's ping wheel.

## UI cursor (out of combat)

Press **Shift+\`**. The cursor also starts by itself when a gossip, quest,
merchant, loot or professions window or a popup opens, and moves there if
it is already on. Where it lands depends on the window:

- vendor: the first item;
- trainer: the next skill you can learn;
- professions: the first profession tab on the right, to pick one with
  W/S and F; the cursor then moves to its first recipe;
- popup: its text field or accept button.

On a recipe, the first F selects it and the second crafts it (the amount
in Blizzard's box); F on Create / Create All runs them. **Option+F** does
the most at once: on a selected recipe it creates all (on another recipe
the first press selects it), on a vendor
item it buys a full stack (or as many as you can afford). **B** opens your bags with the
cursor on sort bags (in combat it only opens them; press B again to
close). It clicks Blizzard's backpack button through a secure button, so
the bags aren't tainted.

| Key | Does |
|---|---|
| W A S D / arrows | Move between buttons |
| F / Space | Click: cast from the spellbook, pick a gossip line, use a bag item (eat, drink, equip, sell to an open vendor); on a text field (search box), type in it, and Escape or Enter goes back to moving |
| Shift+F | Right-click: use or sell an item, cancel a buff (takes over Assist while the cursor is on) |
| Ctrl+F | Pick up a spell or item; move to an action bar slot or bag slot and click to place it (takes over Last target while the cursor is on) |
| Option+F | Most at once: create all of a recipe, buy a full stack of a vendor item (or what you can afford), buy back on the Buyback tab |
| Tab / Shift+Tab | Jump to the next / previous open window (the gamepad's "Next Frame") |
| Esc / Backspace | Close the window the cursor is in (the gamepad's B). Where there's nothing to close (unit frames, auras, popups), leave the cursor. |

While the cursor is on, these keys drive it instead of moving you, like the
gamepad's UI focus mode. They're only taken over while it's on.

- **Started with Shift+\`:** it also reaches the player, target, focus,
  party and raid frames (Space targets that unit) and your **buffs and
  debuffs** (the highlighted one shows its tooltip; Shift+F cancels a
  buff, the same right-click Blizzard's gamepad uses).
- **Started by a window opening:** it only covers windows, and switches off
  when they close.

Clicks go through a secure button bound to the key, so they count as real
key presses, and spells and items work. Moving the cursor is blocked in
combat, so it switches off when combat starts.

## Auras (works in combat)

| Key | Does |
|---|---|
| C | Highlight your target's first aura and show its tooltip, then the next with each press: debuffs first, then buffs, wrapping around |
| Ctrl+C | The same for your own debuffs |
| Shift+C (hold) | Keep the highlighted aura's tooltip up |

A label names the highlighted aura and its place ("Debuff 2/5"): above
your target's nameplate (under the target frame without one), or under
your debuff's icon, which also gets a white frame. The highlight stays 4 s
after the last press (with its tooltip; `tooltip_on_step = false` shows
the tooltip only on Shift+C) and the tooltip 2 s after you let go of
Shift+C; then
they fade over 1 s. A press after that starts at the first aura again.
Timings are in `PadKeys_Auras/Config.lua`.

The auras are your target's: all its debuffs, then the buffs Blizzard
flags as important on an enemy. Keys bound by an older version do nothing;
PadKeys says so at login, and `/padkeys apply` fixes it. The
nameplate picks its auras from fields addons can't read in combat, so
PadKeys uses the Blizzard aura filters that come closest; they're in
`PadKeys_Auras/Config.lua`. In combat the client hides auras from addons,
so PadKeys fills a hidden tooltip of its own to find them. Where the client
keeps the name secret the label shows only the place. Your own buffs have
no key.

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
When a vendor opens, gear is repaired from your own money and junk (grey
items) is sold, as Blizzard's "Sell All Junk" does; `autoRepair` and
`autoSellJunk` in `PadKeys_Cursor/Config.lua` turn them off.

## Key map (F1)

**F1** (or `/padkeys map`) opens the key map in a Blizzard-style window. It
reads your live keybindings each time it opens, with Blizzard's own key and
action names, so it always shows your real setup. Esc closes it.

## Errors (PadKeys_Debug)

Enable **PadKeys_Debug** to keep every Lua error and "action blocked"
message, with its stack, in
`WTF/Account/<account>/SavedVariables/PadKeys_Debug.lua`.

- The game writes the file on `/reload` and logout, so `/reload` after an
  error and the file has it.
- Each login or `/reload` starts a new session; the file holds only the last one.
- Repeats count up instead of adding entries; at most 100 entries.
- `/pkdebug` shows the count, `/pkdebug clear` empties it.
- Blizzard's own error popup still works.

## What is Blizzard's and what is ours

| Feature | Blizzard code used | Our code |
|---|---|---|
| Radials | `GamepadRadial` (`Blizzard_Gamepad/UI/Radials`): art (atlases), menu labels and icons; the micro buttons (clicked); the secure action button; `/ping`, `/tm` | the wheel, pages, mouse direction and paging (secure snippet), release |
| Pings | the ping system (`TOGGLEPINGLISTENER`, `Blizzard_PingUI`) and its wheel | none, only the key |
| NPC dialogs | `QuestFrame_GeneralProgressAction` (accept/continue/complete) and the gamepad's rules: cursor on the first entry, A clicks it, B closes | our cursor in place of SmartNavigation |
| Key layout | Blizzard's binding actions | apply/restore of the bindings |
| Targeting modes | Blizzard's friendly/enemy targeting bindings | a secure toggle that swaps them on Tab |
| Target auras | Blizzard's aura tooltip (`GameTooltip:SetUnitAura`) and aura filters | the highlight label and which aura is next |
| Buff cancelling | the aura icons' right-click (as `BuffFrameMixin:CancelSelectedBuff`) | reaching the icons with the cursor |
| Key map | `ButtonFrameTemplate` window, `GetBindingText` key names, `BINDING_NAME_*` action names | the list of sections |
| Group cycling | none: Blizzard's party/raid targeting only runs in gamepad mode | a secure button |
| UI cursor | none: Blizzard's SmartNavigation only runs in gamepad mode | our own cursor |
| One bar | the action API (`C_ActionBar`), the buttons' own `action`, pressed state and proc glow (LibButtonGlow, `ActionButtonSpellAlertManager`), Edit Mode's "Hidden" bars | choosing which button each key presses with the held modifiers, and drawing it |

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
   Shift, Option and Ctrl (Ctrl+1–4 is the pet bar, Ctrl+Q–T Bar 4). Check that Cmd+Q casts instead of quitting (install
   step 6). X sits.
3. **Interact and soft targeting**: an icon should show over the NPC, herb
   or chest in front of you; press F. No icon and F does nothing: the
   `wow-settings` apply didn't take (`/dump GetCVar("SoftTargetInteract")`
   should print 3). Facing a mob in range should soft-target it, so F or
   an ability attacks it; if not, `/dump GetCVar("SoftTargetEnemy")` on that character
   should print 3. Tab / Shift+Tab cycle enemies,
   Shift+F assists, Ctrl+F and Cmd+F go back to earlier targets.
4. **Key map**: press F1 and check it matches what the keys do.
5. **Pings** (in a group): hold G and click a mob, then drag for the wheel.

**Stage 2: + PadKeys_Cursor**

6. **Cursor**: open the spellbook and bags, press Shift+\`, move with WASD,
   Tab between the windows, Space on a spell, Shift+F on a bag item,
   Esc to close the window.
7. **NPC dialogs**: talk to a quest giver with F and keep pressing F; pick a
   reward with S and F. Talk to an innkeeper or banker, move to an option
   with S and press F. Esc closes.

**Stage 3: + PadKeys_Auras**

8. **Auras in combat**: put a debuff on a mob and press C. The label above
   its nameplate should name it ("Debuff 1/1"); C again steps on, Shift+C
   held shows the tooltip, which stays 2 s after you let go and then
   fades. On a mob that debuffs you, Ctrl+C should frame your debuff's
   icon. Check that the label follows the nameplate and that the name
   shows in combat.

**Stage 4: + PadKeys_Targeting**

9. **Targeting** (in a group, also in combat): Ctrl+Tab through the party,
   \` then Tab for friends, \` again for enemies. With PadKeys_Cursor on,
   press Shift+\` and move over the raid frames.

**Stage 5: + PadKeys_Radial**

10. **Menu radial**: hold Ctrl+G, move the mouse, switch pages with Q/E and
    the wheel, release on a segment, also in combat. Watch for Lua errors
    when the window opens.
11. **Buffs** (with PadKeys_Cursor on): hold Ctrl+G, left page, pick Buffs.
    The cursor should land on your buffs; cancel one with Shift+F.
12. **Combat ring**: put a spell on Action Bar 6 slot 3, hold G, point up,
    release: it should cast, also in combat. Then Cmd+G up (attack ping)
    and Shift+G up (skull on your target). The highlight must match what
    fires; if not, send the debug file.

**Stage 6: + PadKeys_Bar**

13. **Bar**: hold Cmd, Shift, Option and Ctrl in turn; the bar should show
    Bars 2, 3 and 5, then the pet bar and Bar 4. Cast something with a
    cooldown on each layer and watch the swipe. `/padkeys bar` and drag it.
14. **Hidden bars**: hide all of Blizzard's bars in Edit Mode, then press
    keys on every layer: they should still cast. Drag a spell from the
    spellbook: the hidden bars should appear until you drop it.
15. **Proc glow** (optional, only if you installed SpellActivationOverlay;
    skip it otherwise): trigger a proc it tracks
    for a spell on Bar 2, hold Cmd: that button should glow on the bar.

**Stage 7: + PadKeys_Combat**

16. **Banner**: pull a mob; "Combat" fades in and out, then "Out of
    Combat" as it dies.
17. **Buff reminder**: out of combat with a buff missing (cancel one, or
    join a group with a priest, druid or mage), the list should name it.
    Pull a mob: the list fades out with the banner, and the buff frame
    folds its long buffs into one icon; after the fight both come back.
    In a group where you cast a buff, the list should name who lacks it.

**Stage 8: + PadKeys_Look**

18. **Fonts**: windows, chat, tooltips and quest text should all be in
    Roboto Condensed; names and damage numbers above heads after a relog.
19. **Chat**: every chat window, and a new whisper tab, on a black
    background.
20. **Menu cursor** (PadKeys_Cursor): open a profession; the cursor should
    sit on the first tab on the right, and F should open it and move to
    its first recipe. Option+F on a recipe selects it, a second press
    creates all; Option+F on a
    vendor's reagent buys a stack.

Known risks:
- The buff reminder reads auras by name out of combat. If a list stays
  empty with a buff missing, `/dump C_UnitAuras.GetAuraDataByIndex("player", 1)`
  and send what you see. If turning on consolidation in combat causes
  errors, set `consolidate_in_combat = false`.
- SpellActivationOverlay only lights up buttons that are shown. Edit Mode
  hides the bar, not its buttons, so it should still light them up; if
  procs never glow with the bars hidden, set the bars to "Always" to
  check, and send what you see.
- PadKeys_Bar checks range from Blizzard's range events. If the key label
  never turns grey out of range, the hidden bars may have stopped range
  checks; send what you see.
- The radial reads its entries from Blizzard's `GamepadRadial` frame. If
  Blizzard changes that table, or an entry's action only works in gamepad
  mode (like Buffs, which PadKeys hooks), send what you see.
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

PadKeys.zip also carries SpellActivationOverlay unchanged, under its MIT
licence; the rest of this section is about PadKeys.

It only uses Blizzard's public UI API. Every key press does one thing, and
nothing runs on its own, reads game memory or automates play. That's in
line with Blizzard's UI Add-On Development Policy.
