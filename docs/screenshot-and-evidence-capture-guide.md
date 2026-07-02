# Screenshot and Evidence Capture Guide

This guide explains how to capture usable screenshots and supporting exports for the Microsoft 365 Security Hardening Lab. It complements the identity-specific evidence checklist in `docs/identity-module-evidence-walkthrough.md` and applies across identity, email, endpoint, data protection, monitoring, and rollback phases.

## Core evidence rules

1. Capture enough context to prove the portal, workload, setting, scope, and date.
2. Prefer structured exports for large lists and use screenshots for settings that are difficult to export.
3. Redact tenant IDs, user names, device names, IP addresses, domains, message IDs, and client data before sharing outside the lab team.
4. Keep the raw unredacted version only in an approved internal evidence store if your organisation requires it.
5. Record who captured the evidence, when, from which tenant, and for which lab phase.
6. Link screenshots and exports to a verification result, change record, or lab step.

## Screenshot standard

A useful screenshot should include:

- Portal or blade name.
- Setting name and visible value.
- Scope, included users/groups, locations, workloads, or devices where relevant.
- Policy state such as enabled, report-only, audit-only, disabled, or enforced.
- Capture date in the file name or evidence index.
- Redaction where evidence leaves the trusted lab environment.

Avoid screenshots that show only a green tick, partial table, or isolated value without source context.

## File naming convention

```text
YYYY-MM-DD_PHASE_WORKLOAD_EVIDENCE-TYPE_OWNER_v1.ext
```

Examples:

```text
2026-07-02_02-identity_EntraID_CA-ReportOnlyResult_IAMOwner_v1.png
2026-07-02_03-email_Exchange_DKIMConfig_MailAdmin_v1.csv
2026-07-02_06-monitoring_Sentinel_ConnectorHealth_SecOps_v1.png
```

## Evidence by lab phase

| Phase | Screenshot or export examples | What it proves |
| --- | --- | --- |
| Baseline | Baseline export folder, Secure Score export, skipped workload notes. | Starting state and known limitations. |
| Identity | Emergency access accounts, CA policy scope, report-only results, MFA registration, privileged roles. | Access controls are pilot-scoped, recoverable, and reviewable. |
| Email | Anti-phishing policy, Safe Links/Safe Attachments status, DKIM, external sender tagging, message trace sample. | Mail protection settings are configured and testable. |
| Endpoint | Intune compliance policy, managed device list, Defender onboarding state, ASR audit/block status. | Endpoint controls are assigned and visible. |
| Data protection | DLP policy mode, sensitivity label publication, DLP match sample, exception or false-positive review. | Data controls exist and are reviewed before enforcement. |
| Monitoring | Unified Audit Log status, Defender incident queue, Sentinel workspace, connector health, analytics rules. | Monitoring sources and rules are available. |
| Rollback | Policy disabled/reverted state, rollback command output, follow-up sign-in or mail-flow test. | Risky changes can be undone safely. |

## Evidence index template

| Field | Example |
| --- | --- |
| Evidence ID | EVID-IDENTITY-001 |
| File name | 2026-07-02_02-identity_EntraID_CA-ReportOnlyResult_IAMOwner_v1.png |
| Lab phase | Identity and access |
| Workload | Entra ID |
| Setting or test | Conditional Access report-only result |
| Source | Entra admin centre / Sign-in logs |
| Captured by | IAM Owner |
| Capture date | 2026-07-02 |
| Related script output | m365-hardening-checks.csv |
| Result | Accepted / needs review / rejected |
| Notes | Redacted for external sharing. |

## Quality review checklist

Before marking evidence complete, confirm:

1. The screenshot or export maps to the lab step.
2. The tenant and workload are clear.
3. The setting value or test result is visible.
4. The scope is visible or documented.
5. The evidence is current for the lab run.
6. The evidence is protected and redacted where required.
7. Skipped or unavailable features have a licence limitation note.
8. Manual checks are not marked complete only because a script ran.

## Common evidence gaps

- Policy screenshots omit assignments or exclusions.
- Report-only or audit-only results are not captured before enforcement.
- CSV exports are saved without a date or owner.
- Licence limitations are treated as passes.
- Sentinel workspace evidence is captured but teardown evidence is missing.
- Rollback is documented as a plan but not tested.
- Evidence includes sensitive identifiers that should have been redacted.