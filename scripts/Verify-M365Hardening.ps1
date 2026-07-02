<#
.SYNOPSIS
Read-only Microsoft 365 hardening verification helper.

.DESCRIPTION
This script collects high-level verification signals for a Microsoft 365 security hardening lab.
It is intentionally read-only and designed to produce evidence-friendly console output.
Some checks require Microsoft Graph permissions and optional modules.

.EXAMPLE
pwsh ./scripts/Verify-M365Hardening.ps1

.EXAMPLE
pwsh ./scripts/Verify-M365Hardening.ps1 -ExportPath ./evidence/07-verification-script-output/m365-hardening-checks.csv
#>

[CmdletBinding()]
param(
    [string]$ExportPath
)

$ErrorActionPreference = "Stop"

$Results = New-Object System.Collections.Generic.List[object]

function Add-CheckResult {
    param(
        [Parameter(Mandatory = $true)][string]$Area,
        [Parameter(Mandatory = $true)][string]$Check,
        [Parameter(Mandatory = $true)][string]$Status,
        [string]$Evidence = "",
        [string]$Recommendation = ""
    )

    $Results.Add([pscustomobject]@{
        Timestamp      = (Get-Date).ToString("s")
        Area           = $Area
        Check          = $Check
        Status         = $Status
        Evidence       = $Evidence
        Recommendation = $Recommendation
    }) | Out-Null
}

function Test-CommandAvailable {
    param([Parameter(Mandatory = $true)][string]$CommandName)
    return [bool](Get-Command $CommandName -ErrorAction SilentlyContinue)
}

Write-Host "Microsoft 365 Hardening Verification" -ForegroundColor Cyan
Write-Host "Mode: read-only" -ForegroundColor Cyan
Write-Host "Started: $(Get-Date)" -ForegroundColor Cyan
Write-Host ""

# Local PowerShell environment checks
Add-CheckResult -Area "Local" -Check "PowerShell version" -Status "Info" -Evidence $PSVersionTable.PSVersion.ToString() -Recommendation "Use PowerShell 7+ for best compatibility."

if (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication) {
    Add-CheckResult -Area "Local" -Check "Microsoft Graph PowerShell module" -Status "Present" -Evidence "Microsoft.Graph.Authentication module found" -Recommendation "Import Microsoft Graph and connect with read permissions."
} else {
    Add-CheckResult -Area "Local" -Check "Microsoft Graph PowerShell module" -Status "Missing" -Evidence "Microsoft.Graph.Authentication module not found" -Recommendation "Install-Module Microsoft.Graph -Scope CurrentUser"
}

if (Get-Module -ListAvailable -Name ExchangeOnlineManagement) {
    Add-CheckResult -Area "Local" -Check "Exchange Online PowerShell module" -Status "Present" -Evidence "ExchangeOnlineManagement module found" -Recommendation "Use for EOP and Defender for Office 365 checks where needed."
} else {
    Add-CheckResult -Area "Local" -Check "Exchange Online PowerShell module" -Status "Missing" -Evidence "ExchangeOnlineManagement module not found" -Recommendation "Install-Module ExchangeOnlineManagement -Scope CurrentUser"
}

# Microsoft Graph connection checks
if (Test-CommandAvailable -CommandName Get-MgContext) {
    $MgContext = Get-MgContext
    if ($null -ne $MgContext) {
        Add-CheckResult -Area "Graph" -Check "Microsoft Graph connection" -Status "Connected" -Evidence "TenantId=$($MgContext.TenantId); Account=$($MgContext.Account)" -Recommendation "Run tenant checks with least-privilege read permissions."
    } else {
        Add-CheckResult -Area "Graph" -Check "Microsoft Graph connection" -Status "NotConnected" -Evidence "No active Graph context" -Recommendation "Run Connect-MgGraph with appropriate read-only scopes."
    }
} else {
    Add-CheckResult -Area "Graph" -Check "Microsoft Graph connection" -Status "Unavailable" -Evidence "Get-MgContext command unavailable" -Recommendation "Install and import Microsoft.Graph."
}

