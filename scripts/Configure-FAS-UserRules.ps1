<#
.SYNOPSIS
    Citrix FAS User Rules Configuration Script

.DESCRIPTION
    This script configures FAS User Certificate Rules and Access Control Lists (ACLs) by:
    1. Creating Certificate Definition (using 917Citrix_SmartcardLogon template)
    2. Defining StoreFront permissions
    3. Defining VDA permissions
    4. Defining User permissions
    5. Creating FAS Rules with combined ACLs

    IMPORTANT: This version uses CUSTOM template "917Citrix_SmartcardLogon"

.PARAMETER ConfigFile
    Path to JSON configuration file. When specified, parameters are loaded from config file.
    Example: ".\config\dev.json"

.PARAMETER StoreFrontPermissions
    Array of hashtables defining StoreFront server permissions.
    Example: @(@{SID="S-1-5-21-xxx-1001"; Permission="Allow"})
    Optional when ConfigFile is specified.

.PARAMETER VDAPermissions
    Array of hashtables defining VDA permissions.
    Example: @(@{SID="S-1-5-21-xxx-1002"; Permission="Allow"})
    Optional when ConfigFile is specified.

.PARAMETER UserPermissions
    Array of hashtables defining User permissions.
    Example: @(@{SID="S-1-5-21-xxx-1003"; Permission="Allow"})
    Optional when ConfigFile is specified.

.PARAMETER CertificateAuthority
    Array of Certificate Authority server FQDNs.
    Optional when ConfigFile is specified.

.PARAMETER FASAddress
    FQDN of the FAS Server.
    Optional when ConfigFile is specified.

.PARAMETER LogPath
    Optional path for log file. Default: "$env:TEMP\FAS-UserRules.log"
    Can be overridden from config file.

.EXAMPLE
    # Using config file
    .\Configure-FAS-UserRules.ps1 -ConfigFile ".\config\dev.json"

