# Release Signing Keys

Every `skill-veil-rules` release ships with a detached `manifest.json.sig`
(base64-encoded Ed25519 signature) over `manifest.json`. The `skill-veil`
binary embeds the public verification keys listed below at compile time;
`skill-veil init` rejects any release whose signature does not verify
against one of them.

## Active keys

### skill-veil-rules-2026

- **Algorithm:** Ed25519 (PureEdDSA, RFC 8032)
- **Public key (base64, 32-byte raw):**
  `rGyuo55WLCRQk9684PR5ctDVFbrdWa3fipKMbMZiMOo=`
- **Public key (hex):**
  `ac6caea39e562c245093debce0f47972d0d515badd59addf8a928c6cc66230ea`
- **Issued:** 2026-05-09
- **Status:** active — signs every release in the v0.x.y line

The same key is embedded in `skill-veil` at
`crates/skill-veil-cli/src/init/keys.rs`.

## Verifying a release manually

```bash
# Download a release tarball + manifest + signature.
gh release download v0.1.0 --repo seifreed/skill-veil-rules

# Verify the signature against the active public key.
openssl pkeyutl -verify \
  -pubin \
  -inkey <(echo -n 'rGyuo55WLCRQk9684PR5ctDVFbrdWa3fipKMbMZiMOo=' | base64 -d \
           | python3 -c "import sys; raw=sys.stdin.buffer.read(); \
             print('-----BEGIN PUBLIC KEY-----'); \
             import base64; \
             header=bytes.fromhex('302a300506032b6570032100'); \
             print(base64.b64encode(header+raw).decode()); \
             print('-----END PUBLIC KEY-----')") \
  -rawin -in manifest.json \
  -sigfile <(base64 -d manifest.json.sig)

# Verify per-file SHA-256 against the manifest.
python3 - <<'PY'
import json, hashlib, sys
m = json.load(open("manifest.json"))
fail = False
for entry in m["files"]:
    actual = hashlib.sha256(open(entry["path"], "rb").read()).hexdigest()
    if actual != entry["sha256"]:
        print(f"MISMATCH: {entry['path']}", file=sys.stderr); fail = True
sys.exit(1 if fail else 0)
PY
```

## Key rotation policy

- Keys are rotated on a yearly cadence (next planned: `skill-veil-rules-2027`).
- A new key is added **before** the old one is retired, so a single
  `skill-veil` release can verify against either. This avoids forcing all
  consumers to upgrade in lockstep with a key roll.
- Compromised keys are revoked immediately and the corresponding entry in
  this file is moved to **Retired keys** below with the revocation date and
  the SHA-256 of the last release signed by that key.

## Retired keys

_(none yet)_
