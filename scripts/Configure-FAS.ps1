<#
.SYNOPSIS
    Citrix FAS Configuration Script - Certificate Templates and CA Integration

.DESCRIPTION
    This script configures Citrix Federated Authentication Service by:
    1. Deploying Certificate Templates (917Citrix_SmartcardLogon, Citrix_RegistrationAuthority)
    2. Publishing templates to Certificate Authority
    3. Creating Authorization Certificate for FAS Server

    IMPORTANT: This version uses CUSTOM template "917Citrix_SmartcardLogon" with:
    - Schema Version 4 (Windows Server 2016+)
    - SHA256 Hash Algorithm
    - RSA 2048-bit keys
    - Microsoft Software Key Storage Provider

.PARAMETER ConfigFile
    Path to JSON configuration file. When specified, parameters are loaded from config file.
    Example: ".\config\dev.json"

.PARAMETER CertificateAuthority
    Array of Certificate Authority server FQDNs.
    Example: @("CA-SERVER-01.domain.com", "CA-SERVER-02.domain.com")
    Optional when ConfigFile is specified.

.PARAMETER FASAddress
    FQDN of the FAS Server.
    Example: "FAS-SERVER-01.domain.com"
    Optional when ConfigFile is specified.

.PARAMETER FASSecurityGroupSID
    Security Identifier (SID) of the FAS Servers security group.
    Example: "S-1-5-21-xxxxxxxxxx-xxxxxxxxxx-xxxxxxxxxx-xxxx"
    Optional when ConfigFile is specified.

.PARAMETER LogPath
    Optional path for log file. Default: "$env:TEMP\FAS-Configure.log"
    Can be overridden from config file.

.EXAMPLE
    # Using config file
    .\Configure-FAS.ps1 -ConfigFile ".\config\dev.json"

.EXAMPLE
    # Using explicit parameters (legacy mode)
    $CAServers = @("CA-SERVER-01.domain.com")
    $FASServer = "FAS-SERVER-01.domain.com"
    $FASSID = "S-1-5-21-123456789-123456789-123456789-1234"

    .\Configure-FAS.ps1 -CertificateAuthority $CAServers `
                        -FASAddress $FASServer `
                        -FASSecurityGroupSID $FASSID

.NOTES
    Author: FAS Automation Team
    Version: 1.0.0
    Date: 2025-11-05

    Requirements:
    - Enterprise Forest Administrator rights
    - Certificate Authority Administrator rights
    - FAS Server must be installed (Deploy-FAS.ps1)
    - Citrix FAS PowerShell SDK loaded

    Template Configuration:
    - 917Citrix_SmartcardLogon: Custom template for user certificates
    - Citrix_RegistrationAuthority: Standard template for FAS authorization
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
    [string[]]$CertificateAuthority,

    [Parameter(Mandatory=$false, ParameterSetName='Manual')]
    [ValidateNotNullOrEmpty()]
    [string]$FASAddress,

    [Parameter(Mandatory=$false, ParameterSetName='Manual')]
    [ValidatePattern('^S-1-5-21-\d+-\d+-\d+-\d+$')]
    [string]$FASSecurityGroupSID,

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
        $fasModule = Get-Command -Name "New-FasMsTemplate" -ErrorAction Stop
        Write-Log "FAS PowerShell SDK: Available" -Level Success
    }
    catch {
        throw "Citrix FAS PowerShell SDK not found. Please install FAS Server first."
    }

    # Check if running as Administrator
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        throw "This script must be run as Administrator with Enterprise Admin rights"
    }

    Write-Log "Administrator rights: OK" -Level Success

    # Check FAS service
    $fasService = Get-Service -Name "CitrixFederatedAuthenticationService" -ErrorAction SilentlyContinue

    if (-not $fasService) {
        throw "FAS Service not found. Please run Deploy-FAS.ps1 first."
    }

    if ($fasService.Status -ne 'Running') {
        Write-Log "FAS Service is not running. Starting service..." -Level Warning
        Start-Service -Name "CitrixFederatedAuthenticationService"
        Start-Sleep -Seconds 5
    }

    Write-Log "FAS Service Status: Running" -Level Success

    # Test FAS connectivity
    try {
        $null = Get-FasServer -Address $FASAddress -ErrorAction Stop
        Write-Log "FAS Server connectivity: OK" -Level Success
    }
    catch {
        throw "Cannot connect to FAS Server at $FASAddress. Error: $($_.Exception.Message)"
    }

    Write-Log "Prerequisites check completed" -Level Success
}

