<#
Pester tests for the lab deployment and teardown scripts.

Two kinds of test:

1. Static tests parse each script and assert the safety-relevant structure:
   mandatory parameters, ShouldProcess support, validation attributes, and
   the absence of shared-key output.

2. Sandbox tests run each script end to end in a short-lived pwsh process
   with the stub commands from TestStubs.ps1 standing in for Graph, Exchange
   Online, and Az cmdlets. Stubs log every state-changing call, so the tests
   can assert that -WhatIf changes nothing and that defaults stay safe.

No test touches a real tenant, subscription, or the network.
#>

BeforeAll {
    $script:RepoRoot = Split-Path -Path $PSScriptRoot -Parent
    $script:ScriptsPath = Join-Path -Path $script:RepoRoot -ChildPath 'scripts'
    $script:StubsPath = Join-Path -Path $PSScriptRoot -ChildPath 'TestStubs.ps1'

    function Get-ScriptAst {
        param([Parameter(Mandatory = $true)][string]$ScriptName)

        $path = Join-Path -Path $script:ScriptsPath -ChildPath $ScriptName
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)

        if ($errors.Count -gt 0) {
            throw "Parse errors in ${ScriptName}: $($errors | Out-String)"
        }

        return $ast
    }

    function Get-ScriptParameter {
        param(
            [Parameter(Mandatory = $true)]$Ast,
            [Parameter(Mandatory = $true)][string]$Name
        )

        return $Ast.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq $Name }
    }

    function Test-ParameterIsMandatory {
        param([Parameter(Mandatory = $true)]$Parameter)

        foreach ($attribute in $Parameter.Attributes) {
            if ($attribute.TypeName.GetReflectionType() -eq [Parameter] -or $attribute.TypeName.Name -eq 'Parameter') {
                foreach ($argument in $attribute.NamedArguments) {
                    if ($argument.ArgumentName -eq 'Mandatory' -and $argument.Argument.Extent.Text -match '\$true') {
                        return $true
                    }
                }
            }
        }

        return $false
    }

    function Test-ScriptSupportsShouldProcess {
        param([Parameter(Mandatory = $true)]$Ast)

        foreach ($attribute in $Ast.ParamBlock.Attributes) {
            if ($attribute.TypeName.Name -eq 'CmdletBinding') {
                foreach ($argument in $attribute.NamedArguments) {
                    if ($argument.ArgumentName -eq 'SupportsShouldProcess' -and $argument.Argument.Extent.Text -match '\$true') {
                        return $true
                    }
                }
            }
        }

        return $false
    }

    function Invoke-ScriptSandbox {
        <#
        Runs a script in a fresh pwsh process with the stub commands loaded.
        Returns the exit code, combined output, and the state-change call log.
        #>
        param(
            [Parameter(Mandatory = $true)][string]$ScriptName,
            [string]$Arguments = '',
            [bool]$WorkspaceExists = $false
        )

        $scriptPath = Join-Path -Path $script:ScriptsPath -ChildPath $ScriptName
        $runId = [guid]::NewGuid().ToString('N')
        $callLog = Join-Path -Path $TestDrive -ChildPath "calls-$runId.log"
        $driverPath = Join-Path -Path $TestDrive -ChildPath "driver-$runId.ps1"

        New-Item -Path $callLog -ItemType File -Force | Out-Null

        $driver = @"
. '$($script:StubsPath)'
`$ErrorActionPreference = 'Stop'
try {
    & '$scriptPath' $Arguments
} catch {
    Write-Host "SANDBOX-ERROR: `$(`$_.Exception.Message)"
    exit 1
}
"@
        Set-Content -Path $driverPath -Value $driver

        $previousCallLog = $env:SANDBOX_CALL_LOG
        $previousWorkspaceExists = $env:SANDBOX_WORKSPACE_EXISTS
        try {
            $env:SANDBOX_CALL_LOG = $callLog
            $env:SANDBOX_WORKSPACE_EXISTS = if ($WorkspaceExists) { '1' } else { '0' }

            $output = & pwsh -NoProfile -NonInteractive -File $driverPath 2>&1 | Out-String
            $exitCode = $LASTEXITCODE
        } finally {
            $env:SANDBOX_CALL_LOG = $previousCallLog
            $env:SANDBOX_WORKSPACE_EXISTS = $previousWorkspaceExists
        }

        return [pscustomobject]@{
            ExitCode = $exitCode
            Output   = $output
            CallLog  = (Get-Content -Path $callLog -Raw -ErrorAction SilentlyContinue) ?? ''
        }
    }
}

Describe 'Static safety structure' {

    Context 'State-changing scripts support ShouldProcess' {
        It '<_> declares SupportsShouldProcess' -ForEach @(
            'Deploy-ConditionalAccessPolicies.ps1'
            'Deploy-PurviewDLP.ps1'
            'Deploy-SentinelWorkspace.ps1'
            'Remove-SentinelWorkspace.ps1'
        ) {
            $ast = Get-ScriptAst -ScriptName $_
            Test-ScriptSupportsShouldProcess -Ast $ast | Should -BeTrue
        }
    }

    Context 'Deploy-ConditionalAccessPolicies.ps1 parameters' {
        BeforeAll {
            $script:CaAst = Get-ScriptAst -ScriptName 'Deploy-ConditionalAccessPolicies.ps1'
        }

        It 'requires BreakGlassUserIds' {
            $parameter = Get-ScriptParameter -Ast $script:CaAst -Name 'BreakGlassUserIds'
            $parameter | Should -Not -BeNullOrEmpty
            Test-ParameterIsMandatory -Parameter $parameter | Should -BeTrue
        }

        It 'validates HighRiskCountryCodes as two-letter codes' {
            $parameter = Get-ScriptParameter -Ast $script:CaAst -Name 'HighRiskCountryCodes'
            ($parameter.Attributes | Where-Object { $_.TypeName.Name -eq 'ValidatePattern' }) | Should -Not -BeNullOrEmpty
        }

        It 'keeps AllUsersScope as an opt-in switch' {
            $parameter = Get-ScriptParameter -Ast $script:CaAst -Name 'AllUsersScope'
            $parameter.StaticType.Name | Should -Be 'SwitchParameter'
            Test-ParameterIsMandatory -Parameter $parameter | Should -BeFalse
        }
    }

    Context 'Deploy-SentinelWorkspace.ps1 parameters' {
        It 'requires <_>' -ForEach @('ResourceGroupName', 'WorkspaceName', 'Location') {
            $ast = Get-ScriptAst -ScriptName 'Deploy-SentinelWorkspace.ps1'
            $parameter = Get-ScriptParameter -Ast $ast -Name $_
            $parameter | Should -Not -BeNullOrEmpty
            Test-ParameterIsMandatory -Parameter $parameter | Should -BeTrue
        }
    }

    Context 'Remove-SentinelWorkspace.ps1 parameters' {
        BeforeAll {
            $script:TeardownAst = Get-ScriptAst -ScriptName 'Remove-SentinelWorkspace.ps1'
        }

        It 'requires ResourceGroupName and WorkspaceName' {
            foreach ($name in @('ResourceGroupName', 'WorkspaceName')) {
                $parameter = Get-ScriptParameter -Ast $script:TeardownAst -Name $name
                Test-ParameterIsMandatory -Parameter $parameter | Should -BeTrue
            }
        }

        It 'keeps ConfirmTeardown as an opt-in switch' {
            $parameter = Get-ScriptParameter -Ast $script:TeardownAst -Name 'ConfirmTeardown'
            $parameter.StaticType.Name | Should -Be 'SwitchParameter'
            Test-ParameterIsMandatory -Parameter $parameter | Should -BeFalse
        }
    }

    Context 'Secrets are never printed' {
        It 'no script retrieves workspace shared keys' {
            $matches = Get-ChildItem -Path $script:ScriptsPath -Filter '*.ps1' |
                Select-String -Pattern 'WorkspaceSharedKey|SharedKeys'
            $matches | Should -BeNullOrEmpty
        }
    }
}

Describe 'Deploy-ConditionalAccessPolicies.ps1 sandbox behaviour' {

    It 'refuses to run without a pilot scope or explicit -AllUsersScope' {
        $result = Invoke-ScriptSandbox -ScriptName 'Deploy-ConditionalAccessPolicies.ps1' `
            -Arguments "-BreakGlassUserIds @('bg-1','bg-2') -WhatIf"
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'Safe default requires'
    }

    It 'fails parameter binding without BreakGlassUserIds' {
        $result = Invoke-ScriptSandbox -ScriptName 'Deploy-ConditionalAccessPolicies.ps1' `
            -Arguments "-PilotGroupIds @('pg-1') -WhatIf"
        $result.ExitCode | Should -Not -Be 0
    }

    It 'rejects three-letter country codes' {
        $result = Invoke-ScriptSandbox -ScriptName 'Deploy-ConditionalAccessPolicies.ps1' `
            -Arguments "-BreakGlassUserIds @('bg-1','bg-2') -PilotGroupIds @('pg-1') -HighRiskCountryCodes @('GBR') -WhatIf"
        $result.ExitCode | Should -Not -Be 0
    }

    It 'makes no Graph writes with -WhatIf' {
        $result = Invoke-ScriptSandbox -ScriptName 'Deploy-ConditionalAccessPolicies.ps1' `
            -Arguments "-BreakGlassUserIds @('bg-1','bg-2') -PilotGroupIds @('pg-1') -HighRiskCountryCodes @('KP') -ReportOnly -WhatIf"
        $result.ExitCode | Should -Be 0
        $result.CallLog | Should -Not -Match 'POST|PATCH|PUT|DELETE'
        $result.Output | Should -Match 'What if:'
    }

    It 'creates report-only policies when -ReportOnly is used' {
        $result = Invoke-ScriptSandbox -ScriptName 'Deploy-ConditionalAccessPolicies.ps1' `
            -Arguments "-BreakGlassUserIds @('bg-1','bg-2') -PilotGroupIds @('pg-1') -ReportOnly -Confirm:`$false"
        $result.ExitCode | Should -Be 0
        $result.CallLog | Should -Match 'POST https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies state=enabledForReportingButNotEnforced'
        $result.CallLog | Should -Not -Match 'state=enabled\b'
    }
}

