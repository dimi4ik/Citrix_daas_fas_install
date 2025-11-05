---
description: "FAS Backup und Disaster Recovery Procedures"
---

# FAS Backup & Recovery

Du bist ein Citrix FAS Backup-Experte. Erstelle umfassende Backup- und Recovery-Strategien.

## Backup-Strategie

### Backup-Komponenten

**Was muss gesichert werden:**
1. FAS Server Konfiguration
2. Certificate Templates
3. User Rules und Policies
4. FAS Database (falls SQL verwendet)
5. Certificates und Private Keys
6. PowerShell Skripte und Konfigurationsdateien

### Backup-Frequenz

**Empfohlener Backup Schedule:**
- **Full Backup:** Wöchentlich (Sonntag 02:00)
- **Differential Backup:** Täglich (02:00)
- **Configuration Backup:** Nach jeder Änderung
- **Log Backup:** Täglich (00:00)

## Backup Procedures

### 1. FAS Configuration Backup

```powershell
<#
.SYNOPSIS
    Erstellt vollständiges FAS Configuration Backup
#>

function Backup-FasConfiguration {
    [CmdletBinding()]
    param(
        [string]$BackupPath = "C:\Backup\FAS",
        [switch]$IncludeCertificates,
        [switch]$Compress
    )

    # Backup Timestamp
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupDir = Join-Path $BackupPath "FAS-Backup-$timestamp"

    Write-Host "=== FAS Configuration Backup ===" -ForegroundColor Cyan
    Write-Host "Backup Location: $backupDir`n"

    # Create Backup Directory
    New-Item -Path $backupDir -ItemType Directory -Force | Out-Null

    # 1. FAS Server Configuration
    Write-Host "1. Backing up FAS Server Configuration..." -ForegroundColor Yellow
    Import-Module Citrix.Authentication.FederatedAuthenticationService.V1

    try {
        $fasConfig = Get-FasServer
        $fasConfig | Export-Clixml -Path "$backupDir\FAS-Server-Config.xml"
        Write-Host "   ✅ FAS Server Configuration backed up" -ForegroundColor Green
    } catch {
        Write-Warning "   ❌ Failed to backup FAS Configuration: $($_.Exception.Message)"
    }

    # 2. FAS Rules
    Write-Host "2. Backing up FAS Rules..." -ForegroundColor Yellow
    try {
        $rules = Get-FasRule
        $rules | Export-Clixml -Path "$backupDir\FAS-Rules.xml"
        $rules | Export-Csv -Path "$backupDir\FAS-Rules.csv" -NoTypeInformation
        Write-Host "   ✅ $($rules.Count) Rules backed up" -ForegroundColor Green
    } catch {
        Write-Warning "   ❌ Failed to backup FAS Rules: $($_.Exception.Message)"
    }

    # 3. FAS Authorization Certificates
    Write-Host "3. Backing up Authorization Certificates..." -ForegroundColor Yellow
    try {
        $authCerts = Get-FasAuthorizationCertificate
        $authCerts | Export-Clixml -Path "$backupDir\FAS-AuthCerts.xml"
        Write-Host "   ✅ Authorization Certificates backed up" -ForegroundColor Green
    } catch {
        Write-Warning "   ❌ Failed to backup Auth Certificates: $($_.Exception.Message)"
    }

    # 4. Configuration Files
    Write-Host "4. Backing up Configuration Files..." -ForegroundColor Yellow
    $configPath = "C:\Program Files\Citrix\Federated Authentication Service"
    if (Test-Path $configPath) {
        Copy-Item -Path "$configPath\*.config" -Destination "$backupDir\ConfigFiles\" -Recurse -Force
        Write-Host "   ✅ Configuration Files backed up" -ForegroundColor Green
    }

    # 5. FAS Data
    Write-Host "5. Backing up FAS Data..." -ForegroundColor Yellow
    $dataPath = "C:\ProgramData\Citrix\FAS"
    if (Test-Path $dataPath) {
        Copy-Item -Path $dataPath -Destination "$backupDir\FAS-Data" -Recurse -Force -Exclude "Logs"
        Write-Host "   ✅ FAS Data backed up" -ForegroundColor Green
    }

    # 6. Certificates (Optional)
    if ($IncludeCertificates) {
        Write-Host "6. Backing up Certificates..." -ForegroundColor Yellow

        # Export FAS Service Certificate
        $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -match "FAS"}
        if ($cert) {
            $certPassword = ConvertTo-SecureString -String "BackupP@ssw0rd" -Force -AsPlainText
            Export-PfxCertificate -Cert $cert -FilePath "$backupDir\FAS-ServiceCert.pfx" -Password $certPassword | Out-Null
            Write-Host "   ✅ FAS Service Certificate backed up" -ForegroundColor Green
        }
    }

    # 7. PowerShell Scripts
    Write-Host "7. Backing up PowerShell Scripts..." -ForegroundColor Yellow
    if (Test-Path ".\scripts") {
        Copy-Item -Path ".\scripts\*.ps1" -Destination "$backupDir\Scripts\" -Force
        Write-Host "   ✅ PowerShell Scripts backed up" -ForegroundColor Green
    }

    # 8. Create Backup Manifest
    Write-Host "8. Creating Backup Manifest..." -ForegroundColor Yellow
    $manifest = @{
        BackupDate = Get-Date
        BackupVersion = "1.0"
        BackupType = "Full"
        FASServer = $env:COMPUTERNAME
        BackupItems = @(
            "FAS Server Configuration",
            "FAS Rules",
            "Authorization Certificates",
            "Configuration Files",
            "FAS Data",
            "PowerShell Scripts"
        )
        if ($IncludeCertificates) { "Service Certificates" }
    }

    $manifest | ConvertTo-Json | Out-File "$backupDir\MANIFEST.json"
    Write-Host "   ✅ Backup Manifest created" -ForegroundColor Green

    # 9. Compress Backup (Optional)
    if ($Compress) {
        Write-Host "9. Compressing Backup..." -ForegroundColor Yellow
        $zipPath = "$BackupPath\FAS-Backup-$timestamp.zip"
        Compress-Archive -Path $backupDir -DestinationPath $zipPath -CompressionLevel Optimal
        Write-Host "   ✅ Backup compressed to: $zipPath" -ForegroundColor Green

        # Remove uncompressed backup
        Remove-Item -Path $backupDir -Recurse -Force
    }

    Write-Host "`n=== Backup Complete ===" -ForegroundColor Green
    Write-Host "Backup Location: $(if($Compress){$zipPath}else{$backupDir})"

    return $(if($Compress){$zipPath}else{$backupDir})
}

