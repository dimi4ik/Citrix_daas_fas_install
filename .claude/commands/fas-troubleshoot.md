---
description: "Umfassende Troubleshooting-Anleitung für Citrix FAS Installation und Betrieb"
---

# FAS Troubleshooting Guide

Du bist ein Citrix FAS Troubleshooting-Experte. Analysiere und löse FAS-bezogene Probleme systematisch.

## Troubleshooting Methodology

### SYSTEMATIC APPROACH:
1. **Symptom Identification** - Was ist das Problem?
2. **Log Analysis** - Sammle relevante Logs
3. **Root Cause Analysis** - Finde die Ursache
4. **Solution Implementation** - Behebe das Problem
5. **Validation** - Verifiziere die Lösung
6. **Documentation** - Dokumentiere die Lösung

## Common Issues und Solutions

### 1. Certificate Issuance Failures

#### Symptom: "Failed to request certificate from CA"

**Diagnostics:**
```powershell
# Check CA Connectivity
certutil -ping

# Check Certificate Template
certutil -v -template CitrixFAS_UserCert

# Check FAS Service Account Permissions
certutil -getUserRoles domain\FAS-SVC$

# Check FAS Logs
Get-Content "C:\ProgramData\Citrix\FAS\Logs\Citrix.Authentication.FederatedAuthenticationService.log" -Tail 50 | Select-String "Error|Exception"
```

**Common Causes:**
- ❌ CA nicht erreichbar
- ❌ Certificate Template nicht verfügbar
- ❌ Fehlende Permissions für Service Account
- ❌ Certificate Template falsch konfiguriert

**Solutions:**

**1. CA Connectivity:**
```powershell
# Test Network Path zu CA
Test-NetConnection -ComputerName ca-server.domain.local -Port 135

# Restart Certificate Services
Restart-Service -Name CertSvc

# Check CA Status
certutil -CAInfo
```

**2. Certificate Template Permissions:**
```powershell
# Grant Permissions für FAS Service Account
# Auf CA Server ausführen:
certutil -dsTemplate CitrixFAS_UserCert

# Manuell in Certificate Templates Console:
# 1. certtmpl.msc öffnen
# 2. CitrixFAS_UserCert → Properties → Security
# 3. Füge "domain\FAS-SVC$" hinzu
# 4. Grant: Read, Enroll
```

**3. Template Configuration Fix:**
```powershell
# Template muss folgende Settings haben:
# - Subject Name: Supplied in request
# - Private Key: Exportable
# - Purpose: Client Authentication
# - Validity: 8 hours (oder gewünschte Dauer)

# Prüfe Template Configuration:
certutil -v -template CitrixFAS_UserCert | Select-String "Subject|Private|Purpose|Validity"
```

#### Symptom: "Certificate request denied by policy module"

**Diagnostics:**
```powershell
# Check CA Audit Logs
Get-WinEvent -LogName "Security" -FilterXPath "*[System[EventID=4886 or EventID=4887]]" | Select-Object -First 10

# Check Certificate Services Log
Get-WinEvent -LogName "Application" -FilterXPath "*[System[Provider[@Name='Microsoft-Windows-CertificationAuthority']]]" -MaxEvents 20
```

**Solutions:**
- Prüfe CA Policy Module Settings
- Prüfe ob Request Subject Name rules verletzt
- Prüfe ob Approval erforderlich ist (sollte nicht sein)

### 2. FAS Service Won't Start

#### Symptom: FAS Service startet nicht oder stoppt sofort

**Diagnostics:**
```powershell
# Check Service Status
Get-Service -Name "CitrixFederatedAuthenticationService" | Format-List *

# Check Service Dependencies
Get-Service -Name "CitrixFederatedAuthenticationService" -RequiredServices

# Check Event Log
Get-WinEvent -LogName "Application" -FilterXPath "*[System[Provider[@Name='Citrix FAS']]]" -MaxEvents 20
```

**Common Causes:**
- ❌ Database Connection Fehler
- ❌ Service Account Permissions
- ❌ Port Konflikt (443 bereits in Verwendung)
- ❌ Corrupt Configuration

**Solutions:**

**1. Database Connection:**
```powershell
# Check FAS Database Connection
$config = Get-Content "C:\Program Files\Citrix\Federated Authentication Service\Citrix.Authentication.FederatedAuthenticationService.exe.config"

# Test SQL Connection (falls SQL verwendet)
$connectionString = "Server=sql-server;Database=FAS;Integrated Security=True;"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
try {
    $connection.Open()
    Write-Host "✅ Database Connection: OK" -ForegroundColor Green
    $connection.Close()
} catch {
    Write-Warning "❌ Database Connection Failed: $($_.Exception.Message)"
}
```

