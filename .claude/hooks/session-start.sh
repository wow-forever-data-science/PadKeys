#!/bin/bash
# Installs the Lua checks (luac5.1, luacheck) in Claude Code cloud sessions.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# System-wide tools: skip when already there (the container is cached).
if ! command -v luac5.1 > /dev/null || ! command -v luarocks > /dev/null; then
  apt-get install -y -q lua5.1 luarocks > /dev/null 2>&1 ||
    { apt-get update -q > /dev/null && apt-get install -y -q lua5.1 luarocks > /dev/null; }
fi
if ! command -v luacheck > /dev/null; then
  luarocks install luacheck > /dev/null
fi
