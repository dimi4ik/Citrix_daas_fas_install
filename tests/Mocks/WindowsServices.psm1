<#
.SYNOPSIS
    Mock module for Windows Services

.DESCRIPTION
    Provides mock implementations of Windows Service cmdlets for testing
    FAS deployment scripts without requiring actual Windows services.

.NOTES
    Version: 1.0.0
    Purpose: Isolated PowerShell testing without backend dependencies
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#region Mock Data Storage

$script:MockServices = @{}

#endregion

#region Service Management

function Initialize-MockService {
    <#
    .SYNOPSIS
        Initializes a mock Windows service
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$false)]
        [string]$DisplayName = $Name,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Running', 'Stopped', 'Paused')]
        [string]$Status = 'Stopped',

        [Parameter(Mandatory=$false)]
        [ValidateSet('Automatic', 'Manual', 'Disabled')]
        [string]$StartType = 'Manual'
    )

    $mockService = [PSCustomObject]@{
        Name = $Name
        DisplayName = $DisplayName
        Status = $Status
        StartType = $StartType
        ServiceType = 'Win32OwnProcess'
        CanStop = $true
        CanPauseAndContinue = $false
        DependentServices = @()
        ServicesDependedOn = @()
    }

    # Add Refresh method
    $mockService | Add-Member -MemberType ScriptMethod -Name 'Refresh' -Value {
        $currentService = $script:MockServices[$this.Name]
        if ($currentService) {
            $this.Status = $currentService.Status
            $this.StartType = $currentService.StartType
        }
    }

    $script:MockServices[$Name] = $mockService
    return $mockService
}

function Get-Service {
    <#
    .SYNOPSIS
        Mock implementation of Get-Service
    .NOTES
        No [CmdletBinding()] to avoid Common Parameter conflict with explicit ErrorAction
    #>
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name,

        [Parameter(Mandatory=$false)]
        [ValidateSet('SilentlyContinue', 'Continue', 'Stop', 'Inquire', 'Ignore')]
        [string]$ErrorAction = 'Continue'
    )

    if ($script:MockServices.ContainsKey($Name)) {
        return $script:MockServices[$Name]
    }

    # Simulate service not found
    # Check if ErrorAction was set to SilentlyContinue
    if ($ErrorAction -eq 'SilentlyContinue') {
        return $null
    }

    throw "Cannot find any service with service name '$Name'."
}

function Start-Service {
    <#
    .SYNOPSIS
        Mock implementation of Start-Service
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name
    )

    if (-not $script:MockServices.ContainsKey($Name)) {
        throw "Service '$Name' not found"
    }

    $service = $script:MockServices[$Name]

    if ($service.Status -eq 'Running') {
        Write-Warning "Service '$Name' is already running"
        return
    }

    Write-Verbose "Mock: Starting service '$Name'"
    $service.Status = 'Running'
}

function Stop-Service {
    <#
    .SYNOPSIS
        Mock implementation of Stop-Service
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name,

        [Parameter(Mandatory=$false)]
        [switch]$Force
    )

    if (-not $script:MockServices.ContainsKey($Name)) {
        throw "Service '$Name' not found"
    }

    $service = $script:MockServices[$Name]

    if ($service.Status -eq 'Stopped') {
        Write-Warning "Service '$Name' is already stopped"
        return
    }

    if (-not $service.CanStop -and -not $Force) {
        throw "Service '$Name' cannot be stopped"
    }

    Write-Verbose "Mock: Stopping service '$Name'"
    $service.Status = 'Stopped'
}

function Restart-Service {
    <#
    .SYNOPSIS
        Mock implementation of Restart-Service
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name,

        [Parameter(Mandatory=$false)]
        [switch]$Force
    )

    Write-Verbose "Mock: Restarting service '$Name'"
    Stop-Service -Name $Name -Force:$Force
    Start-Service -Name $Name
}

function Set-Service {
    <#
    .SYNOPSIS
        Mock implementation of Set-Service
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Automatic', 'Manual', 'Disabled')]
        [string]$StartupType,

        [Parameter(Mandatory=$false)]
        [string]$DisplayName,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Running', 'Stopped')]
        [string]$Status
    )

    if (-not $script:MockServices.ContainsKey($Name)) {
        throw "Service '$Name' not found"
    }

    $service = $script:MockServices[$Name]

    if ($StartupType) {
        Write-Verbose "Mock: Setting service '$Name' startup type to '$StartupType'"
        $service.StartType = $StartupType
    }

    if ($DisplayName) {
        Write-Verbose "Mock: Setting service '$Name' display name to '$DisplayName'"
        $service.DisplayName = $DisplayName
    }

    if ($Status) {
        Write-Verbose "Mock: Setting service '$Name' status to '$Status'"
        $service.Status = $Status
    }
}

#endregion

