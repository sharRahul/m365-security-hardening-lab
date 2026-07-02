<#
.SYNOPSIS
Tears down the Microsoft Sentinel lab workspace and the starter analytics rules created by Deploy-SentinelWorkspace.ps1.

.DESCRIPTION
Removes the starter scheduled analytics rules deployed by Deploy-SentinelWorkspace.ps1 and then deletes the Log Analytics workspace. Optionally removes the resource group as well.

The script previews by default. Nothing is deleted unless you pass -ConfirmTeardown. As an additional guard against production impact, the script refuses to run unless the workspace name contains 'lab'.

Deleting the workspace removes Microsoft Sentinel, its data connectors, analytics rules, and ingested data. Log Analytics keeps deleted workspaces in a soft-deleted state for 14 days, during which the workspace name stays reserved and the workspace can be recovered. Data ingestion charges stop once the workspace is deleted.

.PARAMETER ResourceGroupName
Azure resource group that contains the Log Analytics workspace.

.PARAMETER WorkspaceName
Log Analytics workspace name. Must contain 'lab' as a guard against targeting a production workspace.

.PARAMETER ConfirmTeardown
Required to actually delete anything. Without this switch the script runs in preview mode and only reports what it would remove.

.PARAMETER RulesOnly
Remove only the starter analytics rules and keep the workspace.

.PARAMETER RemoveResourceGroup
Also remove the resource group after the workspace. Use only when the resource group was created for this lab and contains nothing else.

.EXAMPLE
pwsh ./scripts/Remove-SentinelWorkspace.ps1 -ResourceGroupName rg-m365-lab-sentinel -WorkspaceName law-m365-lab

Preview mode. Lists what would be removed without deleting anything.

.EXAMPLE
pwsh ./scripts/Remove-SentinelWorkspace.ps1 -ResourceGroupName rg-m365-lab-sentinel -WorkspaceName law-m365-lab -ConfirmTeardown

Removes the starter analytics rules and the workspace after confirmation prompts.

.EXAMPLE
pwsh ./scripts/Remove-SentinelWorkspace.ps1 -ResourceGroupName rg-m365-lab-sentinel -WorkspaceName law-m365-lab -RulesOnly -ConfirmTeardown

Removes only the starter analytics rules and keeps the workspace.

.NOTES
Required modules: Az.Accounts, Az.Resources, Az.OperationalInsights.
The script uses Azure Resource Manager REST calls for Sentinel resources to reduce dependency on cmdlet version differences.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$WorkspaceName,

    [switch]$ConfirmTeardown,

    [switch]$RulesOnly,

    [switch]$RemoveResourceGroup
)

$ErrorActionPreference = 'Stop'

# Display names of the starter analytics rules created by Deploy-SentinelWorkspace.ps1.
$StarterRuleDisplayNames = @(
    'Successful sign-in after multiple failures'
    'MFA disabled for a user'
    'New Conditional Access policy created or modified'
    'Privileged role assigned outside PIM'
    'Impossible travel activity'
)

if ($WorkspaceName -notmatch 'lab') {
    throw "Guard rail: workspace name '$WorkspaceName' does not contain 'lab'. This teardown script only targets named lab workspaces. Rename the workspace or remove production resources manually through change control."
}

if (-not $ConfirmTeardown) {
    Write-Warning 'Preview mode. Nothing will be deleted. Re-run with -ConfirmTeardown to remove resources.'
    $WhatIfPreference = $true
}

if ($ResourceGroupName -notmatch 'lab') {
    Write-Warning "Resource group name '$ResourceGroupName' does not contain 'lab'. Confirm it belongs to this lab before continuing."
}

function Import-RequiredModule {
    param([Parameter(Mandatory = $true)][string]$Name)

    if (-not (Get-Module -ListAvailable -Name $Name)) {
        throw "Required PowerShell module '$Name' is not installed. Install it with: Install-Module $Name -Scope CurrentUser"
    }

    Import-Module $Name -ErrorAction Stop
}

function Connect-AzureIfNeeded {
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if ($null -eq $context) {
        Connect-AzAccount | Out-Null
    }
}

function Get-SentinelStarterRule {
    param(
        [Parameter(Mandatory = $true)][string]$SubscriptionId,
        [Parameter(Mandatory = $true)][string]$ResourceGroup,
        [Parameter(Mandatory = $true)][string]$Workspace,
        [Parameter(Mandatory = $true)][string[]]$DisplayNames
    )

    $path = '/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.OperationalInsights/workspaces/{2}/providers/Microsoft.SecurityInsights/alertRules' -f $SubscriptionId, $ResourceGroup, $Workspace
    $uri = 'https://management.azure.com{0}?api-version=2023-02-01-preview' -f $path

    $response = Invoke-AzRestMethod -Method GET -Uri $uri -ErrorAction Stop
    if ($response.StatusCode -ge 400) {
        throw "Could not list Sentinel analytics rules (HTTP $($response.StatusCode)). Sentinel may not be enabled on this workspace."
    }

    $rules = ($response.Content | ConvertFrom-Json).value
    return @($rules | Where-Object { $_.properties.displayName -in $DisplayNames })
}