**2. Port Conflict:**
```powershell
# Check if Port 443 is in use
Get-NetTCPConnection -LocalPort 443 -State Listen

# If conflict, change FAS Port or stop conflicting service
```

**3. Reset FAS Configuration:**
```powershell
# Backup current configuration
Copy-Item "C:\ProgramData\Citrix\FAS\Configuration" "C:\Backup\FAS-Config-$(Get-Date -Format 'yyyyMMdd')" -Recurse

# Reset to default
Stop-Service -Name "CitrixFederatedAuthenticationService"
Remove-Item "C:\ProgramData\Citrix\FAS\Configuration\*" -Force
Start-Service -Name "CitrixFederatedAuthenticationService"

# Reconfigure FAS
.\scripts\Configure-FAS.ps1
```

### 3. User Authentication Failures

#### Symptom: User kann sich nicht mit FAS authentifizieren

**Diagnostics:**
```powershell
# Test User Certificate Issuance
$testUser = "problemuser@domain.local"
try {
    $cert = New-FasUserCertificate -UserPrincipalName $testUser -Verbose
    Write-Host "✅ Certificate Issuance: OK" -ForegroundColor Green
} catch {
    Write-Warning "❌ Certificate Issuance Failed: $($_.Exception.Message)"
}

# Check User Rule Evaluation
Test-FasRuleEvaluation -UserPrincipalName $testUser -Verbose

# Check User AD Account
Get-ADUser -Identity $testUser -Properties * | Select-Object Enabled, LockedOut, AccountExpirationDate, userCertificate
```

**Common Causes:**
- ❌ User Account disabled oder locked
- ❌ Keine passende FAS Rule
- ❌ Certificate Template Permissions fehlen
- ❌ StoreFront Misconfiguration

**Solutions:**

**1. User Account Issues:**
```powershell
# Enable User
Enable-ADAccount -Identity $testUser

# Unlock User
Unlock-ADAccount -Identity $testUser

# Check Password Expiration
Get-ADUser -Identity $testUser -Properties PasswordExpired, PasswordNeverExpires
```

**2. FAS Rule Issues:**
```powershell
# Check if any rule matches
$rules = Get-FasRule
$userGroups = (Get-ADUser -Identity $testUser -Properties MemberOf).MemberOf

Write-Host "User Groups:" -ForegroundColor Cyan
$userGroups | ForEach-Object { Write-Host "  $_" }

Write-Host "`nMatching Rules:" -ForegroundColor Cyan
foreach ($rule in $rules) {
    if ($rule.UserFilter -and $userGroups -match $rule.UserFilter) {
        Write-Host "  ✅ $($rule.Name) (Priority: $($rule.Priority))" -ForegroundColor Green
    }
}

# Create Rule if needed
New-FasRule -Name "TestUserRule" -UserFilter $testUser -CertificateTemplate "CitrixFAS_UserCert" -Priority 50
```

### 4. StoreFront Integration Issues

#### Symptom: FAS Authentication in StoreFront funktioniert nicht

**Diagnostics:**
```powershell
# Check StoreFront FAS Configuration
# Auf StoreFront Server ausführen:

# Load StoreFront PowerShell Module
Add-PSSnapin Citrix.StoreFront.*

# Check Authentication Service
$authService = Get-STFAuthenticationService
$authService | Format-List *

# Check FAS Configuration
Get-STFAuthenticationServiceProtocol -AuthenticationService $authService
```

**Solutions:**

**1. Configure FAS in StoreFront:**
```powershell
# Enable Certificate Authentication
$authService = Get-STFAuthenticationService
Enable-STFAuthenticationServiceProtocol -AuthenticationService $authService -Name Certificate

# Configure FAS Server
Set-STFCertificateAuthority -AuthenticationService $authService -Authority "https://fas-server.domain.local" -Enabled $true
```

**2. Test StoreFront FAS Endpoint:**
```powershell
# Test FAS Endpoint
$fasUrl = "https://fas-server.domain.local/fas"
try {
    $response = Invoke-WebRequest -Uri $fasUrl -UseBasicParsing
    Write-Host "✅ FAS Endpoint erreichbar" -ForegroundColor Green
} catch {
    Write-Warning "❌ FAS Endpoint nicht erreichbar: $($_.Exception.Message)"
}
```

### 5. Performance Issues

#### Symptom: Langsame Certificate Issuance oder Authentication

**Diagnostics:**
```powershell
# Measure Certificate Issuance Time
Measure-Command {
    New-FasUserCertificate -UserPrincipalName "testuser@domain.local"
}

