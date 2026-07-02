# Step-by-Step Lab Guide

This guide takes a lab tenant from baseline capture to a hardened and verified Microsoft 365 security configuration.

> Use a non-production tenant for this lab. Start with report-only, pilot groups, and documented rollback paths before enforcing policies.

## Phase 0: Prepare the lab

### Objective

Create a safe working environment before applying security changes.

### Steps

1. Confirm the tenant is a lab, trial, or developer tenant.
2. Record licence details and known feature limitations.
3. Create test users and groups listed in `docs/lab-architecture.md`.
4. Create two emergency access accounts.
5. Store emergency access credentials in a secure password manager.
6. Test emergency access sign-in.
7. Keep one privileged admin session open while configuring access controls.

### Evidence to collect

- User and group list.
- Emergency access account existence evidence.
- Licence summary.
- Pre-flight checklist completion.

## Phase 1: Capture the baseline

### Objective

Record tenant state before changes so you can verify improvement and support rollback.

### Steps

1. Export or screenshot current Conditional Access policies.
2. Export admin role assignments.
3. Capture MFA registration status.
4. Capture authentication method settings.
5. Capture Exchange Online and Defender for Office 365 policies.
6. Capture current Purview DLP and sensitivity label configuration.
7. Capture endpoint onboarding and compliance state if using Intune or Defender for Endpoint.
8. Save all outputs under `evidence/01-baseline/`.

### Evidence to collect

- Baseline configuration exports.
- Screenshots where export is unavailable.
- Script output from `scripts/Verify-M365Hardening.ps1`.

## Phase 2: Identity and access hardening

### Objective

Improve authentication, administrator protection, and access control.

### Recommended lab controls

| Control | Lab action | Verification |
| --- | --- | --- |
| MFA for users | Create Conditional Access policy scoped to pilot users | Sign-in log shows MFA requirement |
| MFA for admins | Create stricter policy for admin roles | Admin test account requires MFA |
| Legacy authentication block | Create or enable policy blocking legacy auth | Sign-in logs show blocked legacy attempts where tested |
| Emergency access exclusion | Exclude break-glass accounts from normal CA but monitor separately | Policy exclusions and alerting evidence |
| Privileged role review | Review admin role assignments | Export of roles and justification notes |

### Steps

1. Create pilot group `SG-CA-MFA-AllUsers-Pilot`.
2. Add standard test users to the pilot group.
3. Create Conditional Access policy in report-only mode requiring MFA for pilot users.
4. Exclude emergency access accounts.
5. Review report-only results.
6. Move to enforcement only after successful testing.
7. Create a separate admin MFA policy for privileged roles.
8. Review role assignments and remove unnecessary privileges.

### Evidence to collect

- Conditional Access policy export or screenshot.
- Report-only result evidence.
- Sign-in log showing expected policy result.
- Admin role assignment export.
- Emergency access exclusion evidence.

## Phase 3: Email and collaboration security hardening

### Objective

Improve protection against phishing, malware, spoofing, and unsafe links or attachments.

### Recommended lab controls

| Control | Lab action | Verification |
| --- | --- | --- |
| Anti-phishing | Configure anti-phishing policy for pilot users | Policy export and test message review |
| Anti-malware | Review malware filter policy | Policy export |
| Safe Links | Configure Safe Links for pilot users where licensed | URL policy evidence |
| Safe Attachments | Configure Safe Attachments for pilot users where licensed | Attachment policy evidence |
| External sender tagging | Enable or document external sender warning approach | Test email or policy screenshot |

### Steps

1. Review existing EOP and Defender for Office 365 policies.
2. Create or adjust anti-phishing policy for pilot users.
3. Configure impersonation protection for VIP and domain scenarios where available.
4. Enable Safe Links and Safe Attachments for pilot users where licensed.
5. Test with benign test messages only.
6. Preserve message trace and policy evidence.

### Evidence to collect

- Anti-phishing policy export or screenshot.
- Safe Links and Safe Attachments evidence.
- Message trace sample.
- Security portal alert or investigation evidence where applicable.

## Phase 4: Endpoint security hardening

### Objective

Improve endpoint compliance, malware protection, attack surface reduction, and visibility.

### Recommended lab controls

| Control | Lab action | Verification |
| --- | --- | --- |
| Defender AV baseline | Configure antivirus baseline | Device security setting evidence |
| Attack Surface Reduction | Apply ASR rules in audit mode first | ASR event or policy evidence |
| Device compliance | Create compliance policy for test devices | Device compliance report |
| Defender onboarding | Onboard test device to Defender for Endpoint where licensed | Device appears in security portal |

### Steps

1. Enrol or join a Windows 11 test device if using endpoint modules.
2. Create endpoint pilot group `SG-Endpoint-Windows-Pilot`.
3. Apply endpoint security baseline to the pilot group.
4. Configure ASR rules in audit mode before block mode.
5. Confirm Defender AV and EDR status.
6. Collect compliance and device timeline evidence.

