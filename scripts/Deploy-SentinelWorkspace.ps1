<#
.SYNOPSIS
Deploys a Microsoft Sentinel lab workspace, optional data connectors, and starter analytics rules.

.DESCRIPTION
Uses the Az PowerShell module to create a Log Analytics workspace, enable Microsoft Sentinel, attempt to enable common Microsoft security data connectors, and deploy scheduled analytics rules with KQL suitable for a Microsoft 365 hardening lab.

Connector creation is licence and tenant dependent. Connector failures are reported as warnings and do not stop the workspace or analytics rule deployment.

.PARAMETER ResourceGroupName
Azure resource group used for the Log Analytics workspace.

.PARAMETER WorkspaceName
Log Analytics workspace name.

.PARAMETER Location
Azure region for the resource group and workspace, for example uksouth or westeurope.

.EXAMPLE
pwsh ./scripts/Deploy-SentinelWorkspace.ps1 -ResourceGroupName rg-m365-lab-sentinel -WorkspaceName law-m365-lab -Location uksouth

.NOTES
Required modules: Az.Accounts, Az.Resources, Az.OperationalInsights.
Optional module: Az.SecurityInsights.
The script uses Azure Resource Manager REST calls for Sentinel resources to reduce dependency on cmdlet version differences.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$WorkspaceName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Location
)

$ErrorActionPreference = 'Stop'

$AnalyticsRules = @(
    @{
        DisplayName      = 'Successful sign-in after multiple failures'
        Severity         = 'Medium'
        QueryFrequency   = 'PT1H'
        QueryPeriod      = 'PT1H'
        Tactics          = @('CredentialAccess')
        Query            = @'
SigninLogs
| where ResultType != 0
| summarize FailureCount = count(), FailureWindowStart = min(TimeGenerated), FailureWindowEnd = max(TimeGenerated) by UserPrincipalName, IPAddress
| where FailureCount >= 5
| join kind=inner (
    SigninLogs
    | where ResultType == 0
    | project SuccessTime = TimeGenerated, UserPrincipalName, IPAddress, AppDisplayName
) on UserPrincipalName, IPAddress
| where SuccessTime between (FailureWindowStart .. FailureWindowEnd + 30m)
| project SuccessTime, UserPrincipalName, IPAddress, AppDisplayName, FailureCount, FailureWindowStart, FailureWindowEnd
'@
    }
    @{
        DisplayName      = 'MFA disabled for a user'
        Severity         = 'High'
        QueryFrequency   = 'PT1H'
        QueryPeriod      = 'PT1H'
        Tactics          = @('DefenseEvasion')
        Query            = @'
AuditLogs
| where OperationName has_any ('Disable Strong Authentication', 'Update user', 'Authentication Methods Policy Update')
| where TargetResources has_any ('StrongAuthenticationRequirement', 'authentication methods', 'MFA')
| project TimeGenerated, OperationName, InitiatedBy, TargetResources, Result
'@
    }
    @{
        DisplayName      = 'New Conditional Access policy created or modified'
        Severity         = 'Medium'
        QueryFrequency   = 'PT1H'
        QueryPeriod      = 'PT1H'
        Tactics          = @('DefenseEvasion', 'Persistence')
        Query            = @'
AuditLogs
| where OperationName has_any ('Add conditional access policy', 'Update conditional access policy', 'Delete conditional access policy')
| project TimeGenerated, OperationName, InitiatedBy, TargetResources, Result, CorrelationId
'@
    }
    @{
        DisplayName      = 'Privileged role assigned outside PIM'
        Severity         = 'High'
        QueryFrequency   = 'PT1H'
        QueryPeriod      = 'PT1H'
        Tactics          = @('PrivilegeEscalation', 'Persistence')
        Query            = @'
AuditLogs
| where OperationName has_any ('Add member to role', 'Add eligible member to role', 'Add scoped member to role')
| where tostring(InitiatedBy.app.displayName) !has 'Privileged Identity Management'
| project TimeGenerated, OperationName, InitiatedBy, TargetResources, Result, CorrelationId
'@
    }
    @{
        DisplayName      = 'Impossible travel activity'
        Severity         = 'Medium'
        QueryFrequency   = 'PT1H'
        QueryPeriod      = 'PT1H'
        Tactics          = @('InitialAccess')
        Query            = @'
SigninLogs
| where ResultType == 0
| where isnotempty(LocationDetails.countryOrRegion)
| extend Country = tostring(LocationDetails.countryOrRegion)
| project TimeGenerated, UserPrincipalName, IPAddress, Country, AppDisplayName
| sort by UserPrincipalName asc, TimeGenerated asc
| serialize
| extend PreviousUser = prev(UserPrincipalName), PreviousCountry = prev(Country), PreviousTime = prev(TimeGenerated), PreviousIP = prev(IPAddress)
| where UserPrincipalName == PreviousUser and Country != PreviousCountry
| where datetime_diff('minute', TimeGenerated, PreviousTime) between (0 .. 120)
| project TimeGenerated, UserPrincipalName, IPAddress, Country, PreviousIP, PreviousCountry, PreviousTime, AppDisplayName
'@
    }
)

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

