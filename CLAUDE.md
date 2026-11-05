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

## Workflow

- Work on a branch, open a PR, and merge it yourself once the checks pass
  (the user asked for this). Don't wait for approval to merge.
