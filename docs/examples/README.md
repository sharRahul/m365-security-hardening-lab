# Example Outputs

This folder contains synthetic sample outputs so you can see what the scripts produce before running anything against a tenant.

Every value here is fabricated. Tenant IDs, object IDs, and names are placeholders, and scores are invented for illustration. Nothing in this folder comes from a real tenant.

| File | Produced by | What it shows |
| --- | --- | --- |
| [`baseline-capture-summary-sample.json`](baseline-capture-summary-sample.json) | `scripts/Export-M365Baseline.ps1` | The `BaselineCaptureSummary.json` file written at the end of a baseline export, including graceful skips for unlicensed features. |
| [`conditional-access-policies-sample.json`](conditional-access-policies-sample.json) | `scripts/Export-M365Baseline.ps1` | A redacted `ConditionalAccessPolicies.json` capture with one report-only lab policy. |
| [`secure-score-comparison-sample.md`](secure-score-comparison-sample.md) | `scripts/Get-M365SecureScore.ps1` | The console summary comparing the current Secure Score with a saved baseline. |

Real exports can contain user principal names, IP addresses, and policy identifiers. Redact them before sharing evidence outside your lab.
