<#
Stub commands used by the Pester sandbox tests.

This file is dot-sourced by a short-lived pwsh process before a script under
test is invoked. The stubs stand in for Microsoft Graph, Exchange Online
Security and Compliance, and Az cmdlets so the scripts can run end to end
without a tenant, a subscription, or network access.

Every state-changing stub appends a line to the file named by
$env:SANDBOX_CALL_LOG so tests can assert exactly which changes a run would
have made. Read-only stubs return synthetic values only.
#>

# Module handling stubs. The scripts check module availability with
# Get-Module -ListAvailable and then call Import-Module.
function Get-Module {
    [CmdletBinding()]
    param(
        [switch]$ListAvailable,
        [Parameter(Position = 0)]
        [string[]]$Name
    )

    return [pscustomobject]@{ Name = ($Name -join ','); Version = [version]'99.0.0' }
}

function Import-Module {
    [CmdletBinding()]
    param([Parameter(Position = 0)]$Name)
}

function Write-SandboxCall {
    param([Parameter(Mandatory = $true)][string]$Message)

    Add-Content -Path $env:SANDBOX_CALL_LOG -Value $Message
}

# Microsoft Graph stubs
function Get-MgContext {
    [CmdletBinding()]
    param()

    return [pscustomobject]@{
        Account  = 'labadmin@contoso-lab.invalid'
        TenantId = '00000000-0000-0000-0000-000000000000'
    }
}

function Connect-MgGraph {
    [CmdletBinding()]
    param([string[]]$Scopes, [switch]$NoWelcome)
}

function Invoke-MgGraphRequest {
    [CmdletBinding()]
    param(
        [string]$Method,
        [string]$Uri,
        $Body,
        [string]$ContentType
    )

    $state = ''
    if ($Body) {
        try { $state = (ConvertFrom-Json -InputObject $Body).state } catch { $state = '' }
    }

    Write-SandboxCall -Message ('{0} {1} state={2}' -f $Method, $Uri, $state)

    if ($Method -eq 'GET') {
        return @{ value = @() }
    }

    return @{ id = 'stub-created-id' }
}

# Security and Compliance (Purview) stubs
function Connect-IPPSSession {
    [CmdletBinding()]
    param()
}

function Get-DlpCompliancePolicy {
    [CmdletBinding()]
    param([Parameter(Position = 0)]$Identity)

    return $null
}

function Get-DlpComplianceRule {
    [CmdletBinding()]
    param([Parameter(Position = 0)]$Identity)

    return $null
}

function New-DlpCompliancePolicy {
    [CmdletBinding()]
    param(
        [string]$Name,
        [string]$Comment,
        [string]$Mode,
        $ExchangeLocation,
        $SharePointLocation,
        $OneDriveLocation,
        $TeamsLocation
    )

    Write-SandboxCall -Message ('New-DlpCompliancePolicy Name={0} Mode={1}' -f $Name, $Mode)
}

function Set-DlpCompliancePolicy {
    [CmdletBinding()]
    param($Identity, [string]$Mode)

    Write-SandboxCall -Message ('Set-DlpCompliancePolicy Identity={0} Mode={1}' -f $Identity, $Mode)
}

function New-DlpComplianceRule {
    [CmdletBinding()]
    param(
        [string]$Name,
        [string]$Policy,
        $ContentContainsSensitiveInformation,
        $GenerateIncidentReport,
        $NotifyUser,
        $BlockAccess
    )

    Write-SandboxCall -Message ('New-DlpComplianceRule Name={0} BlockAccess={1}' -f $Name, $BlockAccess)
}

function Set-DlpComplianceRule {
    [CmdletBinding()]
    param(
        $Identity,
        $ContentContainsSensitiveInformation,
        $GenerateIncidentReport,
        $NotifyUser,
        $BlockAccess
    )

    Write-SandboxCall -Message ('Set-DlpComplianceRule Identity={0} BlockAccess={1}' -f $Identity, $BlockAccess)
}

# Az stubs
function Get-AzContext {
    [CmdletBinding()]
    param()

    return [pscustomobject]@{
        Subscription = [pscustomobject]@{ Id = '00000000-0000-0000-0000-0000000000aa' }
        Tenant       = [pscustomobject]@{ Id = '00000000-0000-0000-0000-000000000000' }
    }
}

function Connect-AzAccount {
    [CmdletBinding()]
    param()
}

function Get-AzResourceGroup {
    [CmdletBinding()]
    param([string]$Name)

    return $null
}

function New-AzResourceGroup {
    [CmdletBinding()]
    param([string]$Name, [string]$Location)

    Write-SandboxCall -Message ('New-AzResourceGroup Name={0}' -f $Name)
    return [pscustomobject]@{ ResourceGroupName = $Name; Location = $Location }
}

function Remove-AzResourceGroup {
    [CmdletBinding()]
    param([string]$Name, [switch]$Force)

    Write-SandboxCall -Message ('Remove-AzResourceGroup Name={0}' -f $Name)
    return $true
}

function Get-AzOperationalInsightsWorkspace {
    [CmdletBinding()]
    param([string]$ResourceGroupName, [string]$Name)

    # Tests that need an existing workspace set SANDBOX_WORKSPACE_EXISTS=1.
    if ($env:SANDBOX_WORKSPACE_EXISTS -eq '1') {
        return [pscustomobject]@{
            Name              = $Name
            ResourceGroupName = $ResourceGroupName
            CustomerId        = '00000000-0000-0000-0000-0000000000ff'
        }
    }

    return $null
}

function New-AzOperationalInsightsWorkspace {
    [CmdletBinding()]
    param([string]$ResourceGroupName, [string]$Name, [string]$Location, [string]$Sku)

    Write-SandboxCall -Message ('New-AzOperationalInsightsWorkspace Name={0}' -f $Name)
    return [pscustomobject]@{
        Name              = $Name
        ResourceGroupName = $ResourceGroupName
        CustomerId        = '00000000-0000-0000-0000-0000000000ff'
    }
}

function Remove-AzOperationalInsightsWorkspace {
    [CmdletBinding()]
    param([string]$ResourceGroupName, [string]$Name, [switch]$Force)

    Write-SandboxCall -Message ('Remove-AzOperationalInsightsWorkspace Name={0}' -f $Name)
}

function Invoke-AzRestMethod {
    [CmdletBinding()]
    param([string]$Method, [string]$Uri, $Payload)

    Write-SandboxCall -Message ('{0} {1}' -f $Method, $Uri)

    if ($Method -eq 'GET') {
        $content = @{
            value = @(
                @{
                    id         = '/subscriptions/00000000-0000-0000-0000-0000000000aa/resourceGroups/rg-m365-lab-sentinel/providers/Microsoft.OperationalInsights/workspaces/law-m365-lab/providers/Microsoft.SecurityInsights/alertRules/stub-rule-1'
                    properties = @{ displayName = 'MFA disabled for a user' }
                }
            )
        } | ConvertTo-Json -Depth 10

        return [pscustomobject]@{ StatusCode = 200; Content = $content }
    }

    return [pscustomobject]@{ StatusCode = 200; Content = '{}' }
}
