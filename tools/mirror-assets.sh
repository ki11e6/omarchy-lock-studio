#!/bin/bash
# Publish the pinned asset set as a GitHub release on this repo and add each
# file's release URL to the catalog as a mirror. The downloader tries `url`
# first and then each entry in `mirrors`, and the SHA-256 in the catalog has
# to match whichever source answered, so a mirror never weakens verification.
#
# With --primary the release URL becomes `url` instead: a qylock URL is kept
# as the first mirror so a download can still fall back to qylock, and any
# other previous URL is dropped.
#
# Read before running: this makes you the redistributor of every video, image
# and font in the catalog. The qylock repository is GPL-3.0 but most of those
# files are game and anime footage and a few proprietary fonts that Darkkal44
# does not own either. Mirroring them is a licensing decision, not a technical
# one. Fonts under the SIL Open Font License (Outfit, Orbitron, Figtree, Itim,
# Pixelify Sans, Cinzel, Tektur) are safe to mirror, and so is DejaVu (the
# Bitstream Vera license, with DejaVu's changes in the public domain). Google
# Sans and Nothing's NDot55/NType82 are not freely redistributable, so they
# are always skipped and stay on their original URL.
#
#   tools/mirror-assets.sh <release-tag> [--fonts-only] [--primary]
#
# Requires the pin cache from tools/pin-assets.sh for the commit the catalog is
# pinned to, and an authenticated `gh`.
set -euo pipefail

PLUGIN_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CATALOG="$PLUGIN_DIR/designs/thirdparty-assets.json"
TAG="${1:-}"
FONTS_ONLY=0
PRIMARY=0
for arg in "${@:2}"; do
  case $arg in
    --fonts-only) FONTS_ONLY=1 ;;
    --primary) PRIMARY=1 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done
[[ -n $TAG ]] || { echo "usage: tools/mirror-assets.sh <release-tag> [--fonts-only] [--primary]" >&2; exit 1; }
for tool in jq gh sha256sum; do command -v "$tool" >/dev/null || { echo "missing $tool" >&2; exit 1; }; done

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
COMMIT=$(jq -r '[.[] | .files[] | .url, (.mirrors // [])[]] | map(capture("qylock/(?<c>[0-9a-f]{40})/").c) | first' "$CATALOG")
[[ $COMMIT =~ ^[0-9a-f]{40}$ ]] || { echo "catalog is not pinned to a commit, run tools/pin-assets.sh first" >&2; exit 1; }
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/lock-studio/pin/$COMMIT"
[[ -d $CACHE ]] || { echo "no pin cache at $CACHE, run tools/pin-assets.sh $COMMIT" >&2; exit 1; }

gh release view "$TAG" >/dev/null 2>&1 || gh release create "$TAG" --title "Assets $TAG" --notes "Assets for designs/thirdparty-assets.json. Every file's SHA-256 is recorded in the catalog; third-party files keep their own licenses (see NOTICE.md)." --latest=false

# Not freely redistributable (see above): these always stay on their original URL.
RESTRICTED='(^|/)(GoogleSans|NDot55|NType82)[^/]*$'

results="$(mktemp)"
stage="$(mktemp -d)"
trap 'rm -rf "$stage" "$results"' EXIT
while IFS=$'\t' read -r id path sha url; do
  if [[ $path =~ $RESTRICTED ]]; then continue; fi
  if (( FONTS_ONLY )) && [[ ! ${path,,} =~ \.(ttf|otf)$ ]]; then continue; fi
  # Files already served from a release of this repository need no mirror.
  # --primary uploads them again, so a re-pin reaches the release.
  if (( ! PRIMARY )) && [[ $url == https://github.com/$REPO/releases/download/* ]]; then continue; fi
  src="$CACHE/$id/$path"
  [[ -f $src ]] || { echo "missing from cache: $src" >&2; exit 1; }
  got=$(sha256sum "$src" | cut -d' ' -f1)
  [[ $got == "$sha" ]] || { echo "cache file does not match catalog digest: $id/$path" >&2; exit 1; }
  # Release asset names are flat; keep them unique and readable.
  # gh names an asset after the file it is given (the #label form only sets a
  # display label), so stage a link under the flat name first.
  asset="${id#my-}--${path//\//__}"
  ln -sf "$src" "$stage/$asset"
  echo "uploading $asset"
  gh release upload "$TAG" "$stage/$asset" --clobber >/dev/null
  printf '%s\t%s\t%s\n' "$id" "$path" "https://github.com/$REPO/releases/download/$TAG/$asset" >> "$results"
done < <(jq -r 'to_entries[] | .key as $id | .value.files[] | [$id, .path, .sha256, .url] | @tsv' "$CATALOG")

merged=$(jq -Rs 'split("\n") | map(select(length > 0) | split("\t")) | map({ key: (.[0] + "\t" + .[1]), value: .[2] }) | from_entries' "$results")
jq --argjson m "$merged" --argjson primary "$PRIMARY" '
  def qylock: test("^https://raw\\.githubusercontent\\.com/Darkkal44/qylock/");
  to_entries
  | map(.key as $id | .value.files |= map(. as $f | ($m[$id + "\t" + $f.path]) as $url
      | if $url == null then $f
        elif $primary == 1 then $f + { url: $url, mirrors: ((if ($f.url | qylock) then [$f.url] else [] end) + (($f.mirrors // []) | map(select(. != $url and . != $f.url)))) }
        else $f + { mirrors: ((($f.mirrors // []) | map(select(. != $url))) + [$url]) } end))
  | from_entries' "$CATALOG" > "$CATALOG.tmp"
mv -f "$CATALOG.tmp" "$CATALOG"
if (( PRIMARY )); then
  echo "Moved to release $TAG on $REPO in designs/thirdparty-assets.json"
else
  echo "Added release mirrors to designs/thirdparty-assets.json (release $TAG on $REPO)"
fi
