# Microsoft 365 Security Hardening Lab

A practical, reproducible Microsoft 365 security hardening lab that guides users from a vanilla tenant to a more secure baseline across identity, email, endpoint, data protection, and monitoring controls.

> **Read [`docs/safe-execution-modes.md`](docs/safe-execution-modes.md) before running any deployment script.** The Conditional Access and DLP scripts change tenant behaviour, and the Sentinel add-on can create cost-bearing Azure resources. Use emergency access accounts, preview mode, pilot scoping, report-only or audit-only mode, validation, and rollback testing.

## Why this exists

Microsoft 365 security guidance is often spread across multiple admin portals, licensing tiers, and product areas. This repository turns hardening into a structured lab with prerequisites, architecture, step-by-step configuration guidance, verification scripts, rollback procedures, evidence-friendly outputs, and explicit boundaries between scripted and manual work.

Use this repository to:

- Build hands-on Microsoft 365 security hardening experience.
- Create a repeatable lab for consultants, learners, and security engineers.
- Document what was changed, why it matters, and how to verify it.
- Generate evidence that supports security reviews, client assurance, and audit readiness.
- Practise rollback scenarios before applying similar controls in production.

## Who this is for

- Microsoft 365 administrators
- Security engineers
- GRC and audit practitioners who need technical evidence
- Consultants building reusable hardening baselines
- Learners preparing for identity, endpoint, cloud, and compliance roles

## Repository structure

```text
.
├── README.md
├── CONTRIBUTING.md
├── CHANGELOG.md
├── LICENSE
├── docs/
│   ├── examples/
│   ├── IMPLEMENTATION_STATUS.md
│   ├── deployment-prerequisites.md
│   ├── identity-module-evidence-walkthrough.md
│   ├── iso27001-control-mapping-annex.md
│   ├── lab-architecture.md
│   ├── licensing-and-feature-limitations.md
│   ├── permissions-matrix.md
│   ├── rollback-procedures.md
│   ├── run-order-quick-reference.md
│   ├── safe-execution-modes.md
│   ├── screenshot-and-evidence-capture-guide.md
│   ├── scripted-manual-optional-scope.md
│   ├── sentinel-cost-and-teardown.md
│   ├── step-by-step-lab-guide.md
│   └── tenant-setup-walkthrough.md
├── scripts/
│   ├── Deploy-ConditionalAccessPolicies.ps1
│   ├── Deploy-PurviewDLP.ps1
│   ├── Deploy-SentinelWorkspace.ps1
│   ├── Export-M365Baseline.ps1
│   ├── Get-M365SecureScore.ps1
│   ├── Remove-SentinelWorkspace.ps1
│   └── Verify-M365Hardening.ps1
├── tests/
│   ├── Scripts.Tests.ps1
│   └── TestStubs.ps1
└── .github/
    ├── ISSUE_TEMPLATE/
    ├── pull_request_template.md
    └── workflows/
        └── test-scripts.yml
```

## Documentation index

