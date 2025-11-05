<#
.SYNOPSIS
    Integration tests for all custom security rules

.DESCRIPTION
    Validates that all custom security rules work correctly together
    and can be loaded by PSScriptAnalyzer.

.NOTES
    Author: FAS Security Team
    Version: 1.0.0
    Date: 2025-11-05

    Requirements:
    - Pester 5.x
    - PSScriptAnalyzer
    - All custom security rules
#>

BeforeAll {
    # Import dependencies
    Import-Module PSScriptAnalyzer -ErrorAction Stop

    # Define paths
    $script:RulesPath = "$PSScriptRoot/../SecurityRules"
    $script:SettingsPath = "$PSScriptRoot/../../PSScriptAnalyzerSettings.psd1"
    $script:TestScriptsPath = "$PSScriptRoot/../fixtures"

    # Ensure test fixtures directory exists
    if (-not (Test-Path $script:TestScriptsPath)) {
        New-Item -Path $script:TestScriptsPath -ItemType Directory -Force | Out-Null
    }
}

Describe "Security Rules Integration Tests" {
    Context "Module Loading" {
        It "Should load all custom security rule modules" {
            $ruleModules = Get-ChildItem -Path $script:RulesPath -Filter "*.psm1"

            $ruleModules | Should -Not -BeNullOrEmpty
            $ruleModules.Count | Should -BeGreaterThan 0

            foreach ($module in $ruleModules) {
                { Import-Module $module.FullName -Force -ErrorAction Stop } | Should -Not -Throw
            }
        }

        It "Should export Measure-* functions" {
            $expectedFunctions = @(
                'Measure-HardcodedCredentials',
                'Measure-PlainTextPassword',
                'Measure-InvokeExpressionUsage',
                'Measure-ADDomainConsistency'
            )

            foreach ($functionName in $expectedFunctions) {
                $modulePath = Join-Path $script:RulesPath "$functionName.psm1"
                Import-Module $modulePath -Force -ErrorAction Stop

                $function = Get-Command $functionName -ErrorAction SilentlyContinue
                $function | Should -Not -BeNullOrEmpty
                $function.Name | Should -Be $functionName
            }
        }
    }

    Context "PSScriptAnalyzer Settings" {
        It "Should load PSScriptAnalyzerSettings.psd1" {
            Test-Path $script:SettingsPath | Should -Be $true

            { Import-PowerShellDataFile -Path $script:SettingsPath } | Should -Not -Throw
        }

        It "Should define CustomRulePath" {
            $settings = Import-PowerShellDataFile -Path $script:SettingsPath

            $settings.CustomRulePath | Should -Not -BeNullOrEmpty
            $settings.CustomRulePath | Should -Contain './tests/SecurityRules'
        }

        It "Should enable critical security rules" {
            $settings = Import-PowerShellDataFile -Path $script:SettingsPath

            $criticalRules = @(
                'PSAvoidUsingPlainTextForPassword',
                'PSAvoidUsingConvertToSecureStringWithPlainText',
                'PSAvoidUsingInvokeExpression',
                'PSUsePSCredentialType'
            )

            foreach ($rule in $criticalRules) {
                $settings.Rules.$rule.Enable | Should -Be $true
            }
        }
    }

    Context "End-to-End Security Scanning" {
        BeforeAll {
            # Create test script with violations
            $testScriptPath = Join-Path $script:TestScriptsPath "ViolationTest.ps1"

            $testScriptContent = @'
# This test script contains intentional security violations

# FAS-CRED-001: Hardcoded password
$password = "MyPassword123"

# FAS-CRED-002: Plain-text password parameter
param([string]$UserPassword)

# FAS-EXEC-001: Invoke-Expression
Invoke-Expression "Get-Process"

# FAS-AD-001: Invalid SID format
$sid = "S-1-5-21-INVALID"
'@

            Set-Content -Path $testScriptPath -Value $testScriptContent -Force
        }

        It "Should detect all violations in test script" {
            $testScriptPath = Join-Path $script:TestScriptsPath "ViolationTest.ps1"

            $results = Invoke-ScriptAnalyzer -Path $testScriptPath `
                                            -Settings $script:SettingsPath `
                                            -Severity @('Error', 'Warning')

            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0

            # Should detect hardcoded credentials
            $results | Where-Object { $_.RuleName -match 'FAS-CRED-001' } | Should -Not -BeNullOrEmpty

            # Should detect plain-text password parameter
            $results | Where-Object { $_.RuleName -match 'FAS-CRED-002|PSAvoidUsingPlainTextForPassword' } | Should -Not -BeNullOrEmpty

            # Should detect Invoke-Expression
            $results | Where-Object { $_.RuleName -match 'FAS-EXEC-001|PSAvoidUsingInvokeExpression' } | Should -Not -BeNullOrEmpty
        }

        It "Should NOT flag secure credential handling" {
            $secureScriptPath = Join-Path $script:TestScriptsPath "SecureTest.ps1"

            $secureScriptContent = @'
# Secure credential handling examples

# Secure password input
$securePassword = Read-Host "Enter password" -AsSecureString

# PSCredential parameter (correct)
param([PSCredential]$Credential)

# SecureString parameter (correct)
param([SecureString]$Password)

# Get-Credential (correct)
$cred = Get-Credential -Message "Enter credentials"

# Valid SID
$sid = "S-1-5-21-1234567890-1234567890-1234567890-1234"

# Certificate template (not a credential)
$template = "917Citrix_SmartcardLogon"
'@

            Set-Content -Path $secureScriptPath -Value $secureScriptContent -Force

            $results = Invoke-ScriptAnalyzer -Path $secureScriptPath `
                                            -Settings $script:SettingsPath `
                                            -Severity @('Error', 'Warning')

            # Should have minimal or no violations
            $criticalViolations = $results | Where-Object { $_.Severity -eq 'Error' }
            $criticalViolations | Should -BeNullOrEmpty
        }
    }

    Context "Rule Performance" {
        It "Should scan scripts in reasonable time" {
            $testScript = Join-Path $script:TestScriptsPath "PerformanceTest.ps1"

            # Create a larger test script
            $lines = 1..100 | ForEach-Object {
                "# Comment line $_"
                "`$variable$_ = 'value'"
                "Get-Process | Select-Object -First 1"
            }

            Set-Content -Path $testScript -Value ($lines -join "`n") -Force

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            $results = Invoke-ScriptAnalyzer -Path $testScript `
                                            -Settings $script:SettingsPath

            $stopwatch.Stop()

            # Should complete within 5 seconds for 300-line script
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 5000
        }
    }

    Context "SARIF Output Compatibility" {
        It "Should generate valid diagnostic records" {
            $testScript = '$password = "test123"'
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($testScript, [ref]$null, [ref]$null)

            Import-Module (Join-Path $script:RulesPath "Measure-HardcodedCredentials.psm1") -Force

            $results = Measure-HardcodedCredentials -ScriptBlockAst $ast

            $results | Should -Not -BeNullOrEmpty
            $results[0].Message | Should -Not -BeNullOrEmpty
            $results[0].Extent | Should -Not -BeNullOrEmpty
            $results[0].RuleName | Should -Not -BeNullOrEmpty
            $results[0].Severity | Should -BeIn @('Error', 'Warning', 'Information')
        }
    }
}

Describe "Real-World Script Validation" {
    Context "FAS PowerShell Scripts" {
        It "Should scan Deploy-FAS.ps1 without critical violations" {
            $deployScript = "$PSScriptRoot/../../scripts/Deploy-FAS.ps1"

            if (Test-Path $deployScript) {
                $results = Invoke-ScriptAnalyzer -Path $deployScript `
                                                -Settings $script:SettingsPath `
                                                -Severity 'Error'

                # Critical violations should be zero
                $criticalViolations = $results | Where-Object {
                    $_.Severity -eq 'Error' -and
                    $_.RuleName -match 'FAS-CRED|FAS-EXEC'
                }

                $criticalViolations | Should -BeNullOrEmpty
            } else {
                Set-ItResult -Skipped -Because "Deploy-FAS.ps1 not found"
            }
        }

        It "Should scan Configure-FAS.ps1 without critical violations" {
            $configureScript = "$PSScriptRoot/../../scripts/Configure-FAS.ps1"

            if (Test-Path $configureScript) {
                $results = Invoke-ScriptAnalyzer -Path $configureScript `
                                                -Settings $script:SettingsPath `
                                                -Severity 'Error'

                $criticalViolations = $results | Where-Object {
                    $_.Severity -eq 'Error' -and
                    $_.RuleName -match 'FAS-CRED|FAS-EXEC'
                }

                $criticalViolations | Should -BeNullOrEmpty
            } else {
                Set-ItResult -Skipped -Because "Configure-FAS.ps1 not found"
            }
        }
    }
}

AfterAll {
    # Cleanup test fixtures
    if (Test-Path $script:TestScriptsPath) {
        Remove-Item -Path "$script:TestScriptsPath/*.ps1" -Force -ErrorAction SilentlyContinue
    }
}
