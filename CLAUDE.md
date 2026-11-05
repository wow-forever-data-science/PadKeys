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

## Workflow

- Work on a branch, open a PR, and merge it yourself once the checks pass
  (the user asked for this). Don't wait for approval to merge.