.EXAMPLE
    # Using explicit parameters (legacy mode)
    $StoreFrontPerms = @(@{SID="S-1-5-21-xxx-1001"; Permission="Allow"})
    $VDAPerms = @(@{SID="S-1-5-21-xxx-1002"; Permission="Allow"})
    $UserPerms = @(@{SID="S-1-5-21-xxx-1003"; Permission="Allow"})

    .\Configure-FAS-UserRules.ps1 `
        -StoreFrontPermissions $StoreFrontPerms `
        -VDAPermissions $VDAPerms `
        -UserPermissions $UserPerms `
        -CertificateAuthority @("CA-SERVER.domain.com") `
        -FASAddress "FAS-SERVER.domain.com"

.NOTES
    Author: FAS Automation Team
    Version: 1.0.0
    Date: 2025-11-05

    Requirements:
    - Configure-FAS.ps1 must be run first
    - Authorization Certificate must exist
    - Certificate Templates must be deployed

    Template Used:
    - 917Citrix_SmartcardLogon (Custom template)
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false, ParameterSetName='ConfigFile')]
    [ValidateScript({
        if (-not (Test-Path $_)) {
            throw "Config file not found at path: $_"
        }
        if ($_ -notmatch '\.(json|xml)$') {
            throw "Config file must be JSON or XML: $_"
        }
        return $true
    })]
    [string]$ConfigFile,

    [Parameter(Mandatory=$false, ParameterSetName='Manual')]
    [ValidateNotNullOrEmpty()]
    [hashtable[]]$StoreFrontPermissions,

    [Parameter(Mandatory=$false, ParameterSetName='Manual')]
    [ValidateNotNullOrEmpty()]
    [hashtable[]]$VDAPermissions,

    [Parameter(Mandatory=$false, ParameterSetName='Manual')]
    [ValidateNotNullOrEmpty()]
    [hashtable[]]$UserPermissions,

    [Parameter(Mandatory=$false, ParameterSetName='Manual')]
    [ValidateNotNullOrEmpty()]
    [string[]]$CertificateAuthority,

    [Parameter(Mandatory=$false, ParameterSetName='Manual')]
    [ValidateNotNullOrEmpty()]
    [string]$FASAddress,

    [Parameter(Mandatory=$false)]
    [string]$LogPath
)

# Strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#region Helper Functions

function Import-FASConfiguration {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConfigFilePath
    )

    Write-Verbose "Loading configuration from: $ConfigFilePath"

    try {
        # Read and parse JSON config file
        $configContent = Get-Content -Path $ConfigFilePath -Raw -ErrorAction Stop
        $config = $configContent | ConvertFrom-Json -ErrorAction Stop

        Write-Verbose "Configuration loaded successfully for environment: $($config.environment)"

        return $config
    }
    catch {
        throw "Failed to load configuration file: $($_.Exception.Message)"
    }
}

function ConvertTo-PermissionHashtable {
    param(
        [Parameter(Mandatory=$true)]
        [object[]]$Permissions
    )

    $hashtableArray = @()

    foreach ($perm in $Permissions) {
        $hashtableArray += @{
            SID = $perm.SID
            Permission = $perm.Permission
        }
    }

    return $hashtableArray
}

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Info','Warning','Error','Success')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Write to log file
    Add-Content -Path $LogPath -Value $logMessage

    # Write to console with color
    switch ($Level) {
        'Info'    { Write-Host $logMessage -ForegroundColor Cyan }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error'   { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
    }
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..." -Level Info

    # Check if FAS PowerShell module is available
    try {
        $null = Get-Command -Name "New-FasCertificateDefinition" -ErrorAction Stop
        Write-Log "FAS PowerShell SDK: Available" -Level Success
    }
    catch {
        throw "Citrix FAS PowerShell SDK not found. Please install FAS Server first."
    }

    # Check FAS service
    $fasService = Get-Service -Name "CitrixFederatedAuthenticationService" -ErrorAction SilentlyContinue

    if (-not $fasService -or $fasService.Status -ne 'Running') {
        throw "FAS Service not found or not running. Please run Deploy-FAS.ps1 first."
    }

    Write-Log "FAS Service Status: Running" -Level Success

    # Test FAS connectivity
    try {
        $null = Get-FasServer -Address $FASAddress -ErrorAction Stop
        Write-Log "FAS Server connectivity: OK" -Level Success
    }
    catch {
        throw "Cannot connect to FAS Server at $FASAddress"
    }

    # Check if authorization certificate exists
    $authCert = Get-FasAuthorizationCertificate -Address $FASAddress -ErrorAction SilentlyContinue

    if (-not $authCert) {
        throw "Authorization Certificate not found. Please run Configure-FAS.ps1 first."
    }

    Write-Log "Authorization Certificate: Valid (Expires: $($authCert.NotAfter))" -Level Success

    # Validate permission structures
    Write-Log "Validating permission structures..." -Level Info

    foreach ($perm in $StoreFrontPermissions) {
        if (-not $perm.ContainsKey('SID') -or -not $perm.ContainsKey('Permission')) {
            throw "Invalid StoreFront permission structure. Must contain 'SID' and 'Permission' keys."
        }
        if ($perm.Permission -notin @('Allow', 'Deny')) {
            throw "Invalid permission value: $($perm.Permission). Must be 'Allow' or 'Deny'."
        }
    }

    foreach ($perm in $VDAPermissions) {
        if (-not $perm.ContainsKey('SID') -or -not $perm.ContainsKey('Permission')) {
            throw "Invalid VDA permission structure"
        }
    }

    foreach ($perm in $UserPermissions) {
        if (-not $perm.ContainsKey('SID') -or -not $perm.ContainsKey('Permission')) {
            throw "Invalid User permission structure"
        }
    }

    Write-Log "Permission structures: Valid" -Level Success
    Write-Log "Prerequisites check completed" -Level Success
}

function New-SDDLString {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable[]]$Permissions
    )

    Write-Log "Creating SDDL string for $($Permissions.Count) permission(s)..." -Level Info

    $aceStrings = @()

    foreach ($perm in $Permissions) {
        $sid = $perm.SID
        $permission = $perm.Permission

        # ACE format: (A;;GA;;;SID) for Allow, (D;;GA;;;SID) for Deny
        # A = Allow, D = Deny
        # GA = Generic All (full access)
        $aceType = if ($permission -eq 'Allow') { 'A' } else { 'D' }
        $aceString = "($aceType;;GA;;;$sid)"

        Write-Log "  Adding: $aceString ($permission for $sid)" -Level Info
        $aceStrings += $aceString
    }

    # SDDL format: D:(ACE1)(ACE2)(ACE3)...
    # D: = Discretionary ACL
    $sddl = "D:" + ($aceStrings -join '')

    Write-Log "SDDL String created: $sddl" -Level Info

    return $sddl
}

function New-CertificateDefinition {
    Write-Log "========================================" -Level Info
    Write-Log "Step 1: Creating Certificate Definition" -Level Info
    Write-Log "========================================" -Level Info

    try {
        # Get Authorization Certificate GUID
        $authCert = Get-FasAuthorizationCertificate -Address $FASAddress -ErrorAction Stop
        $authCertGuid = $authCert.Id

        Write-Log "Authorization Certificate GUID: $authCertGuid" -Level Info

        # Check if certificate definition already exists
        $existingDef = Get-FasCertificateDefinition -Address $FASAddress -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -eq "default_Definition" }

        if ($existingDef) {
            Write-Log "Certificate Definition 'default_Definition' already exists" -Level Warning
            Write-Log "  Template: $($existingDef.MsTemplate)" -Level Info
            Write-Log "  CA: $($existingDef.CertificateAuthority)" -Level Info

            $response = Read-Host "Do you want to recreate the certificate definition? (Y/N)"
            if ($response -eq 'Y') {
                Write-Log "Removing existing certificate definition..." -Level Info
                Remove-FasCertificateDefinition -Address $FASAddress -Name "default_Definition"
            }
            else {
                Write-Log "Keeping existing certificate definition" -Level Info
                return $existingDef
            }
        }

        # Create Certificate Definition with CUSTOM template
        Write-Log "Creating Certificate Definition with template: 917Citrix_SmartcardLogon" -Level Info

        $certDef = New-FasCertificateDefinition -Address $FASAddress `
                                                -Name "default_Definition" `
                                                -MsTemplate "917Citrix_SmartcardLogon" `
                                                -CertificateAuthority $CertificateAuthority[0] `
                                                -AuthorizationCertificateId $authCertGuid `
                                                -ErrorAction Stop

        Write-Log "Certificate Definition created successfully" -Level Success
        Write-Log "  Name: $($certDef.Name)" -Level Info
        Write-Log "  Template: 917Citrix_SmartcardLogon (Custom)" -Level Success
        Write-Log "  CA: $($CertificateAuthority[0])" -Level Info

        return $certDef
    }
    catch {
        Write-Log "Failed to create certificate definition: $($_.Exception.Message)" -Level Error
        throw
    }
}

