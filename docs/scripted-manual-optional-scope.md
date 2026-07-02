# Scripted, Manual, and Optional Scope Matrix

This matrix separates what the lab scripts currently do from what the documentation asks an operator to verify manually. It prevents the lab from implying that every Microsoft 365 hardening activity is fully automated.

## Scope categories

| Category | Meaning |
| --- | --- |
| Scripted deployment | A repository script can create or update lab configuration. |
| Scripted verification | A repository script can collect read-only verification signals. |
| Manual verification | The operator must use the portal, an export, a screenshot, or another system of record. |
| Optional / licence-dependent | Useful module, but only applies when the tenant has the feature or licence. |

## Lab coverage matrix

| Area | Scripted deployment | Scripted verification | Manual verification | Optional / licence-dependent notes |
| --- | --- | --- | --- | --- |
| Baseline export | None | `scripts/Export-M365Baseline.ps1` | Review skipped captures and screenshots for unavailable workloads. | Captures degrade gracefully when a workload or licence is missing. |
| Microsoft Secure Score | None | `scripts/Get-M365SecureScore.ps1` | Review Secure Score recommended actions in the portal. | Secure Score control coverage varies by licence. |
| Conditional Access | `scripts/Deploy-ConditionalAccessPolicies.ps1` | `scripts/Verify-M365Hardening.ps1` | Confirm report-only results, pilot impact, break-glass exclusions, and sign-in log evidence. | Entra ID P1 or equivalent is required for Conditional Access. |
| Emergency access accounts | None | Name-based discovery in `Verify-M365Hardening.ps1` | Confirm two accounts exist, credentials are protected, sign-in works, and monitoring exists. | Manual sign-in evidence is required. |
| Privileged roles / PIM | None | Baseline export captures directory role assignments. | Review PIM eligibility, activation controls, approval, MFA, and permanent assignments. | PIM requires Entra ID P2 or Governance licensing. |
| Authentication methods | None | Baseline and verification scripts collect high-level policy and MFA registration signals where available. | Review registration campaign, phishing-resistant MFA, password protection, and break-glass handling. | Some authentication method features require Entra ID P1/P2. |
| Email protection | None | `Export-M365Baseline.ps1` and `Verify-M365Hardening.ps1` collect EOP/Defender policy signals where cmdlets are available. | Review anti-phishing impersonation scope, Safe Links, Safe Attachments, DKIM, external tagging, and message trace tests. | Defender for Office 365 features need the relevant licence. |
| Endpoint compliance | None | `Export-M365Baseline.ps1` and `Verify-M365Hardening.ps1` collect Intune compliance and managed-device signals where available. | Confirm endpoint baseline assignment, Defender onboarding, ASR audit/block mode, and device timeline evidence. | Intune and Defender for Endpoint licensing may be required. |
| Purview DLP | `scripts/Deploy-PurviewDLP.ps1` | `scripts/Verify-M365Hardening.ps1` checks DLP policy presence when compliance cmdlets are loaded. | Review DLP match evidence, false positives, incident queue, and policy mode before enforcement. | DLP location coverage depends on compliance licensing. |
| Sensitivity labels | None | Baseline and verification scripts collect labels where compliance cmdlets are available. | Confirm label taxonomy, publication policy, user experience, and sample labelled files. | Advanced labelling depends on Purview licensing. |
| SharePoint and OneDrive external sharing | None | Not currently scripted. | Review tenant and site sharing settings, guest links, anonymous links, domain allow/block lists, and sample evidence. | Identified backlog item for future verification script coverage. |
| Unified audit logging | None | `Verify-M365Hardening.ps1` checks Unified Audit Log status when Exchange cmdlets are available. | Confirm audit search works and retention meets the lab objective. | Audit retention and advanced events vary by licence. |
| Defender portal incidents | None | Verification script records manual checks. | Review alert queue, incidents, classifications, and response evidence. | Defender XDR availability varies by licence. |
| Sentinel workspace | `scripts/Deploy-SentinelWorkspace.ps1` | `scripts/Verify-M365Hardening.ps1` checks lab-named workspaces when Az modules are available. | Confirm connector health, ingestion, analytics rules, incident creation, and teardown. | Azure subscription and consumption charges apply. |
| Sentinel teardown | `scripts/Remove-SentinelWorkspace.ps1` | Sandbox tests validate safety behaviour. | Confirm workspace, rules, connectors, and cost-bearing resources are removed when the lab ends. | Teardown still needs operator review in Azure. |
| Insider Risk Management | None | None | Document as not in scope unless licensed and approved for the lab. | Highly licence- and policy-dependent. |
| Retention and records management | None | Partial baseline signals where available. | Review retention labels, policies, audit retention, and legal hold assumptions. | Depends on Purview licensing and organisational requirements. |

## Operator rule

Do not mark a lab phase complete just because a script ran successfully. Mark it complete only when:

1. The scripted action or scripted verification completed.
2. Any `Skipped`, `NotConnected`, `Warning`, or `Manual` result has been reviewed.
3. Required manual evidence has been captured.
4. Licence limitations are documented.
5. Known gaps have an owner, date, and remediation or risk decision.

## Recommended evidence references

Use the evidence pack folders defined in `docs/lab-architecture.md`:

```text
evidence/
├── 01-baseline/
├── 02-identity-and-access/
├── 03-email-security/
├── 04-endpoint-security/
├── 05-data-protection/
├── 06-logging-and-monitoring/
├── 07-verification-script-output/
└── 08-rollback-test/
```