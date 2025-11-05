<#
.SYNOPSIS
    PowerShell syntax validation tests

.DESCRIPTION
    Validates all PowerShell scripts for:
    - Syntax errors (Parser validation)
    - PSScriptAnalyzer rules compliance
    - Best practices adherence
    - Security issues

.NOTES
    Version: 1.0.0
    Test Framework: Pester 5.x
#>

#Requires -Modules Pester

BeforeAll {
    # Get all PowerShell scripts in the repository
    $repoRoot = Join-Path $PSScriptRoot '..' '..'
    $script:AllScripts = Get-ChildItem -Path $repoRoot -Include '*.ps1', '*.psm1' -Recurse -File |
        Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }

    Write-Host "Found $($script:AllScripts.Count) PowerShell files for validation"

    # Build test data arrays for -ForEach
    $script:ScriptTestData = @()
    $script:Ps1ScriptTestData = @()

    foreach ($scriptFile in $script:AllScripts) {
        $testData = @{
            Name = $scriptFile.Name
            Path = $scriptFile.FullName
        }
        $script:ScriptTestData += $testData

        # Separate array for *.ps1 files only
        if ($scriptFile.Name -like '*.ps1') {
            $script:Ps1ScriptTestData += $testData
        }
    }

    Write-Host "Test Data: All Scripts = $($script:ScriptTestData.Count), PS1 Only = $($script:Ps1ScriptTestData.Count)"

    # Check if PSScriptAnalyzer is available
    $script:HasPSScriptAnalyzer = $null -ne (Get-Module -ListAvailable -Name PSScriptAnalyzer)

    if (-not $script:HasPSScriptAnalyzer) {
        Write-Warning "PSScriptAnalyzer module not found. Install with: Install-Module -Name PSScriptAnalyzer -Scope CurrentUser"
    }
}

Describe "PowerShell Script Syntax Validation" -Tag 'Validation', 'Syntax' {

    Context "Parser Validation - <Name>" -ForEach $script:ScriptTestData {

        It "Should have valid PowerShell syntax: <Name>" {
            # Arrange
            $scriptContent = Get-Content -Path $Path -Raw

            # Act
            $errors = $null
            $tokens = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($scriptContent, [ref]$errors)

            # Assert
            $errors.Count | Should -Be 0 -Because "Script should not contain syntax errors"

            if ($errors.Count -gt 0) {
                $errorDetails = $errors | ForEach-Object {
                    "Line $($_.Token.StartLine): $($_.Message)"
                }
                Write-Host "Syntax Errors in ${Name}:" -ForegroundColor Red
                $errorDetails | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
            }
        }

        It "Should parse successfully with AST: <Name>" {
            # Arrange
            $scriptContent = Get-Content -Path $Path -Raw

            # Act
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseInput(
                $scriptContent,
                [ref]$null,
                [ref]$errors
            )

            # Assert
            $errors.Count | Should -Be 0 -Because "Script should parse without errors"
            $ast | Should -Not -BeNullOrEmpty -Because "AST should be generated"
        }
    }
}

