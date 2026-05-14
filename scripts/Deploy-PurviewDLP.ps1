<#
.SYNOPSIS
Deploys starter Microsoft Purview DLP policies for a Microsoft 365 hardening lab.

.DESCRIPTION
Connects to Security and Compliance PowerShell through ExchangeOnlineManagement and creates two DLP policies:

- UK PII Protection
- Financial Data Protection

Policies are created in audit-only mode by default. Use -Enforce to move matching policies and rules to block mode after lab validation.

.PARAMETER Enforce
Moves the configured DLP policies from audit-only mode to block mode by enabling restrictive rule actions.

.EXAMPLE
pwsh ./scripts/Deploy-PurviewDLP.ps1

.EXAMPLE
pwsh ./scripts/Deploy-PurviewDLP.ps1 -Enforce

.NOTES
Required module: ExchangeOnlineManagement.
Run in a lab tenant first. DLP sensitive information type names can vary by region and service availability.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$Enforce
)

$ErrorActionPreference = 'Stop'

$PolicyDefinitions = @(
    @{
        Name        = 'UK PII Protection'
        Comment     = 'Lab DLP policy for UK personal data signals across Exchange, SharePoint, OneDrive, and Teams.'
        Mode        = if ($Enforce) { 'Enable' } else { 'TestWithoutNotifications' }
        RuleName    = 'UK PII Protection - Detect and protect'
        Locations   = @{
            ExchangeLocation   = 'All'
            SharePointLocation = 'All'
            OneDriveLocation   = 'All'
            TeamsLocation      = 'All'
        }
        SensitiveInformation = @(
            @{ Name = 'U.K. National Insurance Number'; MinCount = 1 }
            @{ Name = 'U.K. Passport Number'; MinCount = 1 }
            @{ Name = 'U.K. Drivers License Number'; MinCount = 1 }
        )
        AuditActions = @{
            GenerateIncidentReport = 'SiteAdmin'
            NotifyUser             = @()
        }
        EnforceActions = @{
            BlockAccess            = $true
            GenerateIncidentReport = 'SiteAdmin'
            NotifyUser             = @('LastModifier')
        }
    }
    @{
        Name        = 'Financial Data Protection'
        Comment     = 'Lab DLP policy for payment card, bank account, and SWIFT/BIC data signals.'
        Mode        = if ($Enforce) { 'Enable' } else { 'TestWithoutNotifications' }
        RuleName    = 'Financial Data Protection - Detect and protect'
        Locations   = @{
            ExchangeLocation   = 'All'
            SharePointLocation = 'All'
            OneDriveLocation   = 'All'
            TeamsLocation      = 'All'
        }
        SensitiveInformation = @(
            @{ Name = 'Credit Card Number'; MinCount = 1 }
            @{ Name = 'International Banking Account Number (IBAN)'; MinCount = 1 }
            @{ Name = 'SWIFT Code'; MinCount = 1 }
        )
        AuditActions = @{
            GenerateIncidentReport = 'SiteAdmin'
            NotifyUser             = @()
        }
        EnforceActions = @{
            BlockAccess            = $true
            GenerateIncidentReport = 'SiteAdmin'
            NotifyUser             = @('LastModifier')
        }
    }
)

function Import-RequiredModule {
    param([Parameter(Mandatory = $true)][string]$Name)

    if (-not (Get-Module -ListAvailable -Name $Name)) {
        throw "Required PowerShell module '$Name' is not installed. Install it with: Install-Module $Name -Scope CurrentUser"
    }

    Import-Module $Name -ErrorAction Stop
}

function Connect-ComplianceIfNeeded {
    if (-not (Get-Command Connect-IPPSSession -ErrorAction SilentlyContinue)) {
        throw 'Connect-IPPSSession is unavailable. Update ExchangeOnlineManagement and try again.'
    }

    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession | Out-Null
    }
}

function ConvertTo-DlpSensitiveInformationParameter {
    param([Parameter(Mandatory = $true)][array]$SensitiveInformation)

    return @($SensitiveInformation | ForEach-Object {
        @{
            name     = $_.Name
            minCount = $_.MinCount
        }
    })
}