# Execute Backup
Backup-FasConfiguration -IncludeCertificates -Compress
```

### 2. Certificate Authority Templates Backup

```powershell
<#
.SYNOPSIS
    Backup Certificate Templates von CA
#>

function Backup-CertificateTemplates {
    [CmdletBinding()]
    param(
        [string]$BackupPath = "C:\Backup\CA-Templates"
    )

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupDir = Join-Path $BackupPath "CA-Templates-$timestamp"
    New-Item -Path $backupDir -ItemType Directory -Force | Out-Null

    Write-Host "Backing up Certificate Templates..." -ForegroundColor Cyan

    # Export all templates
    $templates = certutil -template | Select-String "Template="

    foreach ($template in $templates) {
        $templateName = $template -replace "Template=", "" -replace '"', ''

        # Export template configuration
        certutil -v -template $templateName > "$backupDir\$templateName.txt"

        Write-Host "  ✅ Backed up template: $templateName" -ForegroundColor Green
    }

    Write-Host "`nTemplates backed up to: $backupDir" -ForegroundColor Green
}
```

### 3. Database Backup (SQL)

```powershell
<#
.SYNOPSIS
    Backup FAS SQL Database
#>

function Backup-FasDatabase {
    [CmdletBinding()]
    param(
        [string]$SqlServer = "sql-server.domain.local",
        [string]$Database = "CitrixFAS",
        [string]$BackupPath = "C:\Backup\Database"
    )

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupFile = "$BackupPath\FAS-Database-$timestamp.bak"

    Write-Host "Backing up FAS Database..." -ForegroundColor Cyan

    $query = @"
BACKUP DATABASE [$Database]
TO DISK = '$backupFile'
WITH FORMAT,
     MEDIANAME = 'FAS_Backup',
     NAME = 'Full Backup of FAS Database',
     COMPRESSION
"@

    try {
        Invoke-Sqlcmd -ServerInstance $SqlServer -Query $query -QueryTimeout 600
        Write-Host "✅ Database backed up to: $backupFile" -ForegroundColor Green
    } catch {
        Write-Warning "❌ Database Backup failed: $($_.Exception.Message)"
    }
}
```

## Restore Procedures

### 1. FAS Configuration Restore

```powershell
<#
.SYNOPSIS
    Restore FAS Configuration from Backup
