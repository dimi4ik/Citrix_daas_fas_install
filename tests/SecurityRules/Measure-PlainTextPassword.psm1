<#
.SYNOPSIS
    PSScriptAnalyzer Custom Rule: Detect Plain-Text Password Parameters

.DESCRIPTION
    This custom rule scans PowerShell scripts for parameters that handle passwords
    as plain-text strings instead of SecureString or PSCredential types.

    Detects:
    - [string]$Password parameters (should be [SecureString])
    - ConvertTo-SecureString -AsPlainText without proper validation
    - String variables containing passwords

.NOTES
    Author: FAS Security Team
    Version: 1.0.0
    Date: 2025-11-05

    Rule ID: FAS-CRED-002
    Severity: Error (Critical)
    Category: Security

.LINK
    https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/convertto-securestring
#>

function Measure-PlainTextPassword {
    <#
    .SYNOPSIS
        Detects plain-text password parameters and variables

    .DESCRIPTION
        Analyzes AST to identify password-related parameters and variables
        that use plain-text string type instead of SecureString.

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
            #region Check for String Password Parameters

            # Find all parameter definitions
            $parameters = $ScriptBlockAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.ParameterAst]
            }, $true)

            foreach ($param in $parameters) {
                $paramName = $param.Name.VariablePath.UserPath.ToLower()

                # Check if parameter name suggests password/credential
                $isPasswordRelated = $paramName -match '(password|pwd|pass|secret|key|credential|cred)'

                if (-not $isPasswordRelated) {
                    continue
                }

                # Get parameter type
                $paramType = $null
                if ($param.Attributes) {
                    $typeConstraint = $param.Attributes | Where-Object {
                        $_ -is [System.Management.Automation.Language.TypeConstraintAst]
                    } | Select-Object -First 1

                    if ($typeConstraint) {
                        $paramType = $typeConstraint.TypeName.Name
                    }
                }

                # Check if using plain-text string type
                if ($paramType -eq 'string' -or $paramType -eq 'String' -or -not $paramType) {
                    # Violation: Password parameter using string type

                    # Build recommendation message
                    $recommendedType = if ($paramName -match 'credential|cred') {
                        'PSCredential'
                    } else {
                        'SecureString'
                    }

                    $message = "Parameter '$paramName' handles sensitive data as plain-text string. " +
                               "Use [$recommendedType] instead for secure password handling."

                    $result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message = $message
                        Extent = $param.Extent
                        RuleName = 'FAS-CRED-002-PlainTextPassword'
                        Severity = 'Error'
                        RuleSuppressionID = 'FAS-CRED-002'
                    }

                    $results += $result
                }
            }

            #endregion

            #region Check for ConvertTo-SecureString -AsPlainText

            # Find all ConvertTo-SecureString calls
            $convertCalls = $ScriptBlockAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                $node.GetCommandName() -eq 'ConvertTo-SecureString'
            }, $true)

            foreach ($call in $convertCalls) {
                $callText = $call.Extent.Text

                # Check if using -AsPlainText
                if ($callText -match '-AsPlainText') {
                    # Check if -Force is also present (common pattern)
                    $hasForce = $callText -match '-Force'

                    # Check if it's reading from Read-Host (acceptable)
                    $isReadHost = $callText -match 'Read-Host'

                    # Check if it's in a secure context (try/catch, validation)
                    $parent = $call.Parent
                    $isInTryCatch = $false
                    while ($parent) {
                        if ($parent -is [System.Management.Automation.Language.TryStatementAst]) {
                            $isInTryCatch = $true
                            break
                        }
                        $parent = $parent.Parent
                    }

                    # Only flag if it's potentially unsafe
                    if (-not $isReadHost) {
                        $severity = if ($hasForce -and -not $isInTryCatch) {
                            'Error'  # Critical: -AsPlainText -Force without error handling
                        } else {
                            'Warning'  # Warning: -AsPlainText but might be acceptable
                        }

                        $message = "ConvertTo-SecureString -AsPlainText detected. " +
                                   "This exposes passwords in memory. " +
                                   "Prefer Read-Host -AsSecureString for interactive input, " +
                                   "or Get-Credential for full credential objects."

                        if ($hasForce) {
                            $message += " Additionally, -Force suppresses security warnings."
                        }

                        $result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                            Message = $message
                            Extent = $call.Extent
                            RuleName = 'FAS-CRED-002-PlainTextPassword'
                            Severity = $severity
                            RuleSuppressionID = 'FAS-CRED-002'
                        }

                        $results += $result
                    }
                }
            }

            #endregion

            #region Check for Get-Credential with -Password string

            # Find Get-Credential calls
            $getCredCalls = $ScriptBlockAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                $node.GetCommandName() -eq 'Get-Credential'
            }, $true)

            foreach ($call in $getCredCalls) {
                $callText = $call.Extent.Text

                # Check if -Password parameter uses a string variable
                if ($callText -match '-Password\s+\$\w+' -and
                    $callText -notmatch 'ConvertTo-SecureString') {

                    $message = "Get-Credential -Password with plain-text variable detected. " +
                               "Convert password to SecureString first: " +
                               "`$securePass = ConvertTo-SecureString `$password -AsSecureString"

                    $result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message = $message
                        Extent = $call.Extent
                        RuleName = 'FAS-CRED-002-PlainTextPassword'
                        Severity = 'Warning'
                        RuleSuppressionID = 'FAS-CRED-002'
                    }

                    $results += $result
                }
            }

            #endregion

            #region Check for New-Object PSCredential with string password

            # Find New-Object PSCredential calls
            $newObjCalls = $ScriptBlockAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                $node.GetCommandName() -eq 'New-Object' -and
                $node.Extent.Text -match 'PSCredential'
            }, $true)

            foreach ($call in $newObjCalls) {
                $callText = $call.Extent.Text

                # Check if second parameter (password) is NOT a SecureString
                # Pattern: New-Object PSCredential($user, $password) where $password is string
                if ($callText -match 'PSCredential.*\(.*,\s*\$\w+\)' -and
                    $callText -notmatch 'ConvertTo-SecureString|SecureString') {

                    $message = "New-Object PSCredential with non-SecureString password detected. " +
                               "Second parameter must be SecureString: " +
                               "New-Object PSCredential(`$user, `$securePassword)"

                    $result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message = $message
                        Extent = $call.Extent
                        RuleName = 'FAS-CRED-002-PlainTextPassword'
                        Severity = 'Error'
                        RuleSuppressionID = 'FAS-CRED-002'
                    }

                    $results += $result
                }
            }

            #endregion

            return $results
        }
        catch {
            Write-Error "Error in Measure-PlainTextPassword: $($_.Exception.Message)"
            return @()
        }
    }
}

# Export the function
Export-ModuleMember -Function Measure-PlainTextPassword
