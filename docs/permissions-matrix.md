# Permissions Matrix

This matrix maps each script to the Microsoft Graph scopes, administrative roles, and licence prerequisites it needs. Use the least-privilege option that works for your tenant, and prefer read-only roles for verification and evidence capture.

Scopes and role names change over time. Treat this matrix as the starting point and confirm against current Microsoft documentation before granting anything in a production tenant.

## Deployment scripts (state changing)

| Script | Microsoft Graph scopes | Other connections | Entra or workload role | Licence prerequisites |
| --- | --- | --- | --- | --- |
| `Deploy-ConditionalAccessPolicies.ps1` | `Policy.ReadWrite.ConditionalAccess`, `Policy.Read.All`, `Directory.Read.All` | None | Conditional Access Administrator (or Security Administrator) | Entra ID P1 for Conditional Access. The device compliance policy also needs Intune-enrolled devices to be meaningful. |
| `Deploy-PurviewDLP.ps1` | None (does not use Graph) | Security and Compliance PowerShell via `Connect-IPPSSession` | Compliance Administrator | Exchange DLP needs E3 or equivalent. Teams, SharePoint, and OneDrive DLP locations need E5, E5 Compliance, or the Information Protection and Governance add-on. |
| `Deploy-SentinelWorkspace.ps1` | None (uses Azure Resource Manager) | Az PowerShell via `Connect-AzAccount` | Azure Contributor on the subscription or resource group, plus Microsoft Sentinel Contributor | An Azure subscription. Sentinel and Log Analytics are consumption billed. Connector data depends on source workload licensing. |
| `Remove-SentinelWorkspace.ps1` | None (uses Azure Resource Manager) | Az PowerShell via `Connect-AzAccount` | Azure Contributor on the resource group, plus Microsoft Sentinel Contributor | Same subscription access as the deploy script. |

## Read-only scripts

| Script | Microsoft Graph scopes | Other connections | Entra or workload role | Licence prerequisites |
| --- | --- | --- | --- | --- |
| `Export-M365Baseline.ps1` | `Policy.Read.All`, `Directory.Read.All`, `AuditLog.Read.All`, `Reports.Read.All`, `RoleManagement.Read.Directory`, `SecurityEvents.Read.All`, `DeviceManagementConfiguration.Read.All`, `InformationProtectionPolicy.Read.All` | Exchange Online and Security and Compliance PowerShell for email, DLP, and label exports | Global Reader or Security Reader, plus View-Only Configuration in Exchange Online and a read-only compliance role | Individual captures degrade gracefully. Defender for Office 365 captures need that licence; Intune captures need Intune; Purview captures need compliance licensing. |
| `Get-M365SecureScore.ps1` | `SecurityEvents.Read.All` | None | Security Reader | Secure Score is available on most commercial plans. Control coverage varies by licence. |
| `Verify-M365Hardening.ps1` | `Policy.Read.All`, `Directory.Read.All`, `User.Read.All`, `Organization.Read.All`, `DeviceManagementConfiguration.Read.All`, `DeviceManagementManagedDevices.Read.All` | Optional: Exchange Online, Security and Compliance PowerShell, and Az for the email, Purview, and monitoring checks | Global Reader or Security Reader, plus View-Only Configuration and a read-only compliance role for the optional areas, and Azure Reader for the Sentinel check | Checks report `Skipped`, `NotConnected`, or `Manual` instead of failing when a licence or session is missing. |

## Notes

- The scripts connect interactively and request delegated scopes. None of them require application (app-only) permissions.
- `Verify-M365Hardening.ps1` and the read-only scripts never write to the tenant. Granting them write scopes is unnecessary.
- Grant `Policy.ReadWrite.ConditionalAccess` only for the duration of the Conditional Access lab module and use a dedicated lab admin account.
- For Azure, scope role assignments to the lab resource group rather than the whole subscription where possible.
- Record which roles and scopes you actually granted in your lab record (see [`deployment-prerequisites.md`](deployment-prerequisites.md)).
