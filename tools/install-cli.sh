#!/bin/bash
# Opt-in: links bin/lock-studio into ~/.local/bin so `lock-studio` works from
# any shell. Safe to re-run; an existing link is replaced, a real file of the
# same name is left alone.
#
#   tools/install-cli.sh
set -euo pipefail

PLUGIN_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$PLUGIN_DIR/bin/lock-studio"
DEST="$HOME/.local/bin/lock-studio"

[[ -f $SRC ]] || { echo "Missing $SRC" >&2; exit 1; }
if [[ -e $DEST && ! -L $DEST ]]; then
  echo "$DEST exists and is not a link; leaving it alone" >&2
  exit 1
fi

chmod +x "$SRC"
mkdir -p "$(dirname "$DEST")"
ln -sfn "$SRC" "$DEST"
echo "Linked $DEST -> $SRC"
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) echo "Note: ~/.local/bin is not on your PATH" ;;
esac
