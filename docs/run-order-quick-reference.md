# Run Order and Safety Quick Reference

One page covering the safe sequence for the state-changing lab modules. Print it or keep it open while you work. The full detail lives in [`safe-execution-modes.md`](safe-execution-modes.md), [`step-by-step-lab-guide.md`](step-by-step-lab-guide.md), and [`rollback-procedures.md`](rollback-procedures.md).

## The sequence

Never skip a step. Each one exists because the following steps can lock people out.

| Step | Action | You are done when |
| --- | --- | --- |
| 1 | Confirm emergency access | Two break-glass accounts exist, credentials are stored securely, a sign-in has been tested, and the accounts are excluded from Conditional Access. |
| 2 | Export the baseline | `pwsh ./scripts/Export-M365Baseline.ps1` completes and `pwsh ./scripts/Get-M365SecureScore.ps1` has saved a score. Keep the output folder. |
| 3 | Preview with `-WhatIf` | The deployment script has been run with `-WhatIf` and the preview matches exactly what you intend to change, and nothing else. |
| 4 | Deploy to a pilot scope | Policies apply only to pilot users or groups (`-PilotUserIds` / `-PilotGroupIds`). No all-user scope. |
| 5 | Use report-only mode | Conditional Access policies run with `-ReportOnly`, and DLP policies stay in the default audit-only mode. |
| 6 | Review the results | Sign-in logs and report-only outcomes show the expected effect on pilot users and no effect on anyone else, including the break-glass accounts. |
| 7 | Enforce | Only now move policies to enforced or block mode, still pilot scoped. Keep an admin session open while you do it. |
| 8 | Test rollback | You have moved a policy back to report-only, confirmed access is restored, re-enabled it, and recorded the evidence. |

## Worked example: Conditional Access

```powershell
# Step 2: baseline
pwsh ./scripts/Export-M365Baseline.ps1
pwsh ./scripts/Get-M365SecureScore.ps1

# Step 3: preview only
pwsh ./scripts/Deploy-ConditionalAccessPolicies.ps1 `
  -BreakGlassUserIds @('<break-glass-object-id-1>', '<break-glass-object-id-2>') `
  -PilotGroupIds @('<pilot-group-object-id>') `
  -ReportOnly `
  -WhatIf

# Steps 4 and 5: pilot scope, report-only
pwsh ./scripts/Deploy-ConditionalAccessPolicies.ps1 `
  -BreakGlassUserIds @('<break-glass-object-id-1>', '<break-glass-object-id-2>') `
  -PilotGroupIds @('<pilot-group-object-id>') `
  -ReportOnly

# Step 6: review, then verify
pwsh ./scripts/Verify-M365Hardening.ps1
```

## Stop immediately if

- An emergency access account cannot sign in.
- A policy affects users outside the pilot scope.
- Administrator access is blocked.
- Verification output does not match what you intended.

If any of these happen, follow [`rollback-procedures.md`](rollback-procedures.md) before doing anything else.

## Cleanup reminders

- Move lab DLP policies back to audit-only, or remove them, when testing ends.
- Tear down the optional Sentinel workspace with `scripts/Remove-SentinelWorkspace.ps1` to stop ingestion charges. It previews by default and deletes only with `-ConfirmTeardown`.
