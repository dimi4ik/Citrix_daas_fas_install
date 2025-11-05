<#
.SYNOPSIS
    Mock module for Active Directory operations

.DESCRIPTION
    Provides mock implementations of Active Directory .NET classes and
    DirectorySearcher functionality for testing FAS scripts without AD dependencies.

.NOTES
    Version: 1.0.0
    Purpose: Isolated PowerShell testing without backend dependencies
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#region Mock Data Storage

$script:MockADData = @{
    Domain = $null
    CertificateTemplates = @{}
    OUs = @{}
    Groups = @{}
}

#endregion

#region Domain Mock Classes

class MockDirectoryEntry {
    [string]$distinguishedName
    [hashtable]$Properties

    MockDirectoryEntry([string]$dn, [hashtable]$props) {
        $this.distinguishedName = @($dn)
        $this.Properties = $props
    }
}

class MockSearchResult {
    [string]$Path
    [hashtable]$Properties

    MockSearchResult([string]$path, [hashtable]$props) {
        $this.Path = $path
        $this.Properties = $props
    }
}

class MockDirectorySearcher {
    [object]$SearchRoot
    [string]$Filter
    [int]$PageSize = 1000

    [object[]] FindAll() {
        return Get-MockSearchResults -Filter $this.Filter -SearchRoot $this.SearchRoot
    }

    [object] FindOne() {
        $results = $this.FindAll()
        if ($results.Count -gt 0) {
            return $results[0]
        }
        return $null
    }
}

class MockDomain {
    [string]$Name
    [string]$Forest

    MockDomain([string]$name, [string]$forest) {
        $this.Name = $name
        $this.Forest = $forest
    }

    [object] GetDirectoryEntry() {
        $dn = "DC=" + ($this.Name -split '\.' -join ',DC=')
        return [MockDirectoryEntry]::new($dn, @{
            distinguishedName = @($dn)
            name = @($this.Name)
        })
    }

    static [MockDomain] GetCurrentDomain() {
        if ($null -eq $script:MockADData.Domain) {
            # Create default mock domain
            Initialize-MockDomain -DomainName "example.local" -ForestName "example.local"
        }
        return $script:MockADData.Domain
    }
}

#endregion

#region Mock Initialization

function Initialize-MockDomain {
    <#
    .SYNOPSIS
        Initializes a mock Active Directory domain
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$DomainName,

        [Parameter(Mandatory=$false)]
        [string]$ForestName = $DomainName
    )

    $script:MockADData.Domain = [MockDomain]::new($DomainName, $ForestName)

    Write-Verbose "Mock: Domain '$DomainName' initialized"
}

function Add-MockCertificateTemplate {
    <#
    .SYNOPSIS
        Adds a mock certificate template to Active Directory
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$false)]
        [int]$SchemaVersion = 2,

        [Parameter(Mandatory=$false)]
        [string]$DisplayName = $Name,

        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalProperties = @{}
    )

    $domain = [MockDomain]::GetCurrentDomain()
    $configNC = "CN=Configuration," + $domain.GetDirectoryEntry().distinguishedName[0]
    $templateDN = "CN=$Name,CN=Certificate Templates,CN=Public Key Services,CN=Services,$configNC"

    $properties = @{
        cn = @($Name)
        displayName = @($DisplayName)
        'msPKI-Template-Schema-Version' = @($SchemaVersion)
        'msPKI-Cert-Template-OID' = @("1.3.6.1.4.1.311.21.8.$([guid]::NewGuid().ToString())")
        flags = @(131680)  # Default template flags
        revision = @(100)
    }

    # Merge additional properties
    foreach ($key in $AdditionalProperties.Keys) {
        $properties[$key] = @($AdditionalProperties[$key])
    }

    $script:MockADData.CertificateTemplates[$Name] = @{
        DN = $templateDN
        Properties = $properties
    }

    Write-Verbose "Mock: Certificate template '$Name' added to AD"
}

function Remove-MockCertificateTemplate {
    <#
    .SYNOPSIS
        Removes a mock certificate template from Active Directory
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    if ($script:MockADData.CertificateTemplates.ContainsKey($Name)) {
        $script:MockADData.CertificateTemplates.Remove($Name)
        Write-Verbose "Mock: Certificate template '$Name' removed from AD"
    }
    else {
        Write-Warning "Mock: Certificate template '$Name' not found"
    }
}

#endregion

#region Directory Searcher Mock

function Get-MockSearchResults {
    <#
    .SYNOPSIS
        Returns mock search results based on LDAP filter
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Filter,

        [Parameter(Mandatory=$false)]
        [object]$SearchRoot
    )

    $results = @()

    Write-Verbose "Mock: Searching AD with filter: $Filter"

    # Parse filter for certificate templates
    if ($Filter -match "cn=(.+?)\)") {
        $searchName = $Matches[1]

        # Check for specific template names
        foreach ($templateName in $script:MockADData.CertificateTemplates.Keys) {
            if ($searchName -eq $templateName -or $Filter -match "\|\(cn=$templateName\)") {
                $template = $script:MockADData.CertificateTemplates[$templateName]

                $result = [MockSearchResult]::new(
                    "LDAP://$($template.DN)",
                    $template.Properties
                )

                $results += $result
                Write-Verbose "Mock: Found template '$templateName'"
            }
        }
    }

    return $results
}

