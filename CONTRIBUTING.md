# Contributing rules

Thanks for helping make `skill-veil` smarter at catching malicious
agent skills. This file covers the contract every rule must meet before
it lands in `official/`.

## Pack layout

```
official/<topic>.yaml          # rule pack
fixtures/<topic>.yaml          # paired positive/negative fixtures
```

Pack envelope (matches `schema/skill-veil-rule-pack-v1.yaml`):

```yaml
schema_version: skill-veil.dev/rules/v1alpha1
metadata:
  name: official-<topic>
  kind: official
  compatibility:
    - skill-veil.dev/rules/v1alpha1
rules:
  - id: UPPERCASE_SNAKE_CASE_ID
    category: remote_exec | supply_chain | credential_exposure | ...
    severity: low | medium | high | critical
    confidence: 0.0..1.0
    when: !regex
      pattern: "..."
    action: log | require_approval | block
    reason: "Human-readable, action-oriented sentence."
    enabled: true
    tags: [tag_one, tag_two]
```

## Mandatory checklist

A PR that does not satisfy every box gets sent back with a one-line
comment.

- [ ] **Stable ID.** Once a rule is in `official/`, its `id` is public
      API. Renames or removals require a deprecation cycle and an entry
      in `CHANGELOG.md`.
- [ ] **Positive fixture.** At least one fixture in
      `fixtures/<topic>.yaml` that exercises the rule and asserts
      `expect_match: true` plus the expected severity/action.
- [ ] **Negative fixture.** At least one fixture that looks superficially
      similar but should NOT match (`expect_match: false`). This pins
      the regex against false-positive regressions.
- [ ] **Reason field.** A single sentence explaining what the rule
      catches and why it matters. The `reason` is what shows up in scan
      reports — write for the operator, not the contributor.
- [ ] **Confidence rationale.** If you set `confidence` below `0.7`,
      include a one-line PR comment explaining the reasoning. We err on
      the side of high-confidence rules in `official/` and low-confidence
      experimental work in `community/`.
- [ ] **CHANGELOG entry.** Append `- ADD RULE_ID — short description`
      under the `Unreleased` section of `CHANGELOG.md`.
- [ ] **Local validation passes.**
      ```bash
      skill-veil rules validate --rules-dir official/
      skill-veil rules pack-info --rules-dir official/
      skill-veil rules test-pack --rules-dir official/ --fixtures fixtures/behavioral.yaml
      ```

## Promoting from `community/` to `official/`

Community packs are an explicit incubator. To promote a rule:

1. The rule has been in `community/` for at least one release cycle.
2. Provide a false-positive analysis: scan the
   [skill-veil benchmark corpus](https://github.com/seifreed/skill-veil/blob/main/benchmarks/corpus.yaml)
   and report how many benign packages matched.
3. Confirm `category`, `severity`, `action`, `confidence`, and `reason`
   in the PR description.
4. Move the rule (don't copy) and add fixtures under `fixtures/`.

## Releasing (maintainers)

See `README.md > Cutting a release`.

Releases are signed; the public verification key is committed to
`KEYS.md` and embedded in the `skill-veil` binary. Rotating the signing
key requires a paired PR in
[skill-veil](https://github.com/seifreed/skill-veil) updating the
embedded key.
