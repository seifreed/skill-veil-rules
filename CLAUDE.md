# Project Guidance for Coding Agents

Guidance for Claude Code, GitHub Copilot, and other agentic coding
agents working on `skill-veil-rules`. This repo distributes the
external rule packs consumed by [skill-veil](https://github.com/seifreed/skill-veil)
as **Ed25519-signed GitHub Releases**.

End users do not clone this repo — they run `skill-veil init`, which
downloads the latest release tarball, verifies the Ed25519 signature
against a public key embedded in the `skill-veil` binary, verifies
every extracted file's SHA-256 against the signed manifest, and
installs into `~/.cache/skill-veil/rules/<version>/`.

## Repository layout

| Path | Role | Public-API? |
|------|------|-------------|
| `official/` | Curated default packs loaded by `skill-veil scan`. | **Yes — rule IDs are public API**. Rename/remove only via deprecation cycle. |
| `community/` | Incubating / org-specific packs not enabled by default. | Soft API (advertised, but breakable with a CHANGELOG note). |
| `base/` | Historical category-grouped packs (credentials, obfuscation, supply-chain, …). | Soft API. |
| `fixtures/` | Positive / negative test cases consumed by `skill-veil rules test-pack`. | Internal; required for every PR that adds a rule. |
| `schema/skill-veil-rule-pack-v1.yaml` | Versioned schema reference for pack authors. | **Yes — schema is public API**. |
| `yara/` | Optional YARA rules (loaded when `skill-veil` is built with `--features yara`). | Soft API. |
| `keys/` | **Public** verification keys (PEM + raw + base64). Private keys are NEVER committed; see [Key custody](#key-custody). | Public for verification. |
| `KEYS.md` | Key registry with rotation policy and manual verification recipe. | Reference. |
| `scripts/` | Release pipeline: `build-manifest.sh`, `sign-manifest.sh`, `build-tarball.sh`, `generate-keypair.sh`. | Internal. |
| `.github/workflows/release.yml` | Tag-triggered build + sign + upload-assets. | Maintainers only. |
| `.github/workflows/validate.yml` | Per-PR gating: deterministic manifest check + private-key leak guard. | All PRs. |

## Adding a new rule

1. **Land the rule.** Edit `official/<topic>.yaml` (preferred) or
   `community/<pack-name>.yaml`. The pack envelope is fixed:

   ```yaml
   schema_version: skill-veil.dev/rules/v1alpha1
   metadata:
     name: official-<topic>
     kind: official              # or `community` / `ioc_feed`
     compatibility:
       - skill-veil.dev/rules/v1alpha1
   rules:
     - id: UPPERCASE_SNAKE_CASE_ID   # globally unique; PUBLIC API
       category: remote_exec | supply_chain | credential_exposure | ...
       severity: low | medium | high | critical
       confidence: 0.0..1.0
       when: !regex
         pattern: "..."              # or !all / !any with nested conditions
       action: log | require_approval | block
       reason: "Single sentence shown to operators in scan reports."
       enabled: true
       tags: [tag_one, tag_two]
   ```

2. **Add fixtures.** EVERY new rule requires at least one **positive**
   fixture (`expect_match: true`) AND one **negative** fixture
   (`expect_match: false`) in `fixtures/<topic>.yaml`:

   ```yaml
   cases:
     - id: <rule-id>-positive
       rule_id: NEW_RULE_ID
       content: |
         # Skill markdown that SHOULD match
         ...
       expect_match: true
       expected_count: 1
       expected_severity: medium
       expected_action: require_approval
       expected_category: tool_abuse

     - id: <rule-id>-negative-similar-but-benign
       rule_id: NEW_RULE_ID
       content: |
         # Looks similar but is benign
         ...
       expect_match: false
   ```

   The negative fixture pins the regex against false-positive drift
   over time. Skipping it is not optional — `validate.yml` will fail
   the PR.

3. **Validate locally.** From the `skill-veil` repo (sibling
   checkout):

   ```bash
   skill-veil rules validate --rules-dir ../skill-veil-rules/official
   skill-veil rules pack-info --rules-dir ../skill-veil-rules/official
   skill-veil rules test-pack \
     --rules-dir ../skill-veil-rules/official \
     --fixtures ../skill-veil-rules/fixtures/behavioral.yaml
   ```

   `validate` checks pack-envelope correctness; `pack-info` summarises
   the loaded rules; `test-pack` runs every fixture.

4. **Update the changelog.** Append a one-line entry under
   `## [Unreleased]` in `CHANGELOG.md`:

   ```markdown
   ### Added
   - ADD NEW_RULE_ID — short description of what it catches
   ```

5. **Open a PR.** Maintainers cut a new signed release once the PR
   lands; downstream `skill-veil init` picks it up on the next run.

## Promoting a community rule into `official/`

A `community/` rule is eligible for promotion when ALL of the
following hold:

- The rule has been in `community/` for at least one release cycle.
- A false-positive analysis is provided: scan the
  [skill-veil benchmark corpus](https://github.com/seifreed/skill-veil/blob/main/benchmarks/corpus.yaml)
  and report how many benign packages matched.
- `category`, `severity`, `action`, `confidence`, and `reason` have
  been justified in the PR description.
- The rule moves (don't copy) and fixtures move with it.

Once promoted, the rule ID becomes **public API** and may not be
renamed or removed without a deprecation cycle (which involves
keeping the ID around alongside its replacement for at least one
release).

## Cutting a release (maintainers only)

Releases are produced by the `release.yml` GitHub Actions workflow on
a tag push. The pipeline is:

```
build-manifest.sh <version>   →   manifest.json (per-file SHA-256)
sign-manifest.sh              →   manifest.json.sig (Ed25519, base64)
build-tarball.sh <version>    →   dist/skill-veil-rules-<version>.tar.gz
softprops/action-gh-release   →   uploads all 3 as release assets
```

### Standard release flow

```bash
# 1. Confirm CHANGELOG.md has the right entries under `Unreleased`,
#    then move them under the new version heading.

# 2. Tag and push.
git tag v0.1.0
git push origin v0.1.0
```

The push triggers `release.yml`. Watch it:

```bash
gh run list --workflow=Release --limit 1
gh run watch <run-id>
```

When green, three assets appear at
`https://github.com/seifreed/skill-veil-rules/releases/tag/v0.1.0`:

- `manifest.json`
- `manifest.json.sig`
- `skill-veil-rules-v0.1.0.tar.gz`

### Local rehearsal (no push, no tag)

Useful when iterating on the scripts:

```bash
SKILL_VEIL_RULES_SIGNING_KEY=keys/skill-veil-rules-2026.ed25519.priv.pem \
  scripts/build-manifest.sh v0.1.0-rehearsal && \
  scripts/sign-manifest.sh && \
  scripts/build-tarball.sh v0.1.0-rehearsal

# Verify against the committed public key.
openssl pkeyutl -verify \
  -pubin -inkey keys/skill-veil-rules-2026.ed25519.pub.pem \
  -rawin -in manifest.json \
  -sigfile <(base64 -d < manifest.json.sig)
```

### Required GitHub repo secret

`release.yml` reads the private signing key from the
`SKILL_VEIL_RULES_SIGNING_KEY` GitHub Actions secret. Set it once
when bootstrapping the repo or rotating keys:

```bash
gh secret set SKILL_VEIL_RULES_SIGNING_KEY \
  --repo seifreed/skill-veil-rules \
  < keys/<active-keyset>.ed25519.priv.pem
```

The secret value is the entire PKCS#8 PEM body (from `-----BEGIN
PRIVATE KEY-----` to `-----END PRIVATE KEY-----` inclusive).

## Key custody

### Generating a new keypair

```bash
scripts/generate-keypair.sh keys/skill-veil-rules-<year>
```

Produces:

| File | Contents | Committed? |
|------|----------|------------|
| `<prefix>.ed25519.priv.pem` | PKCS#8 PEM private key, mode 600 | **NEVER** |
| `<prefix>.ed25519.pub.pem` | SPKI PEM public key | yes |
| `<prefix>.ed25519.pub.raw` | Raw 32 bytes | yes |
| `<prefix>.ed25519.pub.b64` | base64 of raw bytes (for `KEYS.md`) | yes |

### Adopting a new key

1. Add the base64 line from `<prefix>.ed25519.pub.b64` to `KEYS.md`
   under `## Active keys`.
2. Embed the raw 32 bytes from `<prefix>.ed25519.pub.raw` in the
   `skill-veil` binary at
   `crates/skill-veil-cli/src/init/keys.rs` and ship a new
   `skill-veil` release that recognises the new key. Until that
   release lands, `init` cannot verify releases signed by the new
   key — adopt-then-rotate, never rotate-then-adopt.
3. Paste the contents of `<prefix>.ed25519.priv.pem` into the
   GitHub Actions secret named `SKILL_VEIL_RULES_SIGNING_KEY`.
4. Securely back up `<prefix>.ed25519.priv.pem` (offline password
   manager, hardware-backed keystore) and then delete it from disk.

### Retiring a key

Move the active entry to `## Retired keys` in `KEYS.md` with the
revocation date and the SHA-256 of the last release that key signed.
Do NOT remove the key from the embedded set in `skill-veil` until
every consumer has had time to upgrade past the last release that
trusted it (otherwise `init` fails for pinned consumers).

## Local repository hygiene (no shared `.gitignore`)

This repo intentionally **does not** ship a `.gitignore`. Every
contributor MUST set up local exclusions before staging anything:

```bash
cat > .git/info/exclude <<'EOF'
# Build artefacts
dist/
*.tar.gz
manifest.json
manifest.json.sig

# Local secrets — must NEVER be committed under any circumstance.
*.ed25519.priv*
keys/*.priv.pem
keys/private/

# OS noise
.DS_Store
Thumbs.db

# Claude Code auto-memory snippets (per-developer state)
**/CLAUDE.md
EOF
```

Critical rule: **never `git add` anything matching `keys/*.priv.pem`
or `*.ed25519.priv.*`.** A leaked private signing key means immediate
key rotation, an emergency `skill-veil` release, and a re-sign of
every still-supported `skill-veil-rules` release with the new key.

## Validation gates (`.github/workflows/validate.yml`)

Every PR triggers:

1. **Deterministic manifest** — runs `build-manifest.sh v0.0.0-ci`
   twice and asserts the JSON (modulo the `generated_at` timestamp)
   is byte-identical. Catches any non-deterministic ordering or
   environment-dependent hashing.
2. **Public key sanity** — confirms the active public key files
   exist (PEM + base64).
3. **Private-key leak guard** — fails the PR if any
   `*.ed25519.priv.*` file is in `git ls-files`. Defence in depth
   above the per-developer local exclude.

If any of these fail, fix the root cause; do not bypass.

## Coordination with `skill-veil`

The `skill-veil` binary embeds two things from this repo:

1. **A snapshot of the canonical official packs** at
   `crates/skill-veil-core/resources/official/{core,behavioral}.yaml`,
   `include_str!`'d at build time so `skill-veil scan` works without
   a prior `init`. When a meaningful update lands here, mirror it
   into the scanner repo as part of the next `skill-veil` release.
2. **The trusted public verification keys** at
   `crates/skill-veil-cli/src/init/keys.rs`. Adding a new active key
   here requires a paired PR in `skill-veil`.

Both sync points are documented in
[`skill-veil/AGENTS.md`](https://github.com/seifreed/skill-veil/blob/main/AGENTS.md)
and [`skill-veil/docs/release-process.md`](https://github.com/seifreed/skill-veil/blob/main/docs/release-process.md).
