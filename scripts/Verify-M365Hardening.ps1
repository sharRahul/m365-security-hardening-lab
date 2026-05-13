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

Add-CheckResult -Area "Email" -Check "EOP and Defender for Office 365 policies" -Status "Manual" -Evidence "Manual review required" -Recommendation "Export or screenshot anti-phishing, anti-malware, Safe Links, and Safe Attachments policies."
Add-CheckResult -Area "Endpoint" -Check "Endpoint security baseline" -Status "Manual" -Evidence "Manual review required" -Recommendation "Capture Intune endpoint security baseline, device compliance, and Defender onboarding evidence."
Add-CheckResult -Area "Purview" -Check "DLP and sensitivity labels" -Status "Manual" -Evidence "Manual review required" -Recommendation "Capture DLP policies, label publication, and audit log evidence."
Add-CheckResult -Area "Monitoring" -Check "Audit and alert visibility" -Status "Manual" -Evidence "Manual review required" -Recommendation "Capture audit log status, security portal incidents, and optional Sentinel connector status."

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