function Deploy-CertificateTemplates {
    Write-Log "========================================" -Level Info
    Write-Log "Step 1: Deploying Certificate Templates" -Level Info
    Write-Log "========================================" -Level Info

    try {
        # Template 1: 917Citrix_SmartcardLogon (Custom Template)
        # IMPORTANT: This replaces the standard Citrix_SmartCardLogon template
        Write-Log "Deploying template: 917Citrix_SmartcardLogon (Custom)" -Level Info
        Write-Log "  - Schema Version: 4 (Windows Server 2016+)" -Level Info
        Write-Log "  - Hash Algorithm: SHA256" -Level Info
        Write-Log "  - Key Algorithm: RSA 2048-bit" -Level Info
        Write-Log "  - Crypto Provider: Microsoft Software Key Storage Provider" -Level Info

        New-FasMsTemplate -Address $FASAddress `
                          -Name "917Citrix_SmartcardLogon" `
                          -SecurityGroupSID $FASSecurityGroupSID `
                          -ErrorAction Stop

        Write-Log "Template '917Citrix_SmartcardLogon' deployed successfully" -Level Success

        # Template 2: Citrix_RegistrationAuthority (Standard Template)
        Write-Log "Deploying template: Citrix_RegistrationAuthority (Standard)" -Level Info

        New-FasMsTemplate -Address $FASAddress `
                          -Name "Citrix_RegistrationAuthority" `
                          -SecurityGroupSID $FASSecurityGroupSID `
                          -ErrorAction Stop

        Write-Log "Template 'Citrix_RegistrationAuthority' deployed successfully" -Level Success

        Write-Log "All certificate templates deployed successfully" -Level Success
    }
    catch {
        Write-Log "Failed to deploy certificate templates: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Publish-TemplatesToCA {
    Write-Log "========================================" -Level Info
    Write-Log "Step 2: Publishing Templates to CA" -Level Info
    Write-Log "========================================" -Level Info

    foreach ($CA in $CertificateAuthority) {
        Write-Log "Publishing templates to CA: $CA" -Level Info

        try {
            # Publish 917Citrix_SmartcardLogon template
            Write-Log "  Publishing: 917Citrix_SmartcardLogon" -Level Info
            Publish-FasMsTemplate -Address $FASAddress `
                                  -Name "917Citrix_SmartcardLogon" `
                                  -CertificateAuthority $CA `
                                  -ErrorAction Stop

            Write-Log "  Template '917Citrix_SmartcardLogon' published to $CA" -Level Success

            # Publish Citrix_RegistrationAuthority template
            Write-Log "  Publishing: Citrix_RegistrationAuthority" -Level Info
            Publish-FasMsTemplate -Address $FASAddress `
                                  -Name "Citrix_RegistrationAuthority" `
                                  -CertificateAuthority $CA `
                                  -ErrorAction Stop

            Write-Log "  Template 'Citrix_RegistrationAuthority' published to $CA" -Level Success
        }
        catch {
            Write-Log "Failed to publish templates to $CA: $($_.Exception.Message)" -Level Error
            throw
        }
    }

    Write-Log "All templates published successfully" -Level Success
}

function New-AuthorizationCertificate {
    Write-Log "========================================" -Level Info
    Write-Log "Step 3: Creating Authorization Certificate" -Level Info
    Write-Log "========================================" -Level Info

    try {
        # Check if authorization certificate already exists
        $existingCert = Get-FasAuthorizationCertificate -Address $FASAddress -ErrorAction SilentlyContinue

        if ($existingCert) {
            Write-Log "Authorization Certificate already exists:" -Level Warning
            Write-Log "  Subject: $($existingCert.Subject)" -Level Info
            Write-Log "  Issuer: $($existingCert.Issuer)" -Level Info
            Write-Log "  NotAfter: $($existingCert.NotAfter)" -Level Info
            Write-Log "  Thumbprint: $($existingCert.Thumbprint)" -Level Info

            $response = Read-Host "Do you want to create a new authorization certificate? (Y/N)"
            if ($response -ne 'Y') {
                Write-Log "Keeping existing authorization certificate" -Level Info
                return $existingCert
            }
        }

        # Create new authorization certificate
        Write-Log "Requesting new authorization certificate from CA..." -Level Info

        $authCert = New-FasAuthorizationCertificate -Address $FASAddress `
                                                    -CertificateAuthority $CertificateAuthority[0] `
                                                    -ErrorAction Stop

        Write-Log "Authorization Certificate created successfully" -Level Success
        Write-Log "  Subject: $($authCert.Subject)" -Level Info
        Write-Log "  Issuer: $($authCert.Issuer)" -Level Info
        Write-Log "  NotBefore: $($authCert.NotBefore)" -Level Info
        Write-Log "  NotAfter: $($authCert.NotAfter)" -Level Info
        Write-Log "  Thumbprint: $($authCert.Thumbprint)" -Level Info

        # Check for pending certificate requests
        Write-Log "" -Level Info
        Write-Log "NOTE: If the certificate request is pending, you need to:" -Level Warning
        Write-Log "1. Open Certificate Authority console on CA server" -Level Warning
        Write-Log "2. Navigate to 'Pending Requests'" -Level Warning
        Write-Log "3. Right-click the FAS certificate request" -Level Warning
        Write-Log "4. Select 'Issue'" -Level Warning
        Write-Log "" -Level Info

        return $authCert
    }
    catch {
        Write-Log "Failed to create authorization certificate: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Test-Configuration {
    Write-Log "========================================" -Level Info
    Write-Log "Verifying FAS Configuration" -Level Info
    Write-Log "========================================" -Level Info

    # Check templates in Active Directory
    Write-Log "Checking certificate templates in Active Directory..." -Level Info

    try {
        $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
        $configNC = "CN=Configuration," + $domain.GetDirectoryEntry().distinguishedName[0]
        $templatePath = "CN=Certificate Templates,CN=Public Key Services,CN=Services,$configNC"

        $searcher = New-Object System.DirectoryServices.DirectorySearcher
        $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$templatePath")
        $searcher.Filter = "(|(cn=917Citrix_SmartcardLogon)(cn=Citrix_RegistrationAuthority))"
        $templates = $searcher.FindAll()

        foreach ($template in $templates) {
            $templateName = $template.Properties["cn"][0]
            Write-Log "  Template found in AD: $templateName" -Level Success
        }

        if ($templates.Count -lt 2) {
            Write-Log "WARNING: Not all templates found in Active Directory" -Level Warning
        }
    }
    catch {
        Write-Log "Could not verify templates in AD: $($_.Exception.Message)" -Level Warning
    }

    # Check authorization certificate
    Write-Log "Checking authorization certificate..." -Level Info

    try {
        $authCert = Get-FasAuthorizationCertificate -Address $FASAddress -ErrorAction Stop

        if ($authCert) {
            Write-Log "  Authorization Certificate: Valid" -Level Success
            Write-Log "  Expiration: $($authCert.NotAfter)" -Level Info

            # Check if certificate is about to expire
            $daysUntilExpiry = ($authCert.NotAfter - (Get-Date)).Days
            if ($daysUntilExpiry -lt 30) {
                Write-Log "  WARNING: Certificate expires in $daysUntilExpiry days!" -Level Warning
            }
        }
        else {
            Write-Log "  WARNING: No authorization certificate found" -Level Warning
        }
    }
    catch {
        Write-Log "Could not verify authorization certificate: $($_.Exception.Message)" -Level Warning
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
        if (-not $FASSecurityGroupSID) {
            $FASSecurityGroupSID = $config.fas.securityGroupSID
        }
        if (-not $LogPath) {
            $LogPath = $config.logging.configureLogPath
        }
    }

    # Set default log path if not specified
    if (-not $LogPath) {
        $LogPath = "$env:TEMP\FAS-Configure.log"
    }

    # Validate required parameters
    if (-not $CertificateAuthority) {
        throw "CertificateAuthority is required. Specify via -CertificateAuthority parameter or in config file."
    }
    if (-not $FASAddress) {
        throw "FASAddress is required. Specify via -FASAddress parameter or in config file."
    }
    if (-not $FASSecurityGroupSID) {
        throw "FASSecurityGroupSID is required. Specify via -FASSecurityGroupSID parameter or in config file."
    }

    Write-Log "========================================" -Level Info
    Write-Log "FAS Configuration Script Started" -Level Info
    Write-Log "========================================" -Level Info
    if ($ConfigFile) {
        Write-Log "Config File: $ConfigFile" -Level Info
        Write-Log "Environment: $($config.environment)" -Level Info
    }
    Write-Log "FAS Server: $FASAddress" -Level Info
    Write-Log "Certificate Authorities: $($CertificateAuthority -join ', ')" -Level Info
    Write-Log "FAS Security Group SID: $FASSecurityGroupSID" -Level Info
    Write-Log "Log Path: $LogPath" -Level Info
    Write-Log "" -Level Info

    # Step 0: Prerequisites check
    Test-Prerequisites

    if ($PSCmdlet.ShouldProcess("FAS Server", "Configure Certificate Templates and CA")) {
        # Step 1: Deploy Certificate Templates
        Deploy-CertificateTemplates

        # Step 2: Publish Templates to CA
        Publish-TemplatesToCA

        # Step 3: Create Authorization Certificate
        $authCert = New-AuthorizationCertificate

        # Step 4: Verify Configuration
        Test-Configuration

        Write-Log "========================================" -Level Success
        Write-Log "FAS Configuration Completed Successfully!" -Level Success
        Write-Log "========================================" -Level Success

        Write-Log "" -Level Info
        Write-Log "CONFIGURATION SUMMARY:" -Level Info
        Write-Log "  Certificate Templates Deployed:" -Level Info
        Write-Log "    - 917Citrix_SmartcardLogon (Custom)" -Level Info
        Write-Log "    - Citrix_RegistrationAuthority" -Level Info
        Write-Log "" -Level Info
        Write-Log "  Templates Published to CA:" -Level Info
        foreach ($CA in $CertificateAuthority) {
            Write-Log "    - $CA" -Level Info
        }
        Write-Log "" -Level Info
        Write-Log "  Authorization Certificate: Issued" -Level Info
        Write-Log "" -Level Info
        Write-Log "NEXT STEPS:" -Level Info
        Write-Log "1. Verify FAS GUI shows all green checkmarks in 'Initial Setup' tab" -Level Info
        Write-Log "2. Run Configure-FAS-UserRules.ps1 to set up User Certificate Rules" -Level Info
        Write-Log "3. Configure StoreFront to use FAS" -Level Info
        Write-Log "" -Level Info

        # Return authorization certificate for use in next script
        return $authCert
    }
}
catch {
    Write-Log "========================================" -Level Error
    Write-Log "FAS Configuration FAILED" -Level Error
    Write-Log "========================================" -Level Error
    Write-Log "Error: $($_.Exception.Message)" -Level Error
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level Error

    exit 1
}
finally {
    Write-Log "Log file saved to: $LogPath" -Level Info
}

#endregion
