# Safe Execution Modes

This repository is intended for lab and educational use. Run changes in a dedicated non-production tenant unless your organisation has approved a formal change plan.

## Conditional Access deployment

`Deploy-ConditionalAccessPolicies.ps1` is pilot-scoped by default.

Required safe inputs:

- `-BreakGlassUserIds`: at least two emergency access account object IDs.
- `-PilotUserIds` or `-PilotGroupIds`: the test users or groups that should receive the lab policies.
- `-ReportOnly`: recommended for the first deployment pass.
- `-WhatIf`: recommended before creating any policy.

The script will stop if you do not provide a pilot user or group, unless you explicitly use `-AllUsersScope`.

Use `-AllUsersScope` only in a dedicated lab tenant after emergency access sign-in has been tested and report-only results have been reviewed.

## Recommended order

1. Export the baseline.
2. Confirm emergency access accounts work.
3. Run the Conditional Access script with `-WhatIf`.
4. Run in report-only mode for the pilot scope.
5. Review sign-in results.
6. Move to enforcement only after validation.
7. Run verification and record output.
8. Test rollback.

## Stop conditions

Stop and roll back if:

- Emergency access cannot sign in.
- The wrong users or groups are included.
- A policy blocks expected administrator access.
- Verification output does not match the intended state.
- You cannot identify the owner or purpose of a setting.

## Evidence to keep

- Baseline export.
- Policy scope and state.
- Emergency access test evidence.
- Report-only results.
- Verification output.
- Rollback test notes.
