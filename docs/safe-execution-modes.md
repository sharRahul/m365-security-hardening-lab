# Safe Execution Modes

This repository is intended for lab and educational use. Run changes in a dedicated non-production tenant unless your organisation has approved a formal change plan.

## Standard safe sequence

Use this sequence for all state-changing lab modules:

1. Confirm two emergency access accounts exist.
2. Test both emergency access accounts.
3. Export the baseline.
4. Run the deployment script in preview mode where supported.
5. Deploy only to pilot users or pilot groups.
6. Use report-only or audit-only mode first.
7. Review results and supporting manual evidence.
8. Move to enforcement only after validation.
9. Test rollback.
10. Save evidence and document known gaps.

Emergency access validation comes before baseline capture because recovery access must be proven before any access-control work begins.

## Conditional Access deployment

`Deploy-ConditionalAccessPolicies.ps1` is pilot-scoped by default.

Required safe inputs:

- `-BreakGlassUserIds`: at least two emergency access account object IDs.
- `-PilotUserIds` or `-PilotGroupIds`: the test users or groups that should receive the lab policies.
- `-ReportOnly`: recommended for the first deployment pass.
- `-WhatIf`: recommended before creating any policy.

The script will stop if you do not provide a pilot user or group, unless you explicitly use `-AllUsersScope`.

Use `-AllUsersScope` only in a dedicated lab tenant after emergency access sign-in has been tested and report-only results have been reviewed.

## Purview DLP deployment

`Deploy-PurviewDLP.ps1` creates or updates lab DLP policies in audit-only mode by default. Keep the default audit-only mode until matches, false positives, and user impact have been reviewed with safe test data.

## Sentinel deployment

`Deploy-SentinelWorkspace.ps1` creates Azure resources and can incur cost. Use a lab subscription or lab-only resource group, preview first, capture connector and rule evidence, and tear down the workspace when the lab ends.

See [`sentinel-cost-and-teardown.md`](sentinel-cost-and-teardown.md) for cost and cleanup guidance.

## Stop conditions

Stop and roll back if:

- Emergency access cannot sign in.
- The wrong users or groups are included.
- A policy blocks expected administrator access.
- Verification output does not match the intended state.
- You cannot identify the owner or purpose of a setting.
- Azure cost or Sentinel ingestion behaviour is unclear.

## Evidence to keep

- Emergency access account existence and sign-in evidence.
- Baseline export.
- Preview output.
- Policy scope and state.
- Report-only or audit-only results.
- Verification output.
- Manual evidence for checks that scripts intentionally cannot automate.
- Rollback test notes.
- Sentinel teardown evidence where the optional Sentinel module was used.

## Documentation map

| Need | Document |
| --- | --- |
| One-page safe order | [`run-order-quick-reference.md`](run-order-quick-reference.md) |
| Scripted/manual/optional boundaries | [`scripted-manual-optional-scope.md`](scripted-manual-optional-scope.md) |
| Licence limitations | [`licensing-and-feature-limitations.md`](licensing-and-feature-limitations.md) |
| Identity screenshots and exports | [`identity-module-evidence-walkthrough.md`](identity-module-evidence-walkthrough.md) |
| Rollback procedures | [`rollback-procedures.md`](rollback-procedures.md) |
| Sentinel cost and cleanup | [`sentinel-cost-and-teardown.md`](sentinel-cost-and-teardown.md) |