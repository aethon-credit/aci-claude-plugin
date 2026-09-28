---
name: aci-risk-indicators
description: Use when the user asks about Aethon Credit Intelligence (ACI) Risk Indicators for digital asset yield providers and products — which modules exist, which providers sit in a module or risk band, one provider's indicator or breakdown, a side-by-side comparison, a portfolio composite, positions matched by their identifiers to the providers behind them, or a summary of these outputs for a committee. Reports only the fields the ACI connector returns.
---

# ACI Risk Indicators

## What ACI is

> ACI Risk Indicators are model-derived quantitative analytics outputs produced under the ACI Framework v1.0 using defined inputs and publicly available data. Outputs are designed to support independent analysis within professional and institutional decision-making processes.

Every tool result carries this classification anchor in `classification_anchor`:

> ACI Framework v1.0 · aethoncredit.com · Quantitative risk analytics outputs for independent analysis

## The tools

The ACI connector (`https://mcp.aethoncredit.com/mcp`) has seven read-only tools.

| Tool | Inputs | What `data` holds |
|---|---|---|
| `list_modules` | none | per module: `code`, `name`, `description`, `provider_count`, `criteria_count` |
| `search_providers` | `query`, `module`, `risk_band`, `subtype`, `limit` (1–100, default 25) | per provider: `name`, `module`, `risk_band`; where the plan includes values, also `slug`, `score` and `subtype` |
| `get_risk_score` | `provider_slug` or `provider_name` | `provider_name`, `module`, `score`, `risk_band`, `hard_caps_applied`, `confidence_level`, `last_certified`, `methodology_version` |
| `get_provider_detail` | `provider_slug` | `provider_name`, `slug`, `module`, `subtype`, `score`, `risk_band`, `criterion_scores` (per criterion: `label`, `score`, `weight`, `weighted_contribution`, `confidence`, `worst_case_applied`, `applicability`, `bucket`), `hard_caps_applied`, `stress_classification`, `last_certified`, `evidence_summary` |
| `compare_providers` | `slugs` (2–5) | `providers` (each as in `get_provider_detail`) and `comparison_matrix` (`criteria`, `score`, `risk_band`) |
| `assess_portfolio_risk` | `allocations`: 2–20 positions of `provider_slug` and `weight`, each weight 0.01–1.0, summing to 1.0 ± 0.01 | `composite_score`, `risk_band`, `per_provider_scores`, `counterparty_concentration_pct`, `custody_concentration_pct`, `regulatory_mix_warning`, `elevated_warnings`, `stress_classification`, `notes` |
| `resolve_exposures` | `positions`: 1–200, each with `identifiers` (one or more of type `figi`, `ticker_mic`, `lei`, `chain_contract`, `provider_slug` or `dti`) and, optionally, `position_ref` and `module_hint`; `mapping_seq` (optional). An ISIN or a CUSIP refuses its position | `positions` in input order (each: `input_index`, `position_ref`, `outcome`, `reason_code`, `match`, `instrument`, `links`, `scored`, `candidates`), `mapping_seq`, `as_of`, `certification_basis`, `resolved_at`, `correlation_id` |

Every result also carries `disclosure`, `classification_anchor` and `methodology_url`. A result with an indicator value, a band or a breakdown adds `scope_note`. In the text, `score` is the indicator value: call it the ACI Risk Indicator, or the indicator value.

## Who sees what

The connector checks the user's plan on every call.

- No sign-in: list_modules, search_providers. The Professional plan adds get_risk_score, get_provider_detail, compare_providers, assess_portfolio_risk, resolve_exposures.
- Below the Professional plan, search_providers results show name, module and risk band only.
- Accounts on the Sandbox and Analyst plans see what a signed-out caller sees.
- A tool above the user's plan returns a refusal that names the plan it needs. When the user is not signed in, calling that tool starts the sign-in to their Aethon Credit Intelligence account.

## Workflows

Use a workflow only where the user's plan includes its tool.

### 1. First connection

When the user starts, tell them what they can see at their plan, from **Who sees what**. Signed out, that is the list of modules and a search with the risk band of each provider. Do not ask them to sign in up front: calling a tool that needs an account starts the sign-in when they ask for something it returns.

### 2. One provider

- Professional and above: call `get_risk_score` with the slug or the name. If nothing is found, call `search_providers` with the name as `query` and show the matches.
- Below Professional: call `search_providers` with the name as `query`, and give `name`, `module` and `risk_band` only.
- For the breakdown (Professional and above): call `get_provider_detail`.

### 3. Screening within a module

Call `list_modules` for the module codes, then `search_providers` with `module`, and `risk_band` if the user names one. Show the rows as returned, in the order returned.

### 4. Side-by-side comparison (Professional and above)

Call `compare_providers` with 2–5 slugs and lay out `comparison_matrix` as a table: one column per provider, one row per criterion, then the indicator value and the band. Name no provider as stronger, weaker or preferred, and order the columns as the user listed the providers.

### 5. Positions (Professional and above)

Call `resolve_exposures` with each position's identifiers as the user gave them, and `position_ref` if the user has one. Report the positions in the order returned, each with its `outcome`: for `resolved`, the provider from `scored`, with the indicator value and its band; for any other outcome, the `reason_code`. An identifier matches exactly or not at all, so never guess a match, and never supply an identifier the user did not give.

### 6. Summary for committee review

A structured summary of what the tools returned, and nothing else:

