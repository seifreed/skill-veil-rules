#!/usr/bin/env bash
# Produce the release tarball that `skill-veil init` downloads.
#
# Usage:
#   scripts/build-tarball.sh <version>
#
# Pre-conditions:
#   - manifest.json exists (run build-manifest.sh first)
#   - manifest.json.sig exists (run sign-manifest.sh first)
#
# Output:
#   dist/skill-veil-rules-<version>.tar.gz
#
# The tarball contains every file listed in the manifest plus the
# manifest itself and its signature; `skill-veil init` extracts it,
# verifies the signature, and verifies each file SHA-256 against the
# manifest before exposing the rules to the scanner.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <version>" >&2
  exit 64
fi

VERSION="$1"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$REPO_ROOT/dist"
TARBALL="$DIST_DIR/skill-veil-rules-${VERSION}.tar.gz"

cd "$REPO_ROOT"

for required in manifest.json manifest.json.sig; do
  if [[ ! -f "$required" ]]; then
    echo "error: $required missing — run build-manifest.sh and sign-manifest.sh first" >&2
    exit 66
  fi
done

mkdir -p "$DIST_DIR"

FILES=()
while IFS= read -r line; do
  FILES+=("$line")
done < <(
  python3 -c '
import json
with open("manifest.json") as f:
    m = json.load(f)
for entry in m["files"]:
    print(entry["path"])
'
)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "error: manifest.json lists zero files" >&2
  exit 65
fi

# Reproducible tar: pinned mtime, sorted entries, no owner/group leakage.
# `--mtime` is GNU tar; on macOS install via `brew install gnu-tar` and
# invoke as `gtar`. The wrapper picks whichever is available.
TAR_BIN="tar"
if tar --version 2>/dev/null | grep -q 'bsdtar'; then
  if command -v gtar >/dev/null 2>&1; then
    TAR_BIN="gtar"
  else
    echo "error: GNU tar required for reproducible builds (brew install gnu-tar)" >&2
    exit 69
  fi
fi

"$TAR_BIN" --owner=0 --group=0 --numeric-owner \
  --sort=name --mtime='2026-01-01 00:00:00 UTC' \
  -czf "$TARBALL" \
  manifest.json manifest.json.sig "${FILES[@]}"

echo "wrote $TARBALL"
ls -la "$TARBALL"
echo
echo "tarball SHA-256:"
sha256sum "$TARBALL"