function New-UserRules {
    Write-Log "========================================" -Level Info
    Write-Log "Step 2: Creating FAS User Rules" -Level Info
    Write-Log "========================================" -Level Info

    try {
        # Create SDDL strings for each permission type
        Write-Log "Creating StoreFront ACL..." -Level Info
        $storeFrontACL = New-SDDLString -Permissions $StoreFrontPermissions

        Write-Log "Creating VDA ACL..." -Level Info
        $vdaACL = New-SDDLString -Permissions $VDAPermissions

        Write-Log "Creating User ACL..." -Level Info
        $userACL = New-SDDLString -Permissions $UserPermissions

        # Check if rule already exists
        $existingRule = Get-FasRule -Address $FASAddress -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -eq "default" }

        if ($existingRule) {
            Write-Log "FAS Rule 'default' already exists" -Level Warning

            $response = Read-Host "Do you want to recreate the rule? (Y/N)"
            if ($response -eq 'Y') {
                Write-Log "Removing existing rule..." -Level Info
                Remove-FasRule -Address $FASAddress -Name "default"
            }
            else {
                Write-Log "Keeping existing rule" -Level Info
                return $existingRule
            }
        }

        # Create FAS Rule
        Write-Log "Creating FAS Rule 'default'..." -Level Info

        $rule = New-FasRule -Address $FASAddress `
                           -Name "default" `
                           -CertificateDefinitions @("default_Definition") `
                           -StoreFrontAcl $storeFrontACL `
                           -VdaAcl $vdaACL `
                           -UserAcl $userACL `
                           -ErrorAction Stop

        Write-Log "FAS Rule created successfully" -Level Success
        Write-Log "  Name: $($rule.Name)" -Level Info
        Write-Log "  Certificate Definitions: $($rule.CertificateDefinitions -join ', ')" -Level Info
        Write-Log "  StoreFront ACL: $($rule.StoreFrontAcl)" -Level Info
        Write-Log "  VDA ACL: $($rule.VdaAcl)" -Level Info
        Write-Log "  User ACL: $($rule.UserAcl)" -Level Info

        return $rule
    }
    catch {
        Write-Log "Failed to create FAS rule: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Test-Configuration {
    Write-Log "========================================" -Level Info
    Write-Log "Verifying User Rules Configuration" -Level Info
    Write-Log "========================================" -Level Info

    # Check Certificate Definitions
    Write-Log "Checking Certificate Definitions..." -Level Info

    $certDefs = Get-FasCertificateDefinition -Address $FASAddress -ErrorAction SilentlyContinue

    if ($certDefs) {
        foreach ($def in $certDefs) {
            Write-Log "  Certificate Definition found:" -Level Success
            Write-Log "    Name: $($def.Name)" -Level Info
            Write-Log "    Template: $($def.MsTemplate)" -Level Info
            Write-Log "    CA: $($def.CertificateAuthority)" -Level Info

            # Verify it's using the custom template
            if ($def.MsTemplate -eq "917Citrix_SmartcardLogon") {
                Write-Log "    Using CUSTOM template: 917Citrix_SmartcardLogon" -Level Success
            }
        }
    }
    else {
        Write-Log "WARNING: No certificate definitions found" -Level Warning
    }

    # Check FAS Rules
    Write-Log "Checking FAS Rules..." -Level Info

    $rules = Get-FasRule -Address $FASAddress -ErrorAction SilentlyContinue

    if ($rules) {
        foreach ($rule in $rules) {
            Write-Log "  Rule found:" -Level Success
            Write-Log "    Name: $($rule.Name)" -Level Info
            Write-Log "    Definitions: $($rule.CertificateDefinitions -join ', ')" -Level Info
            Write-Log "    StoreFront Permissions: $($rule.StoreFrontAcl)" -Level Info
            Write-Log "    VDA Permissions: $($rule.VdaAcl)" -Level Info
            Write-Log "    User Permissions: $($rule.UserAcl)" -Level Info
        }
    }
    else {
        Write-Log "WARNING: No FAS rules found" -Level Warning
    }

    Write-Log "Configuration verification completed" -Level Success
}

