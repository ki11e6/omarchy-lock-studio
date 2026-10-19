#!/bin/bash
#
# Install this plugin into the local Omarchy config for development and
# restart the shell. Safe to re-run; the destination is fully synced.

set -euo pipefail

ID="io.github.ki11e6.lock-studio"
SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.config/omarchy/plugins/$ID"

mkdir -p "$DEST"
rsync -a --delete --exclude '.git' --exclude '.github' --exclude 'docs' --exclude 'dev.sh' --exclude '.gitignore' "$SRC/" "$DEST/"
omarchy plugin validate "$DEST"
# Only one omarchy.lock clone can be enabled at a time.
omarchy plugin disable io.github.smoothpixels.lock-designs || true
omarchy-restart-shell
# The restarted shell takes a moment to answer IPC; enabling before then
# fails with "omarchy-shell is not responding".
deadline=$((SECONDS + 10))
until omarchy-shell lock status >/dev/null 2>&1; do
  ((SECONDS < deadline)) || break
  sleep 0.5
done
# Enable must run after the restart: on first install the running shell
# hasn't discovered the new plugin directory yet and enable fails.
if ! omarchy plugin enable "$ID"; then
  echo "enable failed; run: omarchy plugin enable $ID" >&2
  exit 1
fi