Describe 'Deploy-PurviewDLP.ps1 sandbox behaviour' {

    It 'makes no compliance writes with -WhatIf' {
        $result = Invoke-ScriptSandbox -ScriptName 'Deploy-PurviewDLP.ps1' -Arguments '-WhatIf'
        $result.ExitCode | Should -Be 0
        $result.CallLog | Should -Not -Match 'New-Dlp|Set-Dlp'
        $result.Output | Should -Match 'What if:'
    }

    It 'defaults to audit-only mode without user notifications' {
        $result = Invoke-ScriptSandbox -ScriptName 'Deploy-PurviewDLP.ps1' -Arguments "-Confirm:`$false"
        $result.ExitCode | Should -Be 0
        $result.CallLog | Should -Match 'New-DlpCompliancePolicy Name=UK PII Protection Mode=TestWithoutNotifications'
        $result.CallLog | Should -Match 'New-DlpCompliancePolicy Name=Financial Data Protection Mode=TestWithoutNotifications'
        $result.CallLog | Should -Not -Match 'Mode=Enable\b'
        $result.CallLog | Should -Not -Match 'BlockAccess=True'
    }

    It 'moves to block mode only with -Enforce' {
        $result = Invoke-ScriptSandbox -ScriptName 'Deploy-PurviewDLP.ps1' -Arguments "-Enforce -Confirm:`$false"
        $result.ExitCode | Should -Be 0
        $result.CallLog | Should -Match 'Mode=Enable\b'
        $result.CallLog | Should -Match 'BlockAccess=True'
    }
}

