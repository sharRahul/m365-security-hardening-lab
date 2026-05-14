# Lab Architecture

This document defines the target lab architecture for the Microsoft 365 Security Hardening Lab.

## Architecture goals

The lab should be:

- Reproducible: a new user can rebuild it from a clean tenant.
- Safe: hardening changes are tested in a non-production tenant first.
- Evidence-friendly: every control produces a screenshot, export, report, or script output.
- Rollback-aware: risky settings have a documented recovery path.
- Licence-aware: modules clearly state which features depend on higher licensing.

## High-level architecture

```mermaid
flowchart LR
    Users[Lab users and administrators] --> Entra[Microsoft Entra ID]
    Entra --> CA[Conditional Access]
    Entra --> PIM[Privileged Identity Management]
    CA --> Workloads[Microsoft 365 workloads]
    Workloads --> Exchange[Exchange Online]
    Workloads --> SharePoint[SharePoint and OneDrive]
    Workloads --> Teams[Microsoft Teams]

    Purview[Microsoft Purview] --> DLP[DLP policies]
    Purview --> Labels[Sensitivity labels]
    DLP --> Workloads
    Labels --> Workloads

    Device[Test Windows endpoint] --> Intune[Intune endpoint security]
    Intune --> MDE[Microsoft Defender for Endpoint]
    MDE --> Sentinel[Microsoft Sentinel]
    Workloads --> Sentinel
    Entra --> Sentinel
    Sentinel --> LogAnalytics[Log Analytics workspace]
    LogAnalytics --> Analytics[Scheduled analytics rules]
    Analytics --> Incidents[Incidents and evidence pack]
```

This flow shows the lab's main control paths: Microsoft Entra ID feeds Conditional Access before access reaches Microsoft 365 workloads; Microsoft Defender for Endpoint sends endpoint telemetry into Sentinel and Log Analytics; and Microsoft Purview drives DLP and sensitivity label controls across Exchange, SharePoint, OneDrive, and Teams.

## Tenant components

| Component | Purpose | Example evidence |
| --- | --- | --- |
| Microsoft Entra ID | Identity, users, groups, roles, authentication methods | User list, role assignment export, MFA registration report |
| Conditional Access | Authentication and access control policy enforcement | Policy export, report-only results, sign-in log result |
| Microsoft 365 Admin Center | Core tenant settings and admin roles | Settings screenshots, admin role review |
| Exchange Online Protection | Baseline email protection | Anti-spam, anti-malware, anti-phishing policy exports |
| Defender for Office 365 | Advanced email and collaboration protection | Safe Links, Safe Attachments, campaign or explorer evidence |
| Intune / Endpoint Security | Device compliance and endpoint baselines | Compliance policy export, security baseline assignment |
| Defender for Endpoint | Endpoint detection and response | Device onboarding status, alert simulation evidence |
| Microsoft Purview | DLP, sensitivity labels, audit, retention | DLP policy export, sensitivity label publication, audit settings |
| Sentinel or SIEM optional | Centralised monitoring and alerting | Connector status, analytic rule list, incident queue |

## Suggested lab users

| User | Role | Purpose |
| --- | --- | --- |
| `global.admin.lab` | Emergency setup administrator | Used for initial configuration only |
| `breakglass.one` | Emergency access account | Excluded from normal CA but monitored and reviewed |
| `breakglass.two` | Backup emergency access account | Secondary recovery path |
| `security.admin` | Security administrator | Security portal and Defender configuration |
| `compliance.admin` | Compliance administrator | Purview and DLP configuration |
| `standard.user1` | Standard user | User impact testing |
| `standard.user2` | Standard user | Group and policy assignment testing |
| `vip.user` | Sensitive user persona | Higher-risk access and alert scenario testing |

## Suggested groups

| Group | Purpose |
| --- | --- |
| `SG-CA-MFA-AllUsers-Pilot` | Pilot scope for MFA Conditional Access |
| `SG-CA-Excluded-EmergencyAccess` | Emergency access exclusions |
| `SG-Endpoint-Windows-Pilot` | Test devices for endpoint policies |
| `SG-DLP-PilotUsers` | DLP and sensitivity label pilot users |
| `SG-Security-Admins` | Security administrator assignment group |
| `SG-Compliance-Admins` | Compliance administrator assignment group |

## Lab zones

| Zone | Description | Risk level |
| --- | --- | --- |
| Baseline | Capture tenant state before changes | Low |
| Pilot | Apply policies to a limited test group | Medium |
| Enforcement | Move selected policies from report-only to on | High |
| Verification | Confirm hardening state and collect evidence | Low |
| Rollback | Restore access or undo changes if required | High |

## Evidence outputs

At the end of the lab, create an evidence pack with:

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

## Architecture assumptions

- This is a lab-first architecture, not a production reference architecture.
- Licensing and feature availability may vary by tenant, region, subscription, and trial state.
- Some features require time to propagate before verification results appear.
- Portal names and navigation paths may change, so verification scripts and exported evidence are preferred where possible.

## Lockout prevention design

Before enforcing Conditional Access or privileged role restrictions:

1. Create two emergency access accounts.
2. Store their credentials securely.
3. Exclude them from normal Conditional Access policies.
4. Monitor and review them separately.
5. Confirm both accounts can sign in before enabling enforcement.
6. Keep one active admin session open during changes.

This lab is designed to simulate a real-world enterprise Microsoft 365 environment with modern security controls applied. It focuses on identity, email, endpoints, data protection, and SIEM monitoring.

## Lab components

The environment includes:

1. Identity and access management
   - Microsoft Entra ID tenant
   - Conditional Access policies
   - MFA enforcement
   - Break-glass emergency accounts
   - Role-Based Access Control and Privileged Identity Management

2. Email and collaboration security
   - Exchange Online
   - Defender for Office 365
   - Anti-spam and anti-phishing controls
   - Safe Links and Safe Attachments

3. Endpoint security
   - Microsoft Defender for Endpoint
   - Attack surface reduction rules
   - Defender Antivirus baseline
   - Threat and Vulnerability Management

4. Data loss prevention and compliance
   - Sensitivity labels
   - DLP policies
   - Insider Risk Management, where licensed

5. Monitoring and threat detection
   - Microsoft Defender XDR unified incidents
   - Sentinel add-on
   - KQL-based threat hunting
