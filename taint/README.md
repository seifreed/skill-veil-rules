# Taint rule pack

`taint.yaml` is the canonical source for skill-veil's source→sink
exfiltration rules (`ARTIFACT_TAINT_*`).

It is **not** a standard rule pack: entries use `family` / `source` /
`sink` (no `when:`) and are consumed by a bespoke loader in
`skill-veil-core` (`artifact_taint::taint_rules`), not the generic
`RuleEngine`. It therefore lives here, **outside `official/`**, so
`skill-veil rules validate` (which only scans `official/`) does not
choke on the non-standard schema.

skill-veil ships a byte-identical mirror at
`crates/skill-veil-core/src/taint_rules.yaml` (`include_str!`'d so
`scan` works before `init`). An env-gated drift check in skill-veil
keeps the two locked; this file is the source of truth.
