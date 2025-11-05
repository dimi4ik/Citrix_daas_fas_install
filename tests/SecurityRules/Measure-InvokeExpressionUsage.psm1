<#
.SYNOPSIS
    PSScriptAnalyzer Custom Rule: Detect Invoke-Expression Usage

.DESCRIPTION
    This custom rule scans PowerShell scripts for Invoke-Expression usage,
    which poses a code injection security risk.

    Detects:
    - Invoke-Expression cmdlet
    - iex alias
    - Dynamic script block execution
    - Invoke-Command with -ScriptBlock from strings

    Recommended alternatives:
    - Use & (call operator) with script blocks
    - Use parameter splatting
    - Use direct cmdlet calls
    - Use Invoke-Command with pre-defined script blocks

.NOTES
    Author: FAS Security Team
    Version: 1.0.0
    Date: 2025-11-05

    Rule ID: FAS-EXEC-001
    Severity: Error (Critical)
    Category: Security

.LINK
    https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-expression
#>

function Measure-InvokeExpressionUsage {
    <#
    .SYNOPSIS
        Detects Invoke-Expression and related code injection risks

    .DESCRIPTION
        Analyzes AST to identify potentially dangerous dynamic code execution patterns.

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
            #region Check for Invoke-Expression cmdlet

            # Find all command calls
            $commands = $ScriptBlockAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst]
            }, $true)

            foreach ($command in $commands) {
                $commandName = $command.GetCommandName()

                if (-not $commandName) {
                    continue
                }

                # Check for Invoke-Expression or its alias (iex)
                if ($commandName -eq 'Invoke-Expression' -or $commandName -eq 'iex') {
                    $commandText = $command.Extent.Text

                    # Build context-aware message
                    $message = "Invoke-Expression detected - Code injection risk. "

                    # Check what's being executed
                    if ($commandText -match '\$\w+') {
                        $message += "Executing dynamic variable content. "
                    }

                    if ($commandText -match 'Invoke-WebRequest|Invoke-RestMethod|Download') {
                        $message += "WARNING: Executing downloaded content - CRITICAL SECURITY RISK! "
                    }

                    # Provide alternative
                    $message += "Alternatives: Use & (call operator) with script blocks, " +
                                "parameter splatting, or direct cmdlet calls. " +
                                "Found: $commandText"

                    $result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message = $message
                        Extent = $command.Extent
                        RuleName = 'FAS-EXEC-001-InvokeExpression'
                        Severity = 'Error'
                        RuleSuppressionID = 'FAS-EXEC-001'
                    }

                    $results += $result
                }
            }

            #endregion

            #region Check for [ScriptBlock]::Create()

            # Find all member invocation expressions
            $memberInvocations = $ScriptBlockAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.InvokeMemberExpressionAst]
            }, $true)

            foreach ($invocation in $memberInvocations) {
                $invocationText = $invocation.Extent.Text

                # Check for [ScriptBlock]::Create() with string
                if ($invocationText -match '\[ScriptBlock\]::Create') {
                    # Check if creating from variable (dynamic)
                    $isDynamic = $invocationText -match 'Create\s*\(\s*\$'

                    if ($isDynamic) {
                        $message = "[ScriptBlock]::Create() with dynamic content detected - Code injection risk. " +
                                   "Avoid creating script blocks from string variables. " +
                                   "Use pre-defined script blocks instead. " +
                                   "Found: $invocationText"

                        $result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                            Message = $message
                            Extent = $invocation.Extent
                            RuleName = 'FAS-EXEC-001-InvokeExpression'
                            Severity = 'Error'
                            RuleSuppressionID = 'FAS-EXEC-001'
                        }

                        $results += $result
                    }
                }

                # Check for .Invoke() on dynamically created script blocks
                if ($invocationText -match '\.Invoke\(\)' -and
                    $invocationText -match '\$\w+\.Invoke') {

                    # Only flag if the script block appears to be dynamically created
                    # (not flagging pre-defined script blocks)
                    $isLikelyDynamic = $invocationText -match 'Create|Parse|FromFile'

                    if ($isLikelyDynamic) {
                        $message = "Dynamic script block invocation detected. " +
                                   "Ensure script block source is trusted and validated. " +
                                   "Found: $invocationText"

                        $result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                            Message = $message
                            Extent = $invocation.Extent
                            RuleName = 'FAS-EXEC-001-InvokeExpression'
                            Severity = 'Warning'
                            RuleSuppressionID = 'FAS-EXEC-001'
                        }

                        $results += $result
                    }
                }
            }

            #endregion

            #region Check for Add-Type with dynamic source

            # Find Add-Type commands
            $addTypeCalls = $ScriptBlockAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                $node.GetCommandName() -eq 'Add-Type'
            }, $true)

            foreach ($call in $addTypeCalls) {
                $callText = $call.Extent.Text

                # Check if using -TypeDefinition with variable (dynamic)
                if ($callText -match '-TypeDefinition\s+\$' -or
                    $callText -match '-MemberDefinition\s+\$') {

                    $message = "Add-Type with dynamic type definition detected. " +
                               "Ensure type source is trusted and validated. " +
                               "Code injection risk if source is from untrusted input. " +
                               "Found: $callText"

                    $result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message = $message
                        Extent = $call.Extent
                        RuleName = 'FAS-EXEC-001-InvokeExpression'
                        Severity = 'Warning'
                        RuleSuppressionID = 'FAS-EXEC-001'
                    }

                    $results += $result
                }
            }

            #endregion

            #region Check for Invoke-Command with dynamic ScriptBlock

            # Find Invoke-Command calls
            $invokeCommandCalls = $ScriptBlockAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                $node.GetCommandName() -eq 'Invoke-Command'
            }, $true)

            foreach ($call in $invokeCommandCalls) {
                $callText = $call.Extent.Text

                # Check if -ScriptBlock is created from string
                if ($callText -match '-ScriptBlock\s+\[ScriptBlock\]::Create' -or
                    $callText -match '-ScriptBlock\s+\$' -and
                    $callText -match 'Create|Parse') {

                    $message = "Invoke-Command with dynamically created ScriptBlock detected. " +
                               "Use pre-defined script blocks or validate input thoroughly. " +
                               "Found: $callText"

                    $result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message = $message
                        Extent = $call.Extent
                        RuleName = 'FAS-EXEC-001-InvokeExpression'
                        Severity = 'Warning'
                        RuleSuppressionID = 'FAS-EXEC-001'
                    }

                    $results += $result
                }
            }

            #endregion

            #region Check for dangerous patterns with downloaded content

            # Find web request commands
            $webCalls = $ScriptBlockAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                ($node.GetCommandName() -eq 'Invoke-WebRequest' -or
                 $node.GetCommandName() -eq 'Invoke-RestMethod' -or
                 $node.GetCommandName() -eq 'wget' -or
                 $node.GetCommandName() -eq 'curl')
            }, $true)

            foreach ($webCall in $webCalls) {
                # Check if result is piped to Invoke-Expression
                $parent = $webCall.Parent

                if ($parent -is [System.Management.Automation.Language.PipelineAst]) {
                    $pipelineText = $parent.Extent.Text

                    if ($pipelineText -match 'Invoke-Expression|iex|\|\s*&') {
                        $message = "CRITICAL: Downloaded content executed with Invoke-Expression! " +
                                   "This is a severe security vulnerability. " +
                                   "Never execute untrusted downloaded content. " +
                                   "Found: $pipelineText"

                        $result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                            Message = $message
                            Extent = $parent.Extent
                            RuleName = 'FAS-EXEC-001-InvokeExpression'
                            Severity = 'Error'
                            RuleSuppressionID = 'FAS-EXEC-001'
                        }

                        $results += $result
                    }
                }
            }

            #endregion

            return $results
        }
        catch {
            Write-Error "Error in Measure-InvokeExpressionUsage: $($_.Exception.Message)"
            return @()
        }
    }
}

# Export the function
Export-ModuleMember -Function Measure-InvokeExpressionUsage