# Check FAS Server Resources
Get-Counter -Counter "\Processor(_Total)\% Processor Time", "\Memory\Available MBytes"

# Check CA Performance
Measure-Command { certutil -ping }
```

**Solutions:**

**1. Optimize FAS Configuration:**
```powershell
# Increase Certificate Cache
Set-FasCacheConfiguration -MaxCacheSize 10000 -CacheDuration (New-TimeSpan -Hours 4)

# Enable Connection Pooling
Set-FasConnectionPooling -Enabled $true -MaxConnections 100
```

**2. CA Performance Tuning:**
```powershell
# Auf CA Server ausführen:

# Increase CA Queue Length
certutil -setreg CA\CRLPublicationURLs "http://ca-server/CertEnroll/%3%8.crl"

# Optimize CA Database
certutil -f -repairstore my

# Restart Certificate Services
Restart-Service CertSvc
```

**3. Network Optimization:**
```powershell
# Check Network Latency between FAS and CA
Test-NetConnection -ComputerName ca-server.domain.local -TraceRoute

# Enable Network QoS für FAS Traffic
New-NetQosPolicy -Name "FAS-Priority" -IPProtocol TCP -IPDstPort 443 -ThrottleRateAction 10Gbps
```

## Advanced Troubleshooting

### Log Analysis

**FAS Service Logs:**
```powershell
# Parse FAS Logs für Errors
$logPath = "C:\ProgramData\Citrix\FAS\Logs\Citrix.Authentication.FederatedAuthenticationService.log"

# Get Errors from last hour
$lastHour = (Get-Date).AddHours(-1)
Get-Content $logPath | Select-String "ERROR|EXCEPTION" | ForEach-Object {
    if ($_ -match "\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}") {
        $timestamp = [datetime]::ParseExact($matches[0], "yyyy-MM-dd HH:mm:ss", $null)
        if ($timestamp -gt $lastHour) {
            Write-Host $_ -ForegroundColor Red
        }
    }
}
```

**Windows Event Logs:**
```powershell
# FAS Event Log Errors
Get-WinEvent -LogName "Citrix-FederatedAuthenticationService/Admin" -MaxEvents 50 |
    Where-Object {$_.LevelDisplayName -eq "Error"} |
    Format-Table TimeCreated, Id, Message -AutoSize

# Certificate Enrollment Errors
Get-WinEvent -LogName "Application" -FilterXPath "*[System[Provider[@Name='Microsoft-Windows-CertificateServicesClient-CertEnroll']]]" -MaxEvents 20
```

**Network Trace:**
```powershell
# Capture Network Traffic between FAS and CA
netsh trace start capture=yes tracefile=C:\Temp\FAS-Network-Trace.etl

# Reproduce Issue

# Stop Capture
netsh trace stop

# Analyze with Message Analyzer or Wireshark
```

### Database Troubleshooting

**FAS Database Issues:**
```powershell
# Check Database Connectivity
$dbServer = "sql-server.domain.local"
$dbName = "CitrixFAS"

# Test Connection
$connectionString = "Server=$dbServer;Database=$dbName;Integrated Security=True;Connection Timeout=5;"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)

