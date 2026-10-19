#!/usr/bin/env bash
# fetch-image.sh <https-url> <dest>
#
# Downloads one image without trusting the response, ported from omalock's
# album-art fetch: https only, no redirects (a redirect would move the fetch
# off the host the caller checked), a hard size cap, and the format read from
# the magic bytes rather than a header or extension. The download lands in a
# random temp file next to <dest> and is mv'd into place with -T, so a
# symlink or directory pre-placed at <dest> can't redirect the write. Host
# allowlisting is the caller's job.
set -eu

src="${1:-}"
dest="${2:-}"
max=8000000

case "$src" in https://*) ;; *) exit 1 ;; esac
[ -n "$dest" ] || exit 1

mkdir -p -- "$(dirname -- "$dest")" || exit 1
tmp=$(mktemp "${dest}.XXXXXX") || exit 1
trap 'rm -f -- "$tmp"' EXIT

curl -sf --proto "=https" --max-redirs 0 --max-filesize "$max" --max-time 8 -o "$tmp" -- "$src" || exit 1
size=$(wc -c < "$tmp") || exit 1
[ "$size" -gt 0 ] && [ "$size" -le "$max" ] || exit 1
sig=$(od -An -v -tx1 -N16 "$tmp" | tr -d ' \n') || exit 1
case "$sig" in
  ffd8ff*|89504e470d0a1a0a*|474946383961*|474946383761*|424d*|52494646????????57454250*) ;;
  *) exit 1 ;;
esac
mv -fT -- "$tmp" "$dest"