# Conditional Access policies
if (Test-CommandAvailable -CommandName Get-MgIdentityConditionalAccessPolicy) {
    try {
        $Policies = Get-MgIdentityConditionalAccessPolicy -All
        $PolicyCount = ($Policies | Measure-Object).Count
        Add-CheckResult -Area "Identity" -Check "Conditional Access policies" -Status "Info" -Evidence "Policies found: $PolicyCount" -Recommendation "Confirm pilot, report-only, emergency access exclusions, and admin MFA policies."

        $EnabledPolicies = ($Policies | Where-Object { $_.State -eq "enabled" } | Measure-Object).Count
        Add-CheckResult -Area "Identity" -Check "Enabled Conditional Access policies" -Status "Info" -Evidence "Enabled policies: $EnabledPolicies" -Recommendation "Ensure enforced policies were tested in report-only or pilot scope first."
    } catch {
        Add-CheckResult -Area "Identity" -Check "Conditional Access policies" -Status "Error" -Evidence $_.Exception.Message -Recommendation "Confirm Graph permissions include Policy.Read.All or equivalent."
    }
} else {
    Add-CheckResult -Area "Identity" -Check "Conditional Access policies" -Status "Skipped" -Evidence "Get-MgIdentityConditionalAccessPolicy unavailable" -Recommendation "Install Microsoft.Graph.Identity.SignIns module."
}

# Directory roles
if (Test-CommandAvailable -CommandName Get-MgDirectoryRole) {
    try {
        $Roles = Get-MgDirectoryRole -All
        $RoleCount = ($Roles | Measure-Object).Count
        Add-CheckResult -Area "Identity" -Check "Active directory roles" -Status "Info" -Evidence "Active roles found: $RoleCount" -Recommendation "Review privileged roles and document business justification."
    } catch {
        Add-CheckResult -Area "Identity" -Check "Active directory roles" -Status "Error" -Evidence $_.Exception.Message -Recommendation "Confirm Directory.Read.All or equivalent read permission."
    }
} else {
    Add-CheckResult -Area "Identity" -Check "Active directory roles" -Status "Skipped" -Evidence "Get-MgDirectoryRole unavailable" -Recommendation "Install Microsoft.Graph.Identity.DirectoryManagement module."
}

# Users with display names containing breakglass or emergency
if (Test-CommandAvailable -CommandName Get-MgUser) {
    try {
        $EmergencyUsers = Get-MgUser -All -Property Id,DisplayName,UserPrincipalName,AccountEnabled | Where-Object {
            $_.DisplayName -match "breakglass|break-glass|emergency" -or $_.UserPrincipalName -match "breakglass|break-glass|emergency"
        }
        $EmergencyCount = ($EmergencyUsers | Measure-Object).Count
        $Status = if ($EmergencyCount -ge 2) { "Pass" } elseif ($EmergencyCount -eq 1) { "Warning" } else { "Fail" }
        Add-CheckResult -Area "Identity" -Check "Emergency access accounts" -Status $Status -Evidence "Matching accounts found: $EmergencyCount" -Recommendation "Maintain at least two emergency access accounts and monitor their use."
    } catch {
        Add-CheckResult -Area "Identity" -Check "Emergency access accounts" -Status "Error" -Evidence $_.Exception.Message -Recommendation "Confirm User.Read.All or Directory.Read.All permission."
    }
} else {
    Add-CheckResult -Area "Identity" -Check "Emergency access accounts" -Status "Skipped" -Evidence "Get-MgUser unavailable" -Recommendation "Install Microsoft.Graph.Users module."
}

# Authentication methods policy availability
if (Test-CommandAvailable -CommandName Get-MgPolicyAuthenticationMethodPolicy) {
    try {
        $AuthPolicy = Get-MgPolicyAuthenticationMethodPolicy
        Add-CheckResult -Area "Identity" -Check "Authentication methods policy" -Status "Info" -Evidence "Policy id: $($AuthPolicy.Id)" -Recommendation "Review allowed authentication methods and registration campaign settings."
    } catch {
        Add-CheckResult -Area "Identity" -Check "Authentication methods policy" -Status "Error" -Evidence $_.Exception.Message -Recommendation "Confirm Policy.Read.All or equivalent permission."
    }
} else {
    Add-CheckResult -Area "Identity" -Check "Authentication methods policy" -Status "Skipped" -Evidence "Get-MgPolicyAuthenticationMethodPolicy unavailable" -Recommendation "Install Microsoft.Graph.Identity.SignIns module."
}

