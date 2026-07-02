# Identity Module Evidence Walkthrough

This walkthrough describes the evidence to capture for the identity and access phase of the lab. It replaces the need for repository screenshots by telling contributors exactly what screenshots or exports to capture in their own tenant.

## Before you start

Complete the safe sequence first:

1. Confirm two emergency access accounts exist.
2. Test both emergency access accounts.
3. Capture baseline exports.
4. Run the Conditional Access script with `-WhatIf`.
5. Deploy to a pilot user or group only.
6. Use `-ReportOnly` before enforcing.
7. Review sign-in results.
8. Test rollback.

## Evidence folder

Save identity evidence under:

```text
evidence/02-identity-and-access/
```

## Evidence capture checklist

| Evidence | Source | Capture method | What it proves |
| --- | --- | --- | --- |
| Emergency access accounts | Entra admin centre | Screenshot or user export | Two recovery accounts exist and are enabled. |
| Emergency access test | Sign-in logs | Screenshot or CSV export | Both accounts can sign in successfully. |
| CA policy preview | PowerShell output | Save terminal output | `-WhatIf` was run before creating policies. |
| CA policy scope | Entra Conditional Access policy | Screenshot or Graph export | Policies target pilot users/groups and exclude break-glass accounts. |
| Report-only result | Sign-in logs / CA insights | Screenshot or CSV export | Policy effect is understood before enforcement. |
| Legacy authentication block | CA policy and sign-in log test | Screenshot/export | Legacy clients are blocked or tested where safe. |
| Admin protection | CA policy or role-targeted policy | Screenshot/export | Privileged access requires stronger controls. |
| MFA registration | Graph report | CSV export | Pilot users and admins are MFA capable/registered. |
| Privileged role review | Entra roles/PIM | CSV/screenshot | Privileged roles are known, justified, and reviewed. |
| Rollback test | Policy state and sign-in test | Screenshot/export | A risky access-control change can be reverted. |

## Suggested commands

Run the baseline and score capture:

```powershell
pwsh ./scripts/Export-M365Baseline.ps1
pwsh ./scripts/Get-M365SecureScore.ps1
```

Preview Conditional Access changes:

```powershell
pwsh ./scripts/Deploy-ConditionalAccessPolicies.ps1 `
  -BreakGlassUserIds @('<break-glass-object-id-1>', '<break-glass-object-id-2>') `
  -PilotGroupIds @('<pilot-group-object-id>') `
  -ReportOnly `
  -WhatIf
```

Deploy report-only policies to the pilot scope:

```powershell
pwsh ./scripts/Deploy-ConditionalAccessPolicies.ps1 `
  -BreakGlassUserIds @('<break-glass-object-id-1>', '<break-glass-object-id-2>') `
  -PilotGroupIds @('<pilot-group-object-id>') `
  -ReportOnly
```

Run verification:

```powershell
pwsh ./scripts/Verify-M365Hardening.ps1 `
  -ExportPath ./evidence/07-verification-script-output/m365-hardening-checks.csv
```

## Screenshot standard

For each screenshot:

- Show the tenant portal area or command output title.
- Show the setting name and current state.
- Include scope, included users/groups, and excluded users/groups where relevant.
- Redact tenant IDs, user names, IP addresses, and sensitive identifiers if evidence will be shared externally.
- Record the capture date in the evidence index.

## Identity closeout questions

Before moving to email, endpoint, data protection, or monitoring modules, confirm:

1. Are both emergency access accounts usable and excluded from normal CA policies?
2. Are policies still pilot-scoped?
3. Has report-only evidence been reviewed?
4. Are any expected users unexpectedly affected?
5. Are privileged role assignments documented?
6. Are MFA registration gaps assigned to an owner?
7. Has rollback been tested and recorded?

## Common identity evidence gaps

- Conditional Access screenshots omit exclusions, so break-glass protection cannot be proven.
- Report-only results are not captured before enforcement.
- MFA registration export is captured before pilot users complete registration.
- Privileged role review lists roles but does not record business justification.
- Rollback is documented as a plan but not actually tested.