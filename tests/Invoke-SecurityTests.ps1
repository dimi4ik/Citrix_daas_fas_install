<#
.SYNOPSIS
    Comprehensive Security Scanner for Citrix FAS PowerShell Scripts

.DESCRIPTION
    Automated security testing tool that scans PowerShell scripts for:
    - Hardcoded credentials and API keys
    - Plain-text password usage
    - Invoke-Expression and code injection risks
    - Active Directory domain consistency
    - Security best practices violations

    Supports multiple output formats:
    - Console (color-coded)
    - JSON (detailed results)
    - SARIF 2.1.0 (GitLab Security Dashboard)
    - Log files (audit trail)

.PARAMETER Path
    Path to scan (file or directory). Default: ./scripts/

.PARAMETER OutputFormat
    Output format: Console, JSON, SARIF, or All. Default: Console

.PARAMETER OutputPath
    Path for output files. Default: ./security-reports/

.PARAMETER Severity
    Minimum severity level to report: Error, Warning, Information. Default: @('Error','Warning')

.PARAMETER IncludeDefaultRules
    Include PSScriptAnalyzer default rules. Default: $true

.PARAMETER Recurse
    Scan directories recursively. Default: $true

.PARAMETER Verbose
    Enable verbose output for debugging

.EXAMPLE
    .\Invoke-SecurityTests.ps1
    # Basic scan with console output

.EXAMPLE
    .\Invoke-SecurityTests.ps1 -OutputFormat SARIF -OutputPath ./reports/
    # Generate SARIF report for GitLab

.EXAMPLE
    .\Invoke-SecurityTests.ps1 -Path ./scripts/Deploy-FAS.ps1 -Severity Error
    # Scan specific file for critical issues only

.EXAMPLE
    .\Invoke-SecurityTests.ps1 -OutputFormat All -Verbose
    # Generate all output formats with verbose logging

.NOTES
    Author: FAS Security Team
    Version: 1.0.0
    Date: 2025-11-05

    Requirements:
    - PSScriptAnalyzer module (Install-Module -Name PSScriptAnalyzer)
    - PowerShell 5.1 or PowerShell 7+

    Exit Codes:
    0 = No issues found
    1 = Errors found (Critical severity)
    2 = Warnings found (High severity)
    3 = Script execution error
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateScript({Test-Path $_ -PathType Any})]
    [string]$Path = "./scripts/",

    [Parameter(Mandatory=$false)]
    [ValidateSet('Console', 'JSON', 'SARIF', 'All')]
    [string]$OutputFormat = 'Console',

    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "./security-reports/",

    [Parameter(Mandatory=$false)]
    [ValidateSet('Error', 'Warning', 'Information')]
    [string[]]$Severity = @('Error', 'Warning'),

    [Parameter(Mandatory=$false)]
    [bool]$IncludeDefaultRules = $true,

    [Parameter(Mandatory=$false)]
    [bool]$Recurse = $true
)

#region Initialization

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Script metadata
$script:ScriptVersion = "1.0.0"
$script:ScriptName = "FAS-Security-Scanner"
$script:StartTime = Get-Date

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

#endregion

#region Helper Functions

function Write-ColorOutput {
    <#
    .SYNOPSIS
        Write colored output to console
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Critical')]
        [string]$Level = 'Info'
    )

    $color = switch ($Level) {
        'Info'     { 'Cyan' }
        'Success'  { 'Green' }
        'Warning'  { 'Yellow' }
        'Error'    { 'Red' }
        'Critical' { 'Magenta' }
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Write-SecurityLog {
    <#
    .SYNOPSIS
        Write to security audit log
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$Level = 'INFO'
    )

    $logFile = Join-Path $OutputPath "security-scan-$(Get-Date -Format 'yyyyMMdd').log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    Add-Content -Path $logFile -Value $logMessage
}

function Test-PSScriptAnalyzer {
    <#
    .SYNOPSIS
        Check if PSScriptAnalyzer module is available
    #>
    try {
        $module = Get-Module -Name PSScriptAnalyzer -ListAvailable
        if (-not $module) {
            throw "PSScriptAnalyzer module not found"
        }

        Import-Module -Name PSScriptAnalyzer -ErrorAction Stop
        Write-ColorOutput "PSScriptAnalyzer module loaded: Version $($module.Version)" -Level Success
        Write-SecurityLog "PSScriptAnalyzer module loaded: Version $($module.Version)" -Level INFO

        return $true
    }
    catch {
        Write-ColorOutput "Failed to load PSScriptAnalyzer: $($_.Exception.Message)" -Level Error
        Write-ColorOutput "Install with: Install-Module -Name PSScriptAnalyzer -Force" -Level Warning
        return $false
    }
}

