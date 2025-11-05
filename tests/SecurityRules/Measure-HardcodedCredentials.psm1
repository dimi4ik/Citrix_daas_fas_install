<#
.SYNOPSIS
    PSScriptAnalyzer Custom Rule: Detect Hardcoded Credentials

.DESCRIPTION
    This custom rule scans PowerShell scripts for hardcoded credentials including:
    - Passwords in string literals
    - API keys and tokens
    - Connection strings with credentials
    - Username/password combinations

    IMPORTANT: This rule is AD-aware and will NOT flag:
    - Security Identifier (SID) values (S-1-5-21-xxx-xxx-xxx-xxx)
    - Domain names and UPNs
    - Certificate templates names

.NOTES
    Author: FAS Security Team
    Version: 1.0.0
    Date: 2025-11-05

    Rule ID: FAS-CRED-001
    Severity: Error (Critical)
    Category: Security

.LINK
    https://github.com/PowerShell/PSScriptAnalyzer
#>

function Measure-HardcodedCredentials {
    <#
    .SYNOPSIS
        Detects hardcoded credentials in PowerShell scripts

    .DESCRIPTION
        Analyzes AST (Abstract Syntax Tree) to identify potential hardcoded credentials.
        Returns diagnostic records for violations.

    .PARAMETER ScriptBlockAst
        The AST of the script to analyze

    .OUTPUTS
        Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]$ScriptBlockAst
    )

    process {
        $results = @()

        try {
            # Define credential-related patterns to search for
            $suspiciousPatterns = @{
                # Password patterns
                'password\s*=\s*[''"](?!<|>|\$|param|secure|read-host)(.+?)[''"]' = 'Hardcoded password detected'
                'pwd\s*=\s*[''"](?!<|>|\$|param)(.+?)[''"]' = 'Hardcoded password detected (pwd)'

                # API Key patterns
                'api[-_]?key\s*=\s*[''"](?!<|>|\$|param)(.+?)[''"]' = 'Hardcoded API key detected'
                'apikey\s*=\s*[''"](?!<|>|\$|param)(.+?)[''"]' = 'Hardcoded API key detected'
                'api[-_]?secret\s*=\s*[''"](?!<|>|\$|param)(.+?)[''"]' = 'Hardcoded API secret detected'

                # Token patterns
                'token\s*=\s*[''"](?!<|>|\$|param)(.{20,})[''"]' = 'Hardcoded token detected'
                'bearer\s+[''"](?!<|>|\$)(.{20,})[''"]' = 'Hardcoded bearer token detected'

                # Connection string patterns
                'connection[-_]?string\s*=\s*[''"].*password\s*=.*[''"]' = 'Connection string with hardcoded password'
                'data\s+source\s*=.*password\s*=' = 'Database connection with hardcoded password'

                # Access key patterns
                'access[-_]?key\s*=\s*[''"](?!<|>|\$|param)(.+?)[''"]' = 'Hardcoded access key detected'
                'secret[-_]?key\s*=\s*[''"](?!<|>|\$|param)(.+?)[''"]' = 'Hardcoded secret key detected'

                # Username/Password combo (basic auth)
                '[''"]https?://\w+:\w+@' = 'URL with embedded credentials detected'
            }

            # Whitelisted patterns (AD-specific values that are NOT credentials)
            $whitelistPatterns = @(
                # SID patterns (S-1-5-21-xxxxxxxxxx-xxxxxxxxxx-xxxxxxxxxx-xxxx)
                'S-1-5-21-\d+-\d+-\d+-\d+',

                # Certificate template names
                '917Citrix_SmartcardLogon',
                'Citrix_RegistrationAuthority',
                'SmartcardLogon',

                # Well-known AD values
                'CN=',
                'DC=',
                'OU=',

                # Empty/placeholder values
                '^\s*$',
                '<.*>',
                '\$\w+',  # Variables
                'param\(',  # Parameters
                'Read-Host',  # Interactive input
                'Get-Credential'  # Proper credential handling
            )

            # Get all string constant expressions from AST
            $stringConstants = $ScriptBlockAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.StringConstantExpressionAst]
            }, $true)

            # Get all assignment statements
            $assignments = $ScriptBlockAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.AssignmentStatementAst]
            }, $true)

            # Analyze assignments for credential patterns
            foreach ($assignment in $assignments) {
                $assignmentText = $assignment.Extent.Text.ToLower()

                # Check if whitelisted (SID, template name, etc.)
                $isWhitelisted = $false
                foreach ($whitelistPattern in $whitelistPatterns) {
                    if ($assignmentText -match $whitelistPattern) {
                        $isWhitelisted = $true
                        break
                    }
                }

                if ($isWhitelisted) {
                    continue
                }

                # Check against suspicious patterns
                foreach ($pattern in $suspiciousPatterns.Keys) {
                    if ($assignmentText -match $pattern) {
                        # Found potential hardcoded credential
                        $message = $suspiciousPatterns[$pattern]

                        # Create diagnostic record
                        $result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                            Message = "$message. Use SecureString or PSCredential instead. Found in: $($assignment.Extent.Text)"
                            Extent = $assignment.Extent
                            RuleName = 'FAS-CRED-001-HardcodedCredentials'
                            Severity = 'Error'
                            RuleSuppressionID = 'FAS-CRED-001'
                        }

                        $results += $result
                        break  # Only report once per assignment
                    }
                }
            }

            # Analyze string constants for embedded credentials
            foreach ($stringConst in $stringConstants) {
                $stringValue = $stringConst.Value.ToLower()

                # Skip short strings (< 8 chars) - unlikely to be real credentials
                if ($stringValue.Length -lt 8) {
                    continue
                }

                # Check if whitelisted
                $isWhitelisted = $false
                foreach ($whitelistPattern in $whitelistPatterns) {
                    if ($stringValue -match $whitelistPattern) {
                        $isWhitelisted = $true
                        break
                    }
                }

                if ($isWhitelisted) {
                    continue
                }

                # Check for URL with credentials (http://user:pass@host)
                if ($stringValue -match '^https?://\w+:\w+@') {
                    $result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message = "URL with embedded credentials detected. Use authentication headers instead. Found: $($stringConst.Extent.Text)"
                        Extent = $stringConst.Extent
                        RuleName = 'FAS-CRED-001-HardcodedCredentials'
                        Severity = 'Error'
                        RuleSuppressionID = 'FAS-CRED-001'
                    }

                    $results += $result
                }
            }

            # Check for ConvertTo-SecureString with hardcoded string
            $convertToSecureStringCalls = $ScriptBlockAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                $node.GetCommandName() -eq 'ConvertTo-SecureString'
            }, $true)

            foreach ($call in $convertToSecureStringCalls) {
                $callText = $call.Extent.Text

                # Check if -String parameter has a literal value (not a variable)
                if ($callText -match '-String\s+[''"](.+?)[''"]' -and
                    $callText -notmatch '-String\s+\$') {

                    $result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message = "ConvertTo-SecureString with hardcoded string detected. Read password securely with Read-Host -AsSecureString. Found: $callText"
                        Extent = $call.Extent
                        RuleName = 'FAS-CRED-001-HardcodedCredentials'
                        Severity = 'Error'
                        RuleSuppressionID = 'FAS-CRED-001'
                    }

                    $results += $result
                }
            }

            return $results
        }
        catch {
            Write-Error "Error in Measure-HardcodedCredentials: $($_.Exception.Message)"
            return @()
        }
    }
}

# Export the function
Export-ModuleMember -Function Measure-HardcodedCredentials
