# Secure Score Comparison Sample

Synthetic console output from `scripts/Get-M365SecureScore.ps1` when a saved baseline exists. All scores are invented for illustration.

```text
Microsoft Graph already connected as labadmin@<tenant-name>.onmicrosoft.com.
Baseline comparison file: ./outputs/baseline-2026-01-15/SecureScore.json

Microsoft Secure Score summary

Category Score MaxScore Percentage Delta RecommendedActionCount
-------- ----- -------- ---------- ----- ----------------------
Overall  187.5   278.00      67.45 55.25                     14
Apps      41.0    62.00      66.13  4.00                      5
Data      18.0    30.00      60.00  0.00                      3
Device    52.5    90.00      58.33 12.25                      4
Identity 118.0   140.00      84.29 39.00                      2

Secure Score exported to ./outputs/SecureScore.json
```

How to read it:

- `Delta` is the change since the baseline export. Positive numbers mean the hardening work improved the score. A blank delta means no baseline file was found.
- `RecommendedActionCount` is the number of controls in that category not yet marked as implemented. Use it to prioritise the next lab module.
- The identity delta is usually the largest after Phase 2, because Conditional Access and MFA controls carry heavy score weight.

Note: the overall `Score` and `MaxScore` come from the tenant-level Secure Score record, while category rows are summed from individual control scores, so the category rows do not necessarily add up to the overall row.
