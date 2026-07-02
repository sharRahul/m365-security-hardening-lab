# Implementation Status

This document separates working lab capability from partial or planned areas and highlights safe execution expectations.

## Current working capabilities

| Area | Status | Notes |
| --- | --- | --- |
| Lab architecture | Working | `docs/lab-architecture.md` describes the target lab components and evidence outputs. |
| Deployment prerequisites | Working | Prerequisites are documented in `docs/deployment-prerequisites.md`. The older `docs/prerequisites.md` stub has been merged in and removed, and formatting has been cleaned up. |
| Documentation index | Working | The README links every document in `docs/`, with `docs/safe-execution-modes.md` linked first. |
| Step-by-step lab guide | Working | Provides baseline, identity, email, endpoint, data protection, monitoring, verification, and rollback phases. |
| Rollback procedures | Working | Covers administrator lockout recovery, Conditional Access rollback, email, endpoint, DLP, and monitoring rollback scenarios. |
| Baseline export | Working starter | `scripts/Export-M365Baseline.ps1` collects many baseline settings and skips unavailable workloads gracefully. |
| Secure Score export | Working starter | `scripts/Get-M365SecureScore.ps1` exports current Secure Score and compares with a saved baseline where available. |
| Conditional Access deployment | Updated safe default | `scripts/Deploy-ConditionalAccessPolicies.ps1` is pilot-scoped by default and stops unless pilot users/groups are provided or `-AllUsersScope` is explicitly used. |
| Safe execution guidance | Working | See `docs/safe-execution-modes.md`. |
| Verification | Working starter | `scripts/Verify-M365Hardening.ps1` automates read-only identity, tenant, email, endpoint, Purview, and monitoring checks where modules and sessions are available, and emits explicit manual verification lines where a check cannot be automated safely. |
| Purview DLP deployment | Working starter | Creates or updates starter lab DLP policies; validate in audit-only mode first. |
| Sentinel deployment | Working starter | Creates a workspace, attempts data connectors, deploys starter analytics rules, supports `-WhatIf` preview, and no longer prints workspace shared keys. Review cost while the workspace is running. |
| Sentinel teardown | Working | `scripts/Remove-SentinelWorkspace.ps1` previews by default, deletes only with `-ConfirmTeardown`, and refuses to target workspaces without `lab` in the name. |
| CI | Working | GitHub Actions runs PSScriptAnalyzer plus Pester tests covering parameter validation, `-WhatIf` behaviour, and safe defaults for the deploy and teardown scripts. Tests run against stub commands only and never touch a tenant. |

## Safe execution rule

Run all scripts in a dedicated non-production lab tenant unless your organisation has approved a formal change plan.

Conditional Access changes must follow this order:

1. Confirm two emergency access accounts exist and can sign in.
2. Export the baseline.
3. Run with `-WhatIf`.
4. Use pilot users or pilot groups.
5. Use report-only mode first.
6. Review results.
7. Enforce only after validation.
8. Test rollback.

## Priority backlog

1. Add a permissions matrix for every script.
2. Add synthetic example outputs for evidence packs.

## Completed backlog items

- Link `docs/safe-execution-modes.md` from the README. Done: the README now carries a docs index and an early safety callout.
- Add a Sentinel cleanup or teardown script. Done: `scripts/Remove-SentinelWorkspace.ps1`, documented in the lab guide closeout section.
- Expand `Verify-M365Hardening.ps1` coverage for email, endpoint, Purview, and monitoring. Done: all checks remain strictly read-only and non-automatable checks emit manual verification lines.
- Add Pester tests for script parameter validation and `-WhatIf` behaviour. Done: `tests/Scripts.Tests.ps1` runs in CI alongside PSScriptAnalyzer.
