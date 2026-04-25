#!/bin/bash
# ai-ring-hook.sh - Claude Code / OpenCode hook script for ai-ring.wezterm
#
# Sends OSC 1337 user variable to the WezTerm pane.
# If stdout is not a terminal (hook captures output), falls back to
# writing directly to the pane's tty via /dev/tty, or uses wezterm cli.
#
# Usage:
#   ai-ring-hook.sh done     # mark agent as done
#   ai-ring-hook.sh running  # mark agent as running

STATUS="${1:-done}"
PANE_ID="${WEZTERM_PANE:-}"

if [ -z "$PANE_ID" ]; then
  exit 0
fi

ENCODED=$(printf '%s' "$STATUS" | base64)
# Build inner OSC sequence
INNER=$(printf '\033]1337;SetUserVar=%s=%s\007' "AI_RING" "$ENCODED")
# Wrap with tmux DCS passthrough if running inside tmux
if [ -n "${TMUX:-}" ]; then
  OSC=$(printf '\033Ptmux;\033%s\033\\' "$INNER")
else
  OSC="$INNER"
fi

# Try multiple output methods
if [ -t 1 ]; then
  # stdout is a terminal
  printf '%s' "$OSC"
elif [ -w /dev/tty ]; then
  # Write directly to controlling terminal
  printf '%s' "$OSC" > /dev/tty
else
  # Last resort: use wezterm cli send-text (IPC direct — no tmux wrapping needed)
  printf '%s' "$INNER" | wezterm cli send-text --pane-id "$PANE_ID" --no-paste
fi
