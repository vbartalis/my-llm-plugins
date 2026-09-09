#!/usr/bin/env bash
# post-create.sh — runs once, after the devcontainer is built.
set -euo pipefail

# Repo root — works both when run by the devcontainer lifecycle (workspaceFolder)
# and when invoked by hand from anywhere inside the repo.
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> installing packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
# ncurses-term supplies the tmux-256color terminfo entry used by tmux.conf.
# jq is used by any status-line or hook scripts that parse JSON.
apt-get install -y -qq --no-install-recommends tmux ncurses-term jq

echo "==> installing claude code"
curl -fsSL https://claude.ai/install.sh | bash

echo "==> installing shell aliases"
# Idempotent: the block is fenced by markers and rewritten on every run, so
# rebuilding the container never stacks up duplicate aliases.
BASHRC="$HOME/.bashrc"
BEGIN='# >>> my-llm-plugins >>>'
END='# <<< my-llm-plugins <<<'

if [ -f "$BASHRC" ] && grep -qF "$BEGIN" "$BASHRC"; then
  sed -i "\|$BEGIN|,\|$END|d" "$BASHRC"
fi

cat >> "$BASHRC" <<ALIASES
$BEGIN
# Bring up (or attach to) the tmux dev session.
alias dev='$REPO/.devcontainer/dev-session.sh'
$END
ALIASES

echo "==> done. run 'dev' to start a tmux session."
