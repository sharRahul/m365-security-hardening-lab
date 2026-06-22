<#
.SYNOPSIS
Deploys recommended Microsoft Entra Conditional Access policies for a Microsoft 365 hardening lab.

.DESCRIPTION
Creates a small, opinionated set of lab Conditional Access policies covering MFA, legacy authentication blocking, device requirements, risky geography blocking, and stronger administrator controls.

The script is pilot-scoped by default. You must provide -PilotUserIds or -PilotGroupIds unless you explicitly pass -AllUsersScope. Use -WhatIf to preview without creating policies. Use -ReportOnly to create policies in report-only mode.

.PARAMETER BreakGlassUserIds
Object IDs of emergency access accounts that must be excluded from the lab policies.

.PARAMETER PilotUserIds
Optional object IDs of pilot users to include in the lab policy scope.

.PARAMETER PilotGroupIds
Optional object IDs of pilot groups to include in the lab policy scope.

.PARAMETER AllUsersScope
Explicitly scope the policies to all users. This is not the default because the repository is intended for lab and community use.

.PARAMETER HighRiskCountryCodes
Two-letter ISO country or region codes to include in the high-risk country named location. If omitted, the geography-blocking policy is skipped.

.PARAMETER HighRiskNamedLocationName
Display name for the Conditional Access country named location.

.PARAMETER ReportOnly
Creates policies in report-only mode instead of enabled mode.

.EXAMPLE
pwsh ./scripts/Deploy-ConditionalAccessPolicies.ps1 `
  -BreakGlassUserIds @('00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002') `
  -PilotGroupIds @('11111111-1111-1111-1111-111111111111') `
  -ReportOnly `
  -WhatIf

.EXAMPLE
pwsh ./scripts/Deploy-ConditionalAccessPolicies.ps1 `
  -BreakGlassUserIds @('00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002') `
  -PilotGroupIds @('11111111-1111-1111-1111-111111111111') `
  -HighRiskCountryCodes @('KP','IR','SY') `
  -ReportOnly

.EXAMPLE
pwsh ./scripts/Deploy-ConditionalAccessPolicies.ps1 `
  -BreakGlassUserIds @('00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002') `
  -AllUsersScope `
  -ReportOnly `
  -WhatIf

.NOTES
Required module: Microsoft.Graph.
Recommended Graph scopes: Policy.ReadWrite.ConditionalAccess, Policy.Read.All, Directory.Read.All.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$BreakGlassUserIds,

    [Parameter(Mandatory = $false)]
    [string[]]$PilotUserIds = @(),

    [Parameter(Mandatory = $false)]
    [string[]]$PilotGroupIds = @(),

    [Parameter(Mandatory = $false)]
    [switch]$AllUsersScope,

    [ValidatePattern('^[A-Z]{2}$')]
    [string[]]$HighRiskCountryCodes = @(),

    [string]$HighRiskNamedLocationName = 'LAB-High-Risk-Countries',

    [switch]$ReportOnly
)

$ErrorActionPreference = 'Stop'

if (-not $AllUsersScope -and $PilotUserIds.Count -eq 0 -and $PilotGroupIds.Count -eq 0) {
    throw 'Safe default requires -PilotUserIds or -PilotGroupIds. Use -AllUsersScope only when you intentionally want all-user lab policies.'
}

if ($AllUsersScope) {
    Write-Warning 'All-users scope was explicitly requested. Confirm this is a lab tenant, break-glass access works, and report-only results have been reviewed.'
} else {
    Write-Host 'Using pilot scope. Policies will include only the supplied pilot users and/or groups.' -ForegroundColor Cyan
}

# Directory role template IDs used by Conditional Access includeRoles when -AllUsersScope is explicitly selected.
$PrivilegedRoleTemplateIds = @(
    '62e90394-69f5-4237-9190-012177145e10', # Global Administrator
    'e8611ab8-c189-46e8-94e1-60213ab1f814', # Privileged Role Administrator
    '194ae4cb-b126-40b2-bd5b-6091b380977d', # Security Administrator
    'b1be1c3e-b65d-4f19-8427-f6fa0d97feb9', # Conditional Access Administrator
    '29232cdf-9323-42fd-ade2-1d097af3e4de', # Exchange Administrator
    'f28a1f50-f6e7-4571-818b-6a12f2af6b6c', # SharePoint Administrator
    '729827e3-9c14-49f7-bb1b-9608f156bbb8'  # Helpdesk Administrator
)

