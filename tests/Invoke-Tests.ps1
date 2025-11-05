<#
.SYNOPSIS
    Test runner for FAS PowerShell scripts

.DESCRIPTION
    Executes all tests for FAS deployment automation with mock backends.
    Supports different test categories and output formats for CI/CD integration.

.PARAMETER TestType
    Type of tests to run: All, Unit, Integration, Validation, or specific test names

.PARAMETER OutputFormat
    Output format: Console (default), NUnitXml, JUnitXml for CI/CD integration

.PARAMETER OutputPath
    Path for test result output file (required for XML formats)

.PARAMETER CodeCoverage
    Generate code coverage report

.PARAMETER Tags
    Run only tests with specific tags

.EXAMPLE
    .\Invoke-Tests.ps1 -TestType All

.EXAMPLE
    .\Invoke-Tests.ps1 -TestType Validation -OutputFormat NUnitXml -OutputPath "test-results.xml"

.EXAMPLE
    .\Invoke-Tests.ps1 -Tags "Unit","Integration" -CodeCoverage

.NOTES
    Author: FAS Automation Team
    Version: 1.0.0
    Requires: Pester 5.x
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('All', 'Unit', 'Integration', 'Validation', 'Syntax', 'Security')]
    [string]$TestType = 'All',

    [Parameter(Mandatory=$false)]
    [ValidateSet('Console', 'NUnitXml', 'JUnitXml')]
    [string]$OutputFormat = 'Console',

    [Parameter(Mandatory=$false)]
    [string]$OutputPath,

    [Parameter(Mandatory=$false)]
    [switch]$CodeCoverage,

    [Parameter(Mandatory=$false)]
    [string[]]$Tags
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#region Prerequisites Check

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FAS PowerShell Test Runner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check Pester module
$pesterModule = Get-Module -ListAvailable -Name Pester

if (-not $pesterModule) {
    Write-Error "Pester module not found. Install with: Install-Module -Name Pester -Scope CurrentUser -Force"
    exit 1
}

# Check Pester version (require 5.x)
$pesterVersion = ($pesterModule | Sort-Object -Property Version -Descending | Select-Object -First 1).Version

if ($pesterVersion.Major -lt 5) {
    Write-Warning "Pester version $pesterVersion detected. Pester 5.x is recommended."
    Write-Warning "Upgrade with: Install-Module -Name Pester -Force -SkipPublisherCheck"
}

Write-Host "Pester Version: $pesterVersion" -ForegroundColor Green

# Import Pester
Import-Module Pester -MinimumVersion 5.0.0 -ErrorAction Stop

#endregion

#region Test Configuration

$testsRoot = $PSScriptRoot
$repoRoot = Split-Path $testsRoot -Parent

Write-Host "Repository Root: $repoRoot" -ForegroundColor Cyan
Write-Host "Tests Root: $testsRoot" -ForegroundColor Cyan

# Build test path based on test type
$testPaths = switch ($TestType) {
    'All' {
        @(
            (Join-Path $testsRoot 'Validation'),
            (Join-Path $testsRoot 'Unit'),
            (Join-Path $testsRoot 'Integration')
        )
    }
    'Unit' {
        @((Join-Path $testsRoot 'Unit'))
    }
    'Integration' {
        @((Join-Path $testsRoot 'Integration'))
    }
    'Validation' {
        @((Join-Path $testsRoot 'Validation'))
    }
    'Syntax' {
        @((Join-Path $testsRoot 'Validation' 'Syntax.Tests.ps1'))
    }
    'Security' {
        @((Join-Path $testsRoot 'Validation'))
    }
}

Write-Host "Test Type: $TestType" -ForegroundColor Cyan
Write-Host "Test Paths:" -ForegroundColor Cyan
$testPaths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }

#endregion

#region Pester Configuration

$pesterConfig = New-PesterConfiguration

# Test Discovery
$pesterConfig.Run.Path = $testPaths
$pesterConfig.Run.PassThru = $true

# Output Configuration
$pesterConfig.Output.Verbosity = 'Detailed'

# Filter by tags if specified
if ($Tags) {
    $pesterConfig.Filter.Tag = $Tags
    Write-Host "Filtering by tags: $($Tags -join ', ')" -ForegroundColor Cyan
}