function Get-PowerShellFiles {
    <#
    .SYNOPSIS
        Get all PowerShell files to scan
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TargetPath,

        [Parameter(Mandatory=$false)]
        [bool]$RecurseFiles = $true
    )

    if (Test-Path $TargetPath -PathType Leaf) {
        # Single file
        return @(Get-Item $TargetPath)
    }
    else {
        # Directory
        $params = @{
            Path    = $TargetPath
            Filter  = "*.ps1"
            File    = $true
        }

        if ($RecurseFiles) {
            $params.Recurse = $true
        }

        return Get-ChildItem @params
    }
}

function Invoke-SecurityScan {
    <#
    .SYNOPSIS
        Execute PSScriptAnalyzer security scan
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TargetPath,

        [Parameter(Mandatory=$true)]
        [string]$SettingsPath
    )

    Write-ColorOutput "Starting security scan: $TargetPath" -Level Info
    Write-SecurityLog "Starting security scan: $TargetPath" -Level INFO

    try {
        $params = @{
            Path     = $TargetPath
            Settings = $SettingsPath
            Severity = $Severity
        }

        if ($Recurse) {
            $params.Recurse = $true
        }

        $results = Invoke-ScriptAnalyzer @params

        Write-ColorOutput "Scan completed: $($results.Count) findings" -Level Info
        Write-SecurityLog "Scan completed: $($results.Count) findings" -Level INFO

        return $results
    }
    catch {
        Write-ColorOutput "Scan failed: $($_.Exception.Message)" -Level Error
        Write-SecurityLog "Scan failed: $($_.Exception.Message)" -Level ERROR
        throw
    }
}

function ConvertTo-SecurityReport {
    <#
    .SYNOPSIS
        Convert PSScriptAnalyzer results to structured report
    #>
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyCollection()]
        [array]$Results
    )

    # Categorize findings by severity
    $critical = $Results | Where-Object { $_.Severity -eq 'Error' }
    $high = $Results | Where-Object { $_.Severity -eq 'Warning' }
    $medium = $Results | Where-Object { $_.Severity -eq 'Information' }

    # Build structured report
    $report = [PSCustomObject]@{
        ScanMetadata = [PSCustomObject]@{
            ScannerName    = $script:ScriptName
            ScannerVersion = $script:ScriptVersion
            ScanDate       = $script:StartTime
            ScanDuration   = (Get-Date) - $script:StartTime
            TargetPath     = $Path
            TotalFindings  = $Results.Count
        }
        Summary = [PSCustomObject]@{
            Critical = $critical.Count
            High     = $high.Count
            Medium   = $medium.Count
            Total    = $Results.Count
        }
        CriticalFindings = $critical
        HighFindings     = $high
        MediumFindings   = $medium
        AllFindings      = $Results
    }

    return $report
}

