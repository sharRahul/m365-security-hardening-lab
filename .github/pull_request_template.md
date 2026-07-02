# Pull request

## What does this change

Describe the change and why it improves the lab.

## Type of change

- [ ] Hardening control or script change
- [ ] Verification or evidence improvement
- [ ] Documentation
- [ ] Tests or CI
- [ ] Other

## Safety checklist

- [ ] No real tenant data, credentials, IPs, or user names. Synthetic values and placeholders like `<tenant-id>` only.
- [ ] Any state-changing script supports `-WhatIf` and keeps a safe default (pilot scope, report-only, or audit-only).
- [ ] No existing control, safe default, or guard rail is weakened.
- [ ] No secrets or workspace keys are printed or logged.
- [ ] Rollback guidance updated if the change affects how a control is undone.

## Docs and status

- [ ] README structure tree and docs index updated if files were added, moved, or removed.
- [ ] `docs/IMPLEMENTATION_STATUS.md` updated in the same change.

## Testing

- [ ] `Invoke-ScriptAnalyzer -Path ./scripts -Recurse` shows no new findings.
- [ ] Pester tests pass (`Invoke-Pester -Path ./tests`), with new tests added for new script behaviour.
- [ ] Describe any manual lab-tenant testing you did, including `-WhatIf` and report-only runs.
