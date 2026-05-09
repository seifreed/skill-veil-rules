# Release signing keys

This directory stores **public** Ed25519 verification keys committed to
the repo, plus tooling to generate new keypairs.

## Files

| File | Type | Committed? |
|------|------|------------|
| `*.ed25519.pub.pem` | SubjectPublicKeyInfo PEM (the canonical public key) | ✅ yes |
| `*.ed25519.pub.raw` | Raw 32-byte Ed25519 public key | ✅ yes |
| `*.ed25519.pub.b64` | Base64 of the raw public key (for `KEYS.md`) | ✅ yes |
| `*.ed25519.priv.pem` | PKCS#8 PEM private key | ❌ never |

`.gitignore` blocks `*.ed25519.priv.*` to make the "do not commit"
rule a hard constraint instead of a convention.

## Generating a new keypair

```bash
scripts/generate-keypair.sh keys/skill-veil-rules-<year>
```

Then:

1. Add the base64 line from `<prefix>.ed25519.pub.b64` to `KEYS.md` as a
   new "Active key" entry.
2. Embed the raw 32 bytes from `<prefix>.ed25519.pub.raw` in the
   skill-veil binary at
   `crates/skill-veil-cli/src/init/keys.rs` and ship a new
   skill-veil release that recognises the new key.
3. Paste the contents of `<prefix>.ed25519.priv.pem` into the GitHub
   Actions secret named `SKILL_VEIL_RULES_SIGNING_KEY`.
4. Securely back up `<prefix>.ed25519.priv.pem` (e.g. an offline
   password manager) and then delete it from disk.

Releases tagged after the secret is rotated will be signed with the new
key. Keep the previous public key in `KEYS.md` (and embedded in
skill-veil) until every release signed by it has aged past your support
window.