#endregion

#region Main Script

try {
    # Load configuration from file if specified
    if ($PSCmdlet.ParameterSetName -eq 'ConfigFile') {
        Write-Verbose "Using configuration file mode"
        $config = Import-FASConfiguration -ConfigFilePath $ConfigFile

        # Extract parameters from config
        if (-not $CertificateAuthority) {
            $CertificateAuthority = $config.certificateAuthority
        }
        if (-not $FASAddress) {
            $FASAddress = $config.fas.address
        }
        if (-not $StoreFrontPermissions) {
            $StoreFrontPermissions = ConvertTo-PermissionHashtable -Permissions $config.permissions.storeFront
        }
        if (-not $VDAPermissions) {
            $VDAPermissions = ConvertTo-PermissionHashtable -Permissions $config.permissions.vda
        }
        if (-not $UserPermissions) {
            $UserPermissions = ConvertTo-PermissionHashtable -Permissions $config.permissions.user
        }
        if (-not $LogPath) {
            $LogPath = $config.logging.userRulesLogPath
        }
    }

    # Set default log path if not specified
    if (-not $LogPath) {
        $LogPath = "$env:TEMP\FAS-UserRules.log"
    }

    # Validate required parameters
    if (-not $CertificateAuthority) {
        throw "CertificateAuthority is required. Specify via -CertificateAuthority parameter or in config file."
    }
    if (-not $FASAddress) {
        throw "FASAddress is required. Specify via -FASAddress parameter or in config file."
    }
    if (-not $StoreFrontPermissions) {
        throw "StoreFrontPermissions is required. Specify via -StoreFrontPermissions parameter or in config file."
    }
    if (-not $VDAPermissions) {
        throw "VDAPermissions is required. Specify via -VDAPermissions parameter or in config file."
    }
    if (-not $UserPermissions) {
        throw "UserPermissions is required. Specify via -UserPermissions parameter or in config file."
    }

    Write-Log "========================================" -Level Info
    Write-Log "FAS User Rules Configuration Started" -Level Info
    Write-Log "========================================" -Level Info
    if ($ConfigFile) {
        Write-Log "Config File: $ConfigFile" -Level Info
        Write-Log "Environment: $($config.environment)" -Level Info
    }
    Write-Log "FAS Server: $FASAddress" -Level Info
    Write-Log "Certificate Authority: $($CertificateAuthority -join ', ')" -Level Info
    Write-Log "StoreFront Permissions: $($StoreFrontPermissions.Count)" -Level Info
    Write-Log "VDA Permissions: $($VDAPermissions.Count)" -Level Info
    Write-Log "User Permissions: $($UserPermissions.Count)" -Level Info
    Write-Log "Log Path: $LogPath" -Level Info
    Write-Log "" -Level Info

    # Step 0: Prerequisites check
    Test-Prerequisites

    if ($PSCmdlet.ShouldProcess("FAS Server", "Configure User Rules")) {
        # Step 1: Create Certificate Definition (with 917Citrix_SmartcardLogon)
        $certDef = New-CertificateDefinition

        # Step 2: Create FAS Rules with ACLs
        $rule = New-UserRules

        # Step 3: Verify Configuration
        Test-Configuration

        Write-Log "========================================" -Level Success
        Write-Log "FAS User Rules Configuration Completed!" -Level Success
        Write-Log "========================================" -Level Success

        Write-Log "" -Level Info
        Write-Log "CONFIGURATION SUMMARY:" -Level Info
        Write-Log "  Certificate Definition: default_Definition" -Level Info
        Write-Log "  Template: 917Citrix_SmartcardLogon (Custom)" -Level Success
        Write-Log "  FAS Rule: default" -Level Info
        Write-Log "  StoreFront Permissions: $($StoreFrontPermissions.Count) entries" -Level Info
        Write-Log "  VDA Permissions: $($VDAPermissions.Count) entries" -Level Info
        Write-Log "  User Permissions: $($UserPermissions.Count) entries" -Level Info
        Write-Log "" -Level Info
        Write-Log "NEXT STEPS:" -Level Info
        Write-Log "1. Test certificate issuance with test user" -Level Info
        Write-Log "2. Configure StoreFront to use FAS" -Level Info
        Write-Log "3. Test end-to-end SSO with Citrix Virtual Apps/Desktops" -Level Info
        Write-Log "4. Monitor Event Logs for certificate issuance" -Level Info
        Write-Log "" -Level Info
        Write-Log "VALIDATION COMMANDS:" -Level Info
        Write-Log "  Get-FasRule -Address '$FASAddress'" -Level Info
        Write-Log "  Get-FasCertificateDefinition -Address '$FASAddress'" -Level Info
        Write-Log "  Get-WinEvent -LogName 'Citrix-FederatedAuthenticationService/Admin'" -Level Info
        Write-Log "" -Level Info
    }
}
catch {
    Write-Log "========================================" -Level Error
    Write-Log "FAS User Rules Configuration FAILED" -Level Error
    Write-Log "========================================" -Level Error
    Write-Log "Error: $($_.Exception.Message)" -Level Error
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level Error

    exit 1
}
finally {
    Write-Log "Log file saved to: $LogPath" -Level Info
}

#endregion
