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
| Verification | Partial | `scripts/Verify-M365Hardening.ps1` automates selected identity and tenant checks; email, endpoint, Purview, and monitoring evidence still require manual review. |
| Purview DLP deployment | Working starter | Creates or updates starter lab DLP policies; validate in audit-only mode first. |
| Sentinel deployment | Working starter | Creates a workspace, attempts data connectors, deploys starter analytics rules, and no longer prints workspace shared keys. Review cost while the workspace is running. |
| Sentinel teardown | Working | `scripts/Remove-SentinelWorkspace.ps1` previews by default, deletes only with `-ConfirmTeardown`, and refuses to target workspaces without `lab` in the name. |
| CI | Partial | GitHub Actions runs PSScriptAnalyzer. Pester tests and dry-run validation are still missing. |

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

1. Add Pester tests for script parameter validation and `-WhatIf` behaviour.
2. Expand `Verify-M365Hardening.ps1` coverage for email, endpoint, Purview, and monitoring checks.
3. Add a permissions matrix for every script.
4. Add synthetic example outputs for evidence packs.

## Completed backlog items

- Link `docs/safe-execution-modes.md` from the README. Done: the README now carries a docs index and an early safety callout.
- Add a Sentinel cleanup or teardown script. Done: `scripts/Remove-SentinelWorkspace.ps1`, documented in the lab guide closeout section.
