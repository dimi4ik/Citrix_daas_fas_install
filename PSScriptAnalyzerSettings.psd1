<#
.SYNOPSIS
    PSScriptAnalyzer Settings for Citrix FAS Security Testing

.DESCRIPTION
    Central configuration file for PSScriptAnalyzer with focus on:
    - Credential Security (Hardcoded credentials, plain-text passwords)
    - Code Injection Prevention (Invoke-Expression)
    - Active Directory Validation (Domain consistency, SID format)
    - Security Best Practices

.NOTES
    Author: FAS Security Team
    Version: 1.0.0
    Date: 2025-11-05

    Rule Severity Levels:
    - Error (Critical):   Build-breaking security issues
    - Warning (High):     Security concerns requiring attention
    - Information (Med):  Best practice recommendations

.LINK
    https://github.com/PowerShell/PSScriptAnalyzer
#>

@{
    #region General Configuration

    # Include all default PSScriptAnalyzer rules
    IncludeDefaultRules = $true

    # No rules excluded - Full security coverage
    ExcludeRules = @()

    # Scan severity levels
    Severity = @('Error', 'Warning', 'Information')

    #endregion

    #region Custom Security Rules

    # Path to custom security rules
    CustomRulePath = @(
        './tests/SecurityRules'
    )

    # Recurse into subdirectories for custom rules
    RecurseCustomRulePath = $true

    #endregion

    #region Critical Security Rules (Severity: Error)

    Rules = @{
        # CRITICAL: Plain-text password detection
        # Detects string parameters named "Password" (should be SecureString)
        PSAvoidUsingPlainTextForPassword = @{
            Enable = $true
        }

        # CRITICAL: Insecure SecureString conversion
        # Detects ConvertTo-SecureString with -AsPlainText without proper context
        PSAvoidUsingConvertToSecureStringWithPlainText = @{
            Enable = $true
        }

        # CRITICAL: Invoke-Expression usage
        # Code injection risk - use direct cmdlet calls instead
        PSAvoidUsingInvokeExpression = @{
            Enable = $true
        }

        # CRITICAL: PSCredential type validation
        # Ensure credential parameters use proper PSCredential type
        PSUsePSCredentialType = @{
            Enable = $true
        }

        # CRITICAL: Avoid using username/password parameters
        # Use PSCredential instead of separate username/password
        PSAvoidUsingUserNameAndPasswordParams = @{
            Enable = $true
        }

        # CRITICAL: ComputerName hardcoding
        # Avoid hardcoded computer names (use parameters)
        PSAvoidUsingComputerNameHardcoded = @{
            Enable = $true
        }

        #endregion

        #region High Priority Rules (Severity: Warning)

        # HIGH: Write-Host usage
        # Use Write-Output, Write-Verbose, or Write-Information instead
        PSAvoidUsingWriteHost = @{
            Enable = $true
        }

        # HIGH: Cmdlet aliases
        # Use full cmdlet names for better readability
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
        }

        # HIGH: Positional parameters
        # Use named parameters for clarity
        PSAvoidUsingPositionalParameters = @{
            Enable = $true
        }

        # HIGH: Uninitialized variables
        # Initialize variables before use
        PSAvoidUsingUninitializedVariable = @{
            Enable = $true
        }

        # HIGH: Global variables
        # Minimize global scope usage
        PSAvoidGlobalVars = @{
            Enable = $true
        }

        #endregion

        #region Medium Priority Rules (Severity: Information)

        # MEDIUM: ShouldProcess for state-changing functions
        # Implement -WhatIf and -Confirm support
        PSUseShouldProcessForStateChangingFunctions = @{
            Enable = $true
        }

        # MEDIUM: Singular nouns for cmdlet names
        # Follow PowerShell naming conventions
        PSUseSingularNouns = @{
            Enable = $true
        }

        # MEDIUM: Approved verbs
        # Use standard PowerShell verbs (Get, Set, New, Remove, etc.)
        PSUseApprovedVerbs = @{
            Enable = $true
        }

        # MEDIUM: BOM encoding
        # Use UTF-8 with BOM for PowerShell files
        PSUseBOMForUnicodeEncodedFile = @{
            Enable = $true
        }

        # MEDIUM: Output type attribute
        # Declare output types for better type inference
        PSUseOutputTypeCorrectly = @{
            Enable = $true
        }

        # MEDIUM: Consistent indentation (4 spaces)
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind = 'space'
        }

        # MEDIUM: Consistent whitespace
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckPipeForRedundantWhitespace = $true
            CheckSeparator = $true
            CheckParameter = $false
        }

        # MEDIUM: Correct casing for built-in functions
        PSUseCorrectCasing = @{
            Enable = $true
        }

        #endregion

        #region Error Handling Rules

        # Error handling best practices
        PSAvoidUsingEmptyCatchBlock = @{
            Enable = $true
        }

        PSAvoidTrailingWhitespace = @{
            Enable = $true
        }

        #endregion

        #region Performance Rules

        # Performance: Use literal initiator for arrays
        PSUseLiteralInitializerForHashtable = @{
            Enable = $true
        }

        #endregion

        #region AD-Specific Security (Custom Rules)

        # These rules are implemented in custom modules:
        # - Measure-HardcodedCredentials.psm1
        # - Measure-PlainTextPassword.psm1
        # - Measure-InvokeExpressionUsage.psm1
        # - Measure-ADDomainConsistency.psm1

        #endregion
    }

    #region Exclusions Configuration

    # File/folder patterns to exclude from analysis
    ExcludeRules = @(
        # No exclusions - Full security coverage
    )

    # Specific files to exclude (e.g., third-party code)
    # Currently none - all repository code must pass security scan
    IncludeRules = @('*')

    #endregion

    #region Output Configuration

    # Output format for results (Text, SarifReport, Json, etc.)
    # Note: This is typically set via Invoke-ScriptAnalyzer -ReportFormat parameter
    # Default: Text for console output

    #endregion
}

<#
.EXAMPLE
    # Basic usage
    Invoke-ScriptAnalyzer -Path ./scripts/ -Settings ./PSScriptAnalyzerSettings.psd1

.EXAMPLE
    # Generate SARIF report for GitLab Security Dashboard
    Invoke-ScriptAnalyzer -Path ./scripts/ `
                          -Settings ./PSScriptAnalyzerSettings.psd1 `
                          -ReportFormat SarifReport `
                          -ReportFile security-report.sarif

.EXAMPLE
    # Scan specific file with custom rules
    Invoke-ScriptAnalyzer -Path ./scripts/Deploy-FAS.ps1 `
                          -Settings ./PSScriptAnalyzerSettings.psd1 `
                          -Recurse

.EXAMPLE
    # Scan all PowerShell files recursively
    Invoke-ScriptAnalyzer -Path ./ `
                          -Settings ./PSScriptAnalyzerSettings.psd1 `
                          -Recurse `
                          -Severity @('Error','Warning')
#>