try {
    $connection.Open()
    Write-Host "✅ Database Connection: OK" -ForegroundColor Green

    # Check Database Size
    $query = "SELECT
        DB_NAME() AS DatabaseName,
        SUM(size * 8 / 1024) AS SizeMB
    FROM sys.master_files
    WHERE database_id = DB_ID()"

    $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
    $reader = $command.ExecuteReader()

    if ($reader.Read()) {
        Write-Host "Database Size: $($reader['SizeMB']) MB"
    }

    $connection.Close()
} catch {
    Write-Warning "❌ Database Connection Failed: $($_.Exception.Message)"
}
```

## Diagnostic Tools

**FAS Health Check Script:**
```powershell
function Invoke-FasHealthCheck {
    [CmdletBinding()]
    param()

    Write-Host "`n=== FAS Health Check ===" -ForegroundColor Cyan
    Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

    # Service Status
    Write-Host "1. Service Status" -ForegroundColor Yellow
    $service = Get-Service -Name "CitrixFederatedAuthenticationService"
    $serviceStatus = if ($service.Status -eq "Running") { "✅" } else { "❌" }
    Write-Host "   $serviceStatus FAS Service: $($service.Status)"

    # CA Connectivity
    Write-Host "`n2. Certificate Authority" -ForegroundColor Yellow
    try {
        certutil -ping | Out-Null
        Write-Host "   ✅ CA Connectivity: OK"
    } catch {
        Write-Host "   ❌ CA Connectivity: Failed" -ForegroundColor Red
    }

    # AD Connectivity
    Write-Host "`n3. Active Directory" -ForegroundColor Yellow
    try {
        Get-ADDomain | Out-Null
        Write-Host "   ✅ AD Connectivity: OK"
    } catch {
        Write-Host "   ❌ AD Connectivity: Failed" -ForegroundColor Red
    }

    # Certificate Template
    Write-Host "`n4. Certificate Templates" -ForegroundColor Yellow
    $template = certutil -template CitrixFAS_UserCert 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Certificate Template: Available"
    } else {
        Write-Host "   ❌ Certificate Template: Not Found" -ForegroundColor Red
    }

    # Test Certificate Issuance
    Write-Host "`n5. Test Certificate Issuance" -ForegroundColor Yellow
    try {
        $testCert = New-FasUserCertificate -UserPrincipalName "testuser@domain.local" -ErrorAction Stop
        Write-Host "   ✅ Certificate Issuance: OK"
    } catch {
        Write-Host "   ❌ Certificate Issuance: Failed" -ForegroundColor Red
        Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Resource Usage
    Write-Host "`n6. Resource Usage" -ForegroundColor Yellow
    $cpu = Get-Counter '\Processor(_Total)\% Processor Time' | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty CookedValue
    $memory = Get-Counter '\Memory\Available MBytes' | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty CookedValue

    Write-Host "   CPU: $([math]::Round($cpu, 2))%"
    Write-Host "   Available Memory: $([math]::Round($memory, 2)) MB"

    Write-Host "`n=== Health Check Complete ===" -ForegroundColor Cyan
}

# Run Health Check
Invoke-FasHealthCheck
```

## Troubleshooting Checklist

**When troubleshooting FAS issues, systematically check:**

- [ ] **Service Status:** Is FAS Service running?
- [ ] **CA Connectivity:** Can FAS reach CA?
- [ ] **AD Connectivity:** Can FAS access Active Directory?
- [ ] **Network:** Are all required ports open?
- [ ] **Permissions:** Does Service Account have required permissions?
- [ ] **Configuration:** Is FAS correctly configured?
- [ ] **Templates:** Are Certificate Templates available and correct?
- [ ] **Rules:** Do User Rules match expected users?
- [ ] **Logs:** What do logs say about the issue?
- [ ] **Resources:** Is server under resource pressure?

## Escalation Path

**If issue cannot be resolved:**

1. **Collect Diagnostic Data:**
   - FAS Logs (last 24h)
   - Windows Event Logs
   - Network Traces
   - Configuration Files

2. **Contact Citrix Support:**
   - Case Number: [Record here]
   - Severity Level: [Critical/High/Medium/Low]
   - Attachments: Diagnostic Bundle

3. **Citrix Diagnostic Bundle:**
   ```powershell
   # Collect FAS Diagnostic Bundle
   New-Item -Path "C:\Temp\FAS-Diagnostics" -ItemType Directory -Force

   # Copy Logs
   Copy-Item "C:\ProgramData\Citrix\FAS\Logs\*" "C:\Temp\FAS-Diagnostics\Logs\" -Recurse

   # Export Configuration
   Get-FasServer | Export-Clixml "C:\Temp\FAS-Diagnostics\FAS-Config.xml"
   Get-FasRule | Export-Csv "C:\Temp\FAS-Diagnostics\FAS-Rules.csv" -NoTypeInformation

   # Export Event Logs
   wevtutil epl Application "C:\Temp\FAS-Diagnostics\Application.evtx"
   wevtutil epl System "C:\Temp\FAS-Diagnostics\System.evtx"

   # Create ZIP
   Compress-Archive -Path "C:\Temp\FAS-Diagnostics\*" -DestinationPath "C:\Temp\FAS-Diagnostics-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"
   ```

## Best Practices

- **Proactive Monitoring:** Don't wait for issues - monitor continuously
- **Log Retention:** Keep logs for minimum 30 days
- **Regular Health Checks:** Run automated health checks daily
- **Documentation:** Document all issues and resolutions
- **Testing:** Test in non-production first
- **Backups:** Always have current configuration backups