function Get-DlpPolicyOrNull {
    param([Parameter(Mandatory = $true)][string]$Name)
    return Get-DlpCompliancePolicy -Identity $Name -ErrorAction SilentlyContinue
}

function Get-DlpRuleOrNull {
    param([Parameter(Mandatory = $true)][string]$Name)
    return Get-DlpComplianceRule -Identity $Name -ErrorAction SilentlyContinue
}

function Set-DlpRuleMode {
    param(
        [Parameter(Mandatory = $true)]$Definition,
        [Parameter(Mandatory = $true)][bool]$BlockMode
    )

    $sensitiveInfo = ConvertTo-DlpSensitiveInformationParameter -SensitiveInformation $Definition.SensitiveInformation
    $existingRule = Get-DlpRuleOrNull -Name $Definition.RuleName

    $baseParameters = @{
        ContentContainsSensitiveInformation = $sensitiveInfo
        GenerateIncidentReport              = if ($BlockMode) { $Definition.EnforceActions.GenerateIncidentReport } else { $Definition.AuditActions.GenerateIncidentReport }
        NotifyUser                          = if ($BlockMode) { $Definition.EnforceActions.NotifyUser } else { $Definition.AuditActions.NotifyUser }
    }

    if ($BlockMode) {
        $baseParameters['BlockAccess'] = $Definition.EnforceActions.BlockAccess
    } else {
        $baseParameters['BlockAccess'] = $false
    }

    if ($null -eq $existingRule) {
        $newParameters = @{
            Name   = $Definition.RuleName
            Policy = $Definition.Name
        }

        foreach ($key in $baseParameters.Keys) {
            $newParameters[$key] = $baseParameters[$key]
        }

        if ($PSCmdlet.ShouldProcess($Definition.RuleName, 'Create Purview DLP rule')) {
            New-DlpComplianceRule @newParameters | Out-Null
        }

        return 'Rule created'
    }

    if ($PSCmdlet.ShouldProcess($Definition.RuleName, 'Update Purview DLP rule')) {
        Set-DlpComplianceRule -Identity $Definition.RuleName @baseParameters | Out-Null
    }

    return 'Rule updated'
}

Import-RequiredModule -Name ExchangeOnlineManagement
Connect-ComplianceIfNeeded

$results = New-Object System.Collections.Generic.List[object]
$targetModeDescription = if ($Enforce) { 'Block mode' } else { 'Audit-only mode' }
Write-Warning "Deploying Purview DLP policies in $targetModeDescription. Validate matches in audit-only mode before enforcing in production."

foreach ($definition in $PolicyDefinitions) {
    $policy = Get-DlpPolicyOrNull -Name $definition.Name
    $policyAction = 'Already exists'

    if ($null -eq $policy) {
        $policyParameters = @{
            Name              = $definition.Name
            Comment           = $definition.Comment
            Mode              = $definition.Mode
            ExchangeLocation  = $definition.Locations.ExchangeLocation
            SharePointLocation = $definition.Locations.SharePointLocation
            OneDriveLocation  = $definition.Locations.OneDriveLocation
            TeamsLocation     = $definition.Locations.TeamsLocation
        }

        if ($PSCmdlet.ShouldProcess($definition.Name, 'Create Purview DLP policy')) {
            New-DlpCompliancePolicy @policyParameters | Out-Null
        }

        $policyAction = 'Policy created'
    } elseif ($PSCmdlet.ShouldProcess($definition.Name, "Set Purview DLP policy mode to $($definition.Mode)")) {
        Set-DlpCompliancePolicy -Identity $definition.Name -Mode $definition.Mode | Out-Null
        $policyAction = 'Policy mode updated'
    }

    $ruleAction = Set-DlpRuleMode -Definition $definition -BlockMode ([bool]$Enforce)
    $policy = Get-DlpPolicyOrNull -Name $definition.Name

    $results.Add([pscustomobject]@{
        PolicyName  = $definition.Name
        Mode        = $targetModeDescription
        PolicyId    = if ($policy) { $policy.Guid } else { '' }
        PolicyAction = $policyAction
        RuleAction  = $ruleAction
    }) | Out-Null
}

Write-Host ''
Write-Host 'Purview DLP deployment results' -ForegroundColor Cyan
$results | Format-Table -AutoSize