#>

function Restore-FasConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BackupPath,

        [switch]$Force
    )

    Write-Host "=== FAS Configuration Restore ===" -ForegroundColor Cyan
    Write-Host "Restore Source: $BackupPath`n"

    # Verify Backup
    if (-not (Test-Path $BackupPath)) {
        Write-Error "Backup path not found: $BackupPath"
        return
    }

    # Extract if compressed
    if ($BackupPath -match "\.zip$") {
        Write-Host "Extracting backup..." -ForegroundColor Yellow
        $extractPath = $BackupPath -replace "\.zip$", ""
        Expand-Archive -Path $BackupPath -DestinationPath $extractPath -Force
        $BackupPath = $extractPath
    }

    # Verify Manifest
    $manifestPath = Join-Path $BackupPath "MANIFEST.json"
    if (Test-Path $manifestPath) {
        $manifest = Get-Content $manifestPath | ConvertFrom-Json
        Write-Host "Backup Date: $($manifest.BackupDate)" -ForegroundColor Cyan
        Write-Host "Backup Type: $($manifest.BackupType)" -ForegroundColor Cyan
    }

    # Confirmation
    if (-not $Force) {
        $confirm = Read-Host "This will overwrite current FAS configuration. Continue? (yes/no)"
        if ($confirm -ne "yes") {
            Write-Host "Restore cancelled." -ForegroundColor Yellow
            return
        }
    }

    # Stop FAS Service
    Write-Host "`n1. Stopping FAS Service..." -ForegroundColor Yellow
    Stop-Service -Name "CitrixFederatedAuthenticationService" -Force
    Write-Host "   ✅ FAS Service stopped" -ForegroundColor Green

    # Import Module
    Import-Module Citrix.Authentication.FederatedAuthenticationService.V1

    # Restore FAS Server Configuration
    Write-Host "2. Restoring FAS Server Configuration..." -ForegroundColor Yellow
    $configPath = Join-Path $BackupPath "FAS-Server-Config.xml"
    if (Test-Path $configPath) {
        $fasConfig = Import-Clixml -Path $configPath

        # Apply configuration
        Set-FasServer -Address $fasConfig.Address `
                      -CertificateAuthority $fasConfig.CertificateAuthority `
                      -Verbose

        Write-Host "   ✅ FAS Server Configuration restored" -ForegroundColor Green
    }

    # Restore FAS Rules
    Write-Host "3. Restoring FAS Rules..." -ForegroundColor Yellow
    $rulesPath = Join-Path $BackupPath "FAS-Rules.xml"
    if (Test-Path $rulesPath) {
        $rules = Import-Clixml -Path $rulesPath

        # Remove existing rules
        Get-FasRule | Remove-FasRule -Force

        # Import rules
        foreach ($rule in $rules) {
            New-FasRule -Name $rule.Name `
                        -Priority $rule.Priority `
                        -UserFilter $rule.UserFilter `
                        -CertificateTemplate $rule.CertificateTemplate `
                        -CertificateLifetime $rule.CertificateLifetime `
                        -Enabled $rule.Enabled
        }

        Write-Host "   ✅ $($rules.Count) Rules restored" -ForegroundColor Green
    }

    # Restore Configuration Files
    Write-Host "4. Restoring Configuration Files..." -ForegroundColor Yellow
    $configFilesPath = Join-Path $BackupPath "ConfigFiles"
    if (Test-Path $configFilesPath) {
        $destPath = "C:\Program Files\Citrix\Federated Authentication Service"
        Copy-Item -Path "$configFilesPath\*" -Destination $destPath -Recurse -Force
        Write-Host "   ✅ Configuration Files restored" -ForegroundColor Green
    }

    # Restore FAS Data
    Write-Host "5. Restoring FAS Data..." -ForegroundColor Yellow
    $dataPath = Join-Path $BackupPath "FAS-Data"
    if (Test-Path $dataPath) {
        $destPath = "C:\ProgramData\Citrix\FAS"
        Copy-Item -Path "$dataPath\*" -Destination $destPath -Recurse -Force
        Write-Host "   ✅ FAS Data restored" -ForegroundColor Green
    }

    # Restore Certificates
    Write-Host "6. Restoring Certificates..." -ForegroundColor Yellow
    $certPath = Join-Path $BackupPath "FAS-ServiceCert.pfx"
    if (Test-Path $certPath) {
        $certPassword = ConvertTo-SecureString -String "BackupP@ssw0rd" -Force -AsPlainText
        Import-PfxCertificate -FilePath $certPath -CertStoreLocation Cert:\LocalMachine\My -Password $certPassword | Out-Null
        Write-Host "   ✅ Service Certificate restored" -ForegroundColor Green
    }

    # Start FAS Service
    Write-Host "7. Starting FAS Service..." -ForegroundColor Yellow
    Start-Service -Name "CitrixFederatedAuthenticationService"

    # Wait for service to start
    Start-Sleep -Seconds 5

    $service = Get-Service -Name "CitrixFederatedAuthenticationService"
    if ($service.Status -eq "Running") {
        Write-Host "   ✅ FAS Service started" -ForegroundColor Green
    } else {
        Write-Warning "   ⚠️  FAS Service Status: $($service.Status)"
    }

    # Validate Restore
    Write-Host "`n8. Validating Restore..." -ForegroundColor Yellow
    try {
        $fasServer = Get-FasServer
        Write-Host "   ✅ FAS Server responding" -ForegroundColor Green

        $ruleCount = (Get-FasRule).Count
        Write-Host "   ✅ Rules restored: $ruleCount" -ForegroundColor Green

        Write-Host "`n=== Restore Complete ===" -ForegroundColor Green
    } catch {
        Write-Warning "   ⚠️  Validation warnings: $($_.Exception.Message)"
    }
}

# Execute Restore
# Restore-FasConfiguration -BackupPath "C:\Backup\FAS\FAS-Backup-20250105-020000.zip"
```

### 2. Disaster Recovery Procedure

```powershell
<#
.SYNOPSIS
    Complete Disaster Recovery für FAS Server
#>

function Invoke-FasDisasterRecovery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BackupPath,

        [switch]$NewServer,
        [string]$NewServerName
    )

    Write-Host "=== FAS Disaster Recovery ===" -ForegroundColor Red
    Write-Host "WARNING: This will perform a complete FAS restore`n" -ForegroundColor Yellow

    # Confirmation
    $confirm = Read-Host "Type 'RESTORE' to continue"
    if ($confirm -ne "RESTORE") {
        Write-Host "Recovery cancelled." -ForegroundColor Yellow
        return
    }

    # 1. Install FAS (if new server)
    if ($NewServer) {
        Write-Host "`n1. Installing FAS..." -ForegroundColor Yellow
        # Run FAS Installation
        .\scripts\Deploy-FAS.ps1
    }

    # 2. Restore Configuration
    Write-Host "`n2. Restoring Configuration..." -ForegroundColor Yellow
    Restore-FasConfiguration -BackupPath $BackupPath -Force

    # 3. Restore Database (if SQL)
    Write-Host "`n3. Restoring Database..." -ForegroundColor Yellow
    # Restore-FasDatabase -BackupFile "$BackupPath\FAS-Database.bak"

    # 4. Restore Certificate Templates
    Write-Host "`n4. Restoring Certificate Templates..." -ForegroundColor Yellow
    # Manual step - Import templates on CA

    # 5. Validate Recovery
    Write-Host "`n5. Validating Recovery..." -ForegroundColor Yellow

    $validationTests = @{
        "FAS Service Running" = (Get-Service "CitrixFederatedAuthenticationService").Status -eq "Running"
        "FAS Configuration Present" = $null -ne (Get-FasServer)
        "FAS Rules Present" = (Get-FasRule).Count -gt 0
        "CA Connectivity" = (certutil -ping) -match "Ping"
    }

    foreach ($test in $validationTests.GetEnumerator()) {
        $status = if ($test.Value) { "✅" } else { "❌" }
        Write-Host "  $status $($test.Key)"
    }

    # 6. Test Certificate Issuance
    Write-Host "`n6. Testing Certificate Issuance..." -ForegroundColor Yellow
    try {
        $testCert = New-FasUserCertificate -UserPrincipalName "testuser@domain.local" -ErrorAction Stop
        Write-Host "  ✅ Certificate Issuance: Success" -ForegroundColor Green
    } catch {
        Write-Warning "  ❌ Certificate Issuance: Failed"
    }

    Write-Host "`n=== Disaster Recovery Complete ===" -ForegroundColor Green
    Write-Host "Please validate all functionality before putting server into production."
}
```

## Automated Backup Schedule

```powershell
<#
.SYNOPSIS
    Schedule automated FAS backups