# Organisation info
if (Test-CommandAvailable -CommandName Get-MgOrganization) {
    try {
        $Org = Get-MgOrganization
        $OrgName = ($Org | Select-Object -First 1).DisplayName
        Add-CheckResult -Area "Tenant" -Check "Organisation details" -Status "Info" -Evidence "Organisation: $OrgName" -Recommendation "Record tenant name, licence assumptions, and lab owner in evidence pack."
    } catch {
        Add-CheckResult -Area "Tenant" -Check "Organisation details" -Status "Error" -Evidence $_.Exception.Message -Recommendation "Confirm Organization.Read.All or equivalent permission."
    }
} else {
    Add-CheckResult -Area "Tenant" -Check "Organisation details" -Status "Skipped" -Evidence "Get-MgOrganization unavailable" -Recommendation "Install Microsoft.Graph.Identity.DirectoryManagement module."
}

# Email checks (read-only, requires an existing Connect-ExchangeOnline session)
# Exchange Online cmdlets are loaded into the session by Connect-ExchangeOnline, so command availability doubles as a connection check.
if (Test-CommandAvailable -CommandName Get-AntiPhishPolicy) {
    try {
        $AntiPhish = Get-AntiPhishPolicy
        $AntiPhishCount = ($AntiPhish | Measure-Object).Count
        Add-CheckResult -Area "Email" -Check "Anti-phishing policies" -Status "Info" -Evidence "Policies found: $AntiPhishCount" -Recommendation "Confirm impersonation protection and mailbox intelligence settings for pilot users."
    } catch {
        Add-CheckResult -Area "Email" -Check "Anti-phishing policies" -Status "Error" -Evidence $_.Exception.Message -Recommendation "Confirm the account has an Exchange Online read role such as View-Only Configuration."
    }

    try {
        $Malware = Get-MalwareFilterPolicy
        Add-CheckResult -Area "Email" -Check "Anti-malware policies" -Status "Info" -Evidence "Policies found: $(($Malware | Measure-Object).Count)" -Recommendation "Confirm the common attachments filter and admin notification settings."
    } catch {
        Add-CheckResult -Area "Email" -Check "Anti-malware policies" -Status "Error" -Evidence $_.Exception.Message -Recommendation "Confirm Exchange Online read permissions."
    }

    try {
        $Spam = Get-HostedContentFilterPolicy
        Add-CheckResult -Area "Email" -Check "Anti-spam policies" -Status "Info" -Evidence "Policies found: $(($Spam | Measure-Object).Count)" -Recommendation "Review spam action, bulk threshold, and allowed sender lists."
    } catch {
        Add-CheckResult -Area "Email" -Check "Anti-spam policies" -Status "Error" -Evidence $_.Exception.Message -Recommendation "Confirm Exchange Online read permissions."
    }

    if (Test-CommandAvailable -CommandName Get-SafeLinksPolicy) {
        try {
            $SafeLinks = Get-SafeLinksPolicy
            $SafeLinksCount = ($SafeLinks | Measure-Object).Count
            $Status = if ($SafeLinksCount -ge 1) { "Pass" } else { "Warning" }
            Add-CheckResult -Area "Email" -Check "Safe Links policies" -Status $Status -Evidence "Policies found: $SafeLinksCount" -Recommendation "Configure Safe Links for pilot users where Defender for Office 365 is licensed."
        } catch {
            Add-CheckResult -Area "Email" -Check "Safe Links policies" -Status "Warning" -Evidence $_.Exception.Message -Recommendation "Safe Links requires Defender for Office 365 licensing. Record the limitation if unlicensed."
        }
    } else {
        Add-CheckResult -Area "Email" -Check "Safe Links policies" -Status "Skipped" -Evidence "Get-SafeLinksPolicy unavailable" -Recommendation "Safe Links requires Defender for Office 365 licensing. Record the limitation if unlicensed."
    }

    if (Test-CommandAvailable -CommandName Get-SafeAttachmentPolicy) {
        try {
            $SafeAttach = Get-SafeAttachmentPolicy
            $SafeAttachCount = ($SafeAttach | Measure-Object).Count
            $Status = if ($SafeAttachCount -ge 1) { "Pass" } else { "Warning" }
            Add-CheckResult -Area "Email" -Check "Safe Attachments policies" -Status $Status -Evidence "Policies found: $SafeAttachCount" -Recommendation "Configure Safe Attachments for pilot users where Defender for Office 365 is licensed."
        } catch {
            Add-CheckResult -Area "Email" -Check "Safe Attachments policies" -Status "Warning" -Evidence $_.Exception.Message -Recommendation "Safe Attachments requires Defender for Office 365 licensing. Record the limitation if unlicensed."
        }
    } else {
        Add-CheckResult -Area "Email" -Check "Safe Attachments policies" -Status "Skipped" -Evidence "Get-SafeAttachmentPolicy unavailable" -Recommendation "Safe Attachments requires Defender for Office 365 licensing. Record the limitation if unlicensed."
    }

    try {
        $Dkim = Get-DkimSigningConfig
        $DkimEnabled = ($Dkim | Where-Object { $_.Enabled } | Measure-Object).Count
        $DkimTotal = ($Dkim | Measure-Object).Count
        $Status = if ($DkimEnabled -ge 1) { "Pass" } else { "Warning" }
        Add-CheckResult -Area "Email" -Check "DKIM signing" -Status $Status -Evidence "Enabled domains: $DkimEnabled of $DkimTotal" -Recommendation "Enable DKIM for all sending domains and publish matching DNS records."
    } catch {
        Add-CheckResult -Area "Email" -Check "DKIM signing" -Status "Error" -Evidence $_.Exception.Message -Recommendation "Confirm Exchange Online read permissions."
    }

    try {
        $ExternalTag = Get-ExternalInOutlook
        $TagEnabled = ($ExternalTag | Where-Object { $_.Enabled } | Measure-Object).Count -gt 0
        $Status = if ($TagEnabled) { "Pass" } else { "Warning" }
        Add-CheckResult -Area "Email" -Check "External sender tagging" -Status $Status -Evidence "External sender tagging enabled: $TagEnabled" -Recommendation "Enable external sender tagging or document an alternative user awareness approach."
    } catch {
        Add-CheckResult -Area "Email" -Check "External sender tagging" -Status "Error" -Evidence $_.Exception.Message -Recommendation "Confirm Exchange Online read permissions."
    }
} else {
    Add-CheckResult -Area "Email" -Check "Exchange Online policy checks" -Status "NotConnected" -Evidence "No Exchange Online session detected" -Recommendation "Run Connect-ExchangeOnline with a read-only role, then re-run this script for email checks."
}

