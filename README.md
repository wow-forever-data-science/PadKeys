# PadKeys (WoW addon)

Gamepad-style play on a keyboard for World of Warcraft: Forever, set up for
a **Mac**. It uses Blizzard's own gamepad code wherever that code runs
without a gamepad, and adds its own code only where Blizzard's doesn't:

- a **key layout** with eight action keys and modifier layers, like a
  gamepad's buttons and shoulders;
- **targeting**: enemy and group cycling, assist and last target, and an
  ally mode for F, all usable in combat;
- **radials** in the style of Blizzard's gamepad radial: actions and
  target markers in combat, and Blizzard's main-menu entries;
- a **keyboard UI cursor** that moves through open windows, unit frames and
  your buffs;
- **aura inspection**: step through your target's nameplate auras and your own debuffs in combat, with a tooltip on hold;
- **NPC dialogs** as on the gamepad: the cursor lands on the first option
  and F takes it, accepts, continues or completes;
- an in-game **key map** (F1), like Blizzard's Controller Map;
- **one action bar** that shows the layer you hold, like a gamepad's
  skill panel, so Blizzard's bars can be hidden;
- **fading bars and frames**: Blizzard's bars, micro menu, bags, unit
  frames, experience bar and quest tracker stay out of sight until you
  need them: on mouseover, while you drag a spell, in combat, with a
  target, while you regenerate, or for a moment as something changes;
- a **combat banner**: "Combat" / "Out of Combat" fades in and out in the
  middle of the screen as you enter and leave combat;
- a **buff bar**: out of combat, an icon for each long buff your class
  and group are missing or about to lose, consumables you haven't used
  and supplies running low; click one to fix it; combat hides it;
- one **look** for the whole game: every font in Roboto Condensed, and
  black chat windows.

It comes as several addons, so you can switch them on one at a time and an
error points at one part:

| Addon | What it adds | Needs |
|---|---|---|
| **PadKeys** | Key layout (action bars, movement, F interact, X sit, targeting keys), soft targeting, F1 key map, `/padkeys` | — |
| **PadKeys_Cursor** | UI cursor (windows, unit frames, buffs) and NPC dialogs (F = A, Esc = B) | PadKeys |
| **PadKeys_Auras** | Aura highlight: your target's nameplate auras (C), your debuffs (Ctrl+C); hold Shift+C for the tooltip | PadKeys |
| **PadKeys_Targeting** | Party/raid cycling (Ctrl+Tab), F that attacks in combat, and ally mode (\`) where F targets the ally you face, or in a raid picks a raid frame with the mouse | PadKeys |
| **PadKeys_Radial** | Radials: actions with consumables on an outer ring (G, by combat), Bar 8 (Cmd+G), markers (Shift+G), main menu (Ctrl+G) | PadKeys |
| **PadKeys_Bar** | One bar that shows the layer you hold (Cmd, Shift, Option, Ctrl) | PadKeys (SpellActivationOverlay optional, for its proc glows) |
| **PadKeys_Fade** | Blizzard's action bars, micro menu, bags, player, pet and party frames, experience and reputation bars, quest tracker and chat fade out until you need them (mouseover, a dragged spell, combat, a target, regenerating, talent points, loot, experience gained; chat fades in combat but comes back for whispers, group and raid chat and boss text); each bar is labelled with its PadKeys key (Cmd, Shift, G wheel) | PadKeys |
| **PadKeys_Look** | Every font in the game in the theme font (Roboto Condensed), and chat windows on a black background | PadKeys |
| **PadKeys_Combat** | "Combat" / "Out of Combat" fades in the middle of the screen as you enter and leave combat, in white; out of combat, a list of missing or expiring long buffs for your class and group | PadKeys |
| **PadKeys_CombatText** | Small combat text: your hits scroll beside the target's nameplate with the spell's icon; the hits you take show lower right of the mouse, fading in as your health drops (earlier as a tank) and fully on heavy damage | PadKeys |
| **PadKeys_Ready** | A spell flashes above the mouse as it becomes ready: reactive abilities (Overpower, Revenge, Execute, Riposte, ...) as they light up, and long cooldowns (30 s or more) as they come back, in combat | PadKeys |
| **PadKeys_Readout** | Beside the mouse: a ring that fills with your cast (blue, green for heals, or glowing yellow while a listed buff outlasts it) and the global cooldown, a swing timer ring around it, your big cooldowns that are ready, your debuffs, your totems, and boss abilities from Blizzard's encounter timeline as they come close | PadKeys |
| **PadKeys_NotReady** | Pressing a key or using an item that is still on cooldown flashes its icon and the time left in the middle of the screen, fading out over a second | PadKeys |
| **PadKeys_Cooldowns** | Blizzard's Cooldown Manager (cooldowns, buff icons, buff bars) in the PadKeys look: black borders, grey tints, the countdown without a swipe | PadKeys |
| **PadKeys_Totems** | Blizzard's totem bar in the PadKeys look: black borders, no gold or element frames | PadKeys |
| **PadKeys_Combo** | Combo points as a row of black and white pips above the bar, in place of Blizzard's (rogues, druids in Cat Form) | PadKeys |
| **PadKeys_Portrait** | Your stance, form, aspect or aura in place of your portrait (else your class icon) | PadKeys |
| **PadKeys_Tracking** | What you are tracking (Find Herbs, Track Beasts, ...) as a round badge on the minimap | PadKeys |
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
| \` | Ally mode (F targets allies, Cmd+F inspects) | | |
| Tab / Shift+Tab | Next / previous enemy | Ctrl+F | Last target |
| Ctrl+Tab / Ctrl+Shift+Tab | Next / previous group member | Cmd+F | Last hostile target |
| G (hold) | Action radial: Bar 6 in combat or with an enemy targeted, town errands while resting, Bar 7 otherwise, consumables on the outer ring; with Cmd: Bar 8, Shift: target markers, Ctrl: main menu | C | Target's next debuff tooltip |
| Z | Sheathe / draw weapon | Cmd / Shift / Ctrl+C | Target buff / your debuff / your buff |
| Shift+\` | UI cursor | X | Sit / stand |
| F1 | Key map | B | Bags, with the UI cursor inside |
| Side mouse button (hold) | Blizzard's ping key: click a unit, a spot or a bar slot | | |

| Context | Keys |
|---|---|
| UI cursor | WASD / arrows move · F / Space click (uses a bag item) · Shift+F right-click · Ctrl+F pick up · Cmd+F buy a stack / create all / open all mail / apply talents or Legacy tree / create auction · Tab / Shift+Tab next / previous window · Esc leave |
| Radials | point with the mouse (further out for G's consumables) · release G: run · Ctrl+G only: mouse wheel pages |
| NPC dialog | W / S move to an option or reward · F choose, accept, continue, complete · Esc close |
| Auras | C: target's first aura, then the next · Ctrl+C: your debuffs · hold Shift+C: tooltip |
| Faded frames | hold `\`: show them all |

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
   `/padkeys apply`. `/padkeys restore` puts your old keys back. After the
   first apply, every login applies the layout again if a key drifted (an
   enabled or disabled `PadKeys_*` addon, a changed `Config.lua`, or a
   `wow-settings` apply of older bindings), so `Config.lua` stays the
   source of truth. After `/padkeys restore` this stops until the next
   apply.
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
ally mode label, the combat banner and PadKeys' messages. Grey
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

PadKeys alone binds its keys, from `Config.lua`, and binds them again at
login if anything changed one. `wow-settings` leaves them out of its
snapshot and apply (it reads them from `PadKeysDB.keys`), so the two never
undo each other. With PadKeys disabled these keys go back to the client
defaults. Cmd+Q quits the game until install step 6 is done.

F needs soft targeting on for keyboard. PadKeys sets only key bindings;
the console settings live in the `wow-settings` repository
(`settings/account/config-cache.wtf`, applied with `./wow.sh apply`):
`SoftTargetInteract` and `SoftTargetEnemy` at 3 (Blizzard's "Enable
Interact Key" and "Action Targeting" options). `SoftTargetEnemy` and
`SoftTargetEnemyArc` are per character, so they sit in
`settings/characters/_default/config-cache.wtf`; a new character needs one
more apply after its first login. `SoftTargetWithLocked` is 0, so a
locked target stays until Tab, even with other mobs in front of you. The
client does not save it, so `wow-settings`' own addon sets it at every login. The other soft-targeting
settings at the values Blizzard's gamepad mode uses (F reaches 20 yards in
a cone in front of you, and an icon shows over the NPC, herb, ore or chest
it will use), key-down casting and auto loot. Without `wow-settings`, tick
Options → Controls → **Enable Interact Key** and Options → Combat →
**Action Targeting**.

Allies get soft targeted like enemies, in a cone in front of you, once
`wow-settings` has `SoftTargetFriend` 3, `SoftTargetFriendArc` 1,
`SoftTargetFriendRange` 40, `SoftTargetIconFriend` 1 and `autoSelfCast` 1.
A helpful spell then goes to your target if it is an ally, else the ally
you face, else you. With PadKeys_Targeting in ally mode (\`), F on an ally
you face (and no NPC or corpse to use) makes them your target. With an
ally targeted, each F moves on to the next ally in front of you, while an
enemy target stays until you change it.

What you lose from WoW's defaults:
- Q/E strafe (now A/D) and R reply to whisper (type `/r`);
- T attack (soft targeting starts attacks), Z sheathe, and C character
  window (it's on the Ctrl+G menu radial; PadKeys_Auras takes Shift+C);
- G target last hostile (now Cmd+F) and Ctrl+Tab nearest friend (F in
  ally mode targets the ally you face);
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
  to its right (its left at the right edge of the screen): the bar and the PadKeys key that fires it, read from your live
  bindings: `Bar 1 No modifier`, `Bar 2 Cmd`, `Bar 3 Shift`, `Bar 5
  Option`, `Bar 4 Ctrl · slots 1–4`, `Pet bar Ctrl · slots 1–4`, `Bar 6 G
  wheel · combat`, `Bar 7 G wheel · rest`, `Bar 8 Cmd+G wheel` (with
  PadKeys_Radial).
- **Drag** a spell, item or macro and the action bars fade in until you
  drop it.
- Other frames show by themselves when they matter (`show_when` and
  `flash_on` in `Config.lua`), and on mouseover:
  - the **micro menu** while you have talent points to spend;
  - the **bags** for 3 seconds as loot goes into them;
  - your **player and pet frames** in combat, with a target, or out of
    combat while your health or mana isn't full;
  - the **party frames** in combat, or out of combat while someone is hurt;
  - the **experience and reputation bars** for 4 seconds as they change;
  - the **quest tracker** for 5 seconds as you take a quest or an
    objective moves;
  - **chat** out of combat and while you type. In combat it fades, and
    comes back for 8 seconds on a whisper, party, raid or instance chat, a
    raid warning, or a boss's emote, yell or speech. Raid warnings and boss
    emotes also show mid-screen as always;
  - your **buffs** only on mouseover (PadKeys_Portrait shows your stance,
    form, aspect or aura).
- **Group frames by role**: make two Edit Mode layouts, `Healer` (party
  and raid frames bottom centre) and `Damage` (at the left), and pick one
  once. From then on the layout follows your role out of combat: the role
  you hold in the group, else your talents (most points in Holy,
  Discipline or Restoration is healing). A chat line says when it
  switches. Any other layout, or one you pick by hand, is left alone
  until your role changes. `roles` in `Config.lua`.
- **Hold `\`** and everything fades in; let go and it fades out again.
- **Edit Mode** shows everything, labels included.

Set up:

1. Enable PadKeys_Fade, `/reload`.
2. In **Edit Mode**, set **Bar Visible: Always** on every bar you want to
   reach by mouse (a bar set to Hidden stays hidden), and stack them at the
   bottom of the screen. Leave room to the right of the bars for the
   labels.
3. `/padkeys fade` keeps them shown while you arrange things; again to fade.

It only changes the frames' alpha, so it works in combat and the keys
press the buttons as before. Invisible buttons still take clicks where
they sit, which is why the bottom of the screen is the place for them.
Groups, their conditions and events, timings, the faded alpha (0 is
invisible) and the labels are in `PadKeys_Fade/Config.lua`; take a frame
out of its group to keep it always shown. Health and mana are secret in
combat, so "not full" is only read out of combat; in combat those frames
show because you are in combat.

## Look (PadKeys_Look)

Every font object in the game takes the theme font (Roboto Condensed
ExtraBold, `ns.config.theme.font` in `PadKeys/Config.lua`), keeping
Blizzard's sizes and outlines. Names and damage numbers above heads change
after a relog. Chat windows get a black background through Blizzard's own
chat window settings, so they still fade with the mouse as before.
`game_font` and `chat_alpha` are in `PadKeys_Look/Config.lua`.

## Cooldown Manager, totem bar and combo points

Three addons put Blizzard's own frames in the PadKeys bar's look, one at a
time so an error points at one of them. They only change how things look:
the frames still work, and Edit Mode still moves them.

- **PadKeys_Cooldowns**: every icon of the Cooldown Manager (Essential,
  Utility, buff icons and buff bars) gets the bar's 1px black border and
  rounded corners instead of Blizzard's round mask and ring. Spells on
  cooldown lose the swipe, as on the bar: Blizzard greys them and the
  countdown shows the seconds, so turn on **Show timer** in the Cooldown
  Manager's options. Out of range, no mana and not usable are grey instead
  of red, blue and dark; buff swipes are black; buff bars are light grey
  on black.
- **PadKeys_Totems**: the totem bar's buttons and slots get the black
  border; Blizzard's frame art and the element-coloured frames go
  (`element_colors = true` keeps the colours).
- **PadKeys_Combo**: Blizzard's combo points around the target's portrait
  are hidden, and a row of pips above the PadKeys bar fills white, one per
  point. It shows in combat and while you have points. If the client keeps
  the count secret, the number shows instead of the pips.
- **PadKeys_Portrait**: your portrait shows the stance or form you are in
  (warrior stances, druid forms, stealth), else your hunter aspect or
  paladin aura, else your class icon (`fallback = "face"` keeps
  Blizzard's portrait). Aspects and auras are buffs, read out of combat
  only; in combat your own cast of one switches the icon, and one
  cancelled in combat shows as combat ends.
- **PadKeys_Tracking**: a round badge on the minimap's rim, at 2 o'clock
  next to the day and night dial, shows what you are tracking, in the ring
  Blizzard puts behind your level; hover it for the name. In combat only your own tracking casts change it.

Settings are in each addon's `Config.lua`.

## Combat banner (PadKeys_Combat)

As you enter combat, **Combat** fades in above the middle of the screen in
white and fades out a second later; as you leave it, **Out of Combat** does
the same, in the PadKeys font.
Texts, size, position and timings are in
`PadKeys_Combat/Config.lua`; `banner = false` turns it off.

It only sets a text's alpha, so it works in combat. Later this addon is
meant to show boss timers or, in PvP, enemy cooldowns.

### Buff bar

Long buffs matter before a pull, not during it. Out of combat, a row of
icons just below the middle of the screen (under your character; the
combat banner is above) shows what needs doing; when nothing does, it
isn't there. Combat hides it at once, and it fades back in as you leave
combat (`fade_in`).

- A **red frame**: missing (the icon is grey). A number on its top right
  is how many in the group miss it.
- **Yellow** with a time: under 5 minutes left.
- **Grey** with a number: a supply running low (see below).
- **Click** an icon to fix it: a group buff you cast goes on whoever needs
  it first (click again for the next), your own buff on you, a consumable
  is used, a sharpening stone or oil goes on your main hand, a rogue's
  poison on its weapon (`poison_main`, `poison_off`), the pet is called or
  revived. Hover for its name and who is missing it.
- **Supplies**: ammo under 200, reagents for spells you know (soul shards,
  poisons and Flash Powder, Sacred Candles, Arcane Powder and Runes of
  Teleportation, Wild Thornroot, Symbols of Kings, an Ankh), and for hunters and
  warlocks no pet or a dead one.
- **Always**, at the end of the bar (also in inns and cities): your most
  worn item, with its own icon and its durability %, and your free bag
  slots; yellow under 30% and under 3 slots (`supplies.always = false`
  shows them only then). Limits and lists are under `supplies`.
- **Watched buffs**, also always (and in inns and cities): the sleeping
  bag's buff while you carry the bag or have the buff, below the level
  cap: its time left bottom right (45m, then 30s), its stacks top right; red while
  missing (click to use the bag), yellow under 5 minutes. Add others
  under `watch`.
  Your pet in trouble in combat shows at the mouse (PadKeys_Readout).

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
`hide_resting = false` to keep it in inns and cities,
`consolidate_in_combat = false` to leave the buff frame alone, and
`enabled = false` to turn the bar off.

## Combat text (PadKeys_CombatText)

Two small scrolls in place of Blizzard's floating combat text (turn that
off in `wow-settings`: its CVars belong there). Lines are white, crits
red and special abilities yellow; nothing is coloured by school or source.
Each line drifts smoothly upward (24 px) and fades out over 1 s;
a new line glides the older ones further up to make room.

- **Your hits** sit beside the right end of the target's nameplate health
  bar (beside the target frame without a nameplate), up to 4 lines, each
  with an icon. The game doesn't say which spell made a hit, so the icon
  is your last cast if it ended within 1.5 s before the hit; a melee swing
  shows your weapon. In a group the target's hits from others look the
  same, so there only hits that follow one of your casts show
  (`group_only_linked = false` shows all of them).
- **Hits you take** show lower right of the mouse pointer, outside the G
  radial, with no icon (the game doesn't name the spell). The whole
  scroll fades in as your health drops: hidden above 75%, fully shown at
  40% and below. As a tank (Defensive Stance, Bear Form, Righteous Fury
  or the tank role) it is half shown at full health and fully shown at
  70%. **Heavy damage** (a crit, a crushing blow, or 4 hits within 1.5 s)
  shows it fully for 3 seconds whatever your health, and lights G's
  healing slices. `anchor = "center"` puts it under your character.

Damage amounts and health are secret in combat: they can be shown but not
compared, so the alpha comes from Blizzard's health curve
(`UnitHealthPercent`) and a hit fully absorbed in combat shows as 0. Sizes,
the health points of both curves and `tank = true / false` are in
`PadKeys_CombatText/Config.lua`.

## Not ready flash (PadKeys_NotReady)

Press a key whose spell or item is still on cooldown (or out of charges),
or use such an item from your bags, and its icon flashes in the middle of
the screen with the time left on it, then fades out over a second. Another
press on cooldown, of the same key or another, replaces it at once. The
global cooldown alone flashes nothing.

A spell whose cooldown only starts when its buff ends (Rapid Fire) flashes
too while the buff runs, but without a time: the game has none to give
until the cooldown starts. The PadKeys bar and the G wheel show it
see-through without a countdown in that time, and the big cooldowns
beside the mouse drop it at once.

It listens for the game's own "Spell is not ready yet." / "Item is not
ready yet." errors and matches them to the key you just pressed. Size,
position and timings are in `PadKeys_NotReady/Config.lua`.

## Ready flash (PadKeys_Ready)

The opposite of the not-ready flash: a spell's icon and name pop up above
the mouse pointer, just outside the swing ring, as it becomes ready, then
fade out. `anchor = "center"` puts it above the middle of the screen.

- **Reactive abilities** flash as they light up: Overpower after a dodge,
  Revenge after a block, Execute under 20%, Riposte, Counterattack,
  Mongoose Bite (the `reactive` list in `Config.lua`).
- **Cooldowns**: any spell or item on your action bars flashes as it
  comes back, if its cooldown lasted 30 seconds or more (`cooldown_min`):
  Evocation, Innervate, trinkets, potions. `ignore` leaves some out
  (Hearthstone by default).
- Only in combat or with an enemy targeted (`only_when_fighting`).

Cooldown numbers are secret in combat, so it times each cooldown itself,
from when Blizzard's plain "on cooldown" flag turns on to when it turns
off. Only spells and items on Blizzard's action bars (any of the eight,
hidden ones too) count; macros don't.

## Readout at the mouse (PadKeys_Readout)

What changes fast, beside the mouse pointer, only while it matters:

- a **ring** around the pointer, empty most of the time:
  - your **cast or channel** fills it: **blue** for a damaging spell,
    **green** for a heal (or another helpful spell);
  - **glowing yellow** instead when the cast will land while one of your
    listed buffs (`ring.buffs`, spell IDs: Clearcasting, Elemental
    Mastery, Power Infusion, ...) is still on you. This is decided as the
    cast starts; if the client keeps a buff's time secret in combat and
    refuses the comparison, the ring stays blue;
  - out of a cast, the **global cooldown** fills it faintly, in combat;
  - hits you take no longer flash it red: they show lower right of the
    mouse (PadKeys_CombatText). `ring.hits = true` brings the flash back;
- a **swing ring** just outside it: a thin ring that fills from one auto
  attack to the next, white for melee, orange for Auto Shot (the client's
  own swing timer, `PLAYER_SWING`). Its faint track stays on all through
  combat and is the line everything else sits on.

Everything else sits right outside the swing ring (about 44 px from the
pointer), at about twice its old size; holding G covers it while the
wheel is open:

- your **big cooldowns that are ready**, to the right: a row of icons
  for self-buffs, trinkets and impactful spells, one per spell or item
  on any action bar (hidden bars count, so put trinkets on one) whose
  cooldown is a minute or longer and isn't running. Each pops in as it
  comes back and goes as you use it; dimmed while you can't use it (no
  mana, no target). Only in combat or with an enemy targeted. Which
  cooldowns are big is learned as you use them (and saved), so a spell
  shows once you've used it once; `big.names` adds some up front. Your
  race's spells ("Racial" on their tooltip) always show, first in the
  row, whatever their cooldown: they are for pressing early in a fight
  (`big.racials`). They too must be on an action bar;
- **boss abilities** from Blizzard's encounter timeline, upper left:
  each one as the timeline highlights it (a few seconds before it lands),
  with its icon, countdown and name to its left, up to three at once,
  stacking upwards; each goes when the timeline drops it. Blizzard's own
  timeline stays where it is;
- your **target's cast** (to interrupt) is off: the big cooldowns took
  its place and nameplates show casts. `target_cast = true` brings it
  back, lower right;
- your **pet in trouble**, below, in combat: its portrait with a
  pulsing red ring, for 3 seconds after it takes a lot of damage (a crit,
  a crushing blow, or 3 hits within 2 seconds) and for as long as its
  health is under 35%; otherwise nothing. Health is secret in combat; it
  goes from the client straight into the ring's visibility;
- your **debuffs**, left: Blizzard's own debuff frame, docked like the
  tracked buffs, with its icons, times and dispel-type borders. Blizzard
  reads the debuffs, so this works in combat; Edit Mode still shows it
  where Blizzard keeps it;
- your **totems**, above right over the tracked buffs (timers running on
  you, like them): one small icon per totem that is down, draining
  with its time left and the seconds on it; gone when none are down;
- your **tracked buffs**, above right: Blizzard's Cooldown Manager buff
  icons ("Tracked Buffs") follow the pointer, each while the buff is on
  you, with its time left. Pick them in the Cooldown Manager's options
  (e.g. Rapid Fire and Quick Shots for a hunter). Blizzard reads the
  buffs, so this works in combat; PadKeys only moves the icons, and Edit
  Mode still shows them where Blizzard keeps them.

While you turn with the right mouse button the pointer is hidden, so the
readout stays where it was. Times, names and icons are secret in combat
and during encounters; they go straight from Blizzard's duration objects
and info into the widgets, never compared. Whether Classic raids and
dungeons on Forever fill Blizzard's encounter timeline isn't known yet:
if Blizzard's own timeline never shows in a boss fight, the boss rows
won't either. Sizes, places and switches are in
`PadKeys_Readout/Config.lua`.

## Targeting (works in combat)

| Key | Does |
|---|---|
| \` | Toggle ally mode (off by default). On, F targets the ally you face, then the next ally on each press, Cmd+F inspects the ally you target, and "F targets allies" shows near the top of the screen. Off, F interacts. |
| Tab / Shift+Tab | Next / previous nearest enemy |
| F | Outside ally mode, in combat with a living enemy targeted: start your attack (hunters: Auto Shot; with a wand equipped: Shoot, also on a living enemy you target out of combat; `auto_shot = false` or `wand = false` in `PadKeys_Targeting/Config.lua` turns them off). Else a corpse or NPC you face: interact. Else, in ally mode, with an ally or enemy targeted: target the next ally in front of you. Else, in ally mode, the ally you face: target them. Else: interact (mailbox, herb, chest) |
| F in ally mode, in a raid | Hold F and move the mouse a little, wherever it is: a white frame moves over Blizzard's raid frames, from the member you last picked (out of combat: your target). Release F to target that member; a tap targets the one it starts on. `raid.step` and `raid.dead_zone` in `PadKeys_Targeting/Config.lua` set how far the mouse moves per frame. In combat the start doesn't follow a target picked another way, and raid frames created mid-combat can't be picked until combat ends |
| Ctrl+Tab / Ctrl+Shift+Tab | Next / previous party or raid member, in raid frame order |
| Shift+F | Assist: target your target's target |
| Ctrl+F | Last target |
| Cmd+F | Last hostile target. In ally mode with a living ally targeted: inspect them |

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
| G | In combat or with an enemy targeted, Action Bar 6, slots 1-8: drag spells, items and macros there. Resting in an inn or a city, the town page: Consumabuddy and town tracking. Otherwise Action Bar 7 (mount, food, buffs). Your consumables on a second ring outside (not on the town page): flick further to pick one | yes |
| Cmd+G | Action Bar 8, slots 1-8, the same way | yes |
| Shift+G | Target markers on your target, skull at the top | yes |
| Ctrl+G | Blizzard's main-menu entries, three pages | yes |

- **G follows the fight**: which page it opens is a macro condition,
  read on press (`main_pick = "[combat][harm,nodead] actions; [resting]
  town; extra"` under `ring` in `PadKeys_Radial/Config.lua`). Any page
  works there.
- **The town page** (resting, not fighting) is town errands, one ring
  of fixed entries: Consumabuddy east (when it's loaded); **town
  tracking** north-east, one segment for all of it (repair, trainers,
  general goods, mailbox, banker, auctioneer): on if any is off, else all
  off, grey while off; Dungeon Finder north, PvP north-west, guild west,
  calendar south-west, profession book south, collections (mounts, pets)
  south-east. Edit `town`: segments can also be a single tracking, a
  macro, another main-menu entry or your professions (examples in the
  comments).
  Only G changes; Cmd, Shift and Ctrl+G always open the same radial.
- **Two rings on G**: the action page on the inner ring, the consumables
  on an outer ring. A short flick picks from the inner ring; past about
  59 px (halfway between the rings, `outer_from`) from the outer one.
  `main_outer = false` gives a single ring.
- **Action Bar 6** is Blizzard's bar 6; it can stay hidden in Edit Mode.
  The action radials show the cooldown countdown over each icon, as the
  PadKeys bar does: a spell on cooldown is dimmed with the seconds on
  top, a charge recharging shows its time but stays solid, and the global
  cooldown alone shows nothing. An action you can't use (an item you have
  none of, a missing reagent) is dark grey, one short of mana lighter
  grey, as on the bar. Items and reagents show their stack count on the
  icon's lower right. Range isn't shown.
- All four are one **secure button**: on release, a secure snippet
  turns the mouse direction into a segment and fires its action, so
  spells, macros and windows work in combat and nothing is tainted. The
  modifier only matters on press.
- **Z** is sheathe / draw again.

### Consumables (G's outer ring)

G's **outer ring** is what's in your bags, picked for you: no
dragging new ranks onto a bar as you level or restock. It shows one set
in combat and another out of it:

- **In combat**, in the directions of the readouts at the mouse: rage
  potion east, Limited Invulnerability Potion north-east, Swiftness
  Potion north, Free Action Potion north-west, bandage west, mana potion
  south-west, healthstone south, healing potion south-east.
- **Out of combat**: drink, food, Hearthstone, bandage, and west, while
  you carry quest items with a Use:, **quest items**: it opens the bags
  holding them (all of them with Combined Bags on). In any open bag
  those items pulse with a gold border, however you opened it.

Each segment takes the best one you carry: the first of its list in your
bags (Major before Superior before Greater…), or for drink, food and
bandages any item with that use, the highest item level your level
allows (conjured water too). A segment with nothing in your bags is
empty. Cooldowns and stack counts show as on the action radials.

The picks are made out of combat, as your bags change: a secure button's
actions can't change in combat. So a potion you use up in a fight stays,
greyed with a count of 0, until the fight ends. Which set shows is a macro
condition (`pick = "[combat] fight; rest"`), which does switch in
combat; add sets such as `"[stealth] sneak; [combat] fight; rest"`. The
sets and their item lists are under `items` in
`PadKeys_Radial/Config.lua`.

### Faint wheel at the mouse, lit segments

A copy of the wheels follows your mouse, but only its **lit segments**
show: nothing is drawn until a segment's moment comes. Each one sits
where its icon will be when you open the wheel there: the G wheel (the
page G opens now) on the inner ring, its consumables on the outer ring,
so you see which way to flick before you press. It hides while you
turn with the right mouse button, and while a wheel is open.
`show = "combat"` brings back the whole faint copy in combat.

A segment **lights up** when its moment comes: on the faint copy it shows
at full strength with a white frame, and on the open wheel its slice
glows. By default:

- the **healing potion** (south-east) under 35% health and the
  **healthstone** (south) under 50%, and both for 3 seconds after heavy
  damage; the **mana potion** (south-west) under 25% mana;
- on Action Bar 6: **slot 6** (south-west, a mana spell) under 25% mana;
  **slot 7** (south, heal your pet) while your pet is under 35% or just
  took heavy damage, or with no pet out like the healthstone, for a
  second heal or defensive of your own; and **slot 8** (south-east, your
  own heal or defensive) like the healing potion.

**In combat G follows the readouts at the mouse**, so a readout lighting
up points at the slice that answers it. Each side has one theme: the top
is timing (boss abilities, cooldowns back, buffs and totems running), the
right your power, the bottom health (yours and your pet's, with the mana,
healthstone and healing potion outside), the left debuffs. Put on Action
Bar 6: your big cooldowns on slot 1 (east; they show ready right of the
mouse), your big self-buff on slot 2 (north-east, where tracked buffs
show), a mana spell on slot 6 (south-west: Evocation, Innervate, Life
Tap), Mend Pet or Health Funnel on slot 7 (south, where the pet warning
shows; without a pet a second heal or defensive) and a heal or defensive
on slot 8 (south-east, where your incoming damage shows). Ready cooldowns aren't lit: the column at the mouse shows them.
`{ pull = 6 }` lights an opener if you want one back.

Other rules: `"proc"` (the spell's proc glow), `"ready"` (usable and off
cooldown), `"casting"` (your target is casting, for an interrupt),
`{ combo = 5 }` and `"boss"` (Blizzard's encounter timeline highlights a
boss ability: put it on a defensive). Set them per segment under `lights` in
`PadKeys_Radial/Config.lua`, and the copy under `ghost` (`show =
"lit"`, `"combat"` or `"always"`, its rings, sizes and alpha).

Lighting only changes the look: a lit segment does what it always does,
so this works in combat. Health and mana are secret in combat and addon
code may not compare them, so the health and mana rules hand the
comparison to the client: a curve turns the percent into the glow's
alpha (`UnitHealthPercent` with a curve), and only `SetAlpha` ever sees
the result. With `show = "lit"` that alpha is the icon's own, so a
health light shows by itself, in combat too; with `"combat"` it can't
bring the copy up out of combat.

### Main menu (Ctrl+G)

Three pages, centre page first:

- **Left:** Group Finder, Legacy, Shop, Guild, Buffs, Collections.
- **Centre:** Bags, Professions, Character, Talents, Map, Spellbook.
- **Right:** Clock, Calendar, PvP.

Switch pages with the **mouse wheel** (up: left, down: right) while it is open, in
combat too (the secure snippet binds the wheel until release). Release Ctrl+G
with nothing highlighted to close.

The labels, icons and enabled state come from Blizzard's gamepad radial
(`GamepadRadial`'s handlers). Each entry opens by `/click`ing Blizzard's
own button (`CharacterMicroButton` and so on), not by calling those
handlers: from addon code their windows open tainted, and tainted Blizzard
code errors on the client's secret values. Social, Chat and Tracking have
no button to click, so they are left out. The game menu is left out too:
its button only opens with the mouse over it, so a `/click` does nothing.
Esc opens it instead. Size, position, dead zone, the
pages and the marker order are in `PadKeys_Radial/Config.lua`.

**Buffs** opens the UI cursor on your buffs (or debuffs, if you have no
buffs) when PadKeys_Cursor is on.

## Pings (Blizzard's)

Hold the **side mouse button** (`BUTTON5`): Blizzard's ping key. The
binding lives in `wow-settings`, not in PadKeys; 5 is left unbound. It
takes a held modifier too, so nothing else can go on a modifier + the side
button. While you hold it:

- click a unit or a spot to send Blizzard's contextual ping;
- click a slot of the PadKeys bar to ping that spell: ready, or on
  cooldown with the time left (as on Blizzard's own buttons); hold a
  modifier too to ping that layer's slots;
- press and drag for Blizzard's ping wheel: attack, assist, warning, on my
  way.

## UI cursor (out of combat)

Press **Shift+\`**. The cursor also starts by itself when a gossip, quest,
merchant, loot, professions or mailbox window or a popup opens, and moves there if
it is already on. Where it lands depends on the window:

- vendor: the first item;
- trainer: the next skill you can learn;
- professions: the first profession tab on the right, to pick one with
  W/S and F; the cursor then moves to its first recipe;
- popup: its text field or accept button.

On a recipe, the first F selects it and the second crafts it (the amount
in Blizzard's box); F on Create / Create All runs them. **Cmd+F** does
the most at once: on a selected recipe it creates all (on another recipe
the first press selects it), on a vendor
item it buys a full stack (or as many as you can afford), at a mailbox it
opens all mail or sends the letter (with the cursor off too, after
dragging items in with the mouse), in the talents it applies your picks. **B** opens your bags with the
cursor on sort bags (in combat it only opens them; press B again to
close). It clicks Blizzard's backpack button through a secure button, so
the bags aren't tainted.

| Key | Does |
|---|---|
| W A S D / arrows | Move between buttons |
| F / Space | Click: cast from the spellbook, pick a gossip line, use a bag item (eat, drink, equip, sell to an open vendor); on a text field (search box), type in it, and Escape or Enter goes back to moving |
| Shift+F | Right-click: use or sell an item, cancel a buff (takes over Assist while the cursor is on) |
| Ctrl+F | Pick up a spell or item; move to an action bar slot or bag slot and click to place it (takes over Last target while the cursor is on) |
| Cmd+F | Most at once: open all mail, apply talents, create all of a recipe, buy a full stack of a vendor item (or what you can afford), buy back on the Buyback tab |
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
your debuff's icon, which also gets a white frame. The highlight stays 6 s
after the last press (with its tooltip; `tooltip_on_step = false` shows
the tooltip only on Shift+C) and the tooltip 2 s after you let go of
Shift+C; then
they fade over 1 s. A press after that starts at the first aura again.
Timings are in `PadKeys_Auras/Config.lua`.

The auras are your target's: all its debuffs, then all its buffs (a
mob's own enrage too). The nameplate picks its auras from fields addons can't read in combat, so
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
| Radials | `GamepadRadial` (`Blizzard_Gamepad/UI/Radials`): art (atlases), menu labels and icons; the micro buttons (clicked); the secure action button; `/tm` | the wheel, pages, mouse direction and paging (secure snippet), release |
| Pings | the ping system (`TOGGLEPINGLISTENER`, `Blizzard_PingUI`) and its wheel; `PingableTypeMixin` for the bar slots | the key; each bar slot answers for the Blizzard button its key presses |
| NPC dialogs | `QuestFrame_GeneralProgressAction` (accept/continue/complete) and the gamepad's rules: cursor on the first entry, A clicks it, B closes | our cursor in place of SmartNavigation |
| Key layout | Blizzard's binding actions | apply/restore of the bindings |
| Interact key | Blizzard's Interact and soft targets (`softinteract`, `softfriend`) | a state driver and the ally mode toggle that rebind F |
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
5. **Pings** (in a group): hold the side mouse button and click a mob,
   then drag for the wheel. With PadKeys_Bar, click a bar slot too, also
   with Shift held.

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

9. **Targeting** (in a group, also in combat): Ctrl+Tab through the party.
   With PadKeys_Cursor on, press Shift+\` and move over the raid frames.
   At a mailbox with an ally nearby: F should open the mailbox. Press \`,
   face an ally: F should target them, and F again the next ally in
   front of you; \` again and F interacts (needs the ally soft
   targeting settings in `wow-settings`; `/dump UnitName("softfriend")`
   shows whether the client sees one). With an enemy targeted, face an
   ally and cast a heal: it should land on the ally.

**Stage 5: + PadKeys_Radial**

10. **Menu radial**: hold Ctrl+G, move the mouse, switch pages with Q/E and
    the wheel, release on a segment, also in combat. Watch for Lua errors
    when the window opens.
11. **Buffs** (with PadKeys_Cursor on): hold Ctrl+G, left page, pick Buffs.
    The cursor should land on your buffs; cancel one with Shift+F.
12. **Combat ring**: put a spell on Action Bar 6 slot 3, hold G, point up,
    release: it should cast, also in combat. Then Shift+G, point up (skull
    on your target). The highlight must match what
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
17. **Buff bar**: out of combat, cancel a buff you cast yourself: its
    icon shows with a red frame; hover it for its name; click it: you
    cast it and the icon goes. In a group where you cast a buff, the icon
    shows how many lack it; each click buffs the next. Pull a mob: the
    bar is gone at once and the buff frame folds its long buffs into one
    icon; after the fight both come back. Supplies: go under 200 arrows
    (hunter) or bring a pet out and dismiss it: a grey icon with a count,
    or the pet icon (click: Call Pet).

**Stage 8: + PadKeys_Look**

18. **Fonts**: windows, chat, tooltips and quest text should all be in
    Roboto Condensed; names and damage numbers above heads after a relog.
19. **Chat**: every chat window, and a new whisper tab, on a black
    background.
20. **Menu cursor** (PadKeys_Cursor): open a profession; the cursor should
    sit on the first tab on the right, and F should open it and move to
    its first recipe. Cmd+F on a recipe selects it, a second press
    creates all; Cmd+F on a
    vendor's reagent buys a stack.

**Stage 9: + PadKeys_Portrait, PadKeys_Tracking**

21. **Portrait**: your class icon shows in place of your face. Change
    stance, form, aspect or aura, in combat too; the icon follows.
22. **Tracking**: turn on Find Herbs or Track Beasts; a badge shows on the
    minimap's rim, and hovering it shows the name.

**Stage 10: + PadKeys_NotReady**

23. **Not ready**: cast a spell with a cooldown, then press its key again,
    in and out of combat: its icon flashes mid-screen with the time left
    and fades out over a second. Press it twice fast: the flash restarts.
    Press another key on cooldown mid-fade: its icon replaces the first.
    Spam a key during the global cooldown alone: nothing flashes. Use a
    potion on cooldown from the bags: it flashes too.

**Stage 11: PadKeys_Fade conditions**

24. **Frames that show by themselves**: out of combat at full health with
    no target, the player frame, bags, micro menu, buffs and quest
    tracker are faded. Target a mob: the player frame shows. Pull it:
    the player frame stays. Kill a quest mob: the quest tracker shows for
    5 seconds. Hold `\`: everything shows; let go: it fades. After the fight,
    the player frame stays until health and mana are full. Kill a mob for
    experience: the experience bar shows for 4 seconds. Loot an item: the
    bags show for 3 seconds. In a party, a hurt member shows the party
    frames out of combat.

**Stage 12: + PadKeys_Ready**

25. **Ready**: as a warrior, fight until a mob dodges: Overpower pops up
    above the mouse pointer. Use a spell with a cooldown of 30 s or
    more in combat: it pops up as it comes back. A short cooldown, and the
    global cooldown, never pop up.

**Stage 13: PadKeys_Radial consumables (G's outer ring)**

26. **Items**: `/padkeys apply` (5 goes back to unbound). Out of combat,
    hold G: Action Bar 7 inside, and your drink, food, Hearthstone and
    bandage on the outer ring, with counts. Flick a short way: an inner
    icon highlights; flick further: an outer one, with a white square.
    Release on the drink: you drink. Pull a mob and hold G: Action Bar 6
    inside, healing potion, healthstone and the rest outside. If you
    often get the outer ring when you meant the inner one, raise
    `outer_from` (e.g. 66). Drink a
    potion in combat: it greys with its cooldown. Buy a better potion: it
    takes the segment once out of combat.

**Stage 14: faint wheel and lights**

27. **G by context**: out of combat with no target, hold G: Action Bar 7.
    Target a mob, hold G: Action Bar 6. In combat: Action Bar 6.
    Nothing follows the mouse until a segment lights.
28. **Lights**: put Mend Pet on Action Bar 6 slot 7. In combat, let your
    pet drop under 35%: its icon shows below the mouse, and its
    slice glows when you hold G. Dismiss the pet and drop under 50%
    health: slot 7 lights for you instead. As a caster, drop under 25%
    mana: slot 6 and the mana potion light south-west; as a warrior
    slot 6 never lights. Drop under 50% health with a healthstone
    in your bags: it lights south on the outer ring; under 35% the healing
    potion south-east too. Take several quick hits: both light for 3 s. If
    neither ever lights, the health curve may need a different scale:
    send `/dump UnitHealthPercent("player")`.

**Stage 15: + PadKeys_Readout**

29. **Ring**: in combat, cast an instant: a faint white ring fills around
    the pointer with the global cooldown. Cast something with a cast time:
    a blue ring fills over the cast, on a grey track; a heal fills it green. If it drains instead
    of filling, set `ring.fill = false` and say so. Get a listed buff
    (e.g. Clearcasting) and cast while it's up: the ring is yellow and
    glows. If the
    ring stays blue with the buff up in combat but turns yellow out of
    combat, the buff's time is refused in combat: send
    `/run local a=C_UnitAuras.GetPlayerAuraBySpellID(16870) print(a and issecretvalue(a.expirationTime))`
    with the buff's ID.
30. **Big cooldowns**: put a spell with a cooldown of a minute or more
    (and a trinket you can use) on any bar. Use each once, then target a
    mob: their icons show in a row right of the pointer. Use one: it
    goes, and pops back in when its cooldown ends. Out of mana, its icon
    is dimmed. With no enemy targeted out of combat, nothing shows.
31. **Pet**: as a hunter or warlock, fight with your pet: nothing shows
    while it is fine. When it takes several hits quickly or a crit, its
    portrait shows below the pointer with a pulsing red ring for
    3 seconds. Under 35% health it stays until healed. If it never shows
    at low health, send `/run print(UnitHealthPercent("pet"))`.
32. **Debuffs and totems**: get a debuff (a mob's poison, or a curse):
    its icon shows left of the pointer with its time. As a shaman, drop
    totems: their icons show above right of the pointer, over the
    tracked buffs, draining. A new file:
    restart the client first.
33. **Boss**: in a boss fight where Blizzard's encounter timeline shows,
    each ability shows upper left of the pointer a few seconds before it
    lands, with a countdown. If the timeline shows but the rows don't, send the
    debug file.

**Stage 16: town page and chat**

34. **Town page**: a new file, so restart the client first. In a city or
    an inn, out of combat with no enemy targeted, hold G: one ring with
    Consumabuddy east, town tracking north-east and Blizzard windows
    around it, no consumables outside. Flick east: Consumabuddy opens.
    Flick north-east: repairers, trainers, vendors, mailboxes, bankers and
    auctioneers show on the minimap, and the icon turns from grey to
    colour; again turns them all off. Hover shows how many are on (e.g.
    6/6). Flick north: the Dungeon Finder opens. If fewer trackings than
    you expect come on, the minimap names them differently: send
    `/run for i=1,C_Minimap.GetNumTrackingTypes() do print(C_Minimap.GetTrackingInfo(i).name) end`.
    Leave the city: G opens Action Bar 7 with food outside again. If G
    still opens Bar 7 in a city, the client may not know `[resting]`:
    send `/run print(SecureCmdOptionParse("[resting] yes; no"))` in an
    inn.
35. **Chat**: start a fight: chat fades. Have someone whisper you or
    write in party or raid: chat shows for 8 seconds. Press Enter to type:
    it shows while you type. Leave combat: it stays.
36. **Roles**: new files, so restart the client. Make Edit Mode layouts
    `Healer` and `Damage` and pick one. As a healer (Holy, Discipline or
    Restoration talents, or the healer role in a group) the layout turns
    `Healer` within a second or two, with a chat line; respec or take the
    damage role: `Damage`. If nothing happens, send
    `/run local l=C_EditMode.GetLayouts() print(l.activeLayout, #l.layouts, l.layouts[1] and l.layouts[1].layoutName)`.
37. **Quest items**: carry a quest item you can use (right-click to use).
    Out of combat away from a city, hold G and flick far west: the bag
    with it opens and the item pulses gold. Open your bags with B: it
    pulses too. Without such an item the segment is empty.

**Stage 17: cursor readout closer, swing timer, sleeping bag**

38. **Swing ring**: new files, so restart the client first. In combat a
    faint thin circle sits just outside the cast ring all the time. Melee
    a mob: a white ring fills around it from one swing to the next. As a
    hunter, Auto Shot fills it orange. If it never fills, send
    `/run print(C_SwingTimer and "yes" or "no")`.
39. **Closer, bigger icons**: in combat, the big cooldowns (a row to the
    right), tracked buffs and totems (upper right), boss rows (upper
    left), debuffs (left) and the pet (below) sit right against the swing
    ring, about twice as big as before. Holding G covers them. If they
    overlap each other, say which ones; the places are in
    `PadKeys_Readout/Config.lua`.
40. **Sleeping bag**: on a character below the level cap carrying the
    sleeping bag, out of combat: the buff bar always shows its icon, red
    while the buff is missing (click it to use the bag), with the time
    left on the bottom right and the stacks on the top right once it is
    on; yellow under 5 minutes. If nothing shows, send the line under
    `watch` in `PadKeys_Combat/Config.lua` with the buff on.
41. **Racials at the mouse**: put your race's spells on any action bar
    (a hidden one is fine), target a mob: they show first in the row
    right of the pointer, before any other big cooldown, even one you
    have never used. Use one: it goes, and pops back when it is ready.
    If one never shows, send
    `/run print(C_Spell.GetSpellSubtext(C_Spell.GetSpellIDForSpellIdentifier("NAME")))`
    with its name.
42. **Rapid Fire on hold**: as a hunter, use Rapid Fire, then press it
    again while its buff runs: its icon flashes mid-screen (no time on
    it), and the PadKeys bar shows it see-through. Once the buff ends the
    countdown appears as usual, and pressing it then flashes with the
    time. If nothing flashes during the buff, send
    `/run local c=C_ActionBar.GetActionCooldown(SLOT) print(c.isEnabled, c.isActive)`
    with its action slot.
43. **Buff bar click, no ammo for casters**: as a shaman without
    Lightning Shield, out of combat: click its icon on the buff bar, it
    casts and the icon goes. If nothing casts, hover it and send
    `/run local b=GetMouseFoci()[1] print(b:GetName(), b:GetAttribute("type"), b:GetAttribute("spell"), GetCVar("ActionButtonUseKeyDown"))`.
    No ammo icon shows on a shaman, mage, priest, warlock, druid or
    paladin; a hunter with under 200 arrows still sees one.

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
- The cursor finds windows from `UIPanelWindows`, `UISpecialFrames` and a
  short list of names. A window it misses can be added to `EXTRA_ROOTS` in
  `PadKeys_Cursor/Cursor.lua`.
- Long scroll lists aren't scrolled by the cursor yet; use the mouse wheel.
- PadKeys_NotReady needs the game's "not ready yet" error to fire. If a
  press on cooldown never flashes, or a spell queued in the spell queue
  window gives no error, send what you see.

## Related branch

`feat/padkeys-custom-rings` adds our own secure rings on top of this
(to become a sixth addon, PadKeys_Rings):
a Utility ring (Hearthstone, macros, your own spells and items). Blizzard has no ring
for your own spells and items, so those need our code.

## Terms of service

PadKeys.zip also carries SpellActivationOverlay unchanged, under its MIT
licence; the rest of this section is about PadKeys.

It only uses Blizzard's public UI API. Every key press does one thing, and
nothing runs on its own, reads game memory or automates play. That's in
line with Blizzard's UI Add-On Development Policy.