function Export-ConsoleReport {
    <#
    .SYNOPSIS
        Display results in console with color coding
    #>
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Report
    )

    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  CITRIX FAS SECURITY SCAN REPORT" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    # Summary
    Write-Host "Scan Summary:" -ForegroundColor White
    Write-Host "  Target Path:    $($Report.ScanMetadata.TargetPath)" -ForegroundColor Gray
    Write-Host "  Scan Date:      $($Report.ScanMetadata.ScanDate)" -ForegroundColor Gray
    Write-Host "  Scan Duration:  $($Report.ScanMetadata.ScanDuration.TotalSeconds) seconds" -ForegroundColor Gray
    Write-Host ""

    # Findings summary
    Write-Host "Findings by Severity:" -ForegroundColor White
    Write-Host "  Critical (Error):       $($Report.Summary.Critical)" -ForegroundColor $(if ($Report.Summary.Critical -gt 0) { 'Red' } else { 'Green' })
    Write-Host "  High (Warning):         $($Report.Summary.High)" -ForegroundColor $(if ($Report.Summary.High -gt 0) { 'Yellow' } else { 'Green' })
    Write-Host "  Medium (Information):   $($Report.Summary.Medium)" -ForegroundColor $(if ($Report.Summary.Medium -gt 0) { 'Cyan' } else { 'Green' })
    Write-Host "  ─────────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host "  Total Findings:         $($Report.Summary.Total)" -ForegroundColor White
    Write-Host ""

    # Critical findings detail
    if ($Report.Summary.Critical -gt 0) {
        Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host "  CRITICAL FINDINGS (BUILD BREAKING)" -ForegroundColor Red
        Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host ""

        foreach ($finding in $Report.CriticalFindings) {
            Write-Host "  [$($finding.RuleName)]" -ForegroundColor Magenta
            Write-Host "  File:    $($finding.ScriptName):$($finding.Line)" -ForegroundColor Gray
            Write-Host "  Message: $($finding.Message)" -ForegroundColor Red
            Write-Host "  Recommendation: $($finding.SuggestedCorrections)" -ForegroundColor Yellow
            Write-Host ""
        }
    }

    # High findings summary
    if ($Report.Summary.High -gt 0) {
        Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host "  HIGH PRIORITY FINDINGS" -ForegroundColor Yellow
        Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host ""

        foreach ($finding in $Report.HighFindings | Select-Object -First 10) {
            Write-Host "  [$($finding.RuleName)]" -ForegroundColor Yellow
            Write-Host "  File:    $($finding.ScriptName):$($finding.Line)" -ForegroundColor Gray
            Write-Host "  Message: $($finding.Message)" -ForegroundColor Yellow
            Write-Host ""
        }

        if ($Report.Summary.High -gt 10) {
            Write-Host "  ... and $($Report.Summary.High - 10) more warnings" -ForegroundColor Gray
            Write-Host ""
        }
    }

    # Exit status
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    if ($Report.Summary.Critical -gt 0) {
        Write-Host "  STATUS: FAILED ❌" -ForegroundColor Red
        Write-Host "  Action Required: Fix critical security issues" -ForegroundColor Red
    }
    elseif ($Report.Summary.High -gt 0) {
        Write-Host "  STATUS: WARNING ⚠️" -ForegroundColor Yellow
        Write-Host "  Recommendation: Review high priority findings" -ForegroundColor Yellow
    }
    else {
        Write-Host "  STATUS: PASSED ✓" -ForegroundColor Green
        Write-Host "  No critical or high priority security issues found" -ForegroundColor Green
    }
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Export-JSONReport {
    <#
    .SYNOPSIS
        Export results to JSON format
    #>
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Report
    )

    $jsonPath = Join-Path $OutputPath "security-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

    try {
        $Report | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8
        Write-ColorOutput "JSON report saved: $jsonPath" -Level Success
        Write-SecurityLog "JSON report saved: $jsonPath" -Level INFO
    }
    catch {
        Write-ColorOutput "Failed to save JSON report: $($_.Exception.Message)" -Level Error
        Write-SecurityLog "Failed to save JSON report: $($_.Exception.Message)" -Level ERROR
    }
}

function Export-SARIFReport {
    <#
    .SYNOPSIS
        Export results to SARIF 2.1.0 format for GitLab Security Dashboard
    #>
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Report
    )

    $sarifPath = Join-Path $OutputPath "security-report.sarif"

    # Build SARIF structure (2.1.0 schema)
    $sarif = @{
        '$schema' = "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json"
        version = "2.1.0"
        runs = @(
            @{
                tool = @{
                    driver = @{
                        name = $script:ScriptName
                        version = $script:ScriptVersion
                        informationUri = "https://github.com/dimi4ik/Citrix_daas_fas_install"
                        rules = @()
                    }
                }
                results = @()
            }
        )
    }

    # Convert findings to SARIF results
    foreach ($finding in $Report.AllFindings) {
        # Map severity
        $sarifLevel = switch ($finding.Severity) {
            'Error'       { 'error' }
            'Warning'     { 'warning' }
            'Information' { 'note' }
            default       { 'none' }
        }

        # Build SARIF result
        $result = @{
            ruleId = $finding.RuleName
            level = $sarifLevel
            message = @{
                text = $finding.Message
            }
            locations = @(
                @{
                    physicalLocation = @{
                        artifactLocation = @{
                            uri = $finding.ScriptName
                        }
                        region = @{
                            startLine = $finding.Line
                            startColumn = $finding.Column
                        }
                    }
                }
            )
        }

        # Add suggested corrections if available
        if ($finding.SuggestedCorrections) {
            $result.fixes = @(
                @{
                    description = @{
                        text = "Suggested fix: $($finding.SuggestedCorrections)"
                    }
                }
            )
        }

        $sarif.runs[0].results += $result
    }

    # Save SARIF file
    try {
        $sarif | ConvertTo-Json -Depth 20 | Out-File -FilePath $sarifPath -Encoding UTF8
        Write-ColorOutput "SARIF report saved: $sarifPath" -Level Success
        Write-SecurityLog "SARIF report saved: $sarifPath" -Level INFO
    }
    catch {
        Write-ColorOutput "Failed to save SARIF report: $($_.Exception.Message)" -Level Error
        Write-SecurityLog "Failed to save SARIF report: $($_.Exception.Message)" -Level ERROR
    }
}

