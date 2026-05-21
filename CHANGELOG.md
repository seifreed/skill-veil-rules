# Changelog

All notable changes to the rule packs are recorded here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `taint/taint.yaml` — the internal source→sink exfiltration pack
  (`ARTIFACT_TAINT_*`). Previously lived only in
  `skill-veil-core/src/taint_rules.yaml`; this repo is now its
  canonical source. It uses a distinct schema (`family`/`source`/`sink`,
  no `when:`) consumed by a bespoke loader in skill-veil, so it lives
  under `taint/` and is intentionally OUTSIDE the `official/` path that
  `rules validate` scans.
- Code-detector rule IDs registered as public API (no YAML rule body —
  implemented in `skill-veil-core`; their fixtures are the in-repo Rust
  contract tests, not rules-repo fixtures):
  - `SKILL_CRYPTO_WALLET_DRAINER_DROPPER` (2-of-3 composite)
  - `SKILL_C2_BEACON_DROPPER` (2-of-3 composite)
  - `LLM_CONSENSUS_PROMPT_INJECTION_SUSPECTED` (synthetic
    cross-provider-flip signal)

### Changed

- `official/core.yaml` and `official/behavioral.yaml` resynced to be
  byte-identical to the skill-veil embedded baseline. The embedded copy
  is the shipping truth (the binary `include_str!`s it and the
  regression corpus is calibrated against it); the previous repo copies
  had drifted in metadata/wording only (rule-id sets were already
  identical). A drift check in skill-veil now keeps the embedded mirror
  and this canonical source locked.
- PowerShell web request alias matching now uses token boundaries and
  covers `Invoke-RestMethod` / `irm` in the remote-exec and internal
  network rules.
- `SKILL_REMOTE_EXEC_CURL_BASH` now requires real `curl` and shell
  command tokens, avoiding hash-verification pipeline false positives.

## [v0.1.0] — 2026-05-09

### Added

- Initial split from the `skill-veil` monorepo. This release contains
  every rule, fixture, schema reference, and YARA pack that previously
  lived under `skill-veil/rules/` at the time of the cdd185f → 4fdbb09
  commit range, including:
  - 11 PromptIntel-derived behavioral rules
  - jailbreak refusal-suppression rule
  - PromptIntel-mapped tagging across the official packs
- Ed25519-signed `manifest.json` distribution model — see `KEYS.md`.
- Reproducible `scripts/build-manifest.sh`, `scripts/sign-manifest.sh`,
  and `scripts/build-tarball.sh`.
- GitHub Actions release workflow at `.github/workflows/release.yml`.

[Unreleased]: https://github.com/seifreed/skill-veil-rules/compare/v0.1.0...HEAD
[v0.1.0]: https://github.com/seifreed/skill-veil-rules/releases/tag/v0.1.0
