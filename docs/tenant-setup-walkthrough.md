# Tenant Setup Walkthrough

This walkthrough helps configure a lab tenant from scratch before running the hardening modules. See [`deployment-prerequisites.md`](deployment-prerequisites.md) for the full bill of materials.

## 1. Create emergency access (break-glass) accounts

Create at least two accounts along these lines:

```text
Account: emergencyadmin@<tenant-name>.onmicrosoft.com

Password: Strong, generated, and stored offline

MFA: Excluded from normal MFA policies (break-glass only)

Directory role: Global Administrator

Sign-in risk policy: Excluded

Conditional Access policies: Excluded
```

Then add monitoring so any break-glass sign-in raises an alert:

- Create an alert rule that notifies administrators when a break-glass account signs in.
- Review break-glass sign-in activity as part of regular lab evidence capture.

## 2. Enable security defaults (optional)

If the tenant has E3 or basic licensing and you are not yet using Conditional Access, security defaults:

- Enforce MFA registration and challenges.
- Block legacy authentication.

Turn security defaults off before deploying the lab Conditional Access policies, because the two cannot be active together.

## 3. Block legacy authentication (recommended for all tenants)

Legacy authentication protocols cannot enforce MFA, so block them explicitly:

- Preferred: deploy the lab Conditional Access policy set, which includes a pilot-scoped legacy authentication block. See [`safe-execution-modes.md`](safe-execution-modes.md) before running it.
- Alternative: keep security defaults enabled, which block legacy authentication tenant-wide.

Before blocking, review sign-in logs for legacy authentication usage: Entra admin centre, Monitoring, Sign-in logs, then filter by client app for legacy clients such as POP, IMAP, SMTP AUTH, and Exchange ActiveSync.

## 4. Configure password protection

- Enable the banned password list.
- Require MFA for all administrator roles.

## 5. Assign admin roles based on least privilege

Suggested lab role allocation:

| Role | Allocation |
| --- | --- |
| Global Administrator | Break-glass accounts only after initial setup |
| Security Administrator | 1 |
| Exchange Administrator | 1 |
| Compliance Administrator | 1 |
