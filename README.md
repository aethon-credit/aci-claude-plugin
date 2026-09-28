# ACI Risk Indicators for Claude

A Claude plugin for the Aethon Credit Intelligence connector. It declares the connector (`https://mcp.aethoncredit.com/mcp`) and adds the `aci-risk-indicators` skill, which tells Claude how to read ACI Risk Indicators: which tool to call at each plan, and to report only the fields the tools return.

## Install

**Claude (web, desktop and mobile)**
- As a custom connector: Settings → Connectors → Add custom connector, with the URL `https://mcp.aethoncredit.com/mcp`.
- From the connector directory: listing pending — this will be updated here once ACI is live in the directory.

**Claude Code**
- The connector: `claude mcp add --transport http aethon-credit-intelligence https://mcp.aethoncredit.com/mcp`
- The plugin, with the skill: marketplace listing pending — this will be updated here once the plugin is published.

No sign-in is needed to connect. The first time Claude calls a tool that needs an account, the user is asked to sign in with their Aethon Credit Intelligence account.

## What each plan sees

| Tool | No sign-in | Sandbox | Analyst | Professional | Enterprise |
|---|---|---|---|---|---|
| `list_modules` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `search_providers` | name, module and risk band | name, module and risk band | name, module and risk band | ✓ | ✓ |
| `get_risk_score` | sign-in | — | — | ✓ | ✓ |
| `get_provider_detail` | sign-in | — | — | ✓ | ✓ |
| `compare_providers` | sign-in | — | — | ✓ | ✓ |
| `assess_portfolio_risk` | sign-in | — | — | ✓ | ✓ |
| `resolve_exposures` | sign-in | — | — | ✓ | ✓ |

"sign-in" means calling the tool starts the sign-in; "—" means the tool returns a refusal that names the plan it needs. Plans and prices: https://aethoncredit.com/pricing.

## Links

- Plans: https://aethoncredit.com/pricing
- Developers: https://aethoncredit.com/developers
- Connector privacy policy: https://aethoncredit.com/privacy/mcp
- Methodology: https://aethoncredit.com/methodology

---

ACI Framework v1.0 · aethoncredit.com · Quantitative risk analytics outputs for independent analysis
