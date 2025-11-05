<#
.SYNOPSIS
    Mock module for Citrix FAS PowerShell SDK

.DESCRIPTION
    This module provides mock implementations of Citrix FAS PowerShell SDK cmdlets
    for isolated testing without requiring actual FAS Server, CA, or AD infrastructure.

.NOTES
    Version: 1.0.0
    Purpose: Isolated PowerShell testing without backend dependencies
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#region Mock Data Storage

$script:MockData = @{
    FASServers = @{}
    AuthorizationCertificates = @{}
    CertificateDefinitions = @{}
    Rules = @{}
    Templates = @{}
}

#endregion

#region FAS Server Cmdlets

function Get-FasServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Address
    )

    if ($script:MockData.FASServers.ContainsKey($Address)) {
        return $script:MockData.FASServers[$Address]
    }

    # Create mock FAS server if not exists
    $mockServer = [PSCustomObject]@{
        Address = $Address
        Version = "2112.0.1.0"
        Status = "Running"
        Id = [guid]::NewGuid().ToString()
    }

    $script:MockData.FASServers[$Address] = $mockServer
    return $mockServer
}

#endregion

#region Certificate Template Cmdlets

function New-FasMsTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Address,

        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [string]$SecurityGroupSID
    )

    Write-Verbose "Mock: Creating FAS MS Template '$Name' on server '$Address'"

    $templateKey = "$Address-$Name"

    if ($script:MockData.Templates.ContainsKey($templateKey)) {
        throw "Template '$Name' already exists on server '$Address'"
    }

    $mockTemplate = [PSCustomObject]@{
        Name = $Name
        Address = $Address
        SecurityGroupSID = $SecurityGroupSID
        SchemaVersion = if ($Name -eq "917Citrix_SmartcardLogon") { 4 } else { 2 }
        HashAlgorithm = if ($Name -eq "917Citrix_SmartcardLogon") { "SHA256" } else { "SHA1" }
        KeyAlgorithm = "RSA"
        KeySize = 2048
        Created = Get-Date
    }

    $script:MockData.Templates[$templateKey] = $mockTemplate

    Write-Verbose "Mock: Template '$Name' created successfully"
    return $mockTemplate
}

function Publish-FasMsTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Address,

        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [string]$CertificateAuthority
    )

    Write-Verbose "Mock: Publishing template '$Name' to CA '$CertificateAuthority'"

    $templateKey = "$Address-$Name"

    if (-not $script:MockData.Templates.ContainsKey($templateKey)) {
        throw "Template '$Name' not found on server '$Address'. Please create it first."
    }

    $template = $script:MockData.Templates[$templateKey]
    $template | Add-Member -NotePropertyName "PublishedToCA" -NotePropertyValue $CertificateAuthority -Force

    Write-Verbose "Mock: Template '$Name' published successfully to '$CertificateAuthority'"
    return $template
}

#endregion

#region Authorization Certificate Cmdlets

function Get-FasAuthorizationCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Address
    )

    if ($script:MockData.AuthorizationCertificates.ContainsKey($Address)) {
        return $script:MockData.AuthorizationCertificates[$Address]
    }

    # Return null if no certificate exists (valid scenario)
    return $null
}

function New-FasAuthorizationCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Address,

        [Parameter(Mandatory=$true)]
        [string]$CertificateAuthority
    )

    Write-Verbose "Mock: Creating authorization certificate on '$Address' from CA '$CertificateAuthority'"

    if ($script:MockData.AuthorizationCertificates.ContainsKey($Address)) {
        Write-Warning "Mock: Authorization certificate already exists. Overwriting..."
    }

    $mockCertificate = [PSCustomObject]@{
        Subject = "CN=FAS-$Address"
        Issuer = "CN=$CertificateAuthority"
        Thumbprint = -join ((1..40) | ForEach-Object { '{0:X}' -f (Get-Random -Maximum 16) })
        NotBefore = Get-Date
        NotAfter = (Get-Date).AddYears(2)
        Id = [guid]::NewGuid().ToString()
        SerialNumber = -join ((1..16) | ForEach-Object { '{0:X2}' -f (Get-Random -Maximum 256) })
    }

    $script:MockData.AuthorizationCertificates[$Address] = $mockCertificate

    Write-Verbose "Mock: Authorization certificate created successfully"
    return $mockCertificate
}

#endregion

#region Certificate Definition Cmdlets

function Get-FasCertificateDefinition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Address
    )

    $definitions = $script:MockData.CertificateDefinitions.GetEnumerator() |
        Where-Object { $_.Key -like "$Address-*" } |
        ForEach-Object { $_.Value }

    return $definitions
}

