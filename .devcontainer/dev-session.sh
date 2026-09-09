#!/usr/bin/env bash
# dev-session.sh — build or attach the tmux dev session.
#
# Usage: dev   (via the shell alias set up by post-create.sh)
#        or directly: .devcontainer/dev-session.sh
set -euo pipefail

SESSION="dev"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMUX_CONF="$REPO/.devcontainer/tmux.conf"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Attaching to existing tmux session '$SESSION'..."
  exec tmux attach-session -t "$SESSION"
fi

echo "Creating tmux session '$SESSION'..."
tmux -f "$TMUX_CONF" new-session -d -s "$SESSION" -c "$REPO"

# Window 0: shell at repo root
tmux rename-window -t "$SESSION:0" "shell"

exec tmux attach-session -t "$SESSION"
