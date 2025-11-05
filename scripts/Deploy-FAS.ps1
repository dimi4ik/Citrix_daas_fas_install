<#
.SYNOPSIS
    Citrix Federated Authentication Service (FAS) Installation Script

.DESCRIPTION
    This script automates the installation of Citrix FAS Server using the MSI installer.
    It performs the following tasks:
    - Validates prerequisites
    - Installs FAS Server binaries
    - Verifies successful installation
    - Creates event log entries

.PARAMETER ConfigFile
    Path to JSON configuration file. When specified, parameters are loaded from config file.
    Example: ".\config\dev.json"

.PARAMETER FASMSIPath
    Full path to the FAS MSI installer file.
    Example: "D:\x64\Federated Authentication Service\FederatedAuthenticationService_x64.msi"
    Optional when ConfigFile is specified.

.PARAMETER LogPath
    Optional path for log file. Default: "$env:TEMP\FAS-Deploy.log"
    Can be overridden from config file.

.EXAMPLE
    # Using config file
    .\Deploy-FAS.ps1 -ConfigFile ".\config\dev.json"

.EXAMPLE
    # Using explicit parameters (legacy mode)
    .\Deploy-FAS.ps1 -FASMSIPath "D:\x64\Federated Authentication Service\FederatedAuthenticationService_x64.msi"

.NOTES
    Author: FAS Automation Team
    Version: 1.0.0
    Date: 2025-11-05

    Requirements:
    - Local Administrator rights
    - Windows Server 2016 or newer
    - Active Directory Domain environment

    WARNING: Firewall rules are NOT automatically configured by this script.
    Manual firewall configuration required after installation.
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
    [ValidateScript({
        if (-not (Test-Path $_)) {
            throw "FAS MSI file not found at path: $_"
        }
        if ($_ -notmatch '\.msi$') {
            throw "File must be an MSI installer: $_"
        }
        return $true
    })]
    [string]$FASMSIPath,

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

    # Check if running as Administrator
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        throw "This script must be run as Administrator"
    }

    Write-Log "Administrator rights: OK" -Level Success

    # Check if already installed
    $fasInstalled = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" |
        Where-Object { $_.DisplayName -like "*Citrix*Federated*Authentication*" }

    if ($fasInstalled) {
        Write-Log "FAS is already installed: $($fasInstalled.DisplayName) v$($fasInstalled.DisplayVersion)" -Level Warning
        $response = Read-Host "Do you want to continue with reinstall/upgrade? (Y/N)"
        if ($response -ne 'Y') {
            throw "Installation cancelled by user"
        }
    }

    # Check Windows version
    $osVersion = [System.Environment]::OSVersion.Version
    if ($osVersion.Major -lt 10 -and $osVersion.Build -lt 14393) {
        Write-Log "Windows Server 2016 or newer is required" -Level Warning
    }

    Write-Log "Prerequisites check completed" -Level Success
}