### Evidence to collect

- Security baseline policy export.
- Device compliance report.
- Defender onboarding status.
- ASR audit-mode event evidence.

## Phase 5: Data protection and compliance hardening

### Objective

Protect sensitive information using labels, DLP, audit, and retention-oriented evidence.

### Recommended lab controls

| Control | Lab action | Verification |
| --- | --- | --- |
| Sensitivity labels | Create lab labels and publish to pilot users | Label policy evidence |
| DLP | Create pilot DLP policy using test data | DLP policy and incident evidence |
| Audit | Confirm audit logging is enabled | Audit search or setting evidence |
| External sharing review | Review sharing settings | SharePoint/OneDrive sharing evidence |

### Steps

1. Create a simple sensitivity label taxonomy for lab data.
2. Publish labels to pilot users.
3. Create a DLP policy using test data only.
4. Review SharePoint and OneDrive external sharing settings.
5. Confirm audit log availability.
6. Save exports or screenshots.

### Evidence to collect

- Sensitivity label configuration.
- Label publication policy.
- DLP policy export.
- DLP alert or policy match using safe test data.
- Audit log search evidence.

## Phase 6: Logging and monitoring

### Objective

Ensure security events are visible, reviewable, and suitable for investigation.

### Steps

1. Confirm audit logging is enabled and searchable.
2. Review security portal incident and alert settings.
3. Confirm Defender product integrations where available.
4. Optionally connect logs to Microsoft Sentinel or another SIEM.
5. Create or document analytic rules and alert routing.
6. Capture monitoring evidence.

### Evidence to collect

- Audit log setting evidence.
- Alert queue screenshot.
- SIEM connector status where applicable.
- Example alert or incident record.

## Phase 7: Verification

### Objective

Confirm the lab controls are applied and evidence is complete.

### Steps

1. Run `scripts/Verify-M365Hardening.ps1`.
2. Save output under `evidence/07-verification-script-output/`.
3. Compare results against the intended state.
4. Document gaps or licence limitations.
5. Open remediation actions for failed checks.

### Evidence to collect

- Verification script output.
- Manual evidence for controls the script cannot check.
- Gap register.

## Phase 8: Rollback testing

### Objective

Prove that risky changes can be undone and administrator access can be recovered.

### Steps

1. Review `docs/rollback-procedures.md`.
2. Test emergency account sign-in.
3. Temporarily disable or move a pilot Conditional Access policy back to report-only.
4. Confirm affected test user access is restored.
5. Re-enable the lab policy after confirming rollback works.
6. Document rollback evidence.

### Evidence to collect

- Rollback test notes.
- Before/after policy state.
- Sign-in test evidence.

## Completion checklist

| Check | Complete | Evidence reference |
| --- | --- | --- |
| Baseline captured. |  |  |
| Emergency access tested. |  |  |
| Identity controls configured and verified. |  |  |
| Email controls configured and verified. |  |  |
| Endpoint controls configured and verified where in scope. |  |  |
| Data protection controls configured and verified where in scope. |  |  |
| Audit and monitoring evidence captured. |  |  |
| Verification script output saved. |  |  |
| Rollback tested. |  |  |
| Known gaps documented. |  |  |

## Lab closeout

### Tear down the optional Sentinel workspace

If you deployed the Sentinel add-on, tear it down when the lab is finished. A running Log Analytics workspace continues to incur data ingestion and retention charges even when you are no longer using it.

1. Capture any remaining Sentinel evidence (alerts, incidents, connector status) before teardown.
2. Preview the teardown. Nothing is deleted in this mode:

   ```powershell
   pwsh ./scripts/Remove-SentinelWorkspace.ps1 `
     -ResourceGroupName rg-m365-lab-sentinel `
     -WorkspaceName law-m365-lab
   ```

3. Review the preview summary, then run the teardown for real:

   ```powershell
   pwsh ./scripts/Remove-SentinelWorkspace.ps1 `
     -ResourceGroupName rg-m365-lab-sentinel `
     -WorkspaceName law-m365-lab `
     -ConfirmTeardown
   ```

4. Add `-RemoveResourceGroup` only when the resource group was created for this lab and contains nothing else.

Notes:

- The script refuses to run unless the workspace name contains `lab`, as a guard against targeting a production workspace.
- The workspace is soft deleted. Azure keeps it recoverable for 14 days and the name stays reserved during that window. Ingestion charges stop at deletion.
- Use `-RulesOnly` to remove just the starter analytics rules and keep the workspace.

### Summary report

At the end of the lab, create a summary report containing:

- Tenant and licence assumptions.
- Modules completed.
- Controls configured.
- Evidence references.
- Failed or skipped checks.
- Rollback results.
- Recommended next improvements.
