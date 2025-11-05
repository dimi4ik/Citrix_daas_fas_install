<#
.SYNOPSIS
    PSScriptAnalyzer Custom Rule: Active Directory Domain Consistency Validation

.DESCRIPTION
    This custom rule scans PowerShell scripts for Active Directory-specific issues:
    - Domain parameter consistency across function calls
    - SID format validation (S-1-5-21-xxx-xxx-xxx-xxx)
    - UPN suffix validation
    - Security group SID checks
    - Cross-domain authentication issues

    Critical for Citrix FAS deployment where:
    - User domain must match Computer domain
    - SIDs must be valid and consistent
    - FAS Server security group SID is critical for CA permissions

.NOTES
    Author: FAS Security Team
    Version: 1.0.0
    Date: 2025-11-05

    Rule ID: FAS-AD-001
    Severity: Warning (High)
    Category: Security, Reliability

.LINK
    https://docs.citrix.com/en-us/federated-authentication-service
#>

function Measure-ADDomainConsistency {
    <#
    .SYNOPSIS
        Validates Active Directory domain consistency and SID formats

    .DESCRIPTION
        Analyzes AST to identify potential AD configuration issues that could
        cause authentication failures or security problems in FAS deployments.

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
            #region SID Format Validation

            # Find all string constants that look like SIDs
            $stringConstants = $ScriptBlockAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
                $node.Value -match '^S-1-'
            }, $true)

            foreach ($stringConst in $stringConstants) {
                $sidValue = $stringConst.Value

                # Validate SID format: S-1-5-21-xxxxxxxxxx-xxxxxxxxxx-xxxxxxxxxx-xxxx
                $validSIDPattern = '^S-1-5-21-\d{10}-\d{10}-\d{10}-\d{4,5}$'

                # Also accept well-known SIDs (S-1-5-32-xxx, S-1-5-18, etc.)
                $wellKnownSIDPattern = '^S-1-5-(18|19|20|32-\d+)$'

                if (-not ($sidValue -match $validSIDPattern -or $sidValue -match $wellKnownSIDPattern)) {
                    $message = "Invalid SID format detected: '$sidValue'. " +
                               "Domain SIDs must match pattern: S-1-5-21-xxxxxxxxxx-xxxxxxxxxx-xxxxxxxxxx-xxxx. " +
                               "Well-known SIDs: S-1-5-18 (LocalSystem), S-1-5-32-xxx (Built-in groups). " +
                               "Verify SID is correct using: Get-ADObject or Get-ADUser."

                    $result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message = $message
                        Extent = $stringConst.Extent
                        RuleName = 'FAS-AD-001-DomainConsistency'
                        Severity = 'Warning'
                        RuleSuppressionID = 'FAS-AD-001'
                    }

                    $results += $result
                }

                # Check if SID parameter has proper validation attribute
                $parent = $stringConst.Parent
                $hasValidation = $false

                # Walk up AST to find parameter definition
                while ($parent) {
                    if ($parent -is [System.Management.Automation.Language.ParameterAst]) {
                        # Check if parameter has ValidatePattern attribute
                        foreach ($attribute in $parent.Attributes) {
                            if ($attribute.TypeName.Name -eq 'ValidatePattern' -and
                                $attribute.PositionalArguments[0].Value -match 'S-1-5') {
                                $hasValidation = $true
                                break
                            }
                        }
                        break
                    }
                    $parent = $parent.Parent
                }

                # Recommend validation if missing
                if (-not $hasValidation -and $stringConst.Parent -is [System.Management.Automation.Language.AssignmentStatementAst]) {
                    $varName = $stringConst.Parent.Left.VariablePath.UserPath

                    if ($varName -match 'SID|SecurityIdentifier') {
                        $message = "SID variable '$varName' lacks validation. " +
                                   "Add ValidatePattern attribute to parameter: " +
                                   "[ValidatePattern('^S-1-5-21-\d+-\d+-\d+-\d+`$')]"

                        $result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                            Message = $message
                            Extent = $stringConst.Extent
                            RuleName = 'FAS-AD-001-DomainConsistency'
                            Severity = 'Information'
                            RuleSuppressionID = 'FAS-AD-001'
                        }

                        $results += $result
                    }
                }
            }

            #endregion

            #region Domain Consistency Checks

            # Track domain-related parameters across the script
            $domainParameters = @{}

            # Find all parameters that might contain domain information
            $parameters = $ScriptBlockAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.ParameterAst]
            }, $true)

            foreach ($param in $parameters) {
                $paramName = $param.Name.VariablePath.UserPath

                # Track domain-related parameters
                if ($paramName -match '^(User|Computer|FAS|CA|DC)(Domain|DomainName)$') {
                    $domainParameters[$paramName] = $param
                }
            }

            # Check if multiple domain parameters exist without cross-validation
            if ($domainParameters.Count -gt 1) {
                # Look for validation that ensures domains match
                $scriptText = $ScriptBlockAst.Extent.Text

                $hasConsistencyCheck = $scriptText -match 'if.*Domain.*-ne.*Domain' -or
                                       $scriptText -match 'if.*Domain.*-eq.*Domain' -or
                                       $scriptText -match 'ValidateScript.*Domain'

                if (-not $hasConsistencyCheck) {
                    $domainParamNames = $domainParameters.Keys -join ', '

                    $message = "Multiple domain parameters detected ($domainParamNames) without consistency validation. " +
                               "For FAS deployments, user domain and computer domain must typically match. " +
                               "Add validation: if (`$UserDomain -ne `$ComputerDomain) { throw 'Domain mismatch' }"

                    # Report on first domain parameter
                    $firstParam = $domainParameters.Values | Select-Object -First 1

                    $result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message = $message
                        Extent = $firstParam.Extent
                        RuleName = 'FAS-AD-001-DomainConsistency'
                        Severity = 'Information'
                        RuleSuppressionID = 'FAS-AD-001'
                    }

                    $results += $result
                }
            }

            #endregion

            #region UPN and Email Format Validation

            # Find string constants that look like UPNs (user@domain.com)
            $upnStrings = $ScriptBlockAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
                $node.Value -match '@'
            }, $true)

            foreach ($upnString in $upnStrings) {
                $upnValue = $upnString.Value

                # Skip if it's clearly not a UPN (URLs, email templates, etc.)
                if ($upnValue -match '^https?://' -or $upnValue -match '<|>|\$') {
                    continue
                }

                # Validate UPN format: user@domain.com
                $validUPNPattern = '^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'

                if ($upnValue -match '@' -and -not ($upnValue -match $validUPNPattern)) {
                    $message = "Potentially invalid UPN format: '$upnValue'. " +
                               "UPN should match: user@domain.com. " +
                               "Verify with Get-ADUser -Filter {UserPrincipalName -eq '$upnValue'}"

                    $result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message = $message
                        Extent = $upnString.Extent
                        RuleName = 'FAS-AD-001-DomainConsistency'
                        Severity = 'Information'
                        RuleSuppressionID = 'FAS-AD-001'
                    }

                    $results += $result
                }
            }

            #endregion

            #region FAS-Specific: Security Group SID Validation

            # Find parameters specifically for FAS Security Group SID
            $fasParameters = $ScriptBlockAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.ParameterAst] -and
                $node.Name.VariablePath.UserPath -match 'FAS.*SID|FAS.*SecurityGroup'
            }, $true)

            foreach ($fasParam in $fasParameters) {
                # Check if parameter has proper validation
                $hasValidation = $false
                $hasDocumentation = $false

                foreach ($attribute in $fasParam.Attributes) {
                    if ($attribute.TypeName.Name -eq 'ValidatePattern') {
                        $hasValidation = $true
                    }
                }

                # Check for help comment
                $paramComment = $fasParam.Extent.Text
                if ($paramComment -match '#|<#') {
                    $hasDocumentation = $true
                }

                if (-not $hasValidation) {
                    $message = "FAS Security Group SID parameter lacks validation. " +
                               "This is critical for CA permissions. " +
                               "Add: [ValidatePattern('^S-1-5-21-\d+-\d+-\d+-\d+`$')]"

                    $result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message = $message
                        Extent = $fasParam.Extent
                        RuleName = 'FAS-AD-001-DomainConsistency'
                        Severity = 'Warning'
                        RuleSuppressionID = 'FAS-AD-001'
                    }

                    $results += $result
                }

                if (-not $hasDocumentation) {
                    $message = "FAS Security Group SID parameter should document how to obtain the SID. " +
                               "Example: Get-ADGroup 'FAS Servers' | Select-Object -ExpandProperty SID"

                    $result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message = $message
                        Extent = $fasParam.Extent
                        RuleName = 'FAS-AD-001-DomainConsistency'
                        Severity = 'Information'
                        RuleSuppressionID = 'FAS-AD-001'
                    }

                    $results += $result
                }
            }

            #endregion

            #region Check for AD Cmdlets without Error Handling

            # Find AD cmdlet calls
            $adCmdlets = @(
                'Get-ADUser', 'Get-ADGroup', 'Get-ADComputer', 'Get-ADObject',
                'Set-ADUser', 'New-ADUser', 'Remove-ADUser',
                'Get-ADDomain', 'Get-ADForest'
            )

            $adCommands = $ScriptBlockAst.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                $node.GetCommandName() -in $adCmdlets
            }, $true)

            foreach ($adCommand in $adCommands) {
                # Check if command is in try/catch block
                $parent = $adCommand.Parent
                $isInTryCatch = $false

                while ($parent) {
                    if ($parent -is [System.Management.Automation.Language.TryStatementAst]) {
                        $isInTryCatch = $true
                        break
                    }
                    $parent = $parent.Parent
                }

                if (-not $isInTryCatch) {
                    $cmdName = $adCommand.GetCommandName()

                    $message = "AD cmdlet '$cmdName' used without try/catch error handling. " +
                               "AD operations can fail due to network, permissions, or object not found. " +
                               "Wrap in try/catch block for proper error handling."

                    $result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message = $message
                        Extent = $adCommand.Extent
                        RuleName = 'FAS-AD-001-DomainConsistency'
                        Severity = 'Information'
                        RuleSuppressionID = 'FAS-AD-001'
                    }

                    $results += $result
                }
            }

            #endregion

            return $results
        }
        catch {
            Write-Error "Error in Measure-ADDomainConsistency: $($_.Exception.Message)"
            return @()
        }
    }
}

# Export the function
Export-ModuleMember -Function Measure-ADDomainConsistency
