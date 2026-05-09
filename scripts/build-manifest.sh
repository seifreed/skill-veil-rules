#!/usr/bin/env bash
# shellcheck disable=SC2207
# Build a deterministic manifest.json listing every distributable rule pack
# file with its SHA-256 digest. The manifest is the verification anchor:
# `skill-veil init` verifies its Ed25519 signature against the embedded
# public key, then verifies each extracted file's SHA-256 against the entry
# in the manifest. A tampered tarball thus surfaces as either an invalid
# signature or a checksum mismatch — never as a silently loaded bad rule.
#
# Usage:
#   scripts/build-manifest.sh <version>
#
# Reads:
#   - All YAML files under official/, community/, base/, fixtures/,
#     schema/, and *.yar files under yara/.
#
# Writes:
#   - manifest.json (at repo root)
#
# Determinism contract:
#   - File list is sorted lexicographically (LC_ALL=C).
#   - Hash algorithm is fixed (SHA-256, hex-lowercase).
#   - JSON is emitted with stable key order.
#   - Re-running on the same content produces a byte-identical manifest.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <version>" >&2
  echo "  e.g. $0 v0.1.0" >&2
  exit 64
fi

VERSION="$1"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$REPO_ROOT/manifest.json"

if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?$ ]]; then
  echo "error: version must match vX.Y.Z (optionally -prerelease), got: $VERSION" >&2
  exit 64
fi

cd "$REPO_ROOT"

if ! command -v sha256sum >/dev/null 2>&1; then
  echo "error: sha256sum not found (install coreutils on macOS: brew install coreutils)" >&2
  exit 69
fi

GENERATED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# `mapfile` is bash 4+; macOS ships bash 3.2 by default. Use the portable
# `while read` form so the release scripts work without pinning a newer
# bash via brew.
FILES=()
while IFS= read -r line; do
  FILES+=("$line")
done < <(
  find official community base fixtures schema yara \
    \( -name '*.yaml' -o -name '*.yml' -o -name '*.yar' -o -name 'README.md' \) \
    -type f 2>/dev/null \
    | LC_ALL=C sort
)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "error: no distributable files found under official/community/base/fixtures/schema/yara" >&2
  exit 65
fi

{
  printf '{\n'
  printf '  "schema_version": "skill-veil.dev/rules-manifest/v1",\n'
  printf '  "version": "%s",\n' "$VERSION"
  printf '  "generated_at": "%s",\n' "$GENERATED_AT"
  printf '  "files": [\n'

  for i in "${!FILES[@]}"; do
    f="${FILES[$i]}"
    digest="$(sha256sum "$f" | awk '{print $1}')"
    size="$(wc -c < "$f" | tr -d ' ')"
    sep=","
    if [[ $i -eq $(( ${#FILES[@]} - 1 )) ]]; then
      sep=""
    fi
    printf '    { "path": "%s", "sha256": "%s", "size_bytes": %s }%s\n' \
      "$f" "$digest" "$size" "$sep"
  done

  printf '  ]\n'
  printf '}\n'
} > "$MANIFEST"

echo "wrote $MANIFEST (${#FILES[@]} files, version $VERSION)"