| Document | Read it for |
| --- | --- |
| [`docs/safe-execution-modes.md`](docs/safe-execution-modes.md) | **Read first.** Standard safe sequence, pilot scoping, report-only/audit-only mode, and stop conditions. |
| [`docs/run-order-quick-reference.md`](docs/run-order-quick-reference.md) | One-page safe sequence: emergency access, baseline, preview, pilot, report-only/audit-only, review, enforce, rollback test. |
| [`docs/scripted-manual-optional-scope.md`](docs/scripted-manual-optional-scope.md) | What is scripted deployment, scripted verification, manual verification, and optional/licence-dependent. |
| [`docs/licensing-and-feature-limitations.md`](docs/licensing-and-feature-limitations.md) | How to handle unavailable features, skipped checks, empty exports, and licence-dependent areas. |
| [`docs/identity-module-evidence-walkthrough.md`](docs/identity-module-evidence-walkthrough.md) | Screenshots, exports, and command outputs to capture for the identity module. |
| [`docs/screenshot-and-evidence-capture-guide.md`](docs/screenshot-and-evidence-capture-guide.md) | Screenshot standards and evidence capture rules across all lab phases. |
| [`docs/sentinel-cost-and-teardown.md`](docs/sentinel-cost-and-teardown.md) | Sentinel cost guardrails, evidence, and cleanup procedure. |
| [`docs/deployment-prerequisites.md`](docs/deployment-prerequisites.md) | Licences, roles, tools, and the pre-flight safety checklist. |
| [`docs/permissions-matrix.md`](docs/permissions-matrix.md) | Graph scopes, admin roles, and licence prerequisites for each script. |
| [`docs/tenant-setup-walkthrough.md`](docs/tenant-setup-walkthrough.md) | Setting up a fresh lab tenant, including emergency access accounts. |
| [`docs/lab-architecture.md`](docs/lab-architecture.md) | Lab components, personas, and evidence outputs. |
| [`docs/step-by-step-lab-guide.md`](docs/step-by-step-lab-guide.md) | The full lab flow from baseline capture to closeout. |
| [`docs/rollback-procedures.md`](docs/rollback-procedures.md) | Undoing changes and recovering from administrator lockout. |
| [`docs/examples/`](docs/examples/) | Synthetic sample outputs so you can see expected results without running anything. |
| [`docs/iso27001-control-mapping-annex.md`](docs/iso27001-control-mapping-annex.md) | Mapping lab controls to ISO 27001:2022 Annex A. |
| [`docs/IMPLEMENTATION_STATUS.md`](docs/IMPLEMENTATION_STATUS.md) | What works today, what is partial, and the priority backlog. |

## Quick start

1. Read [`docs/safe-execution-modes.md`](docs/safe-execution-modes.md), [`docs/run-order-quick-reference.md`](docs/run-order-quick-reference.md), and [`docs/deployment-prerequisites.md`](docs/deployment-prerequisites.md).
2. Confirm your licence, role, tenant assumptions, and feature limitations in [`docs/licensing-and-feature-limitations.md`](docs/licensing-and-feature-limitations.md).
3. Review the scripted/manual boundaries in [`docs/scripted-manual-optional-scope.md`](docs/scripted-manual-optional-scope.md).
4. Confirm and test emergency access accounts.
5. Capture screenshots and exports using [`docs/screenshot-and-evidence-capture-guide.md`](docs/screenshot-and-evidence-capture-guide.md).
6. Capture the pre-change tenant state:

   ```powershell
   pwsh ./scripts/Export-M365Baseline.ps1
   ```

7. Capture the current Microsoft Secure Score:

   ```powershell
   pwsh ./scripts/Get-M365SecureScore.ps1
   ```

8. Follow [`docs/step-by-step-lab-guide.md`](docs/step-by-step-lab-guide.md) from baseline capture through identity, email, endpoint, data protection, and monitoring hardening.
9. Deploy the lab Conditional Access policy set in report-only mode first:

   ```powershell
   pwsh ./scripts/Deploy-ConditionalAccessPolicies.ps1 `
     -BreakGlassUserIds @('<break-glass-object-id-1>', '<break-glass-object-id-2>') `
     -PilotGroupIds @('<pilot-group-object-id>') `
     -HighRiskCountryCodes @('KP', 'IR', 'SY') `
     -ReportOnly
   ```

10. Capture identity evidence using [`docs/identity-module-evidence-walkthrough.md`](docs/identity-module-evidence-walkthrough.md).
11. Run [`scripts/Verify-M365Hardening.ps1`](scripts/Verify-M365Hardening.ps1) and review any `Manual`, `Skipped`, `NotConnected`, `Warning`, or `Fail` result.
12. Keep [`docs/rollback-procedures.md`](docs/rollback-procedures.md) open during the lab, especially when configuring Conditional Access, DLP, or monitoring controls.

## Sentinel add-on

The Sentinel add-on creates a Log Analytics workspace, enables Microsoft Sentinel, attempts to enable Microsoft security data connectors, and deploys starter scheduled analytics rules for common identity and Microsoft 365 attack indicators.

