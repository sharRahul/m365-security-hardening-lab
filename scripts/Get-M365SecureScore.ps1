<#
.SYNOPSIS
Retrieves Microsoft Secure Score and optionally compares it with a saved baseline.

.DESCRIPTION
Uses Microsoft Graph Security API to retrieve the latest Microsoft Secure Score. The script exports SecureScore.json to the outputs folder, prints an overall and category-level summary, and compares the current result with a baseline file when one is available.

.PARAMETER BaselinePath
Optional path to a SecureScore.json baseline file. If omitted, the script looks for the newest outputs/baseline-YYYY-MM-DD/SecureScore.json file.

.EXAMPLE
pwsh ./scripts/Get-M365SecureScore.ps1

.EXAMPLE
pwsh ./scripts/Get-M365SecureScore.ps1 -BaselinePath ./outputs/baseline-2026-05-14/SecureScore.json

.NOTES
Required module: Microsoft.Graph.
Recommended Graph scope: SecurityEvents.Read.All.
#>

[CmdletBinding()]
param(
    [string]$BaselinePath
)

$ErrorActionPreference = 'Stop'

function Import-RequiredModule {
    param([Parameter(Mandatory = $true)][string]$Name)

    if (-not (Get-Module -ListAvailable -Name $Name)) {
        throw "Required PowerShell module '$Name' is not installed. Install it with: Install-Module $Name -Scope CurrentUser"
    }

    Import-Module $Name -ErrorAction Stop
}

function Get-RepositoryRoot {
    return (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
}

function Connect-GraphIfNeeded {
    $context = Get-MgContext -ErrorAction SilentlyContinue
    if ($null -ne $context) {
        Write-Host "Microsoft Graph already connected as $($context.Account)." -ForegroundColor Cyan
        return
    }

    Connect-MgGraph -Scopes @('SecurityEvents.Read.All') -NoWelcome
}

function Get-LatestSecureScore {
    $uri = 'https://graph.microsoft.com/v1.0/security/secureScores?$top=1&$orderby=createdDateTime desc'
    $response = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
    $score = @($response.value) | Select-Object -First 1

    if ($null -eq $score) {
        throw 'Microsoft Graph returned no Secure Score records for this tenant.'
    }

    return $score
}

function Get-DefaultBaselinePath {
    $outputsPath = Join-Path -Path (Get-RepositoryRoot) -ChildPath 'outputs'
    if (-not (Test-Path -Path $outputsPath)) {
        return $null
    }

    $candidate = Get-ChildItem -Path $outputsPath -Directory -Filter 'baseline-*' -ErrorAction SilentlyContinue |
        Sort-Object -Property LastWriteTime -Descending |
        ForEach-Object { Join-Path -Path $_.FullName -ChildPath 'SecureScore.json' } |
        Where-Object { Test-Path -Path $_ } |
        Select-Object -First 1

    return $candidate
}

function Get-SecureScoreRows {
    param(
        [Parameter(Mandatory = $true)]$ScoreObject,
        $BaselineObject
    )

    $rows = New-Object System.Collections.Generic.List[object]
    $baselineOverallScore = if ($BaselineObject) { [double]$BaselineObject.currentScore } else { $null }

    $overallMax = [double]$ScoreObject.maxScore
    $overallCurrent = [double]$ScoreObject.currentScore
    $overallPercentage = if ($overallMax -gt 0) { [math]::Round(($overallCurrent / $overallMax) * 100, 2) } else { 0 }
    $overallDelta = if ($null -ne $baselineOverallScore) { [math]::Round($overallCurrent - $baselineOverallScore, 2) } else { $null }

    $controlScores = @($ScoreObject.controlScores)
    $recommendedActions = @($controlScores | Where-Object { $_.implementationStatus -ne 'implemented' }).Count

    $rows.Add([pscustomobject]@{
        Category                = 'Overall'
        Score                   = [math]::Round($overallCurrent, 2)
        MaxScore                = [math]::Round($overallMax, 2)
        Percentage              = $overallPercentage
        Delta                   = $overallDelta
        RecommendedActionCount  = $recommendedActions
    }) | Out-Null

    $baselineByCategory = @{}
    if ($BaselineObject -and $BaselineObject.controlScores) {
        @($BaselineObject.controlScores) |
            Group-Object -Property controlCategory |
            ForEach-Object {
                $baselineByCategory[$_.Name] = ($_.Group | Measure-Object -Property score -Sum).Sum
            }
    }

    $controlScores |
        Group-Object -Property controlCategory |
        Sort-Object -Property Name |
        ForEach-Object {
            $categoryScore = [double](($_.Group | Measure-Object -Property score -Sum).Sum)
            $categoryMax = [double](($_.Group | Measure-Object -Property maxScore -Sum).Sum)
            $categoryPercentage = if ($categoryMax -gt 0) { [math]::Round(($categoryScore / $categoryMax) * 100, 2) } else { 0 }
            $categoryDelta = $null

            if ($baselineByCategory.ContainsKey($_.Name)) {
                $categoryDelta = [math]::Round($categoryScore - [double]$baselineByCategory[$_.Name], 2)
            }

            $rows.Add([pscustomobject]@{
                Category                = if ($_.Name) { $_.Name } else { 'Uncategorised' }
                Score                   = [math]::Round($categoryScore, 2)
                MaxScore                = [math]::Round($categoryMax, 2)
                Percentage              = $categoryPercentage
                Delta                   = $categoryDelta
                RecommendedActionCount  = @($_.Group | Where-Object { $_.implementationStatus -ne 'implemented' }).Count
            }) | Out-Null
        }

    return $rows
}

Import-RequiredModule -Name Microsoft.Graph.Authentication
Connect-GraphIfNeeded

$repoRoot = Get-RepositoryRoot
$outputFolder = Join-Path -Path $repoRoot -ChildPath 'outputs'
New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null

$currentScore = Get-LatestSecureScore
$outputPath = Join-Path -Path $outputFolder -ChildPath 'SecureScore.json'
$currentScore | ConvertTo-Json -Depth 30 | Out-File -FilePath $outputPath -Encoding utf8

if (-not $BaselinePath) {
    $BaselinePath = Get-DefaultBaselinePath
}

$baselineScore = $null
if ($BaselinePath -and (Test-Path -Path $BaselinePath)) {
    Write-Host "Baseline comparison file: $BaselinePath" -ForegroundColor Cyan
    $baselineScore = Get-Content -Path $BaselinePath -Raw | ConvertFrom-Json
} else {
    Write-Warning 'No Secure Score baseline file found. Delta values will be blank.'
}

Write-Host ''
Write-Host 'Microsoft Secure Score summary' -ForegroundColor Cyan
$rows = Get-SecureScoreRows -ScoreObject $currentScore -BaselineObject $baselineScore
$rows | Format-Table -AutoSize

Write-Host "Secure Score exported to $outputPath" -ForegroundColor Green