#>

function Set-FasBackupSchedule {
    [CmdletBinding()]
    param(
        [string]$BackupPath = "C:\Backup\FAS",
        [string]$Time = "02:00"
    )

    # Create Scheduled Task
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File `"C:\Scripts\Backup-FAS.ps1`""

    $trigger = New-ScheduledTaskTrigger -Daily -At $Time

    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RunOnlyIfNetworkAvailable

    Register-ScheduledTask -TaskName "FAS Daily Backup" `
                           -Action $action `
                           -Trigger $trigger `
                           -Principal $principal `
                           -Settings $settings `
                           -Description "Daily backup of Citrix FAS configuration"

    Write-Host "✅ Backup schedule configured: Daily at $Time" -ForegroundColor Green
}
```

## Backup Best Practices

1. **3-2-1 Rule:**
   - 3 Copies of data
   - 2 Different media types
   - 1 Off-site copy

2. **Retention Policy:**
   - Daily Backups: 7 Tage
   - Weekly Backups: 4 Wochen
   - Monthly Backups: 12 Monate
   - Yearly Backups: 7 Jahre (Compliance)

3. **Encryption:**
   - Verschlüssele Backups mit BitLocker oder AES-256
   - Sichere Passwort-Management

4. **Testing:**
   - Teste Restore monatlich
   - Dokumentiere Restore-Zeit (RTO)
   - Validiere Backup-Integrität

5. **Monitoring:**
   - Alert bei Backup-Failures
   - Überprüfe Backup-Size Trends
   - Monitor Backup Storage Capacity

## Backup Checklist

- [ ] FAS Configuration Backup konfiguriert
- [ ] Certificate Templates Backup erstellt
- [ ] Database Backup konfiguriert (falls SQL)
- [ ] Scheduled Task für automatische Backups
- [ ] Off-site Backup Replikation konfiguriert
- [ ] Restore Procedure getestet
- [ ] Disaster Recovery Plan dokumentiert
- [ ] Backup Monitoring aktiviert
- [ ] Retention Policy implementiert
- [ ] Backup Encryption aktiviert
