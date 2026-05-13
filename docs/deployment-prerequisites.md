# Deployment Prerequisites

This document defines the bill of materials, roles, licences, tools, and safety checks required before running the Microsoft 365 Security Hardening Lab.

## Tenant requirements

| Requirement | Minimum | Recommended | Notes |
| --- | --- | --- | --- |
| Tenant type | Microsoft 365 trial or developer tenant | Dedicated non-production lab tenant | Avoid using a production tenant for first-time testing. |
| Domain | Default tenant domain | Custom lab domain if available | Custom domains are optional. |
| Users | 3 test users | 6+ users covering standard, VIP, security, compliance, and break-glass personas | Do not use real production users. |
| Devices | Optional | One Windows 11 test VM or spare device | Required for endpoint modules. |
| Email flow | Internal only | Internal plus controlled external test sender | Do not send malicious test payloads. |

## Licence assumptions

Feature availability varies by subscription, add-on, region, and tenant state. Record your actual licence before starting.

| Lab area | Commonly required capability | Notes |
| --- | --- | --- |
| Conditional Access | Entra ID Conditional Access capability | Use report-only first where supported. |
| Identity Protection | Entra ID risk-based capabilities | May require higher-tier identity licensing. |
| Defender for Office 365 | Safe Links, Safe Attachments, advanced anti-phishing | Availability depends on plan. |
| Defender for Endpoint | EDR, attack surface reduction, device timeline | Requires endpoint onboarding. |
| Intune | Device compliance and security baselines | Requires enrolled test device. |
| Purview DLP and sensitivity labels | Compliance portal capabilities | Some advanced features require higher plans. |
| Audit and eDiscovery | M365 audit capabilities | Retention and event depth vary by licence. |
| Sentinel optional | Azure subscription and workspace | Optional for SIEM integration. |

## Administrator roles

Use the least-privilege role required for each activity after the initial lab setup.

| Role | Used for |
| --- | --- |
| Global Administrator | Initial setup, emergency recovery, role assignment |
| Security Administrator | Defender, security portal, security settings |
| Conditional Access Administrator | Conditional Access policy configuration |
| Privileged Role Administrator | Role assignment and PIM-style configuration |
| Exchange Administrator | Exchange Online and EOP settings |
| Compliance Administrator | Purview, DLP, sensitivity labels |
| Intune Administrator | Endpoint compliance and security baselines |
| Reports Reader / Security Reader | Read-only verification and evidence capture |

## Local workstation tools

| Tool | Purpose |
| --- | --- |
| PowerShell 7+ | Running verification scripts and Graph commands |
| Microsoft Graph PowerShell SDK | Querying tenant settings and reports |
| Exchange Online PowerShell module | Reviewing mail protection settings where needed |
| Microsoft Teams or browser session | Admin portal access |
| Screenshot tool | Evidence capture where export is unavailable |
| Secure password manager | Emergency access account storage |

## PowerShell modules

Recommended modules:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module ExchangeOnlineManagement -Scope CurrentUser
```

The verification script is designed to be read-only and to degrade gracefully when optional modules or permissions are unavailable.

## Pre-flight safety checklist

| Check | Complete | Notes |
| --- | --- | --- |
| Lab tenant confirmed as non-production. |  |  |
| At least two emergency access accounts created. |  |  |
| Emergency access credentials stored securely. |  |  |
| Emergency accounts excluded from normal Conditional Access policies. |  |  |
| Emergency account sign-in tested. |  |  |
| Current admin session remains open during high-risk changes. |  |  |
| Existing tenant settings exported or screenshotted. |  |  |
| Rollback procedures reviewed. |  |  |
| Users and groups created for pilot scope. |  |  |
| Licence limitations documented. |  |  |

## Baseline evidence to capture before changes

Capture the following before applying hardening:

- Current Conditional Access policy list.
- Admin role assignments.
- MFA registration status.
- Authentication methods policy state.
- Exchange Online protection policies.
- Defender security portal settings.
- Audit log status.
- DLP and sensitivity label configuration.
- Endpoint onboarding and compliance status.
- Any existing exclusions or exceptions.

## Required lab records

Create a lab record with:

| Field | Value |
| --- | --- |
| Tenant name | `<tenant-name>` |
| Tenant type | `<trial/developer/lab>` |
| Lab start date | `<yyyy-mm-dd>` |
| Lab owner | `<name>` |
| Licence plan | `<plan>` |
| Modules tested | `<identity/email/endpoint/dlp/monitoring>` |
| Known limitations | `<limitations>` |
| Rollback tested | `<yes/no>` |

## Stop conditions

Stop and rollback if:

- You cannot sign in with an emergency access account.
- Conditional Access blocks all administrator access.
- A policy unexpectedly affects real users or production workloads.
- Verification output does not match the intended change.
- You cannot identify the owner or purpose of a security-impacting configuration.