function New-Object {
    <#
    .SYNOPSIS
        Mock implementation of New-Object for AD types
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$TypeName,

        [Parameter(Mandatory=$false, Position=1)]
        [object[]]$ArgumentList
    )

    Write-Verbose "Mock: New-Object called for type: $TypeName"

    switch ($TypeName) {
        'System.DirectoryServices.DirectorySearcher' {
            return [MockDirectorySearcher]::new()
        }
        'System.DirectoryServices.DirectoryEntry' {
            if ($ArgumentList -and $ArgumentList[0]) {
                $ldapPath = $ArgumentList[0]
                Write-Verbose "Mock: Creating DirectoryEntry for: $ldapPath"

                # Extract DN from LDAP path
                $dn = $ldapPath -replace '^LDAP://', ''

                # Check if this is a template path
                if ($dn -match 'CN=([^,]+),CN=Certificate Templates') {
                    $templateName = $Matches[1]
                    if ($script:MockADData.CertificateTemplates.ContainsKey($templateName)) {
                        $template = $script:MockADData.CertificateTemplates[$templateName]
                        return [MockDirectoryEntry]::new($dn, $template.Properties)
                    }
                }

                # Default entry
                return [MockDirectoryEntry]::new($dn, @{})
            }
            return [MockDirectoryEntry]::new("", @{})
        }
        'Security.Principal.WindowsPrincipal' {
            # Mock for administrator check
            return New-MockWindowsPrincipal -ArgumentList $ArgumentList
        }
        'Security.Principal.WindowsIdentity' {
            # Mock for current identity
            return New-MockWindowsIdentity
        }
        default {
            # Fallback to real New-Object for other types
            return Microsoft.PowerShell.Utility\New-Object -TypeName $TypeName -ArgumentList $ArgumentList
        }
    }
}

#endregion

#region Security Principal Mocks

$script:MockIsAdmin = $true

function New-MockWindowsPrincipal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object[]]$ArgumentList
    )

    $mockPrincipal = [PSCustomObject]@{
        Identity = if ($ArgumentList) { $ArgumentList[0] } else { (New-MockWindowsIdentity) }
    }

    $mockPrincipal | Add-Member -MemberType ScriptMethod -Name 'IsInRole' -Value {
        param($role)
        return $script:MockIsAdmin
    }

    return $mockPrincipal
}

function New-MockWindowsIdentity {
    [CmdletBinding()]
    param()

    return [PSCustomObject]@{
        Name = "$env:USERDOMAIN\$env:USERNAME"
        AuthenticationType = "NTLM"
        IsAuthenticated = $true
    }

    # Add GetCurrent static method
    $identity | Add-Member -MemberType ScriptMethod -Name 'GetCurrent' -Value {
        return $this
    } -Force

    return $identity
}

function Set-MockAdministrator {
    <#
    .SYNOPSIS
        Sets whether the current mock user is an administrator
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [bool]$IsAdmin
    )

    $script:MockIsAdmin = $IsAdmin
    Write-Verbose "Mock: Administrator status set to: $IsAdmin"
}

#endregion

#region Event Log Mocks

$script:MockEventLogs = @()

function Get-WinEvent {
    <#
    .SYNOPSIS
        Mock implementation of Get-WinEvent
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogName,

        [Parameter(Mandatory=$false)]
        [int]$MaxEvents = 100,

        [Parameter(Mandatory=$false)]
        [switch]$ErrorAction
    )

    Write-Verbose "Mock: Getting events from log: $LogName (max: $MaxEvents)"

    $relevantEvents = $script:MockEventLogs |
        Where-Object { $_.LogName -eq $LogName } |
        Select-Object -First $MaxEvents

    if ($relevantEvents.Count -eq 0 -and $ErrorAction -ne 'SilentlyContinue') {
        throw "No events found in log '$LogName'"
    }

    return $relevantEvents
}

function Add-MockEventLog {
    <#
    .SYNOPSIS
        Adds a mock event log entry
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogName,

        [Parameter(Mandatory=$true)]
        [int]$EventID,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Information', 'Warning', 'Error')]
        [string]$Level,

        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$ProviderName = "Citrix-FederatedAuthenticationService"
    )

    $event = [PSCustomObject]@{
        LogName = $LogName
        Id = $EventID
        LevelDisplayName = $Level
        Message = $Message
        ProviderName = $ProviderName
        TimeCreated = Get-Date
    }

    $script:MockEventLogs += $event
    Write-Verbose "Mock: Event log entry added: $LogName - $Level - $Message"
}

function Clear-MockEventLogs {
    <#
    .SYNOPSIS
        Clears all mock event logs
    #>
    [CmdletBinding()]
    param()

    $script:MockEventLogs = @()
    Write-Verbose "Mock: All event logs cleared"
}

#endregion

#region Mock Reset

function Reset-ActiveDirectoryMockData {
    <#
    .SYNOPSIS
        Resets all Active Directory mock data
    #>
    [CmdletBinding()]
    param()

    $script:MockADData = @{
        Domain = $null
        CertificateTemplates = @{}
        OUs = @{}
        Groups = @{}
    }

    $script:MockEventLogs = @()
    $script:MockIsAdmin = $true

    Write-Verbose "Mock: All Active Directory mock data reset"
}

#endregion

# Export all functions and classes
Export-ModuleMember -Function @(
    'Initialize-MockDomain',
    'Add-MockCertificateTemplate',
    'Remove-MockCertificateTemplate',
    'New-Object',
    'Set-MockAdministrator',
    'Get-WinEvent',
    'Add-MockEventLog',
    'Clear-MockEventLogs',
    'Reset-ActiveDirectoryMockData'
)

# Note: Classes are automatically available when module is imported
