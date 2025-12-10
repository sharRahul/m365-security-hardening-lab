This lab is designed to simulate a real-world enterprise Microsoft 365 environment with modern security controls applied. It focuses on identity, email, endpoints, data protection, and SIEM monitoring.

Lab Components

The environment includes:

Identity & Access Management

Azure AD (Entra ID) tenant

Conditional Access policies

MFA enforcement

Break-glass emergency account

Role-Based Access Control (RBAC)

Email & Collaboration Security

Exchange Online

Defender for Office 365

Anti-spam & anti-phishing (EOP & MDO)

Safe Links & Safe Attachments

Endpoint Security

Microsoft Defender for Endpoint

ASR rules

Defender AV baseline

Threat & Vulnerability Management (TVM)

Data Loss Prevention & Compliance

Sensitivity labels

DLP policies

Insider Risk Management (optional)

Monitoring & Threat Detection

Microsoft 365 Defender unified incidents

Sentinel (optional)

KQL-based threat hunting

High-Level Architecture (Text Diagram)
                ┌─────────────────────────┐
                │      Azure AD / Entra   │
                │   - Identities          │
                │   - CA policies         │
                └───────────┬────────────┘
                            │
        ┌───────────────────┼────────────────────┐
        │                   │                    │
┌───────────────┐   ┌──────────────┐   ┌─────────────────┐
│  Exchange      │   │ SharePoint/  │   │ Endpoints:       │
│  Online        │   │ OneDrive     │   │ Win10/11 Clients │
│  MDO/EOP       │   │ Labels/DLP   │   │ MDE Agent        │
└───────────────┘   └──────────────┘   └─────────────────┘
        │                   │                     │
        └───────────────────┼─────────────────────┘
                            │
                 ┌──────────▼─────────┐
                 │  M365 Defender     │
                 │  - Incidents       │
                 │  - Alerts          │
                 └─────────┬──────────┘
                           │
                 ┌────────▼──────────┐
                 │ Sentinel (Optional)│
                 │ KQL Hunting        │
                 └────────────────────┘