Describe 'Deploy-SentinelWorkspace.ps1 sandbox behaviour' {

    It 'fails parameter binding without mandatory parameters' {
        $result = Invoke-ScriptSandbox -ScriptName 'Deploy-SentinelWorkspace.ps1' -Arguments '-WhatIf'
        $result.ExitCode | Should -Not -Be 0
    }

    It 'creates nothing with -WhatIf' {
        $result = Invoke-ScriptSandbox -ScriptName 'Deploy-SentinelWorkspace.ps1' `
            -Arguments '-ResourceGroupName rg-m365-lab-sentinel -WorkspaceName law-m365-lab -Location uksouth -WhatIf'
        $result.ExitCode | Should -Be 0
        $result.CallLog | Should -BeNullOrEmpty
        $result.Output | Should -Match 'What if:'
    }

    It 'creates the workspace, connectors, and rules when confirmed' {
        $result = Invoke-ScriptSandbox -ScriptName 'Deploy-SentinelWorkspace.ps1' `
            -Arguments "-ResourceGroupName rg-m365-lab-sentinel -WorkspaceName law-m365-lab -Location uksouth -Confirm:`$false"
        $result.ExitCode | Should -Be 0
        $result.CallLog | Should -Match 'New-AzResourceGroup Name=rg-m365-lab-sentinel'
        $result.CallLog | Should -Match 'New-AzOperationalInsightsWorkspace Name=law-m365-lab'
        $result.CallLog | Should -Match 'PUT .*onboardingStates/default'
        $result.CallLog | Should -Match 'PUT .*dataConnectors'
        $result.CallLog | Should -Match 'PUT .*alertRules'
    }
}