Prerequisites:

- Azure subscription access with permission to create resource groups and workspaces.
- PowerShell modules: `Az.Accounts`, `Az.Resources`, and `Az.OperationalInsights`.
- Appropriate Microsoft Sentinel and source workload licensing for the connectors you enable.

Preview first:

```powershell
pwsh ./scripts/Deploy-SentinelWorkspace.ps1 `
  -ResourceGroupName rg-m365-lab-sentinel `
  -WorkspaceName law-m365-lab `
  -Location uksouth `
  -WhatIf
```

Deploy:

```powershell
pwsh ./scripts/Deploy-SentinelWorkspace.ps1 `
  -ResourceGroupName rg-m365-lab-sentinel `
  -WorkspaceName law-m365-lab `
  -Location uksouth
```

A running workspace incurs ongoing ingestion and retention charges. When the lab is finished, tear it down with [`scripts/Remove-SentinelWorkspace.ps1`](scripts/Remove-SentinelWorkspace.ps1). See [`docs/sentinel-cost-and-teardown.md`](docs/sentinel-cost-and-teardown.md).

## Purview add-on

The Purview add-on creates two audit-only DLP policies for UK personal data and financial data across Exchange, SharePoint, OneDrive, and Teams. Keep policies in audit-only mode until you have validated expected matches and false positives in the lab.

Run audit-only deployment:

```powershell
pwsh ./scripts/Deploy-PurviewDLP.ps1
```

Move the lab policies to block mode only after validation:

```powershell
pwsh ./scripts/Deploy-PurviewDLP.ps1 -Enforce
```

## High-level lab flow

```text
Emergency access -> Baseline tenant -> Identity protection -> Email protection -> Endpoint security -> Data protection -> Monitoring -> Verification -> Rollback testing -> Evidence pack
```

## Bill of materials summary

| Area | Minimum | Recommended |
| --- | --- | --- |
| Tenant | Microsoft 365 developer or trial tenant | Dedicated lab tenant |
| Licence | Depends on selected controls | Microsoft 365 E5 trial for full Defender, Purview, Entra ID P2 style labs |
| Admin roles | Global Administrator for lab setup | Least privilege roles after setup |
| PowerShell | PowerShell 7+ with Microsoft Graph and Exchange Online modules | PowerShell 7+ with Microsoft Graph, ExchangeOnlineManagement, Az.Accounts, Az.Resources, and Az.OperationalInsights |
| Devices | Optional test Windows endpoint | Windows 11 test VM joined or enrolled to the tenant |

## Safety rules

- Use a dedicated lab tenant wherever possible.
- Create and test emergency access accounts before enforcing Conditional Access.
- Keep at least one verified admin path outside newly created policies until validation is complete.
- Export current settings before changing them.
- Use report-only or audit-only mode first where supported.
- Do not test risky configuration changes directly in a production tenant.
- Tear down the optional Sentinel workspace when testing ends.

## Audit and evidence value

This lab can generate evidence for:

- Secure authentication and MFA.
- Conditional Access policy design.
- Privileged role protection.
- Anti-phishing and email security controls.
- Endpoint security baselines.
- Audit logging and monitoring.
- DLP and sensitivity labelling.
- Configuration management and change evidence.
- ISO 27001:2022 Annex A control traceability through [`docs/iso27001-control-mapping-annex.md`](docs/iso27001-control-mapping-annex.md).

## Contributing

Please read [`CONTRIBUTING.md`](CONTRIBUTING.md) before submitting hardening settings, scripts, lab modules, screenshots, rollback steps, or verification improvements.

## License

This repository is licensed under the MIT License. See [`LICENSE`](LICENSE) for details.

## Disclaimer

This repository is for lab and educational use. Microsoft 365 features, portals, licensing, and PowerShell cmdlets change over time. Validate all settings in a non-production tenant first and tailor controls to your organisation's risk profile, legal obligations, and operational requirements.