function Install-FAS {
    param([string]$MSIPath)

    Write-Log "Starting FAS installation from: $MSIPath" -Level Info

    try {
        # Prepare MSI installation arguments
        $msiArguments = @(
            "/i"
            "`"$MSIPath`""
            "/qn"                    # Quiet mode, no user interaction
            "/norestart"             # Do not restart after installation
            "/l*v"                   # Verbose logging
            "`"$LogPath.msi.log`""   # MSI log file
        )

        Write-Log "MSI Arguments: $($msiArguments -join ' ')" -Level Info

        # Start installation process
        $process = Start-Process -FilePath "msiexec.exe" `
                                 -ArgumentList $msiArguments `
                                 -Wait `
                                 -PassThru `
                                 -NoNewWindow

        Write-Log "Installation process completed with exit code: $($process.ExitCode)" -Level Info

        # Check exit code
        switch ($process.ExitCode) {
            0 {
                Write-Log "FAS installation completed successfully" -Level Success
                return $true
            }
            3010 {
                Write-Log "FAS installation completed successfully (restart required)" -Level Warning
                return $true
            }
            1603 {
                throw "Installation failed with error 1603 (Fatal error during installation)"
            }
            1618 {
                throw "Installation failed with error 1618 (Another installation is in progress)"
            }
            default {
                throw "Installation failed with exit code: $($process.ExitCode)"
            }
        }
    }
    catch {
        Write-Log "Installation failed: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Test-Installation {
    Write-Log "Verifying FAS installation..." -Level Info

    # Check if FAS service exists
    $fasService = Get-Service -Name "CitrixFederatedAuthenticationService" -ErrorAction SilentlyContinue

    if ($fasService) {
        Write-Log "FAS Service found: $($fasService.DisplayName)" -Level Success
        Write-Log "Service Status: $($fasService.Status)" -Level Info

        if ($fasService.Status -ne 'Running') {
            Write-Log "Starting FAS service..." -Level Info
            Start-Service -Name "CitrixFederatedAuthenticationService"
            Start-Sleep -Seconds 5
            $fasService.Refresh()
            Write-Log "Service Status: $($fasService.Status)" -Level Success
        }
    }
    else {
        throw "FAS Service not found after installation"
    }

    # Check installation in registry
    $fasInstalled = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" |
        Where-Object { $_.DisplayName -like "*Citrix*Federated*Authentication*" }

    if ($fasInstalled) {
        Write-Log "FAS installed: $($fasInstalled.DisplayName) v$($fasInstalled.DisplayVersion)" -Level Success
        Write-Log "Install Location: $($fasInstalled.InstallLocation)" -Level Info
    }

    # Check Event Viewer logs
    try {
        $eventLog = Get-WinEvent -LogName "Application" -MaxEvents 10 -ErrorAction SilentlyContinue |
            Where-Object { $_.ProviderName -like "*Citrix*" -or $_.Message -like "*FAS*" }

        if ($eventLog) {
            Write-Log "Recent FAS events found in Event Viewer" -Level Info
        }
    }
    catch {
        Write-Log "Could not check Event Viewer logs: $($_.Exception.Message)" -Level Warning
    }

    Write-Log "FAS installation verification completed successfully" -Level Success
}

#endregion

#region Main Script

try {
    # Load configuration from file if specified
    if ($PSCmdlet.ParameterSetName -eq 'ConfigFile') {
        Write-Verbose "Using configuration file mode"
        $config = Import-FASConfiguration -ConfigFilePath $ConfigFile

        # Extract parameters from config
        if (-not $FASMSIPath) {
            $FASMSIPath = $config.fas.msiPath
        }
        if (-not $LogPath) {
            $LogPath = $config.logging.deployLogPath
        }
    }

    # Set default log path if not specified
    if (-not $LogPath) {
        $LogPath = "$env:TEMP\FAS-Deploy.log"
    }

    # Validate required parameters
    if (-not $FASMSIPath) {
        throw "FASMSIPath is required. Specify via -FASMSIPath parameter or in config file."
    }

    Write-Log "========================================" -Level Info
    Write-Log "Citrix FAS Installation Script Started" -Level Info
    Write-Log "========================================" -Level Info
    if ($ConfigFile) {
        Write-Log "Config File: $ConfigFile" -Level Info
        Write-Log "Environment: $($config.environment)" -Level Info
    }
    Write-Log "MSI Path: $FASMSIPath" -Level Info
    Write-Log "Log Path: $LogPath" -Level Info

    # Step 1: Prerequisites check
    Test-Prerequisites

    # Step 2: Install FAS
    if ($PSCmdlet.ShouldProcess("FAS Server", "Install")) {
        $installSuccess = Install-FAS -MSIPath $FASMSIPath

        if ($installSuccess) {
            # Step 3: Verify installation
            Test-Installation

            Write-Log "========================================" -Level Success
            Write-Log "FAS Installation Completed Successfully!" -Level Success
            Write-Log "========================================" -Level Success

            Write-Log "" -Level Info
            Write-Log "NEXT STEPS:" -Level Info
            Write-Log "1. Configure Windows Firewall (Ports 80/443)" -Level Info
            Write-Log "2. Run Configure-FAS.ps1 to set up Certificate Templates and CA" -Level Info
            Write-Log "3. Run Configure-FAS-UserRules.ps1 to configure User Rules" -Level Info
            Write-Log "" -Level Info
            Write-Log "IMPORTANT: Firewall rules are NOT automatically configured!" -Level Warning
            Write-Log "See: https://docs.citrix.com/en-us/federated-authentication-service/install-configure.html#step-2-configure-windows-firewall" -Level Info
        }
    }
}
catch {
    Write-Log "========================================" -Level Error
    Write-Log "FAS Installation FAILED" -Level Error
    Write-Log "========================================" -Level Error
    Write-Log "Error: $($_.Exception.Message)" -Level Error
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level Error

    exit 1
}
finally {
    Write-Log "Log file saved to: $LogPath" -Level Info
}

#endregion