#endregion

#region Main Execution

try {
    Write-ColorOutput "═══════════════════════════════════════════════════════" -Level Info
    Write-ColorOutput "  Citrix FAS Security Scanner v$script:ScriptVersion" -Level Info
    Write-ColorOutput "═══════════════════════════════════════════════════════" -Level Info
    Write-ColorOutput "" -Level Info

    Write-SecurityLog "═══════════════════════════════════════════════════════" -Level INFO
    Write-SecurityLog "Security scan started by: $env:USERNAME" -Level INFO
    Write-SecurityLog "Target path: $Path" -Level INFO
    Write-SecurityLog "Output format: $OutputFormat" -Level INFO

    # Check prerequisites
    Write-ColorOutput "Checking prerequisites..." -Level Info
    if (-not (Test-PSScriptAnalyzer)) {
        exit 3
    }

    # Validate settings file
    $settingsPath = Join-Path $PSScriptRoot "../PSScriptAnalyzerSettings.psd1"
    if (-not (Test-Path $settingsPath)) {
        Write-ColorOutput "Settings file not found: $settingsPath" -Level Error
        Write-SecurityLog "Settings file not found: $settingsPath" -Level ERROR
        exit 3
    }

    Write-ColorOutput "Using settings: $settingsPath" -Level Success

    # Get files to scan
    $files = Get-PowerShellFiles -TargetPath $Path -RecurseFiles $Recurse
    Write-ColorOutput "Found $($files.Count) PowerShell file(s) to scan" -Level Info
    Write-SecurityLog "Found $($files.Count) PowerShell file(s) to scan" -Level INFO

    # Execute scan
    $scanResults = Invoke-SecurityScan -TargetPath $Path -SettingsPath $settingsPath

    # Generate report
    $report = ConvertTo-SecurityReport -Results $scanResults

    # Export in requested format(s)
    switch ($OutputFormat) {
        'Console' {
            Export-ConsoleReport -Report $report
        }
        'JSON' {
            Export-JSONReport -Report $report
            Export-ConsoleReport -Report $report
        }
        'SARIF' {
            Export-SARIFReport -Report $report
            Export-ConsoleReport -Report $report
        }
        'All' {
            Export-JSONReport -Report $report
            Export-SARIFReport -Report $report
            Export-ConsoleReport -Report $report
        }
    }

    Write-SecurityLog "Security scan completed successfully" -Level INFO
    Write-SecurityLog "Total findings: $($report.Summary.Total) (Critical: $($report.Summary.Critical), High: $($report.Summary.High), Medium: $($report.Summary.Medium))" -Level INFO
    Write-SecurityLog "═══════════════════════════════════════════════════════" -Level INFO

    # Exit with appropriate code
    if ($report.Summary.Critical -gt 0) {
        exit 1  # Critical errors found
    }
    elseif ($report.Summary.High -gt 0) {
        exit 2  # Warnings found
    }
    else {
        exit 0  # Success
    }
}
catch {
    Write-ColorOutput "Security scan failed: $($_.Exception.Message)" -Level Critical
    Write-SecurityLog "Security scan failed: $($_.Exception.Message)" -Level ERROR
    Write-SecurityLog "Stack trace: $($_.ScriptStackTrace)" -Level ERROR
    exit 3
}

#endregion
