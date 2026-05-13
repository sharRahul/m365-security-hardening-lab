# Rollback Procedures

This document explains how to safely undo Microsoft 365 hardening changes during the lab.

> Always test rollback in a lab tenant before applying similar controls in production. Keep an active administrator session open during high-risk access control changes.

## Rollback principles

- Prefer report-only and pilot mode before enforcement.
- Export or screenshot settings before changing them.
- Keep at least two emergency access accounts available.
- Roll back the smallest change necessary to restore access or functionality.
- Preserve evidence before changing the state again.
- Record who performed the rollback, when, why, and what was changed.

## Emergency administrator lockout recovery

Use when Conditional Access or role configuration prevents normal administrator sign-in.

### Immediate steps

1. Try signing in with `breakglass.one`.
2. If unavailable, try `breakglass.two`.
3. Keep the successful session open.
4. Navigate to Conditional Access policies.
5. Identify the most recent policy affecting administrator sign-in.
6. Change the policy from `On` to `Report-only` or exclude the affected administrator group.
7. Confirm standard administrator sign-in works again.
8. Record the incident and fix the policy design before re-enabling enforcement.

### Evidence to preserve

- Sign-in failure evidence.
- Conditional Access result showing the blocking policy.
- Before and after policy state.
- Recovery account used.
- Remediation ticket.

## Conditional Access rollback

| Scenario | Rollback action | Validation |
| --- | --- | --- |
| Pilot users blocked unexpectedly | Move policy to report-only or remove pilot group assignment | Test pilot user sign-in |
| Admin access blocked | Use emergency account and exclude admin break-glass group | Test admin sign-in |
| MFA requirement breaks app | Exclude specific app temporarily and investigate | Confirm app access and risk acceptance |
| Legacy auth block breaks known dependency | Revert to report-only and inventory dependency | Confirm sign-in logs and remediation plan |

### Recommended rollback record

| Field | Value |
| --- | --- |
| Policy name | `<policy-name>` |
| Original state | `<on/report-only/off>` |
| Rollback state | `<on/report-only/off>` |
| Reason | `<reason>` |
| Performed by | `<admin>` |
| Date/time | `<yyyy-mm-dd hh:mm>` |
| Validation result | `<result>` |
| Follow-up action | `<ticket/ref>` |

## Email security rollback

Use when email protection policies block expected mail flow or cause unacceptable business impact during lab testing.

### Rollback options

1. Remove pilot users from the policy assignment.
2. Move policy priority below the default policy.
3. Disable the test policy if required.
4. Revert specific Safe Links or Safe Attachments actions to monitor-only where available.
5. Restore previous anti-phishing threshold or impersonation settings.

### Validation

- Confirm test email delivery state.
- Review message trace.
- Confirm no unexpected quarantine remains.
- Preserve policy before and after screenshots.

## Endpoint security rollback

Use when endpoint policies cause test device instability or block required activity.

### Rollback options

1. Move ASR rules from block to audit mode.
2. Remove the test device from the assignment group.
3. Disable the specific endpoint security profile for the pilot group.
4. Restore previous Defender AV exclusion state only if documented and approved.
5. Sync the device and confirm the policy state updates.

### Validation

- Confirm device check-in.
- Confirm the affected action works again.
- Review Defender or Intune policy status.
- Record any security trade-off.

## DLP and sensitivity label rollback

Use when DLP or labels interrupt lab workflows or produce unexpected results.

### Rollback options

1. Move DLP policy to test mode.
2. Remove pilot users from policy scope.
3. Disable user notifications temporarily.
4. Adjust rule thresholds or conditions.
5. Unpublish a lab sensitivity label from pilot users if required.

### Validation

- Confirm policy match behaviour changes as expected.
- Confirm user can complete the test workflow.
- Preserve the DLP alert and before/after configuration.

## Monitoring and logging rollback

Monitoring changes should normally be additive. Rollback is usually needed only when alert volume becomes unmanageable or a connector causes cost or ingestion issues.

### Rollback options

1. Disable or reduce noisy analytic rules.
2. Change alert severity or suppression window.
3. Pause optional SIEM ingestion for non-critical lab sources.
4. Restore previous connector configuration.

### Validation

- Confirm alert volume returns to expected level.
- Confirm critical security events are still visible.
- Update detection tuning notes.

## Rollback test checklist

| Check | Complete | Evidence reference |
| --- | --- | --- |
| Emergency access account sign-in tested. |  |  |
| Conditional Access report-only rollback tested. |  |  |
| Pilot group removal tested. |  |  |
| Email policy assignment rollback tested. |  |  |
| Endpoint policy audit-mode rollback tested where in scope. |  |  |
| DLP test-mode rollback tested where in scope. |  |  |
| Verification performed after rollback. |  |  |
| Follow-up remediation action recorded. |  |  |

## When not to rollback immediately

Do not immediately rollback if:

- The control is working as intended and the issue is user education or expected enforcement.
- The affected user or device is suspected to be compromised and rollback would increase risk.
- Evidence must be preserved before changing state.
- An incident commander or senior approver has instructed containment to remain in place.

## Production caution

In production, rollback should be managed through change control, incident response, or emergency change procedures. This lab document is not a substitute for an approved production change process.