function Invoke-AzPutJson {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Body,
        [string]$ApiVersion = '2023-02-01-preview'
    )

    $uri = 'https://management.azure.com{0}?api-version={1}' -f $Path, $ApiVersion
    return Invoke-AzRestMethod -Method PUT -Uri $uri -Payload ($Body | ConvertTo-Json -Depth 30) -ErrorAction Stop
}

function Enable-SentinelOnWorkspace {
    param(
        [Parameter(Mandatory = $true)][string]$SubscriptionId,
        [Parameter(Mandatory = $true)][string]$ResourceGroup,
        [Parameter(Mandatory = $true)][string]$Workspace
    )

    $path = '/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.OperationalInsights/workspaces/{2}/providers/Microsoft.SecurityInsights/onboardingStates/default' -f $SubscriptionId, $ResourceGroup, $Workspace
    $body = @{ properties = @{} }
    Invoke-AzPutJson -Path $path -Body $body | Out-Null
}

function Enable-SentinelDataConnector {
    param(
        [Parameter(Mandatory = $true)][string]$SubscriptionId,
        [Parameter(Mandatory = $true)][string]$ResourceGroup,
        [Parameter(Mandatory = $true)][string]$Workspace,
        [Parameter(Mandatory = $true)][string]$ConnectorName,
        [Parameter(Mandatory = $true)][hashtable]$Body
    )

    try {
        $path = '/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.OperationalInsights/workspaces/{2}/providers/Microsoft.SecurityInsights/dataConnectors/{3}' -f $SubscriptionId, $ResourceGroup, $Workspace, (New-Guid)
        Invoke-AzPutJson -Path $path -Body $Body | Out-Null
        return [pscustomobject]@{ Connector = $ConnectorName; Status = 'Enabled or requested'; Message = 'OK' }
    } catch {
        Write-Warning "$ConnectorName connector was skipped or failed: $($_.Exception.Message)"
        return [pscustomobject]@{ Connector = $ConnectorName; Status = 'Skipped'; Message = $_.Exception.Message }
    }
}

function New-SentinelScheduledRule {
    param(
        [Parameter(Mandatory = $true)][string]$SubscriptionId,
        [Parameter(Mandatory = $true)][string]$ResourceGroup,
        [Parameter(Mandatory = $true)][string]$Workspace,
        [Parameter(Mandatory = $true)]$Rule
    )

    $path = '/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.OperationalInsights/workspaces/{2}/providers/Microsoft.SecurityInsights/alertRules/{3}' -f $SubscriptionId, $ResourceGroup, $Workspace, (New-Guid)
    $body = @{
        kind       = 'Scheduled'
        properties = @{
            displayName              = $Rule.DisplayName
            enabled                  = $true
            query                    = $Rule.Query
            queryFrequency           = $Rule.QueryFrequency
            queryPeriod              = $Rule.QueryPeriod
            severity                 = $Rule.Severity
            triggerOperator          = 'GreaterThan'
            triggerThreshold         = 0
            suppressionDuration      = 'PT5H'
            suppressionEnabled       = $false
            tactics                  = $Rule.Tactics
            incidentConfiguration    = @{
                createIncident = $true
                groupingConfiguration = @{
                    enabled                 = $true
                    reopenClosedIncident    = $false
                    lookbackDuration        = 'PT5H'
                    matchingMethod          = 'AllEntities'
                }
            }
            eventGroupingSettings   = @{
                aggregationKind = 'SingleAlert'
            }
        }
    }

    Invoke-AzPutJson -Path $path -Body $body | Out-Null
}

