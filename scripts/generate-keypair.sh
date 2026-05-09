#!/usr/bin/env bash
# Generate a fresh Ed25519 keypair for signing skill-veil-rules releases.
#
# Usage:
#   scripts/generate-keypair.sh <output-prefix>
#
# Produces:
#   <prefix>.ed25519.priv.pem   PKCS#8 PEM-encoded private key (chmod 600)
#   <prefix>.ed25519.pub.pem    SubjectPublicKeyInfo PEM-encoded public key
#   <prefix>.ed25519.pub.raw    Raw 32-byte public key (suitable for embedding)
#   <prefix>.ed25519.pub.b64    Base64 of the raw public key (for KEYS.md)
#
# The PRIVATE key never leaves the maintainer's machine / GitHub Actions
# secret store. The PUBLIC key components ship inside the skill-veil binary
# (compile-time embed) and inside this repo's KEYS.md.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <output-prefix>" >&2
  echo "  e.g. $0 keys/skill-veil-rules-2026" >&2
  exit 64
fi

PREFIX="$1"
PRIV="${PREFIX}.ed25519.priv.pem"
PUB_PEM="${PREFIX}.ed25519.pub.pem"
PUB_RAW="${PREFIX}.ed25519.pub.raw"
PUB_B64="${PREFIX}.ed25519.pub.b64"

if [[ -e "$PRIV" || -e "$PUB_PEM" ]]; then
  echo "error: refusing to overwrite existing keypair at $PREFIX" >&2
  echo "  delete the existing files explicitly if you really mean to rotate" >&2
  exit 73
fi

mkdir -p "$(dirname "$PREFIX")"

openssl genpkey -algorithm ed25519 -out "$PRIV"
chmod 600 "$PRIV"

openssl pkey -in "$PRIV" -pubout -out "$PUB_PEM"

# Strip the SubjectPublicKeyInfo wrapper to get the raw 32-byte key.
# `openssl pkey -pubin -outform DER` produces a 44-byte DER blob whose
# last 32 bytes are the raw Ed25519 public key.
DER_TMP="$(mktemp -t sv-rules-pub.XXXXXX)"
trap 'rm -f "$DER_TMP"' EXIT
openssl pkey -in "$PUB_PEM" -pubin -outform DER -out "$DER_TMP"
tail -c 32 "$DER_TMP" > "$PUB_RAW"

base64 < "$PUB_RAW" | tr -d '\n' > "$PUB_B64"
echo >> "$PUB_B64"

echo "Generated Ed25519 keypair:"
echo "  private (PKCS#8 PEM, chmod 600): $PRIV"
echo "  public  (SPKI PEM):              $PUB_PEM"
echo "  public  (raw 32-byte):           $PUB_RAW"
echo "  public  (base64):                $PUB_B64"
echo
echo "NEXT STEPS:"
echo "  1. Add the base64 public key to KEYS.md."
echo "  2. Embed the raw public key in skill-veil:"
echo "     crates/skill-veil-cli/src/init/keys.rs"
echo "  3. Store the private key as a GitHub Actions secret named"
echo "     SKILL_VEIL_RULES_SIGNING_KEY (paste the entire .priv.pem)."
echo "  4. Keep the .priv.pem file OUT of git (.gitignore covers *.ed25519.priv*)."
