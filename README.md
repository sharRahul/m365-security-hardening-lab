# Microsoft 365 Security Hardening Lab

A practical, reproducible Microsoft 365 security hardening lab that guides users from a vanilla tenant to a more secure baseline across identity, email, endpoint, data protection, and monitoring controls.

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
│   ├── lab-architecture.md
│   ├── deployment-prerequisites.md
│   ├── step-by-step-lab-guide.md
│   └── rollback-procedures.md
└── scripts/
    └── Verify-M365Hardening.ps1
```

## Quick start

1. Read [`docs/deployment-prerequisites.md`](docs/deployment-prerequisites.md) and confirm your licence, role, and tenant assumptions.
2. Review the architecture in [`docs/lab-architecture.md`](docs/lab-architecture.md).
3. Follow [`docs/step-by-step-lab-guide.md`](docs/step-by-step-lab-guide.md) from baseline capture through identity, email, endpoint, data protection, and monitoring hardening.
4. Run [`scripts/Verify-M365Hardening.ps1`](scripts/Verify-M365Hardening.ps1) in report-only mode to check configuration state.
5. Keep [`docs/rollback-procedures.md`](docs/rollback-procedures.md) open during the lab, especially when configuring Conditional Access or privileged access controls.

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
| PowerShell | PowerShell 7+ | PowerShell 7+ with Microsoft Graph modules |
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

## Contributing

Please read [`CONTRIBUTING.md`](CONTRIBUTING.md) before submitting hardening settings, scripts, lab modules, screenshots, rollback steps, or verification improvements.

## License

This repository is licensed under the MIT License. See [`LICENSE`](LICENSE) for details.

## Disclaimer

This repository is for lab and educational use. Microsoft 365 features, portals, licensing, and PowerShell cmdlets change over time. Validate all settings in a non-production tenant first and tailor controls to your organisation's risk profile, legal obligations, and operational requirements.