1. Provider, module, and the indicator value with its band (or the band only, if that is all the result shows).
2. Hard caps, as listed in `hard_caps_applied`.
3. `confidence_level`, `last_certified` and `methodology_version`, as returned.
4. For a breakdown: each criterion's label, value, weight and weighted contribution.
5. The `scope_note`, verbatim.
6. The classification anchor, as the last line.

The summary describes outputs. It proposes no decision, allocation or action.

No tool returns history, changes over time or a stress interpretation, so this skill offers none. `stress_classification` is reported as returned, without comment.

## Rules

- Report only the fields in `data`. The `scope_note` says ACI returned no reasons, drivers or explanations; supply none of your own.
- Weighted contributions are rounded per criterion, so they need not add up to the indicator value. Do not explain the difference.
- If a result shows the band only, give the band only. Never estimate or infer a value.
- Never propose an allocation, a transaction or any other action, and never describe one provider as better or worse than another.
- Report `last_certified` as returned. If it is null, say that no certification is recorded for the indicator.
- A portfolio composite is not an ACI Risk Indicator. When you show one, quote:

  > This portfolio assessment is a computed analytical output based on individual provider Risk Indicators. It is not a certified ACI Risk Indicator.

- If `risk_band` is null, report no band. Never assign one.
- Report a refusal as returned. If it names a plan, point the user to aethoncredit.com/pricing.
- Keep to the vocabulary in `references/language.md`.
- End every answer that shows ACI output with the classification anchor.

## Examples

Values are shown as `{{tokens}}`: the tools supply them.

**"Which ACI modules are there?"** → `list_modules`

```json
{
  "data": [
    { "code": "{{module_code}}", "name": "{{module_name}}", "description": "{{module_description}}", "provider_count": "{{provider_count}}", "criteria_count": "{{criteria_count}}" }
  ],
  "disclosure": "ACI Risk Indicators: quantitative analytics only. Not investment advice. Not a credit rating.",
  "classification_anchor": "ACI Framework v1.0 · aethoncredit.com · Quantitative risk analytics outputs for independent analysis",
  "methodology_url": "https://aethoncredit.com/methodology"
}
```

**"Which stablecoin yield providers have a MEDIUM band?"** → `search_providers` with `module: "stablecoin"`, `risk_band: "MEDIUM"`. Below Professional:

```json
{
  "data": [
    { "name": "{{provider_name}}", "module": "stablecoin", "risk_band": "MEDIUM" }
  ],
  "disclosure": "ACI Risk Indicators: quantitative analytics only. Not investment advice. Not a credit rating.",
  "classification_anchor": "ACI Framework v1.0 · aethoncredit.com · Quantitative risk analytics outputs for independent analysis",
  "methodology_url": "https://aethoncredit.com/methodology"
}
```

On Professional and above, each row adds `slug`, `score` and `subtype`.

**"What is the ACI Risk Indicator for {{provider_name}}?"** → `get_risk_score` (Professional and above)

```json
{
  "data": {
    "provider_name": "{{provider_name}}",
    "module": "{{module_code}}",
    "score": "{{indicator_value}}",
    "risk_band": "{{risk_band}}",
    "hard_caps_applied": [],
    "confidence_level": "{{confidence_level}}",
    "last_certified": "{{last_certified}}",
    "methodology_version": "{{methodology_version}}"
  },
  "scope_note": "This response contains only the fields in data. ACI returned no reasons, drivers or explanations for any score, band or criterion beyond those fields.",
  "disclosure": "ACI Risk Indicators: quantitative analytics only. Not investment advice. Not a credit rating.",
  "classification_anchor": "ACI Framework v1.0 · aethoncredit.com · Quantitative risk analytics outputs for independent analysis",
  "methodology_url": "https://aethoncredit.com/methodology"
}
```

**"Compare {{provider_a}} and {{provider_b}}."** → `compare_providers` (Professional and above). `data` holds `providers` and `comparison_matrix`:

```json
{
  "comparison_matrix": {
    "criteria": { "{{criterion_key}}": { "{{slug_a}}": { "label": "{{criterion_label}}", "score": "{{criterion_value}}", "weight": "{{criterion_weight}}", "weighted_contribution": "{{weighted_contribution}}" } } },
    "score": { "{{slug_a}}": "{{indicator_value_a}}", "{{slug_b}}": "{{indicator_value_b}}" },
    "risk_band": { "{{slug_a}}": "{{risk_band_a}}", "{{slug_b}}": "{{risk_band_b}}" }
  }
}
```

**"Assess an allocation: {{weight_a}} in {{provider_a}}, {{weight_b}} in {{provider_b}}."** → `assess_portfolio_risk` (Professional and above). `data` holds `composite_score`, `risk_band`, `per_provider_scores` (each: `provider_slug`, `provider_name`, `module`, `score`, `risk_band`, `weight`, `weighted_contribution`, `status`) and the portfolio fields in the tools table. Quote the composite note above when you show it.

**A tool above the user's plan**, e.g. `get_risk_score` on the Sandbox plan:

```text
FORBIDDEN: 'get_risk_score' is available on the Professional plan and above (current plan: Sandbox). See aethoncredit.com/pricing.
ACI Framework v1.0 · aethoncredit.com · Quantitative risk analytics outputs for independent analysis
```

## References

- `references/bands.md`: the four risk bands.
- `references/modules.md`: the module codes and names.
- `references/methodology.md`: what the methodology fields mean, and where the methodology is published.
- `references/language.md`: the vocabulary to use and to avoid.