function New-ConditionalAccessUserScope {
    param(
        [switch]$UseAllUsers,
        [string[]]$Users,
        [string[]]$Groups,
        [string[]]$ExcludedUsers
    )

    $scope = @{
        excludeUsers = $ExcludedUsers
    }

    if ($UseAllUsers) {
        $scope['includeUsers'] = @('All')
        return $scope
    }

    if ($Users.Count -gt 0) {
        $scope['includeUsers'] = $Users
    }
    if ($Groups.Count -gt 0) {
        $scope['includeGroups'] = $Groups
    }

    return $scope
}

$PilotScope = New-ConditionalAccessUserScope -UseAllUsers:$AllUsersScope -Users $PilotUserIds -Groups $PilotGroupIds -ExcludedUsers $BreakGlassUserIds
$AdminScope = if ($AllUsersScope) {
    @{
        includeRoles = $PrivilegedRoleTemplateIds
        excludeUsers = $BreakGlassUserIds
    }
} else {
    # In safe community mode, the admin hardening policy is also restricted to the supplied pilot users/groups.
    $PilotScope
}

$PolicyDefinitions = @(
    @{
        DisplayName   = 'LAB-CA-Require-MFA-Pilot-Users'
        Description   = 'Require MFA for pilot users or groups, excluding emergency access accounts.'
        RequiresNamedLocation = $false
        Conditions    = @{
            users = $PilotScope
            applications = @{
                includeApplications = @('All')
            }
            clientAppTypes = @('all')
        }
        GrantControls = @{
            operator        = 'OR'
            builtInControls = @('mfa')
        }
    }
    @{
        DisplayName   = 'LAB-CA-Block-Legacy-Authentication-Pilot'
        Description   = 'Block Exchange ActiveSync and other legacy clients for the pilot scope.'
        RequiresNamedLocation = $false
        Conditions    = @{
            users = $PilotScope
            applications = @{
                includeApplications = @('All')
            }
            clientAppTypes = @('exchangeActiveSync', 'other')
        }
        GrantControls = @{
            operator        = 'OR'
            builtInControls = @('block')
        }
    }
    @{
        DisplayName   = 'LAB-CA-Require-Compliant-Or-Hybrid-Device-Pilot'
        Description   = 'Require a compliant device or Microsoft Entra hybrid joined device for Microsoft 365 access in the pilot scope.'
        RequiresNamedLocation = $false
        Conditions    = @{
            users = $PilotScope
            applications = @{
                includeApplications = @('All')
            }
            clientAppTypes = @('all')
        }
        GrantControls = @{
            operator        = 'OR'
            builtInControls = @('compliantDevice', 'domainJoinedDevice')
        }
    }
    @{
        DisplayName   = 'LAB-CA-Block-High-Risk-Countries-Pilot'
        Description   = 'Block sign-ins from the configured high-risk country named location for the pilot scope.'
        RequiresNamedLocation = $true
        Conditions    = @{
            users = $PilotScope
            applications = @{
                includeApplications = @('All')
            }
            clientAppTypes = @('all')
            locations = @{
                includeLocations = @('__HIGH_RISK_LOCATION_ID__')
                excludeLocations = @()
            }
        }
        GrantControls = @{
            operator        = 'OR'
            builtInControls = @('block')
        }
    }
    @{
        DisplayName   = 'LAB-CA-Admins-Require-MFA-And-Compliant-Device-Pilot'
        Description   = 'Require MFA and a compliant device for privileged administrator testing. In pilot mode this uses supplied pilot users/groups only.'
        RequiresNamedLocation = $false
        Conditions    = @{
            users = $AdminScope
            applications = @{
                includeApplications = @('All')
            }
            clientAppTypes = @('all')
        }
        GrantControls = @{
            operator        = 'AND'
            builtInControls = @('mfa', 'compliantDevice')
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

function Connect-GraphIfNeeded {
    $context = Get-MgContext -ErrorAction SilentlyContinue
    if ($null -ne $context) {
        Write-Host "Microsoft Graph already connected as $($context.Account)." -ForegroundColor Cyan
        return
    }

    Connect-MgGraph -Scopes @('Policy.ReadWrite.ConditionalAccess', 'Policy.Read.All', 'Directory.Read.All') -NoWelcome
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

function Get-OrCreateCountryNamedLocation {
    param(
        [Parameter(Mandatory = $true)][string]$DisplayName,
        [Parameter(Mandatory = $true)][string[]]$CountryCodes
    )

    $locations = Invoke-GraphGetAll -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations'
    $existing = @($locations | Where-Object { $_.displayName -eq $DisplayName }) | Select-Object -First 1
    if ($null -ne $existing) {
        return $existing.id
    }

    $body = @{
        '@odata.type'                       = '#microsoft.graph.countryNamedLocation'
        displayName                         = $DisplayName
        countriesAndRegions                 = $CountryCodes
        includeUnknownCountriesAndRegions   = $true
    }

    if ($PSCmdlet.ShouldProcess($DisplayName, 'Create Conditional Access country named location')) {
        $created = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations' -Body ($body | ConvertTo-Json -Depth 20) -ContentType 'application/json' -ErrorAction Stop
        return $created.id
    }

    return 'WHATIF-NAMED-LOCATION-ID'
}

function Convert-PolicyDefinitionToBody {
    param(
        [Parameter(Mandatory = $true)]$Definition,
        [string]$NamedLocationId
    )

    $conditions = $Definition.Conditions | ConvertTo-Json -Depth 30 | ConvertFrom-Json

    if ($Definition.RequiresNamedLocation) {
        $conditions.locations.includeLocations = @($NamedLocationId)
    }

    return @{
        displayName     = $Definition.DisplayName
        state           = if ($ReportOnly) { 'enabledForReportingButNotEnforced' } else { 'enabled' }
        conditions      = $conditions
        grantControls   = $Definition.GrantControls
        sessionControls = $null
    }
}

Write-Warning 'Confirm at least two emergency access accounts exist, have strong credentials, are monitored, and are excluded before enforcing Conditional Access.'
Write-Warning 'Keep an active Global Administrator session open while testing these policies in a lab tenant.'

Import-RequiredModule -Name Microsoft.Graph.Authentication
Connect-GraphIfNeeded

$highRiskNamedLocationId = $null
if ($HighRiskCountryCodes.Count -gt 0) {
    $highRiskNamedLocationId = Get-OrCreateCountryNamedLocation -DisplayName $HighRiskNamedLocationName -CountryCodes $HighRiskCountryCodes
} else {
    Write-Warning 'No -HighRiskCountryCodes values were provided. The high-risk countries blocking policy will be skipped.'
}

$existingPolicies = Invoke-GraphGetAll -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies'
$results = New-Object System.Collections.Generic.List[object]

foreach ($definition in $PolicyDefinitions) {
    $existing = @($existingPolicies | Where-Object { $_.displayName -eq $definition.DisplayName }) | Select-Object -First 1

    if ($definition.RequiresNamedLocation -and -not $highRiskNamedLocationId) {
        $results.Add([pscustomobject]@{
            PolicyName  = $definition.DisplayName
            ActionTaken = 'Skipped - no country list'
            PolicyId    = ''
        }) | Out-Null
        continue
    }

    if ($null -ne $existing) {
        $results.Add([pscustomobject]@{
            PolicyName  = $definition.DisplayName
            ActionTaken = 'Already exists'
            PolicyId    = $existing.id
        }) | Out-Null
        continue
    }

    $body = Convert-PolicyDefinitionToBody -Definition $definition -NamedLocationId $highRiskNamedLocationId

    if ($PSCmdlet.ShouldProcess($definition.DisplayName, 'Create Conditional Access policy')) {
        $createdPolicy = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies' -Body ($body | ConvertTo-Json -Depth 30) -ContentType 'application/json' -ErrorAction Stop
        $results.Add([pscustomobject]@{
            PolicyName  = $definition.DisplayName
            ActionTaken = if ($ReportOnly) { 'Created report-only' } else { 'Created enabled' }
            PolicyId    = $createdPolicy.id
        }) | Out-Null
    } else {
        $results.Add([pscustomobject]@{
            PolicyName  = $definition.DisplayName
            ActionTaken = 'WhatIf preview'
            PolicyId    = ''
        }) | Out-Null
    }
}

Write-Host ''
Write-Host 'Conditional Access deployment results' -ForegroundColor Cyan
$results | Format-Table -AutoSize
