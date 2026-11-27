# PadKeys notes for Claude

WoW Classic addons (Lua 5.1): the `PadKeys/` base and the `PadKeys_*/`
addons. Only those folders go into the release zip (release.yaml).

## Checks

- Syntax, as CI runs it: `for f in PadKeys*/*.lua; do luac5.1 -p "$f"; done`
- Lint: `luacheck .` (config in `.luacheckrc`)
- Cloud sessions get both from `.claude/hooks/session-start.sh`. Elsewhere:
  `apt-get install -y lua5.1 luarocks && luarocks install luacheck`

There are no tests; changes can only be tried in the game client, so say
what is untested.

## Errors from the game

- PadKeys_Debug saves them on `/reload` or logout
- Read `/Applications/World of Warcraft/_forever_/WTF/Account/*/SavedVariables/PadKeys_Debug.lua`
- The installed addons are symlinks to this repo, so the game runs the checked-out branch
- A new `PadKeys_*` folder needs its own symlink in `Interface/AddOns/` and a client restart
  - Missing symlink = "the feature does nothing", no error (happened with NotReady, Ready, Readout, CombatText)
  - Cloud sessions can't reach the game folder - tell the user to add the link
- Remote or no log - ask for one line of output: `/run ... print(a, b, c)`, not `/dump` (too long to read)

## Forever client rules (learned from in-game errors)

- Secret values - cooldown, aura and health numbers are secret in combat; addon code may not compare them, do arithmetic on them, or pass them to most widget setters (`Cooldown:SetCooldown` refuses them)
- Auras - `C_UnitAuras.GetAuraDataByIndex` errors in combat when tainted; `GameTooltip:SetUnitAura` can still show one by index
- Use the duration objects instead - `C_ActionBar.GetActionCooldownDuration` / `GetActionChargeDuration` with `Cooldown:SetCooldownFromDurationObject`
- Check an API in Gethe's `Blizzard_APIDocumentationGenerated` (branch `forever`) - `SecretArguments = "AllowedWhenUntainted"` means addon code can't pass secrets
- Decide with the plain flags Blizzard returns (`isActive`, `isEnabled`), as Blizzard's own code does
- Taint - calling Blizzard UI functions that open windows from addon code taints them, and tainted Blizzard code then errors on secret values; open windows by `/click`ing Blizzard's button through a secure button instead
- Secret values may go to `SetAlpha` - health and mana thresholds go through a curve (`UnitHealthPercent(unit, false, curve)`) straight into an alpha (PadKeys_Radial `Lights.lua`)
- Auras in combat - let Blizzard read them and move its frames: the Cooldown Manager's Tracked Buffs (`BuffIconCooldownViewer`) is docked at the mouse (PadKeys_Readout `Dock.lua`, also Blizzard's `DebuffFrame`)
- Managed frames - an Edit Mode system in its default place is re-anchored by `BottomManagedFrameContainer` on every `Layout`; re-dock in a post-hook on the container's `Layout`
- Edit Mode systems replace `SetScale` - call the widget's own: `getmetatable(frame).__index.SetScale`
- No "not ready" error - an action pressed on cooldown sends no `UI_ERROR_MESSAGE`; decide from the slot's cooldown state before the press (PadKeys_NotReady)
- No custom cursor - `SetCursor` with an addon's own image leaves the arrow as it is, also after a restart; the pointer can't be hidden
- Health curves - pass `usePredicted = false` to `UnitHealthPercent`; a heal on its way pushes the predicted percent over 100%
- Item cooldowns - a bag item's numbers are secret in combat and have no duration object; an action slot holding the item gives one
- Texture colour sets alpha - `SetVertexColor` after `SetAlpha` undoes the alpha (unlit frames showed as white squares); set the colour first, and pulse on a frame of its own
- Blizzard source - Gethe's `wow-ui-source`, branch `forever`: `gh api "repos/Gethe/wow-ui-source/contents/<path>?ref=forever" -q .content | base64 -d`

## Ownership with wow-settings

One owner per setting, so this repo and `wow-settings` never undo each other.

| Setting | Owner | Other repo |
|---|---|---|
| Bindings of PadKeys' keys (`Config.lua`, saved in `PadKeysDB.keys`) | PadKeys | `wow-settings` leaves them out of snapshot and apply |
| All other key bindings | `wow-settings` | PadKeys does not bind them |
| CVars, incl. soft targeting | `wow-settings` (incl. its `WowSettings` addon for CVars the client does not save) | PadKeys sets no CVars |
| Edit Mode layouts (their contents) | `wow-settings` | PadKeys never edits a layout |
| Which of `Healer` / `Damage` is active (`PadKeys_Fade` `Roles.lua`) | PadKeys, at runtime | `wow-settings` should not snapshot or apply the active layout (proposed; not yet changed there) |

- Never edit `wow-settings` files from a session here - say what should change there instead
- A CVar PadKeys needs goes into `wow-settings`, not `SetCVar` in an addon here
- Sessions on both repos at once - use a worktree each, never switch branches in a checkout another session uses

## Workflow

- Work on a branch, open a PR, and merge it yourself once the checks pass
  (the user asked for this). Don't wait for approval to merge.
- Wait ~15 s after `gh pr create` before `gh pr checks --watch`: right after creation it reports "no checks" and exits 0
- Document a change where the user reads it: the addon's `Config.lua` comments, its README section, and the README's in-game test steps
- `keymap.html` (published key map) is behind the bindings - update it when keys change