# Code Coverage Configuration
if ($CodeCoverage) {
    Write-Host "Code Coverage: Enabled" -ForegroundColor Cyan

    $scriptsPath = Join-Path $repoRoot 'scripts'
    $coverageFiles = Get-ChildItem -Path $scriptsPath -Filter '*.ps1' -Recurse |
        Where-Object { $_.Name -notlike '*.Tests.ps1' } |
        Select-Object -ExpandProperty FullName

    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.Path = $coverageFiles
    $pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
    $pesterConfig.CodeCoverage.OutputPath = Join-Path $testsRoot 'coverage.xml'

    Write-Host "Coverage Files: $($coverageFiles.Count)" -ForegroundColor Cyan
}
else {
    Write-Host "Code Coverage: Disabled" -ForegroundColor Yellow
}

# Test Result Output
if ($OutputFormat -ne 'Console') {
    if (-not $OutputPath) {
        Write-Error "OutputPath is required when using XML output formats"
        exit 1
    }

    Write-Host "Output Format: $OutputFormat" -ForegroundColor Cyan
    Write-Host "Output Path: $OutputPath" -ForegroundColor Cyan

    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = $OutputPath

    switch ($OutputFormat) {
        'NUnitXml' {
            $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
        }
        'JUnitXml' {
            $pesterConfig.TestResult.OutputFormat = 'JUnitXml'
        }
    }
}

#endregion

#region Execute Tests

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Executing Tests..." -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

try {
    $result = Invoke-Pester -Configuration $pesterConfig
}
catch {
    Write-Error "Test execution failed: $($_.Exception.Message)"
    exit 1
}

$stopwatch.Stop()

#endregion

#region Test Results Summary

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Results Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "Total Tests:   $($result.TotalCount)" -ForegroundColor Cyan
Write-Host "Passed:        $($result.PassedCount)" -ForegroundColor Green
Write-Host "Failed:        $($result.FailedCount)" -ForegroundColor $(if ($result.FailedCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "Skipped:       $($result.SkippedCount)" -ForegroundColor Yellow
Write-Host "Not Run:       $($result.NotRunCount)" -ForegroundColor Gray
Write-Host "Duration:      $($stopwatch.Elapsed.ToString('hh\:mm\:ss\.fff'))" -ForegroundColor Cyan

if ($result.FailedCount -gt 0) {
    Write-Host "`nFailed Tests:" -ForegroundColor Red
    $result.Failed | ForEach-Object {
        Write-Host "  [$($_.Block)] $($_.Name)" -ForegroundColor Red
        if ($_.ErrorRecord) {
            Write-Host "    Error: $($_.ErrorRecord.Exception.Message)" -ForegroundColor Gray
        }
    }
}

# Code Coverage Summary
if ($CodeCoverage -and $result.CodeCoverage) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Code Coverage Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $coverage = $result.CodeCoverage
    $coveredPercent = if ($coverage.NumberOfCommandsAnalyzed -gt 0) {
        [math]::Round(($coverage.NumberOfCommandsExecuted / $coverage.NumberOfCommandsAnalyzed) * 100, 2)
    } else { 0 }

    Write-Host "Commands Analyzed:  $($coverage.NumberOfCommandsAnalyzed)" -ForegroundColor Cyan
    Write-Host "Commands Executed:  $($coverage.NumberOfCommandsExecuted)" -ForegroundColor Green
    Write-Host "Commands Missed:    $($coverage.NumberOfCommandsMissed)" -ForegroundColor Yellow
    Write-Host "Coverage:           $coveredPercent%" -ForegroundColor $(if ($coveredPercent -ge 80) { 'Green' } elseif ($coveredPercent -ge 60) { 'Yellow' } else { 'Red' })

    if ($coverage.NumberOfCommandsMissed -gt 0) {
        Write-Host "`nMissed Commands:" -ForegroundColor Yellow
        $coverage.MissedCommands | Select-Object -First 10 | ForEach-Object {
            Write-Host "  Line $($_.Line): $($_.File)" -ForegroundColor Gray
        }

        if ($coverage.MissedCommands.Count -gt 10) {
            Write-Host "  ... and $($coverage.MissedCommands.Count - 10) more" -ForegroundColor Gray
        }
    }

    Write-Host "`nCoverage report saved to: $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor Cyan
}

#endregion

#region Exit Code

Write-Host "`n========================================" -ForegroundColor Cyan

if ($result.FailedCount -eq 0) {
    Write-Host "All tests passed successfully!" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
    exit 0
}
else {
    Write-Host "Some tests failed. Please review the output above." -ForegroundColor Red
    Write-Host "========================================`n" -ForegroundColor Cyan
    exit 1
}

#endregion