Describe 'Remove-SentinelWorkspace.ps1 sandbox behaviour' {

    It 'refuses to target a workspace without lab in the name' {
        $result = Invoke-ScriptSandbox -ScriptName 'Remove-SentinelWorkspace.ps1' `
            -Arguments '-ResourceGroupName rg-corp-sentinel -WorkspaceName law-corp-prod -ConfirmTeardown' -WorkspaceExists $true
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'Guard rail'
        $result.CallLog | Should -BeNullOrEmpty
    }

    It 'previews by default and deletes nothing' {
        $result = Invoke-ScriptSandbox -ScriptName 'Remove-SentinelWorkspace.ps1' `
            -Arguments '-ResourceGroupName rg-m365-lab-sentinel -WorkspaceName law-m365-lab' -WorkspaceExists $true
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Preview mode'
        $result.CallLog | Should -Not -Match 'DELETE|Remove-Az'
    }

    It 'removes the starter rules and workspace with -ConfirmTeardown' {
        $result = Invoke-ScriptSandbox -ScriptName 'Remove-SentinelWorkspace.ps1' `
            -Arguments "-ResourceGroupName rg-m365-lab-sentinel -WorkspaceName law-m365-lab -ConfirmTeardown -Confirm:`$false" -WorkspaceExists $true
        $result.ExitCode | Should -Be 0
        $result.CallLog | Should -Match 'DELETE .*alertRules/stub-rule-1'
        $result.CallLog | Should -Match 'Remove-AzOperationalInsightsWorkspace Name=law-m365-lab'
        $result.CallLog | Should -Not -Match 'Remove-AzResourceGroup'
    }

    It 'keeps the workspace with -RulesOnly' {
        $result = Invoke-ScriptSandbox -ScriptName 'Remove-SentinelWorkspace.ps1' `
            -Arguments "-ResourceGroupName rg-m365-lab-sentinel -WorkspaceName law-m365-lab -RulesOnly -ConfirmTeardown -Confirm:`$false" -WorkspaceExists $true
        $result.ExitCode | Should -Be 0
        $result.CallLog | Should -Match 'DELETE .*alertRules/stub-rule-1'
        $result.CallLog | Should -Not -Match 'Remove-AzOperationalInsightsWorkspace'
    }

    It 'removes the resource group only when explicitly requested' {
        $result = Invoke-ScriptSandbox -ScriptName 'Remove-SentinelWorkspace.ps1' `
            -Arguments "-ResourceGroupName rg-m365-lab-sentinel -WorkspaceName law-m365-lab -RemoveResourceGroup -ConfirmTeardown -Confirm:`$false" -WorkspaceExists $true
        $result.ExitCode | Should -Be 0
        $result.CallLog | Should -Match 'Remove-AzResourceGroup Name=rg-m365-lab-sentinel'
    }
}
