<#
.SYNOPSIS
    Pester tests for Measure-HardcodedCredentials custom rule

.DESCRIPTION
    Unit tests to validate hardcoded credential detection with proper
    handling of AD-specific values (SIDs, domain names, templates).

    ⚠️ IMPORTANT: This file contains INTENTIONAL test credentials
    =====================================================================
    These are NOT real secrets and are used ONLY for unit testing:
    - "MyPassword123" - Test password for detection validation
    - "sk-abc123xyz789" - Test API key pattern
    - "admin:password" - Test URL credentials
    - "P@ssw0rd" - Test connection string password

    These test credentials are:
    ✅ Clearly fake (obvious test patterns)
    ✅ Used ONLY in Pester unit tests
    ✅ NEVER used in production code
    ✅ Required to validate security rule detection

    GitGuardian False Positives:
    This file should be excluded from scanning via .gitguardian.yaml
    Test credentials are essential for validating security detection logic.
    =====================================================================

.NOTES
    Author: FAS Security Team
    Version: 1.0.1
    Date: 2025-11-05

    Requirements:
    - Pester 5.x
    - PSScriptAnalyzer
    - Measure-HardcodedCredentials.psm1

    Security Note:
    All credentials in this file are test data only and pose no security risk.
#>

BeforeAll {
    # Import dependencies
    Import-Module PSScriptAnalyzer -ErrorAction Stop
    Import-Module "$PSScriptRoot/../SecurityRules/Measure-HardcodedCredentials.psm1" -Force -ErrorAction Stop
}

Describe "Measure-HardcodedCredentials" {
    Context "When hardcoded password is detected" {
        It "Should flag simple password assignment" {
            $testScript = @'
$password = "MyPassword123"
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($testScript, [ref]$null, [ref]$null)
            $results = Measure-HardcodedCredentials -ScriptBlockAst $ast

            $results | Should -Not -BeNullOrEmpty
            $results[0].Severity | Should -Be 'Error'
            $results[0].RuleName | Should -Be 'FAS-CRED-001-HardcodedCredentials'
        }

        It "Should flag password in API key assignment" {
            $testScript = @'
$apiKey = "sk-abc123xyz789"
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($testScript, [ref]$null, [ref]$null)
            $results = Measure-HardcodedCredentials -ScriptBlockAst $ast

            $results | Should -Not -BeNullOrEmpty
            $results[0].Severity | Should -Be 'Error'
        }

        It "Should flag connection string with password" {
            $testScript = @'
$connectionString = "Data Source=server;User ID=admin;Password=P@ssw0rd"
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($testScript, [ref]$null, [ref]$null)
            $results = Measure-HardcodedCredentials -ScriptBlockAst $ast

            $results | Should -Not -BeNullOrEmpty
            $results[0].Severity | Should -Be 'Error'
        }

        It "Should flag URL with embedded credentials" {
            $testScript = @'
$url = "https://admin:password@api.example.com"
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($testScript, [ref]$null, [ref]$null)
            $results = Measure-HardcodedCredentials -ScriptBlockAst $ast

            $results | Should -Not -BeNullOrEmpty
            $results[0].Severity | Should -Be 'Error'
        }

        It "Should flag ConvertTo-SecureString with hardcoded string" {
            $testScript = @'
$secure = ConvertTo-SecureString -String "MyPassword" -AsPlainText -Force
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($testScript, [ref]$null, [ref]$null)
            $results = Measure-HardcodedCredentials -ScriptBlockAst $ast

            $results | Should -Not -BeNullOrEmpty
            $results[0].Severity | Should -Be 'Error'
        }
    }

    Context "When AD-specific values should NOT be flagged" {
        It "Should NOT flag valid SID values" {
            $testScript = @'
$FASSecurityGroupSID = "S-1-5-21-1234567890-1234567890-1234567890-1234"
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($testScript, [ref]$null, [ref]$null)
            $results = Measure-HardcodedCredentials -ScriptBlockAst $ast

            $results | Should -BeNullOrEmpty
        }

        It "Should NOT flag certificate template names" {
            $testScript = @'
$templateName = "917Citrix_SmartcardLogon"
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($testScript, [ref]$null, [ref]$null)
            $results = Measure-HardcodedCredentials -ScriptBlockAst $ast

            $results | Should -BeNullOrEmpty
        }

        It "Should NOT flag AD distinguished names" {
            $testScript = @'
$dn = "CN=Users,DC=domain,DC=com"
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($testScript, [ref]$null, [ref]$null)
            $results = Measure-HardcodedCredentials -ScriptBlockAst $ast

            $results | Should -BeNullOrEmpty
        }

        It "Should NOT flag variables (dynamic values)" {
            $testScript = @'
$password = $userInput
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($testScript, [ref]$null, [ref]$null)
            $results = Measure-HardcodedCredentials -ScriptBlockAst $ast

            $results | Should -BeNullOrEmpty
        }

        It "Should NOT flag Read-Host for password input" {
            $testScript = @'
$password = Read-Host "Enter password" -AsSecureString
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($testScript, [ref]$null, [ref]$null)
            $results = Measure-HardcodedCredentials -ScriptBlockAst $ast

            $results | Should -BeNullOrEmpty
        }

        It "Should NOT flag Get-Credential" {
            $testScript = @'
$credential = Get-Credential -Message "Enter credentials"
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($testScript, [ref]$null, [ref]$null)
            $results = Measure-HardcodedCredentials -ScriptBlockAst $ast

            $results | Should -BeNullOrEmpty
        }
    }

    Context "When empty or placeholder values are used" {
        It "Should NOT flag empty strings" {
            $testScript = @'
$password = ""
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($testScript, [ref]$null, [ref]$null)
            $results = Measure-HardcodedCredentials -ScriptBlockAst $ast

            $results | Should -BeNullOrEmpty
        }

        It "Should NOT flag placeholder syntax" {
            $testScript = @'
$password = "<Enter Password>"
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($testScript, [ref]$null, [ref]$null)
            $results = Measure-HardcodedCredentials -ScriptBlockAst $ast

            $results | Should -BeNullOrEmpty
        }
    }

    Context "Rule metadata validation" {
        It "Should have correct rule name" {
            $testScript = '$password = "test123"'
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($testScript, [ref]$null, [ref]$null)
            $results = Measure-HardcodedCredentials -ScriptBlockAst $ast

            $results[0].RuleName | Should -Be 'FAS-CRED-001-HardcodedCredentials'
        }

        It "Should have Error severity for critical violations" {
            $testScript = '$apikey = "sk-123456789"'
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($testScript, [ref]$null, [ref]$null)
            $results = Measure-HardcodedCredentials -ScriptBlockAst $ast

            $results[0].Severity | Should -Be 'Error'
        }

        It "Should provide helpful message" {
            $testScript = '$password = "MyPass123"'
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($testScript, [ref]$null, [ref]$null)
            $results = Measure-HardcodedCredentials -ScriptBlockAst $ast

            $results[0].Message | Should -Match 'SecureString|PSCredential'
        }
    }
}
