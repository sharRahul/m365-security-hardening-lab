<#
.SYNOPSIS
Exports a Microsoft 365 security configuration baseline before lab hardening changes are applied.

.DESCRIPTION
Captures key tenant security settings from Microsoft Graph, Exchange Online, Defender for Office 365, Purview, and Microsoft Defender for Endpoint where available. The script is designed for lab evidence collection and skips unavailable workloads or unlicensed features with warnings instead of failing the whole baseline export.

The default output folder is outputs/baseline-YYYY-MM-DD relative to the repository root. Use -OutputPath to override it.

.PARAMETER OutputPath
Optional folder path where the baseline JSON files will be written.

.EXAMPLE
pwsh ./scripts/Export-M365Baseline.ps1

.EXAMPLE
pwsh ./scripts/Export-M365Baseline.ps1 -OutputPath ./outputs/baseline-pre-hardening

.NOTES
Required modules: Microsoft.Graph and ExchangeOnlineManagement.
Recommended Graph scopes: Policy.Read.All, Directory.Read.All, AuditLog.Read.All, Reports.Read.All, RoleManagement.Read.Directory, SecurityEvents.Read.All, DeviceManagementConfiguration.Read.All, InformationProtectionPolicy.Read.All.
#>

[CmdletBinding()]
param(
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

function Test-ModuleAvailable {
    param([Parameter(Mandatory = $true)][string]$Name)
    return [bool](Get-Module -ListAvailable -Name $Name)
}

function Import-RequiredModule {
    param([Parameter(Mandatory = $true)][string]$Name)

    if (-not (Test-ModuleAvailable -Name $Name)) {
        throw "Required PowerShell module '$Name' is not installed. Install it with: Install-Module $Name -Scope CurrentUser"
    }

    Import-Module $Name -ErrorAction Stop
}

function Get-DefaultOutputPath {
    $repoRoot = Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..')
    $folderName = 'baseline-{0}' -f (Get-Date -Format 'yyyy-MM-dd')
    return Join-Path -Path (Join-Path -Path $repoRoot -ChildPath 'outputs') -ChildPath $folderName
}

function ConvertTo-JsonFile {
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$InputObject,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $InputObject | ConvertTo-Json -Depth 30 | Out-File -FilePath $Path -Encoding utf8
}

function Add-CaptureResult {
    param(
        [Parameter(Mandatory = $true)][System.Collections.Generic.List[object]]$Results,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Status,
        [string]$Path = '',
        [string]$Message = ''
    )

    $size = 0
    if ($Path -and (Test-Path -Path $Path)) {
        $size = (Get-Item -Path $Path).Length
    }

    $Results.Add([pscustomobject]@{
        Item      = $Name
        Status    = $Status
        File      = if ($Path) { Split-Path -Path $Path -Leaf } else { '' }
        SizeBytes = $size
        Message   = $Message
    }) | Out-Null
}

function Invoke-BaselineCapture {
    param(
        [Parameter(Mandatory = $true)][System.Collections.Generic.List[object]]$Results,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$FileName,
        [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock
    )

    $targetPath = Join-Path -Path $script:BaselineOutputPath -ChildPath $FileName

    try {
        $data = & $ScriptBlock
        ConvertTo-JsonFile -InputObject $data -Path $targetPath
        Add-CaptureResult -Results $Results -Name $Name -Status 'Captured' -Path $targetPath -Message 'OK'
    } catch {
        $message = $_.Exception.Message
        Write-Warning "$Name skipped or incomplete: $message"
        Add-CaptureResult -Results $Results -Name $Name -Status 'Skipped' -Message $message
    }
}

function Connect-GraphIfNeeded {
    $context = Get-MgContext -ErrorAction SilentlyContinue
    if ($null -ne $context) {
        Write-Host "Microsoft Graph already connected as $($context.Account)." -ForegroundColor Cyan
        return
    }

    $scopes = @(
        'Policy.Read.All',
        'Directory.Read.All',
        'AuditLog.Read.All',
        'Reports.Read.All',
        'RoleManagement.Read.Directory',
        'SecurityEvents.Read.All',
        'DeviceManagementConfiguration.Read.All',
        'InformationProtectionPolicy.Read.All'
    )

    Connect-MgGraph -Scopes $scopes -NoWelcome
}

function Connect-ExchangeIfNeeded {
    if (-not (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
        return
    }

    $connection = Get-ConnectionInformation -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Connected' } | Select-Object -First 1
    if ($null -eq $connection) {
        Connect-ExchangeOnline -ShowBanner:$false
    }
}

function Connect-ComplianceIfNeeded {
    if (-not (Get-Command Connect-IPPSSession -ErrorAction SilentlyContinue)) {
        Write-Warning 'Connect-IPPSSession is unavailable; Purview DLP and sensitivity label exports may be skipped.'
        return
    }

    $complianceCommand = Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue
    if ($null -eq $complianceCommand) {
        Connect-IPPSSession | Out-Null
    }
}

function Invoke-GraphGetAll {
    param([Parameter(Mandatory = $true)][string]$Uri)

    $items = New-Object System.Collections.Generic.List[object]
    $next = $Uri

    while ($next) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $next -ErrorAction Stop
        if ($response.value) {
            foreach ($item in $response.value) {
                $items.Add($item) | Out-Null
            }
        } else {
            return $response
        }

        $next = $response.'@odata.nextLink'
    }

    return $items
}

if (-not $OutputPath) {
    $OutputPath = Get-DefaultOutputPath
}

$script:BaselineOutputPath = $OutputPath
New-Item -Path $script:BaselineOutputPath -ItemType Directory -Force | Out-Null
$CaptureResults = New-Object System.Collections.Generic.List[object]

Write-Host 'Microsoft 365 baseline export' -ForegroundColor Cyan
Write-Host "Output folder: $script:BaselineOutputPath" -ForegroundColor Cyan
Write-Host ''

Import-RequiredModule -Name Microsoft.Graph.Authentication
Import-RequiredModule -Name ExchangeOnlineManagement

Connect-GraphIfNeeded
Connect-ExchangeIfNeeded
Connect-ComplianceIfNeeded

Invoke-BaselineCapture -Results $CaptureResults -Name 'Conditional Access policies' -FileName 'ConditionalAccessPolicies.json' -ScriptBlock {
    Invoke-GraphGetAll -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies'
}

Invoke-BaselineCapture -Results $CaptureResults -Name 'MFA registration report' -FileName 'MFARegistrationReport.json' -ScriptBlock {
    Invoke-GraphGetAll -Uri 'https://graph.microsoft.com/v1.0/reports/authenticationMethods/userRegistrationDetails'
}

Invoke-BaselineCapture -Results $CaptureResults -Name 'Privileged role assignments' -FileName 'PrivilegedRoleAssignments.json' -ScriptBlock {
    Invoke-GraphGetAll -Uri 'https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments?$expand=principal,roleDefinition'
}

Invoke-BaselineCapture -Results $CaptureResults -Name 'Unified audit log status' -FileName 'UnifiedAuditLogStatus.json' -ScriptBlock {
    $auditConfig = Get-AdminAuditLogConfig -ErrorAction Stop
    [pscustomobject]@{
        UnifiedAuditLogIngestionEnabled = $auditConfig.UnifiedAuditLogIngestionEnabled
        AdminAuditLogEnabled            = $auditConfig.AdminAuditLogEnabled
        LogLevel                        = $auditConfig.LogLevel
        CapturedAtUtc                   = (Get-Date).ToUniversalTime().ToString('o')
    }
}

Invoke-BaselineCapture -Results $CaptureResults -Name 'Anti-phishing policies' -FileName 'AntiPhishingPolicies.json' -ScriptBlock {
    if (-not (Get-Command Get-AntiPhishPolicy -ErrorAction SilentlyContinue)) {
        throw 'Get-AntiPhishPolicy is unavailable. Defender for Office 365 may not be licensed or the session is not connected.'
    }

    [pscustomobject]@{
        Policies = Get-AntiPhishPolicy -ErrorAction Stop
        Rules    = if (Get-Command Get-AntiPhishRule -ErrorAction SilentlyContinue) { Get-AntiPhishRule -ErrorAction SilentlyContinue } else { @() }
    }
}

Invoke-BaselineCapture -Results $CaptureResults -Name 'Safe Links and Safe Attachments' -FileName 'SafeLinksAndSafeAttachments.json' -ScriptBlock {
    if (-not (Get-Command Get-SafeLinksPolicy -ErrorAction SilentlyContinue)) {
        throw 'Safe Links cmdlets are unavailable. Defender for Office 365 may not be licensed or the session is not connected.'
    }

    [pscustomobject]@{
        SafeLinksPolicies       = Get-SafeLinksPolicy -ErrorAction SilentlyContinue
        SafeLinksRules          = if (Get-Command Get-SafeLinksRule -ErrorAction SilentlyContinue) { Get-SafeLinksRule -ErrorAction SilentlyContinue } else { @() }
        SafeAttachmentPolicies  = if (Get-Command Get-SafeAttachmentPolicy -ErrorAction SilentlyContinue) { Get-SafeAttachmentPolicy -ErrorAction SilentlyContinue } else { @() }
        SafeAttachmentRules     = if (Get-Command Get-SafeAttachmentRule -ErrorAction SilentlyContinue) { Get-SafeAttachmentRule -ErrorAction SilentlyContinue } else { @() }
    }
}

Invoke-BaselineCapture -Results $CaptureResults -Name 'MDE security baseline' -FileName 'MDESecurityBaseline.json' -ScriptBlock {
    try {
        $intents = Invoke-GraphGetAll -Uri 'https://graph.microsoft.com/beta/deviceManagement/intents'
        $mdeIntents = @($intents | Where-Object { $_.displayName -match 'Defender|Endpoint|MDE|Security Baseline' })
        [pscustomobject]@{
            BaselineIntents = $mdeIntents
            Source          = 'Microsoft Graph beta deviceManagement/intents'
            CapturedAtUtc   = (Get-Date).ToUniversalTime().ToString('o')
        }
    } catch {
        throw 'MDE or Intune endpoint security baseline data is unavailable for this tenant or permission set.'
    }
}

Invoke-BaselineCapture -Results $CaptureResults -Name 'DLP policies' -FileName 'DLPPolicies.json' -ScriptBlock {
    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
        throw 'Get-DlpCompliancePolicy is unavailable. Connect to Security and Compliance PowerShell and confirm Purview licensing.'
    }

    [pscustomobject]@{
        Policies = Get-DlpCompliancePolicy -ErrorAction Stop
        Rules    = if (Get-Command Get-DlpComplianceRule -ErrorAction SilentlyContinue) { Get-DlpComplianceRule -ErrorAction SilentlyContinue } else { @() }
    }
}

Invoke-BaselineCapture -Results $CaptureResults -Name 'Sensitivity labels' -FileName 'SensitivityLabels.json' -ScriptBlock {
    if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) {
        throw 'Get-Label is unavailable. Connect to Security and Compliance PowerShell and confirm Purview Information Protection availability.'
    }

    [pscustomobject]@{
        Labels        = Get-Label -ErrorAction Stop
        LabelPolicies = if (Get-Command Get-LabelPolicy -ErrorAction SilentlyContinue) { Get-LabelPolicy -ErrorAction SilentlyContinue } else { @() }
    }
}

Write-Host ''
Write-Host 'Baseline capture summary' -ForegroundColor Cyan
$CaptureResults | Format-Table -AutoSize

$summaryPath = Join-Path -Path $script:BaselineOutputPath -ChildPath 'BaselineCaptureSummary.json'
ConvertTo-JsonFile -InputObject $CaptureResults -Path $summaryPath
Write-Host "Summary exported to $summaryPath" -ForegroundColor Green