function Remove-SentinelRule {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([Parameter(Mandatory = $true)]$Rule)

    if ($PSCmdlet.ShouldProcess($Rule.properties.displayName, 'Remove Sentinel analytics rule')) {
        $uri = 'https://management.azure.com{0}?api-version=2023-02-01-preview' -f $Rule.id
        $response = Invoke-AzRestMethod -Method DELETE -Uri $uri -ErrorAction Stop
        if ($response.StatusCode -ge 400) {
            throw "Rule deletion failed (HTTP $($response.StatusCode))."
        }
        return 'Removed'
    }

    return 'Would remove'
}

Import-RequiredModule -Name Az.Accounts
Import-RequiredModule -Name Az.Resources
Import-RequiredModule -Name Az.OperationalInsights
Connect-AzureIfNeeded

$context = Get-AzContext
$subscriptionId = $context.Subscription.Id

$summary = New-Object System.Collections.Generic.List[object]

$workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -ErrorAction SilentlyContinue
if ($null -eq $workspace) {
    throw "Workspace '$WorkspaceName' was not found in resource group '$ResourceGroupName'. Nothing to remove."
}

Write-Host "Targeting workspace $WorkspaceName in resource group $ResourceGroupName (subscription $subscriptionId)." -ForegroundColor Cyan

# Starter analytics rules
try {
    $starterRules = Get-SentinelStarterRule -SubscriptionId $subscriptionId -ResourceGroup $ResourceGroupName -Workspace $WorkspaceName -DisplayNames $StarterRuleDisplayNames
} catch {
    Write-Warning $_.Exception.Message
    $starterRules = @()
    $summary.Add([pscustomobject]@{ Item = 'Starter analytics rules'; Type = 'Sentinel analytics rules'; Action = 'Could not list rules' }) | Out-Null
}

foreach ($rule in $starterRules) {
    $action = Remove-SentinelRule -Rule $rule
    $summary.Add([pscustomobject]@{ Item = $rule.properties.displayName; Type = 'Sentinel analytics rule'; Action = $action }) | Out-Null
}

if ($starterRules.Count -eq 0) {
    Write-Host 'No starter analytics rules from Deploy-SentinelWorkspace.ps1 were found.' -ForegroundColor Cyan
}

# Workspace
if ($RulesOnly) {
    $summary.Add([pscustomobject]@{ Item = $WorkspaceName; Type = 'Log Analytics workspace'; Action = 'Kept (-RulesOnly)' }) | Out-Null
} else {
    if ($PSCmdlet.ShouldProcess($WorkspaceName, 'Remove Log Analytics workspace and Microsoft Sentinel')) {
        Remove-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -Force
        $summary.Add([pscustomobject]@{ Item = $WorkspaceName; Type = 'Log Analytics workspace'; Action = 'Removed (soft delete, 14 day recovery window)' }) | Out-Null
    } else {
        $summary.Add([pscustomobject]@{ Item = $WorkspaceName; Type = 'Log Analytics workspace'; Action = 'Would remove' }) | Out-Null
    }
}

# Resource group
if ($RemoveResourceGroup -and -not $RulesOnly) {
    if ($PSCmdlet.ShouldProcess($ResourceGroupName, 'Remove resource group')) {
        Remove-AzResourceGroup -Name $ResourceGroupName -Force | Out-Null
        $summary.Add([pscustomobject]@{ Item = $ResourceGroupName; Type = 'Resource group'; Action = 'Removed' }) | Out-Null
    } else {
        $summary.Add([pscustomobject]@{ Item = $ResourceGroupName; Type = 'Resource group'; Action = 'Would remove' }) | Out-Null
    }
}

Write-Host ''
if ($ConfirmTeardown) {
    Write-Host 'Teardown summary' -ForegroundColor Green
} else {
    Write-Host 'Teardown preview. Nothing was deleted. Re-run with -ConfirmTeardown to remove these items.' -ForegroundColor Yellow
}
$summary | Format-Table -AutoSize

Write-Host 'Cost note: data ingestion and retention charges stop once the workspace is deleted. A soft-deleted workspace does not incur ingestion charges.' -ForegroundColor Cyan
