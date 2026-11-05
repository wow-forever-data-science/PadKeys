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

## Forever client rules (learned from in-game errors)

- Secret values - cooldown, aura and health numbers are secret in combat; addon code may not compare them, do arithmetic on them, or pass them to most widget setters (`Cooldown:SetCooldown` refuses them)
- Auras - `C_UnitAuras.GetAuraDataByIndex` errors in combat when tainted; `GameTooltip:SetUnitAura` can still show one by index
- Use the duration objects instead - `C_ActionBar.GetActionCooldownDuration` / `GetActionChargeDuration` with `Cooldown:SetCooldownFromDurationObject`
- Check an API in Gethe's `Blizzard_APIDocumentationGenerated` (branch `forever`) - `SecretArguments = "AllowedWhenUntainted"` means addon code can't pass secrets
- Decide with the plain flags Blizzard returns (`isActive`, `isEnabled`), as Blizzard's own code does
- Taint - calling Blizzard UI functions that open windows from addon code taints them, and tainted Blizzard code then errors on secret values; open windows by `/click`ing Blizzard's button through a secure button instead

## Workflow

- Work on a branch, open a PR, and merge it yourself once the checks pass
  (the user asked for this). Don't wait for approval to merge.
