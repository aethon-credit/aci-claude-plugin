# Risk bands

Every ACI Risk Indicator falls in one of four risk bands. The ranges are indicator values, lower bounds inclusive:

| Band | Indicator value |
|---|---|
| LOW | 80–100 |
| MEDIUM | 60–79 |
| ELEVATED | 40–59 |
| HIGH | 0–39 |

- `risk_band` is returned with every indicator. Report it as returned: never derive a band from a value yourself, and never move a provider to a neighbouring band.
- A band can be returned without a value (a result below the Professional plan). Give the band only.
- A `risk_band` of null means the tool returned no band. Report that; never assign one.
- `hard_caps_applied` lists the hard caps the methodology applied. Report their names as returned, without explaining them.
