# Sentinel Cost and Teardown Guidance

The Sentinel add-on is useful for monitoring and detection practice, but it can create ongoing Azure costs through Log Analytics ingestion, retention, and connected data sources. Use this guide before and after running `scripts/Deploy-SentinelWorkspace.ps1`.

## Cost guardrails before deployment

1. Use a dedicated lab subscription or resource group.
2. Name the resource group and workspace with `lab` so the teardown guard rails can identify them.
3. Set a budget or cost alert in the Azure subscription.
4. Keep retention low for lab work unless you deliberately need a longer test window.
5. Connect only the data sources you need for the lab scenario.
6. Record the workspace owner and planned teardown date.
7. Do not leave the workspace running after the lab is finished.

## Deployment preview

Always preview before creating resources:

```powershell
pwsh ./scripts/Deploy-SentinelWorkspace.ps1 `
  -ResourceGroupName rg-m365-lab-sentinel `
  -WorkspaceName law-m365-lab `
  -Location uksouth `
  -WhatIf
```

Deploy only after reviewing the preview:

```powershell
pwsh ./scripts/Deploy-SentinelWorkspace.ps1 `
  -ResourceGroupName rg-m365-lab-sentinel `
  -WorkspaceName law-m365-lab `
  -Location uksouth
```

## Evidence to capture after deployment

| Evidence | Source | Why it matters |
| --- | --- | --- |
| Workspace overview | Azure portal | Shows workspace name, resource group, region, and workspace ID. |
| Sentinel onboarding state | Sentinel portal | Shows Sentinel is enabled on the workspace. |
| Data connector status | Sentinel content/data connectors | Shows which connectors are enabled, failed, or not licensed. |
| Analytics rules list | Sentinel analytics | Shows starter rules were created and enabled. |
| Incident sample or rule test | Sentinel incidents/logs | Shows alerts can generate incidents where data exists. |
| Cost management screenshot | Azure Cost Management | Shows the operator reviewed cost exposure. |

## Teardown preview

The teardown script previews by default:

```powershell
pwsh ./scripts/Remove-SentinelWorkspace.ps1 `
  -ResourceGroupName rg-m365-lab-sentinel `
  -WorkspaceName law-m365-lab
```

Delete starter analytics rules and the workspace only after confirming:

```powershell
pwsh ./scripts/Remove-SentinelWorkspace.ps1 `
  -ResourceGroupName rg-m365-lab-sentinel `
  -WorkspaceName law-m365-lab `
  -ConfirmTeardown
```

Remove only starter rules and keep the workspace:

```powershell
pwsh ./scripts/Remove-SentinelWorkspace.ps1 `
  -ResourceGroupName rg-m365-lab-sentinel `
  -WorkspaceName law-m365-lab `
  -RulesOnly `
  -ConfirmTeardown
```

Remove the resource group only when it contains lab-only resources:

```powershell
pwsh ./scripts/Remove-SentinelWorkspace.ps1 `
  -ResourceGroupName rg-m365-lab-sentinel `
  -WorkspaceName law-m365-lab `
  -RemoveResourceGroup `
  -ConfirmTeardown
```

## Teardown evidence checklist

| Evidence | Capture method | What it proves |
| --- | --- | --- |
| Teardown command output | Terminal output | Shows operator ran the script intentionally. |
| Workspace deleted or retained intentionally | Azure portal screenshot | Shows cost-bearing workspace was removed or retained by decision. |
| Rules deleted | Sentinel analytics screenshot/export | Shows starter rules were removed when requested. |
| Resource group status | Azure portal screenshot | Shows the lab resource group is gone or contains only intended resources. |
| Cost review | Azure Cost Management screenshot | Shows no unexpected cost trend remains. |

## Stop conditions

Stop and review before deleting if:

- The workspace name or resource group name does not include `lab`.
- The workspace contains production data.
- Other teams use the same Log Analytics workspace.
- You cannot confirm which analytics rules were created by the lab.
- The resource group contains non-lab resources.

## Common mistakes

- Deploying Sentinel in a production subscription for a training exercise.
- Enabling connectors without checking ingestion volume.
- Forgetting that Log Analytics retention and ingestion can continue after the lab.
- Removing a shared resource group instead of a lab-only resource group.
- Treating a successful deployment as complete without proving teardown.