Add-CheckResult -Area "Email" -Check "Impersonation protection scope" -Status "Manual" -Evidence "Manual verification required" -Recommendation "Review VIP and domain impersonation entries in the anti-phishing policy and capture a screenshot or export."
Add-CheckResult -Area "Email" -Check "Mail flow test evidence" -Status "Manual" -Evidence "Manual verification required" -Recommendation "Send benign test messages and capture message trace evidence for pilot users."

# Endpoint checks (read-only, requires Microsoft Graph with DeviceManagementConfiguration.Read.All and DeviceManagementManagedDevices.Read.All)
if (Test-CommandAvailable -CommandName Get-MgDeviceManagementDeviceCompliancePolicy) {
    try {
        $CompliancePolicies = Get-MgDeviceManagementDeviceCompliancePolicy -All
        $CompliancePolicyCount = ($CompliancePolicies | Measure-Object).Count
        $Status = if ($CompliancePolicyCount -ge 1) { "Pass" } else { "Warning" }
        Add-CheckResult -Area "Endpoint" -Check "Intune device compliance policies" -Status $Status -Evidence "Policies found: $CompliancePolicyCount" -Recommendation "Confirm a compliance policy is assigned to the endpoint pilot group."
    } catch {
        Add-CheckResult -Area "Endpoint" -Check "Intune device compliance policies" -Status "Error" -Evidence $_.Exception.Message -Recommendation "Confirm DeviceManagementConfiguration.Read.All permission and Intune licensing."
    }
} else {
    Add-CheckResult -Area "Endpoint" -Check "Intune device compliance policies" -Status "Skipped" -Evidence "Get-MgDeviceManagementDeviceCompliancePolicy unavailable" -Recommendation "Install Microsoft.Graph.DeviceManagement and connect with DeviceManagementConfiguration.Read.All."
}

