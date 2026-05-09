#!/usr/bin/env bash
# Produce a detached Ed25519 signature over manifest.json.
#
# Inputs:
#   - manifest.json (at repo root, produced by build-manifest.sh)
#   - $SKILL_VEIL_RULES_SIGNING_KEY: path to a PKCS#8 PEM-encoded Ed25519
#     private key. The release workflow loads this from a GitHub Actions
#     secret. Local maintainers should never commit this key — see
#     keys/README.md for keypair generation.
#
# Outputs:
#   - manifest.json.sig (raw Ed25519 signature, base64-encoded)
#
# Verification (matches what skill-veil's init command does internally):
#   openssl pkeyutl -verify \
#     -pubin -inkey keys/skill-veil-rules.ed25519.pub.pem \
#     -rawin -in manifest.json \
#     -sigfile <(base64 -d manifest.json.sig)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$REPO_ROOT/manifest.json"
SIG_OUT="$REPO_ROOT/manifest.json.sig"

if [[ ! -f "$MANIFEST" ]]; then
  echo "error: $MANIFEST not found — run scripts/build-manifest.sh first" >&2
  exit 66
fi

KEY_PATH="${SKILL_VEIL_RULES_SIGNING_KEY:-}"
if [[ -z "$KEY_PATH" ]]; then
  echo "error: \$SKILL_VEIL_RULES_SIGNING_KEY must point to a PKCS#8 PEM Ed25519 private key" >&2
  echo "  generate one locally with: scripts/generate-keypair.sh keys/skill-veil-rules" >&2
  exit 64
fi

if [[ ! -f "$KEY_PATH" ]]; then
  echo "error: signing key not found at $KEY_PATH" >&2
  exit 66
fi

# `openssl pkeyutl -sign -rawin` performs PureEd25519 (RFC 8032) which is
# what ed25519-dalek expects on the verification side. Avoid the older
# `openssl dgst -sign` path — that one prepends a hash and would not
# verify against ed25519-dalek's `Verifier::verify(msg, sig)`.
TMP_SIG="$(mktemp -t sv-rules-sig.XXXXXX)"
trap 'rm -f "$TMP_SIG"' EXIT

openssl pkeyutl -sign \
  -inkey "$KEY_PATH" \
  -rawin \
  -in "$MANIFEST" \
  -out "$TMP_SIG"

# Base64 single-line — easier to inspect/copy and matches the format
# `init` decodes on the verification path.
base64 < "$TMP_SIG" | tr -d '\n' > "$SIG_OUT"
echo >> "$SIG_OUT"

echo "wrote $SIG_OUT ($(wc -c < "$SIG_OUT" | tr -d ' ') bytes base64)"
