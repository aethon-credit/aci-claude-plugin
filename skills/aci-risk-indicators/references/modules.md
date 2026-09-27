# Modules

ACI groups providers into modules. A tool's `module` field and `search_providers`' `module` input use the code; `list_modules` returns the code with its name, a description, and live counts. Quote counts from `list_modules`, never from this file.

| Code | Name |
|---|---|
| `btc` | BTC Collateral Lending |
| `fiat` | Treasury Preferred Shares |
| `stablecoin` | Stablecoin Yield |
| `infrastructure` | Infrastructure |
| `market_neutral` | Market Neutral |
| `venture` | Venture |
| `tokenised_rwa` | Tokenised RWA |
| `volatility` | Volatility |
| `digital_asset_etp` | Digital Asset ETP |

- `fiat` is the code for Treasury Preferred Shares. It has nothing to do with stablecoins; never describe it as fiat yield.
- Use the names as written here and as `list_modules` returns them.
