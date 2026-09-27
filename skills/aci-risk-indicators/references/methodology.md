# Methodology

The methodology is published at https://aethoncredit.com/methodology; every tool result links it in `methodology_url`. For anything beyond the fields below, point the user there. Do not summarise or explain the methodology yourself.

- **Framework.** ACI Framework v1.0. `get_risk_score` returns it in `methodology_version`.
- **Determinism.** Risk Indicator calculations are deterministic when the approved inputs, methodology version and configuration are held constant.
- **The fields, as returned:**
  - `score`: the indicator value, 0–100. See `bands.md` for the bands.
  - `criterion_scores`: per criterion, its `label`, its value (`score`), its `weight`, its `weighted_contribution` (rounded, so the contributions need not add up to the indicator value), `confidence`, `worst_case_applied`, `applicability` and `bucket`.
  - `hard_caps_applied`: the hard caps the methodology applied.
  - `confidence_level`: the confidence recorded with the indicator.
  - `last_certified`: the date recorded for the indicator's certification, or null.
  - `stress_classification`: a stored classification, where one exists.

Report each field as returned. Supply no reason, driver or cause for any value, band, cap or criterion.