Import-RequiredModule -Name Az.Accounts
Import-RequiredModule -Name Az.Resources
Import-RequiredModule -Name Az.OperationalInsights
Connect-AzureIfNeeded

$context = Get-AzContext
$subscriptionId = $context.Subscription.Id
$tenantId = $context.Tenant.Id

$resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if ($null -eq $resourceGroup) {
    Write-Host "Creating resource group $ResourceGroupName in $Location" -ForegroundColor Cyan
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location | Out-Null
}

$workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -ErrorAction SilentlyContinue
if ($null -eq $workspace) {
    Write-Host "Creating Log Analytics workspace $WorkspaceName" -ForegroundColor Cyan
    $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -Location $Location -Sku PerGB2018
} else {
    Write-Host "Log Analytics workspace $WorkspaceName already exists." -ForegroundColor Cyan
}

Write-Host 'Enabling Microsoft Sentinel on the workspace.' -ForegroundColor Cyan
Enable-SentinelOnWorkspace -SubscriptionId $subscriptionId -ResourceGroup $ResourceGroupName -Workspace $WorkspaceName

$connectorResults = New-Object System.Collections.Generic.List[object]

$connectorResults.Add((Enable-SentinelDataConnector -SubscriptionId $subscriptionId -ResourceGroup $ResourceGroupName -Workspace $WorkspaceName -ConnectorName 'Microsoft Entra ID' -Body @{
    kind = 'AzureActiveDirectory'
    properties = @{ tenantId = $tenantId }
})) | Out-Null

$connectorResults.Add((Enable-SentinelDataConnector -SubscriptionId $subscriptionId -ResourceGroup $ResourceGroupName -Workspace $WorkspaceName -ConnectorName 'Microsoft 365' -Body @{
    kind = 'Office365'
    properties = @{
        tenantId = $tenantId
        dataTypes = @{
            exchange   = @{ state = 'Enabled' }
            sharePoint = @{ state = 'Enabled' }
            teams      = @{ state = 'Enabled' }
        }
    }
})) | Out-Null

$connectorResults.Add((Enable-SentinelDataConnector -SubscriptionId $subscriptionId -ResourceGroup $ResourceGroupName -Workspace $WorkspaceName -ConnectorName 'Microsoft Defender for Cloud' -Body @{
    kind = 'AzureSecurityCenter'
    properties = @{ subscriptionId = $subscriptionId }
})) | Out-Null

$connectorResults.Add((Enable-SentinelDataConnector -SubscriptionId $subscriptionId -ResourceGroup $ResourceGroupName -Workspace $WorkspaceName -ConnectorName 'Microsoft Defender XDR' -Body @{
    kind = 'MicrosoftThreatProtection'
    properties = @{
        tenantId = $tenantId
        dataTypes = @{ incidents = @{ state = 'Enabled' } }
    }
})) | Out-Null

$ruleResults = New-Object System.Collections.Generic.List[object]
foreach ($rule in $AnalyticsRules) {
    try {
        New-SentinelScheduledRule -SubscriptionId $subscriptionId -ResourceGroup $ResourceGroupName -Workspace $WorkspaceName -Rule $rule
        $ruleResults.Add([pscustomobject]@{ Rule = $rule.DisplayName; Status = 'Created or updated' }) | Out-Null
    } catch {
        Write-Warning "Analytics rule '$($rule.DisplayName)' failed: $($_.Exception.Message)"
        $ruleResults.Add([pscustomobject]@{ Rule = $rule.DisplayName; Status = 'Failed' }) | Out-Null
    }
}

$workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName
$sharedKeys = Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName $ResourceGroupName -Name $WorkspaceName

Write-Host ''
Write-Host 'Data connector results' -ForegroundColor Cyan
$connectorResults | Format-Table -AutoSize

Write-Host ''
Write-Host 'Analytics rule results' -ForegroundColor Cyan
$ruleResults | Format-Table -AutoSize

Write-Host ''
Write-Host 'Workspace onboarding output' -ForegroundColor Green
[pscustomobject]@{
    WorkspaceName = $WorkspaceName
    ResourceGroup = $ResourceGroupName
    WorkspaceId   = $workspace.CustomerId
    PrimaryKey    = $sharedKeys.PrimarySharedKey
} | Format-List