if (Test-CommandAvailable -CommandName Get-MgDeviceManagementManagedDevice) {
    try {
        $ManagedDevices = Get-MgDeviceManagementManagedDevice -All -Property Id,ComplianceState
        $DeviceCount = ($ManagedDevices | Measure-Object).Count
        $CompliantCount = ($ManagedDevices | Where-Object { $_.ComplianceState -eq "compliant" } | Measure-Object).Count
        Add-CheckResult -Area "Endpoint" -Check "Managed devices" -Status "Info" -Evidence "Managed devices: $DeviceCount; compliant: $CompliantCount" -Recommendation "Investigate non-compliant test devices and capture the compliance report."
    } catch {
        Add-CheckResult -Area "Endpoint" -Check "Managed devices" -Status "Error" -Evidence $_.Exception.Message -Recommendation "Confirm DeviceManagementManagedDevices.Read.All permission and Intune licensing."
    }
} else {
    Add-CheckResult -Area "Endpoint" -Check "Managed devices" -Status "Skipped" -Evidence "Get-MgDeviceManagementManagedDevice unavailable" -Recommendation "Install Microsoft.Graph.DeviceManagement and connect with DeviceManagementManagedDevices.Read.All."
}

Add-CheckResult -Area "Endpoint" -Check "Defender for Endpoint onboarding" -Status "Manual" -Evidence "Manual verification required" -Recommendation "Confirm the test device appears in the Defender portal device inventory and capture a screenshot."
Add-CheckResult -Area "Endpoint" -Check "Attack surface reduction rule state" -Status "Manual" -Evidence "Manual verification required" -Recommendation "Confirm ASR rules were validated in audit mode before block mode and capture the policy export."

# Purview checks (read-only, requires an existing Connect-IPPSSession session)
if (Test-CommandAvailable -CommandName Get-DlpCompliancePolicy) {
    try {
        $DlpPolicies = Get-DlpCompliancePolicy
        $DlpCount = ($DlpPolicies | Measure-Object).Count
        Add-CheckResult -Area "Purview" -Check "DLP policies" -Status "Info" -Evidence "Policies found: $DlpCount" -Recommendation "Validate matches in audit-only mode before moving any DLP policy to block mode."

        foreach ($LabPolicyName in @("UK PII Protection", "Financial Data Protection")) {
            $LabPolicy = $DlpPolicies | Where-Object { $_.Name -eq $LabPolicyName }
            if ($LabPolicy) {
                Add-CheckResult -Area "Purview" -Check "Lab DLP policy: $LabPolicyName" -Status "Pass" -Evidence "Mode: $($LabPolicy.Mode)" -Recommendation "Keep the policy in audit-only mode until matches and false positives have been reviewed."
            } else {
                Add-CheckResult -Area "Purview" -Check "Lab DLP policy: $LabPolicyName" -Status "Info" -Evidence "Policy not found" -Recommendation "Deploy with scripts/Deploy-PurviewDLP.ps1 if this lab module is in scope."
            }
        }
    } catch {
        Add-CheckResult -Area "Purview" -Check "DLP policies" -Status "Error" -Evidence $_.Exception.Message -Recommendation "Confirm a Compliance Administrator or read-only compliance role."
    }

    if (Test-CommandAvailable -CommandName Get-Label) {
        try {
            $Labels = Get-Label
            Add-CheckResult -Area "Purview" -Check "Sensitivity labels" -Status "Info" -Evidence "Labels found: $(($Labels | Measure-Object).Count)" -Recommendation "Confirm the lab label taxonomy exists and is published to pilot users."
        } catch {
            Add-CheckResult -Area "Purview" -Check "Sensitivity labels" -Status "Error" -Evidence $_.Exception.Message -Recommendation "Confirm compliance read permissions."
        }
    } else {
        Add-CheckResult -Area "Purview" -Check "Sensitivity labels" -Status "Skipped" -Evidence "Get-Label unavailable" -Recommendation "Reconnect with Connect-IPPSSession to load compliance cmdlets."
    }
} else {
    Add-CheckResult -Area "Purview" -Check "Purview compliance checks" -Status "NotConnected" -Evidence "No Security and Compliance session detected" -Recommendation "Run Connect-IPPSSession with a read-only compliance role, then re-run this script for Purview checks."
}

