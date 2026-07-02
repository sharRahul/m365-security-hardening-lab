# Implementation Status

This document separates working lab capability from partial or planned areas and highlights safe execution expectations.

## Current working capabilities

| Area | Status | Notes |
| --- | --- | --- |
| Lab architecture | Working | `docs/lab-architecture.md` describes the target lab components and evidence outputs. |
| Deployment prerequisites | Working | Prerequisites are documented in `docs/deployment-prerequisites.md`. |
| Documentation index | Working | The README links every major document in `docs/`, with `docs/safe-execution-modes.md` linked first. |
| Safe execution guidance | Working | `docs/safe-execution-modes.md` and `docs/run-order-quick-reference.md` now use the same order: emergency access, baseline, preview, pilot, report-only/audit-only, review, enforce, rollback. |
| Scripted/manual/optional scope matrix | Working | `docs/scripted-manual-optional-scope.md` separates scripted deployment, scripted verification, manual verification, and licence-dependent areas. |
| Licensing and feature limitations | Working | `docs/licensing-and-feature-limitations.md` explains how to handle `Skipped`, `NotConnected`, `Manual`, empty, and licence-limited results. |
| Identity evidence walkthrough | Working | `docs/identity-module-evidence-walkthrough.md` defines the screenshots, exports, and command outputs to capture for the identity module. |
| Screenshot and evidence capture guide | Working | `docs/screenshot-and-evidence-capture-guide.md` defines screenshot standards and evidence capture rules across all lab phases. |
| Sentinel cost and teardown guidance | Working | `docs/sentinel-cost-and-teardown.md` documents cost guardrails, evidence, and teardown checks. |
| Permissions matrix | Working | `docs/permissions-matrix.md` maps each script to Graph scopes, roles, and licence prerequisites. |
| Example outputs | Working | `docs/examples/` holds synthetic baseline export and Secure Score comparison samples. |
| Run order quick reference | Working | `docs/run-order-quick-reference.md` chains the safe sequence on one page. |
| Community templates | Working | Issue templates and a pull request template with a safety checklist live under `.github/`. |
| Step-by-step lab guide | Working | Provides baseline, identity, email, endpoint, data protection, monitoring, verification, and rollback phases. |
| Rollback procedures | Working | Covers administrator lockout recovery, Conditional Access rollback, email, endpoint, DLP, and monitoring rollback scenarios. |
| Baseline export | Working starter | `scripts/Export-M365Baseline.ps1` collects many baseline settings and skips unavailable workloads gracefully. |
| Secure Score export | Working starter | `scripts/Get-M365SecureScore.ps1` exports current Secure Score and compares with a saved baseline where available. |
| Conditional Access deployment | Updated safe default | `scripts/Deploy-ConditionalAccessPolicies.ps1` is pilot-scoped by default and stops unless pilot users/groups are provided or `-AllUsersScope` is explicitly used. |
| Verification | Working starter | `scripts/Verify-M365Hardening.ps1` automates read-only identity, tenant, email, endpoint, Purview, and monitoring checks where modules and sessions are available, and emits explicit manual verification lines where a check cannot be automated safely. |
| Purview DLP deployment | Working starter | Creates or updates starter lab DLP policies; validate in audit-only mode first. |
| Sentinel deployment | Working starter | Creates a workspace, attempts data connectors, deploys starter analytics rules, supports preview mode, and no longer prints workspace shared keys. Review cost while the workspace is running. |
| Sentinel teardown | Working | `scripts/Remove-SentinelWorkspace.ps1` previews by default, deletes only with `-ConfirmTeardown`, and refuses to target workspaces without `lab` in the name. |
| CI | Working | GitHub Actions runs PSScriptAnalyzer plus Pester tests covering parameter validation, preview behaviour, and safe defaults for the deploy and teardown scripts. Tests run against stub commands only and never touch a tenant. |

## Safe execution rule

Run all scripts in a dedicated non-production lab tenant unless your organisation has approved a formal change plan.

State-changing changes must follow this order:

1. Confirm two emergency access accounts exist.
2. Test both emergency access accounts.
3. Export the baseline.
4. Run with preview mode where supported.
5. Use pilot users or pilot groups.
6. Use report-only or audit-only mode first.
7. Review results and manual evidence.
8. Enforce only after validation.
9. Test rollback.
10. Save evidence and document known gaps.

## Current documentation boundaries

The lab now clearly documents that:

- Some areas are scripted deployment, such as Conditional Access, starter DLP, and optional Sentinel.
- Some areas are scripted verification only, such as baseline export, Secure Score, and high-level verification checks.
- Some areas require manual evidence, such as emergency access sign-in, report-only review, PIM activation settings, external sharing settings, Defender portal incident review, and Sentinel connector health.
- Some areas are licence-dependent, such as Entra ID P2, Defender for Office 365, Intune, Defender for Endpoint, Purview, and Sentinel.

See [`scripted-manual-optional-scope.md`](scripted-manual-optional-scope.md), [`licensing-and-feature-limitations.md`](licensing-and-feature-limitations.md), and [`screenshot-and-evidence-capture-guide.md`](screenshot-and-evidence-capture-guide.md).

## Priority backlog

1. Add optional read-only checks for SharePoint and OneDrive external sharing settings to `Verify-M365Hardening.ps1`.
2. Add optional read-only PIM configuration checks where the tenant has Entra ID P2 or Governance licensing.
3. Add optional read-only sensitivity label publication checks where compliance cmdlets are available.
4. Add more synthetic example outputs for verification CSV, DLP policy output, Sentinel connector review, and rollback test notes.
5. Consider a configuration-file-driven policy definition format for lab Conditional Access and DLP examples.

## Completed backlog items

- Link `docs/safe-execution-modes.md` from the README.
- Add a Sentinel cleanup or teardown script: `scripts/Remove-SentinelWorkspace.ps1`.
- Expand `Verify-M365Hardening.ps1` coverage for email, endpoint, Purview, and monitoring.
- Add Pester tests for script parameter validation and preview behaviour.
- Add a permissions matrix for every script: `docs/permissions-matrix.md`.
- Add synthetic example outputs for evidence packs: `docs/examples/`.
- Add scripted/manual/optional scope matrix: `docs/scripted-manual-optional-scope.md`.
- Add licence and feature limitation guide: `docs/licensing-and-feature-limitations.md`.
- Add identity module evidence walkthrough: `docs/identity-module-evidence-walkthrough.md`.
- Add screenshot and evidence capture guide: `docs/screenshot-and-evidence-capture-guide.md`.
- Add Sentinel cost and teardown guidance: `docs/sentinel-cost-and-teardown.md`.