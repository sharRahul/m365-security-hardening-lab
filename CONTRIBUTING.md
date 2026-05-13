# Contributing

Thank you for helping improve **Microsoft 365 Security Hardening Lab**. Contributions should make the lab safer, more reproducible, and easier to verify.

## Contribution principles

All contributions should be:

- Reproducible: provide steps another user can follow in a clean lab tenant.
- Safe: default to report-only, read-only, or clearly reversible actions where possible.
- Licence-aware: state the Microsoft 365 or Entra licensing assumptions for each control.
- Evidence-friendly: include how to prove the setting is enabled and operating.
- Rollback-aware: document how to undo the change or recover access if something goes wrong.

## Adding a lab module

Each lab module should include:

1. Objective.
2. Risk addressed.
3. Required licence or feature.
4. Required administrator role.
5. Pre-change baseline capture.
6. Configuration steps.
7. Verification method.
8. Evidence to collect.
9. Rollback steps.
10. Known limitations or tenant-specific assumptions.

## Adding a verification script

Scripts should:

- Be read-only by default.
- Include clear comments and usage examples.
- Avoid destructive actions unless clearly named and documented.
- Never hard-code tenant IDs, user IDs, secrets, credentials, or production values.
- Output human-readable results that can be used as audit evidence.
- Fail safely with helpful error messages.

## Pull request checklist

Before opening a pull request, confirm that:

- [ ] Steps were tested in a lab or trial tenant.
- [ ] Required licence and admin role are documented.
- [ ] Verification steps are included.
- [ ] Rollback steps are included.
- [ ] Screenshots or examples are anonymised.
- [ ] No secrets, tenant identifiers, or real user data are included.
- [ ] `CHANGELOG.md` is updated for new or changed hardening guidance.

## Style guide

- Use numbered steps for configuration procedures.
- Use warnings for lockout risk, destructive changes, or irreversible actions.
- State whether a setting is recommended for lab only, pilot, or production consideration.
- Avoid claiming a setting is universally correct. Security baselines must be adapted to business risk.

## Security and privacy

Do not submit screenshots, exports, logs, tenant IDs, application IDs, domain names, or user details from a real tenant unless they are fully anonymised and safe to publish.