Add-CheckResult -Area "Purview" -Check "DLP incident review" -Status "Manual" -Evidence "Manual verification required" -Recommendation "Review DLP alerts generated by safe test data and capture the incident evidence."

# Monitoring checks (read-only)
if (Test-CommandAvailable -CommandName Get-AdminAuditLogConfig) {
    try {
        $AuditConfig = Get-AdminAuditLogConfig
        $AuditEnabled = [bool]$AuditConfig.UnifiedAuditLogIngestionEnabled
        $Status = if ($AuditEnabled) { "Pass" } else { "Fail" }
        Add-CheckResult -Area "Monitoring" -Check "Unified audit log ingestion" -Status $Status -Evidence "UnifiedAuditLogIngestionEnabled: $AuditEnabled" -Recommendation "Enable unified audit logging so security events are searchable."
    } catch {
        Add-CheckResult -Area "Monitoring" -Check "Unified audit log ingestion" -Status "Error" -Evidence $_.Exception.Message -Recommendation "Confirm Exchange Online read permissions."
    }
} else {
    Add-CheckResult -Area "Monitoring" -Check "Unified audit log ingestion" -Status "NotConnected" -Evidence "No Exchange Online session detected" -Recommendation "Run Connect-ExchangeOnline, then re-run this script to check audit log status."
}

if ((Test-CommandAvailable -CommandName Get-AzContext) -and (Test-CommandAvailable -CommandName Get-AzOperationalInsightsWorkspace)) {
    try {
        $AzContext = Get-AzContext -ErrorAction SilentlyContinue
        if ($null -ne $AzContext) {
            $LabWorkspaces = Get-AzOperationalInsightsWorkspace | Where-Object { $_.Name -match "lab" }
            Add-CheckResult -Area "Monitoring" -Check "Sentinel lab workspace" -Status "Info" -Evidence "Lab-named workspaces found: $(($LabWorkspaces | Measure-Object).Count)" -Recommendation "Confirm connector health and analytics rules in the Sentinel portal, and tear down the workspace after the lab."
        } else {
            Add-CheckResult -Area "Monitoring" -Check "Sentinel lab workspace" -Status "NotConnected" -Evidence "No Azure context" -Recommendation "Run Connect-AzAccount if the optional Sentinel module is in scope, then re-run this script."
        }
    } catch {
        Add-CheckResult -Area "Monitoring" -Check "Sentinel lab workspace" -Status "Error" -Evidence $_.Exception.Message -Recommendation "Confirm Azure read permissions on the lab subscription."
    }
} else {
    Add-CheckResult -Area "Monitoring" -Check "Sentinel lab workspace" -Status "Skipped" -Evidence "Az modules unavailable" -Recommendation "Optional. Install Az.Accounts and Az.OperationalInsights if the Sentinel module is in scope."
}

Add-CheckResult -Area "Monitoring" -Check "Security portal alerts and incidents" -Status "Manual" -Evidence "Manual verification required" -Recommendation "Review the Defender portal alert queue and capture an example alert or incident record."
Add-CheckResult -Area "Monitoring" -Check "Analytics rule review" -Status "Manual" -Evidence "Manual verification required" -Recommendation "Confirm the starter Sentinel analytics rules are enabled and tuned, or document the alternative monitoring approach."

Write-Host "Verification results" -ForegroundColor Cyan
$Results | Format-Table -AutoSize

if ($ExportPath) {
    $Parent = Split-Path -Path $ExportPath -Parent
    if ($Parent -and -not (Test-Path -Path $Parent)) {
        New-Item -Path $Parent -ItemType Directory -Force | Out-Null
    }

    $Results | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    Write-Host "Results exported to $ExportPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "Completed: $(Get-Date)" -ForegroundColor Cyan
