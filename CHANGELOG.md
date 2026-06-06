# Changelog

All notable changes to the rule packs are recorded here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `official/behavioral.yaml` — `OFFICIAL_REMOTE_CONFIG_FETCH_OVERRIDE`
  (high / require_approval): catches a skill instructing the agent to fetch
  agent-config / tool-call overrides from a remote URL at runtime using
  neutral verbs (`access`/`load`/`get`) and config-file resource names
  (`agent-config.json`, `tool_call_overrides`, `overrides.json`) that evade
  the keyword-anchored `OFFICIAL_PROMPT_INJECT_REMOTE_INSTRUCTION_FETCH`. The
  resource anchor is override-specific so benign links to `config.json` /
  `settings.json` do not match.

### Fixed

- `official/behavioral.yaml` — `OFFICIAL_REMOTE_FETCH_EXEC_POLYGLOT`
  fetch-side alternation now covers the modern Python HTTP clients
  `httpx` (`httpx.get/post/put/patch/delete/request/stream/Client/AsyncClient(`)
  and `aiohttp` (`aiohttp.ClientSession(` / `aiohttp.request(`). Previously
  only `requests.get(` / `urllib.request.urlopen(` were matched, so a
  `httpx.get(url).text` → `exec(...)` or `aiohttp.ClientSession()` →
  `exec(await r.text())` download-and-run cradle evaded the rule even
  though the same libraries were already covered by the SSRF and
  secret-exfil egress vocabularies. Positive fixtures added for both
  clients plus a benign-httpx negative.
- `official/core.yaml` — `SKILL_REMOTE_EXEC_CURL_BASH` now also matches
  Bash process substitution `bash <(curl …)` and command substitution
  `bash -c "$(curl …)"` / `eval "$(curl …)"`, not only the `curl … | sh`
  pipe form. `SKILL_REMOTE_EXEC_POWERSHELL_IEX` now also matches the
  reverse-order download cradle `iex (irm …)` / `iex(iwr …)`, not only
  `irm … | iex`.
- `official/behavioral.yaml` — `OFFICIAL_DESTRUCTIVE_COMMAND_NARRATIVE`
  now matches the `rm -fr` flag-order swap (was `-rf` only).
- `official/behavioral.yaml` — `OFFICIAL_PROMPT_INJECT_REMOTE_INSTRUCTION_FETCH`
  verb group is now word-bounded (`\b(?:fetch|read|run|…)\b`). The bare
  `read` previously matched inside `ready`/`readme`/`thread`, so a phrase
  like "ready handles. see dlazy.com … README.md" tripped a critical
  block. Across the labelled corpus this cut benign matches 180 → 33
  (−147) with zero change to the 45 malicious matches.
- `official/core.yaml` — `SKILL_CHINESE_AUTO_TRIGGER` no longer fires on
  the bare phrase 无需手动 ("no manual … needed"), which is benign UX copy
  (无需手动配置/安装/复制粘贴). It now requires a confirmation/approval
  word adjacent (无需手动确认/审批/授权 …); the standalone bypass terms
  (不要等用户确认, 立即自动执行 …) are unchanged. An OpenAI+Grok review of
  the labelled corpus confirmed 无需手动 drove 207 benign matches vs 28
  malicious; the change cuts benign→malicious false positives from 27.9%
  to 21.5% with negligible true-positive loss.

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
- `taxonomy_tags:` on `official/core.yaml` and `official/behavioral.yaml`
  rules — the named threat-taxonomy vocabulary (`memory_poisoning`,
  `rogue_agent`, `excessive_agency`, `output_handling`, `trigger_abuse`,
  `system_prompt_leakage`). Orthogonal to `category`: surfaced in
  skill-veil's JSON/SARIF output (`properties.tags`), never feeds verdict
  scoring. Requires a skill-veil binary that understands the field
  (the `Rule` schema is `deny_unknown_fields`), so an older binary will
  reject a pack carrying these tags — release the skill-veil binary that
  added `TaxonomyTag` before tagging the rules release that ships them.

### Fixed

- `base/obfuscation.yaml` — `SKILL_OBFUSCATION_BASE64` now matches the
  GNU long flag `base64 --decode` in addition to `-d`/`-D`. Previously
  `base64 --decode payload.b64 | bash` (long flag + intervening filename)
  evaded every base64 obfuscation rule: the pipe-adjacent rules require
  the flag glued to `|`, and this medium safety-net only knew the short
  flag. Added positive + negative smoke fixtures.

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
- `OFFICIAL_REMOTE_FETCH_EXEC_POLYGLOT` now requires a token-bounded
  PowerShell `iex` sink instead of matching `iexplore.exe`.
- Base64 pipe-exec rules now require real `base64` and shell command
  tokens, avoiding `shasum` verification pipeline false positives.

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
