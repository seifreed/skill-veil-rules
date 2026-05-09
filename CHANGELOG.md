# Changelog

All notable changes to the rule packs are recorded here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