function New-FasCertificateDefinition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Address,

        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [string]$MsTemplate,

        [Parameter(Mandatory=$true)]
        [string]$CertificateAuthority,

        [Parameter(Mandatory=$true)]
        [string]$AuthorizationCertificateId
    )

    Write-Verbose "Mock: Creating certificate definition '$Name' on '$Address'"

    $defKey = "$Address-$Name"

    if ($script:MockData.CertificateDefinitions.ContainsKey($defKey)) {
        throw "Certificate definition '$Name' already exists on server '$Address'"
    }

    # Verify authorization certificate exists
    if (-not $script:MockData.AuthorizationCertificates.ContainsKey($Address)) {
        throw "Authorization certificate not found. Please create it first."
    }

    # Verify template exists
    $templateKey = "$Address-$MsTemplate"
    if (-not $script:MockData.Templates.ContainsKey($templateKey)) {
        Write-Warning "Mock: Template '$MsTemplate' not found in mock data. Creating template reference..."
    }

    $mockDefinition = [PSCustomObject]@{
        Name = $Name
        Address = $Address
        MsTemplate = $MsTemplate
        CertificateAuthority = $CertificateAuthority
        AuthorizationCertificateId = $AuthorizationCertificateId
        Id = [guid]::NewGuid().ToString()
        Created = Get-Date
    }

    $script:MockData.CertificateDefinitions[$defKey] = $mockDefinition

    Write-Verbose "Mock: Certificate definition '$Name' created successfully"
    return $mockDefinition
}

function Remove-FasCertificateDefinition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Address,

        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    Write-Verbose "Mock: Removing certificate definition '$Name' from '$Address'"

    $defKey = "$Address-$Name"

    if (-not $script:MockData.CertificateDefinitions.ContainsKey($defKey)) {
        throw "Certificate definition '$Name' not found on server '$Address'"
    }

    $script:MockData.CertificateDefinitions.Remove($defKey)
    Write-Verbose "Mock: Certificate definition '$Name' removed successfully"
}

#endregion

#region FAS Rule Cmdlets

function Get-FasRule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Address
    )

    $rules = $script:MockData.Rules.GetEnumerator() |
        Where-Object { $_.Key -like "$Address-*" } |
        ForEach-Object { $_.Value }

    return $rules
}

function New-FasRule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Address,

        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [string[]]$CertificateDefinitions,

        [Parameter(Mandatory=$true)]
        [string]$StoreFrontAcl,

        [Parameter(Mandatory=$true)]
        [string]$VdaAcl,

        [Parameter(Mandatory=$true)]
        [string]$UserAcl
    )

    Write-Verbose "Mock: Creating FAS rule '$Name' on '$Address'"

    $ruleKey = "$Address-$Name"

    if ($script:MockData.Rules.ContainsKey($ruleKey)) {
        throw "Rule '$Name' already exists on server '$Address'"
    }

    # Validate certificate definitions exist
    foreach ($certDef in $CertificateDefinitions) {
        $defKey = "$Address-$certDef"
        if (-not $script:MockData.CertificateDefinitions.ContainsKey($defKey)) {
            throw "Certificate definition '$certDef' not found"
        }
    }

    # Validate SDDL format (basic check)
    foreach ($acl in @($StoreFrontAcl, $VdaAcl, $UserAcl)) {
        if ($acl -notmatch '^D:\(.*\)$') {
            throw "Invalid SDDL format: $acl"
        }
    }

    $mockRule = [PSCustomObject]@{
        Name = $Name
        Address = $Address
        CertificateDefinitions = $CertificateDefinitions
        StoreFrontAcl = $StoreFrontAcl
        VdaAcl = $VdaAcl
        UserAcl = $UserAcl
        Id = [guid]::NewGuid().ToString()
        Created = Get-Date
    }

    $script:MockData.Rules[$ruleKey] = $mockRule

    Write-Verbose "Mock: Rule '$Name' created successfully"
    return $mockRule
}

function Remove-FasRule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Address,

        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    Write-Verbose "Mock: Removing rule '$Name' from '$Address'"

    $ruleKey = "$Address-$Name"

    if (-not $script:MockData.Rules.ContainsKey($ruleKey)) {
        throw "Rule '$Name' not found on server '$Address'"
    }

    $script:MockData.Rules.Remove($ruleKey)
    Write-Verbose "Mock: Rule '$Name' removed successfully"
}

#endregion

#region Mock Data Management

function Reset-FasMockData {
    <#
    .SYNOPSIS
        Resets all mock data to initial state
    .DESCRIPTION
        Use this function in BeforeEach blocks to ensure clean test state
    #>
    [CmdletBinding()]
    param()

    $script:MockData = @{
        FASServers = @{}
        AuthorizationCertificates = @{}
        CertificateDefinitions = @{}
        Rules = @{}
        Templates = @{}
    }

    Write-Verbose "Mock: All FAS mock data reset"
}

function Get-FasMockData {
    <#
    .SYNOPSIS
        Returns current mock data for inspection
    .DESCRIPTION
        Useful for debugging and test assertions
    #>
    [CmdletBinding()]
    param()

    return $script:MockData
}

#endregion

# Export all functions
Export-ModuleMember -Function @(
    'Get-FasServer',
    'New-FasMsTemplate',
    'Publish-FasMsTemplate',
    'Get-FasAuthorizationCertificate',
    'New-FasAuthorizationCertificate',
    'Get-FasCertificateDefinition',
    'New-FasCertificateDefinition',
    'Remove-FasCertificateDefinition',
    'Get-FasRule',
    'New-FasRule',
    'Remove-FasRule',
    'Reset-FasMockData',
    'Get-FasMockData'
)