#region Registry Mocks

$script:MockRegistry = @{}

function Get-ItemProperty {
    <#
    .SYNOPSIS
        Mock implementation of Get-ItemProperty for registry queries
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path
    )

    # Handle wildcard paths for software enumeration
    if ($Path -like "*Uninstall\*") {
        return Get-MockInstalledSoftware
    }

    if ($script:MockRegistry.ContainsKey($Path)) {
        return $script:MockRegistry[$Path]
    }

    # Check if ErrorAction common parameter was passed with SilentlyContinue
    if ($PSBoundParameters.ContainsKey('ErrorAction') -and $ErrorAction -eq 'SilentlyContinue') {
        return $null
    }

    throw "Cannot find path '$Path' because it does not exist."
}

function Set-MockRegistryKey {
    <#
    .SYNOPSIS
        Sets a mock registry key for testing
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [hashtable]$Properties
    )

    $mockObject = [PSCustomObject]$Properties
    $script:MockRegistry[$Path] = $mockObject
}

function Get-MockInstalledSoftware {
    <#
    .SYNOPSIS
        Returns mock installed software list
    #>
    [CmdletBinding()]
    param()

    $installedSoftware = $script:MockRegistry.GetEnumerator() |
        Where-Object { $_.Key -like "*Uninstall*" } |
        ForEach-Object { $_.Value }

    return $installedSoftware
}

function Add-MockInstalledSoftware {
    <#
    .SYNOPSIS
        Adds mock installed software to registry
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$DisplayName,

        [Parameter(Mandatory=$true)]
        [string]$DisplayVersion,

        [Parameter(Mandatory=$false)]
        [string]$Publisher = "Citrix Systems, Inc.",

        [Parameter(Mandatory=$false)]
        [string]$InstallLocation = "C:\Program Files\Citrix\Federated Authentication Service"
    )

    $guid = [guid]::NewGuid().ToString()
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$guid"

    Set-MockRegistryKey -Path $regPath -Properties @{
        DisplayName = $DisplayName
        DisplayVersion = $DisplayVersion
        Publisher = $Publisher
        InstallLocation = $InstallLocation
        UninstallString = "msiexec.exe /x $guid"
        InstallDate = (Get-Date -Format "yyyyMMdd")
    }
}

#endregion

#region MSI Installation Mock

$script:MockMSIResults = @{}

function Start-Process {
    <#
    .SYNOPSIS
        Mock implementation of Start-Process for MSI installations
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$false)]
        [string[]]$ArgumentList,

        [Parameter(Mandatory=$false)]
        [switch]$Wait,

        [Parameter(Mandatory=$false)]
        [switch]$PassThru,

        [Parameter(Mandatory=$false)]
        [switch]$NoNewWindow
    )

    Write-Verbose "Mock: Start-Process called with FilePath: $FilePath"
    Write-Verbose "Mock: Arguments: $($ArgumentList -join ' ')"

    # Simulate MSI installation
    if ($FilePath -like "*msiexec*") {
        $exitCode = 0

        # Check for predefined exit code
        $msiPath = ($ArgumentList | Where-Object { $_ -like "*.msi*" }) -replace '"', ''
        if ($script:MockMSIResults.ContainsKey($msiPath)) {
            $exitCode = $script:MockMSIResults[$msiPath]
        }

        $process = [PSCustomObject]@{
            ExitCode = $exitCode
            HasExited = $true
            ProcessName = "msiexec"
        }

        if ($PassThru) {
            return $process
        }
    }

    # Default process mock
    return [PSCustomObject]@{
        ExitCode = 0
        HasExited = $true
    }
}

function Set-MockMSIExitCode {
    <#
    .SYNOPSIS
        Sets the exit code for a specific MSI installation
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$MSIPath,

        [Parameter(Mandatory=$true)]
        [int]$ExitCode
    )

    $script:MockMSIResults[$MSIPath] = $ExitCode
    Write-Verbose "Mock: MSI exit code for '$MSIPath' set to $ExitCode"
}

#endregion

#region Mock Reset

function Reset-WindowsServicesMockData {
    <#
    .SYNOPSIS
        Resets all mock data to initial state
    #>
    [CmdletBinding()]
    param()

    $script:MockServices = @{}
    $script:MockRegistry = @{}
    $script:MockMSIResults = @{}

    Write-Verbose "Mock: All Windows Services mock data reset"
}

#endregion

# Export all functions
Export-ModuleMember -Function @(
    'Initialize-MockService',
    'Get-Service',
    'Start-Service',
    'Stop-Service',
    'Restart-Service',
    'Set-Service',
    'Get-ItemProperty',
    'Set-MockRegistryKey',
    'Add-MockInstalledSoftware',
    'Start-Process',
    'Set-MockMSIExitCode',
    'Reset-WindowsServicesMockData'
)
