# Licensing and Feature Limitations

Microsoft 365 security features vary by tenant type, licence, region, and trial availability. This lab should work as a learning and evidence framework even when some modules are unavailable, but every limitation must be recorded in the evidence pack.

## How to use this guide

1. Confirm the tenant type and licence before running scripts.
2. Record expected unavailable features in the baseline notes.
3. Run scripts anyway where safe; they are designed to skip or warn when optional workloads are missing.
4. Do not treat `Skipped`, `NotConnected`, or empty output as success without a control-owner note.
5. Capture portal screenshots or manual exports where the script cannot collect evidence.

## Common licence-sensitive areas

| Area | Typical dependency | What may happen without it | Evidence action |
| --- | --- | --- | --- |
| Conditional Access | Entra ID P1 or equivalent | CA deployment and policy verification cannot be used meaningfully. | Record licence limitation and use Security Defaults or manual evidence if applicable. |
| Identity Protection and risk detections | Entra ID P2 | Risk detections, user risk, sign-in risk, and PIM-style evidence may be unavailable. | Record limitation and use sign-in logs, MFA registration, and manual review evidence. |
| Privileged Identity Management | Entra ID P2 or Governance | Eligible assignments, approval, and activation evidence may be missing. | Use directory role assignments plus manual privileged access review evidence. |
| Defender for Office 365 | Defender for Office 365 Plan 1/2 or E5-style bundle | Safe Links, Safe Attachments, campaign, and Explorer evidence may be unavailable. | Use EOP policy evidence and document advanced-email limitation. |
| Intune endpoint management | Intune or Microsoft 365 plans that include it | Compliance policy and managed device exports may be empty or fail. | Capture manual endpoint baseline evidence or mark endpoint module out of scope. |
| Defender for Endpoint | MDE Plan 1/2 or bundle | Device inventory, ASR evidence, vulnerability, and EDR alert evidence may be unavailable. | Record endpoint protection alternative and collect manual AV/EDR evidence. |
| Purview DLP | Depends on workload and compliance licence | DLP policies may be limited to certain workloads or unavailable. | Keep DLP in audit-only until validated and record covered workloads. |
| Sensitivity labels | Purview Information Protection licensing | Label policy, auto-labelling, or advanced protection may be unavailable. | Document manual classification process and available label evidence. |
| Audit retention | Licence-dependent retention duration | Older audit events may not be searchable. | Record retention limit and collect fresh evidence during the audit period. |
| Sentinel | Azure subscription and consumption billing | Workspace can incur ingestion and retention charges. | Use `Remove-SentinelWorkspace.ps1` after testing and record teardown evidence. |

## Tenant type notes

| Tenant type | Good for | Watch-outs |
| --- | --- | --- |
| Developer tenant | Learning, scripted walkthroughs, safe experimentation. | Some security/compliance features may be unavailable or inconsistent. |
| Trial tenant | Testing E5-style capabilities for a short period. | Trial expiry can change feature availability and evidence completeness. |
| Dedicated lab tenant | Best option for repeatable community use. | Still requires cost and identity governance discipline. |
| Production tenant | Only for approved change-controlled work. | Do not run state-changing scripts without formal approval, pilot scoping, rollback, and emergency access validation. |

## Recording licence limitations

Use this table in your evidence notes or gap register:

| Field | Example |
| --- | --- |
| Feature | Defender for Office 365 Safe Attachments |
| Expected evidence | Safe Attachments policy export and test message evidence |
| Result | Feature unavailable in current tenant |
| Impact | Email module cannot evidence advanced attachment detonation controls |
| Compensating evidence | EOP anti-malware policy export and mail-flow test |
| Owner | Security Administrator |
| Decision | Accepted for lab scope; not a production control claim |
| Review date | 2026-05-31 |

## Script result interpretation

| Result | Meaning | What to do |
| --- | --- | --- |
| `Pass` | The script found a signal that appears to meet the lab expectation. | Preserve output and supporting evidence. |
| `Info` | The script found data, but human review is needed. | Review the recommendation and capture manual context. |
| `Warning` | The setting exists but may be incomplete or risky. | Investigate and either remediate or record a limitation. |
| `Fail` | The expected control signal was missing or false. | Remediate before claiming the control is implemented. |
| `Skipped` | Required command, module, workload, or licence was unavailable. | Record why it was skipped and collect manual evidence if the area remains in scope. |
| `NotConnected` | The script did not have the required session. | Connect with least privilege and rerun if the check is in scope. |
| `Manual` | The script intentionally does not automate this check. | Capture the portal, export, ticket, or review evidence manually. |

## Do not over-claim

A lab tenant can demonstrate method and understanding, but it does not prove production maturity unless the same controls, evidence, review cadence, and change approvals exist in production. Keep lab evidence clearly labelled as lab evidence.