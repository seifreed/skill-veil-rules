# skill-veil-rules

Versioned, signed rule packs for [skill-veil](https://github.com/seifreed/skill-veil) —
the behavioral & supply-chain security analyzer for agent skills.

## What lives here

| Directory | Purpose |
|-----------|---------|
| `official/` | Curated default packs loaded by `skill-veil scan`. Stable rule IDs (treated as public API). |
| `community/` | Incubating / org-specific packs not enabled by default. |
| `base/` | Historical category-grouped packs (credentials, obfuscation, supply chain, ...). |
| `fixtures/` | Positive / negative test fixtures consumed by `skill-veil rules test-pack`. |
| `schema/` | Versioned schema reference for pack authors. |
| `yara/` | Optional YARA rules (consumed when `skill-veil` is built with `--features yara`). |

## Consuming the rules

End users do **not** clone this repo. The `skill-veil` binary downloads
the latest signed release into the user cache:

```bash
skill-veil init                  # latest stable release
skill-veil init --version v0.1.0 # pin to a specific release
skill-veil rules update          # alias for re-running init
skill-veil rules status          # show installed version + signature info
```

Rules are written to `~/.cache/skill-veil/rules/<version>/` and the
scanner picks them up automatically — no `--rules-dir` flag required.

## Verifying a release manually

Every release ships with three artefacts:

| Artefact | Purpose |
|----------|---------|
| `skill-veil-rules-<version>.tar.gz` | All rule files. |
| `manifest.json` | Per-file SHA-256 digests + version metadata. |
| `manifest.json.sig` | Detached Ed25519 signature over `manifest.json`. |

`skill-veil init` verifies the signature against an Ed25519 public key
embedded in the binary at compile time, then verifies each extracted
file's SHA-256 against the manifest. A tampered tarball thus surfaces as
either an invalid signature or a checksum mismatch — never as a silently
loaded bad rule.

To verify by hand, see [`KEYS.md`](KEYS.md).

## Authoring rules

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the full contributor
workflow. The short version:

1. Add the rule to the appropriate `official/<topic>.yaml` or
   `community/<pack-name>.yaml` file.
2. Add at least one **positive** and one **negative** fixture in
   `fixtures/<topic>.yaml`.
3. Run the validators (using a local skill-veil checkout or installed binary):
   ```bash
   skill-veil rules validate --rules-dir official/
   skill-veil rules pack-info --rules-dir official/
   skill-veil rules test-pack --rules-dir official/ --fixtures fixtures/behavioral.yaml
   ```
4. Append a one-line entry to [`CHANGELOG.md`](CHANGELOG.md).
5. Open a PR. Maintainers cut a new signed release once the PR lands.

## Cutting a release (maintainers only)

Releases are produced by the `release.yml` GitHub Actions workflow on a
tag push:

```bash
git tag v0.1.0
git push origin v0.1.0
```

The workflow:
1. Runs `scripts/build-manifest.sh v0.1.0` to compute SHA-256s.
2. Runs `scripts/sign-manifest.sh` (using the
   `SKILL_VEIL_RULES_SIGNING_KEY` secret).
3. Runs `scripts/build-tarball.sh v0.1.0` to package everything.
4. Uploads the tarball, manifest, and signature as release assets.

For a local rehearsal:

```bash
SKILL_VEIL_RULES_SIGNING_KEY=keys/skill-veil-rules-2026.ed25519.priv.pem \
  scripts/build-manifest.sh v0.1.0 && \
  scripts/sign-manifest.sh && \
  scripts/build-tarball.sh v0.1.0
```

## License

MIT — see [`LICENSE`](LICENSE).