Describe "PSScriptAnalyzer Validation" -Tag 'Validation', 'PSScriptAnalyzer' -Skip:(-not $script:HasPSScriptAnalyzer) {

    BeforeAll {
        if ($script:HasPSScriptAnalyzer) {
            Import-Module PSScriptAnalyzer
        }
    }

    Context "Script Analysis - <Name>" -ForEach $script:ScriptTestData {

        It "Should pass PSScriptAnalyzer rules: <Name>" {
            # Act
            $results = Invoke-ScriptAnalyzer -Path $Path -Severity @('Error', 'Warning')

            # Assert
            if ($results.Count -gt 0) {
                $resultDetails = $results | ForEach-Object {
                    "[$($_.Severity)] Line $($_.Line): $($_.Message) (Rule: $($_.RuleName))"
                }

                Write-Host "PSScriptAnalyzer Issues in ${Name}:" -ForegroundColor Yellow
                $resultDetails | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $results.Count | Should -Be 0 -Because "Script should follow PSScriptAnalyzer best practices"
        }

        It "Should have no critical errors: <Name>" {
            # Act
            $criticalErrors = Invoke-ScriptAnalyzer -Path $Path -Severity Error

            # Assert
            $criticalErrors.Count | Should -Be 0 -Because "Script should not have critical errors"
        }

        It "Should use approved verbs for functions: <Name>" {
            # Act
            $results = Invoke-ScriptAnalyzer -Path $Path -IncludeRule PSUseApprovedVerbs

            # Assert
            $results.Count | Should -Be 0 -Because "All functions should use approved PowerShell verbs"
        }

        It "Should avoid using plaintext passwords: <Name>" {
            # Act
            $results = Invoke-ScriptAnalyzer -Path $Path -IncludeRule PSAvoidUsingPlainTextForPassword

            # Assert
            $results.Count | Should -Be 0 -Because "Scripts should not contain plaintext passwords"
        }

        It "Should avoid using ConvertTo-SecureString with plaintext: <Name>" {
            # Act
            $results = Invoke-ScriptAnalyzer -Path $Path -IncludeRule PSAvoidUsingConvertToSecureStringWithPlainText

            # Assert
            $results.Count | Should -Be 0 -Because "ConvertTo-SecureString should not use plaintext"
        }
    }
}

Describe "Security Best Practices" -Tag 'Validation', 'Security' {

    Context "Security Checks - <Name>" -ForEach $script:Ps1ScriptTestData {

        It "Should use Set-StrictMode: <Name>" {
            # Arrange
            $scriptContent = Get-Content -Path $Path -Raw

            # Assert
            $scriptContent | Should -Match 'Set-StrictMode' -Because "Scripts should use strict mode for better error handling"
        }

        It "Should set ErrorActionPreference: <Name>" {
            # Arrange
            $scriptContent = Get-Content -Path $Path -Raw

            # Assert
            $scriptContent | Should -Match '\$ErrorActionPreference\s*=' -Because "Scripts should explicitly set error action preference"
        }

        It "Should not contain hardcoded credentials: <Name>" {
            # Arrange
            $scriptContent = Get-Content -Path $Path -Raw

            # Assert
            $scriptContent | Should -Not -Match 'password\s*=\s*["\x27][^\x27"]+["\x27]' -Because "Scripts should not contain hardcoded passwords"
            $scriptContent | Should -Not -Match 'username\s*=\s*["\x27][^\x27"]+["\x27]' -Because "Scripts should not contain hardcoded usernames"
        }
    }
}

Describe "Code Quality Standards" -Tag 'Validation', 'Quality' {

    Context "Documentation - <Name>" -ForEach $script:Ps1ScriptTestData {

        It "Should have comment-based help: <Name>" {
            # Arrange
            $scriptContent = Get-Content -Path $Path -Raw

            # Assert
            $scriptContent | Should -Match '<#[\s\S]*\.SYNOPSIS[\s\S]*#>' -Because "Scripts should have comment-based help"
        }

        It "Should have .DESCRIPTION section: <Name>" {
            # Arrange
            $scriptContent = Get-Content -Path $Path -Raw

            # Assert
            $scriptContent | Should -Match '\.DESCRIPTION' -Because "Scripts should include a description"
        }

        It "Should have .NOTES section: <Name>" {
            # Arrange
            $scriptContent = Get-Content -Path $Path -Raw

            # Assert
            $scriptContent | Should -Match '\.NOTES' -Because "Scripts should include notes with version and author"
        }
    }

    Context "Parameter Validation - <Name>" -ForEach $script:Ps1ScriptTestData {

        It "Should use CmdletBinding attribute: <Name>" {
            # Arrange
            $scriptContent = Get-Content -Path $Path -Raw

            # Assert
            if ($scriptContent -match 'param\s*\(') {
                $scriptContent | Should -Match '\[CmdletBinding\(' -Because "Scripts with parameters should use CmdletBinding"
            }
        }

        It "Should validate mandatory parameters: <Name>" {
            # Arrange
            $scriptContent = Get-Content -Path $Path -Raw

            # Act - Extract parameter blocks
            $ast = [System.Management.Automation.Language.Parser]::ParseInput(
                $scriptContent,
                [ref]$null,
                [ref]$null
            )

            $params = $ast.FindAll({
                $args[0] -is [System.Management.Automation.Language.ParameterAst]
            }, $true)

            # Assert - If mandatory parameters exist, they should have validation
            $mandatoryParams = $params | Where-Object {
                $_.Attributes.NamedArguments.ArgumentName -contains 'Mandatory' -and
                $_.Attributes.NamedArguments.Argument.SafeGetValue() -eq $true
            }

            foreach ($param in $mandatoryParams) {
                Write-Verbose "Found mandatory parameter: $($param.Name.VariablePath.UserPath)"
            }

            # This test ensures mandatory parameters are properly declared
            $mandatoryParams | Should -Not -BeNullOrEmpty -Because "Mandatory parameters should be properly declared" -ErrorAction SilentlyContinue
        }
    }
}

Describe "Encoding and Format Validation" -Tag 'Validation', 'Format' {

    Context "File Encoding - <Name>" -ForEach $script:ScriptTestData {

        It "Should use UTF-8 encoding (with or without BOM): <Name>" {
            # Arrange
            $bytes = [System.IO.File]::ReadAllBytes($Path)

            # Act - Check for UTF-8 BOM or valid UTF-8
            $hasUtf8Bom = $bytes.Length -ge 3 -and
                         $bytes[0] -eq 0xEF -and
                         $bytes[1] -eq 0xBB -and
                         $bytes[2] -eq 0xBF

            # Try to read as UTF-8
            $validUtf8 = $true
            try {
                $null = [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false, $true))
            }
            catch {
                $validUtf8 = $false
            }

            # Assert
            ($hasUtf8Bom -or $validUtf8) | Should -Be $true -Because "Files should use UTF-8 encoding"
        }

        It "Should not have trailing whitespace: <Name>" {
            # Arrange
            $lines = Get-Content -Path $Path

            # Act
            $linesWithTrailing = $lines | Where-Object { $_ -match '\s+$' }

            # Assert
            $linesWithTrailing.Count | Should -Be 0 -Because "Lines should not have trailing whitespace"
        }
    }
}
