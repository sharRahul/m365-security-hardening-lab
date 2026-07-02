# Microsoft 365 Security Hardening Lab

A practical, reproducible Microsoft 365 security hardening lab that guides users from a vanilla tenant to a more secure baseline across identity, email, endpoint, data protection, and monitoring controls.

> **Read [`docs/safe-execution-modes.md`](docs/safe-execution-modes.md) before running any deployment script.** The Conditional Access and DLP scripts change tenant behaviour and can lock users out if run without pilot scoping, report-only mode, and tested emergency access accounts.

## Why this exists

Microsoft 365 security guidance is often spread across multiple admin portals, licensing tiers, and product areas. This repository turns hardening into a structured lab with prerequisites, architecture, step-by-step configuration guidance, verification scripts, rollback procedures, and evidence-friendly outputs.

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
│   ├── IMPLEMENTATION_STATUS.md
│   ├── deployment-prerequisites.md
│   ├── iso27001-control-mapping-annex.md
│   ├── lab-architecture.md
│   ├── rollback-procedures.md
│   ├── safe-execution-modes.md
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
└── .github/
    └── workflows/
        └── test-scripts.yml
```

## Documentation index

| Document | Read it for |
| --- | --- |
| [`docs/safe-execution-modes.md`](docs/safe-execution-modes.md) | **Read first.** Safe defaults, pilot scoping, report-only mode, and stop conditions for the state-changing scripts. |
| [`docs/deployment-prerequisites.md`](docs/deployment-prerequisites.md) | Licences, roles, tools, and the pre-flight safety checklist. |
| [`docs/tenant-setup-walkthrough.md`](docs/tenant-setup-walkthrough.md) | Setting up a fresh lab tenant, including break-glass accounts. |
| [`docs/lab-architecture.md`](docs/lab-architecture.md) | Lab components, personas, and evidence outputs. |
| [`docs/step-by-step-lab-guide.md`](docs/step-by-step-lab-guide.md) | The full lab flow from baseline capture to closeout. |
| [`docs/rollback-procedures.md`](docs/rollback-procedures.md) | Undoing changes and recovering from administrator lockout. |
| [`docs/iso27001-control-mapping-annex.md`](docs/iso27001-control-mapping-annex.md) | Mapping lab controls to ISO 27001:2022 Annex A. |
| [`docs/IMPLEMENTATION_STATUS.md`](docs/IMPLEMENTATION_STATUS.md) | What works today, what is partial, and the priority backlog. |

## Quick start

1. Read [`docs/deployment-prerequisites.md`](docs/deployment-prerequisites.md) and confirm your licence, role, and tenant assumptions.
2. Review the architecture in [`docs/lab-architecture.md`](docs/lab-architecture.md).
3. Capture the pre-change tenant state:

   ```powershell
   pwsh ./scripts/Export-M365Baseline.ps1
   ```

4. Capture the current Microsoft Secure Score:

   ```powershell
   pwsh ./scripts/Get-M365SecureScore.ps1
   ```

5. Follow [`docs/step-by-step-lab-guide.md`](docs/step-by-step-lab-guide.md) from baseline capture through identity, email, endpoint, data protection, and monitoring hardening.
6. Deploy the lab Conditional Access policy set in report-only mode first:

   ```powershell
   pwsh ./scripts/Deploy-ConditionalAccessPolicies.ps1 `
     -BreakGlassUserIds @('<break-glass-object-id-1>', '<break-glass-object-id-2>') `
     -HighRiskCountryCodes @('KP', 'IR', 'SY') `
     -ReportOnly
   ```

7. Run [`scripts/Verify-M365Hardening.ps1`](scripts/Verify-M365Hardening.ps1) in report-only mode to check configuration state.
8. Keep [`docs/rollback-procedures.md`](docs/rollback-procedures.md) open during the lab, especially when configuring Conditional Access or privileged access controls.

### Sentinel add-on

The Sentinel add-on creates a Log Analytics workspace, enables Microsoft Sentinel, attempts to enable Microsoft security data connectors, and deploys starter scheduled analytics rules for common identity and Microsoft 365 attack indicators.

Prerequisites:

- Azure subscription access with permission to create resource groups and workspaces.
- PowerShell modules: `Az.Accounts`, `Az.Resources`, and `Az.OperationalInsights`.
- Appropriate Microsoft Sentinel and source workload licensing for the connectors you enable.

Run:

```powershell
pwsh ./scripts/Deploy-SentinelWorkspace.ps1 `
  -ResourceGroupName rg-m365-lab-sentinel `
  -WorkspaceName law-m365-lab `
  -Location uksouth
```

A running workspace incurs ongoing ingestion and retention charges. When the lab is finished, tear it down with [`scripts/Remove-SentinelWorkspace.ps1`](scripts/Remove-SentinelWorkspace.ps1), which previews by default and only deletes with `-ConfirmTeardown`. See the teardown section of [`docs/step-by-step-lab-guide.md`](docs/step-by-step-lab-guide.md).

### Purview add-on

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
Baseline tenant -> Identity protection -> Email protection -> Endpoint security -> Data protection -> Monitoring -> Verification -> Rollback testing -> Evidence pack
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
- Use report-only mode first where supported.
- Do not test risky configuration changes directly in a production tenant.

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
