---
description: "Umfassende Test-Suite für FAS Installation und Certificate Issuance"
---

# FAS Testing Workflow

Du bist ein Citrix FAS Test-Experte. Führe umfassende Tests der FAS Installation durch.

## Test-Kategorien

### 1. Infrastructure Tests

**FAS Service Health:**
```powershell
# Teste FAS Service
$service = Get-Service -Name "CitrixFederatedAuthenticationService"
if ($service.Status -eq "Running") {
    Write-Host "✅ FAS Service: Running" -ForegroundColor Green
} else {
    Write-Warning "❌ FAS Service: $($service.Status)"
    Write-Host "Starte Service..." -ForegroundColor Yellow
    Start-Service -Name "CitrixFederatedAuthenticationService"
}

# Teste Service Dependencies
Get-Service -Name "CitrixFederatedAuthenticationService" -DependentServices
Get-Service -Name "CitrixFederatedAuthenticationService" -RequiredServices
```

**Network Connectivity:**
```powershell
# Teste alle erforderlichen Ports
$tests = @(
    @{Host="fas-server.domain.local"; Port=443; Service="HTTPS"},
    @{Host="dc01.domain.local"; Port=88; Service="Kerberos"},
    @{Host="dc01.domain.local"; Port=389; Service="LDAP"},
    @{Host="ca-server.domain.local"; Port=135; Service="RPC"}
)

foreach ($test in $tests) {
    $result = Test-NetConnection -ComputerName $test.Host -Port $test.Port -WarningAction SilentlyContinue
    $status = if ($result.TcpTestSucceeded) { "✅" } else { "❌" }
    Write-Host "$status $($test.Service) ($($test.Host):$($test.Port))"
}
```

**Certificate Authority Connectivity:**
```powershell
# Teste CA Erreichbarkeit
certutil -ping

# Prüfe CA Templates
certutil -CATemplates | Select-String "CitrixFAS"

# Teste Certificate Request
certreq -submit -attrib "CertificateTemplate:CitrixFAS_UserCert" test-request.req
```

### 2. Configuration Tests

**FAS Configuration Validation:**
```powershell
# Importiere FAS Module
Import-Module Citrix.Authentication.FederatedAuthenticationService.V1

# Prüfe FAS Server Konfiguration
$fasConfig = Get-FasServer
Write-Host "FAS Server Configuration:" -ForegroundColor Cyan
$fasConfig | Format-List

# Erwartete Konfiguration:
# - ServerUrl: https://fas-server.domain.local
# - CertificateAuthority: DC-CA.domain.local\CompanyCA
# - Status: Active
# - LastHealthCheck: < 5 Minuten
```

**Certificate Template Validation:**
```powershell
# Prüfe Template Konfiguration
$templates = @("CitrixFAS_UserCert", "CitrixFAS_AdminCert")

foreach ($template in $templates) {
    Write-Host "`nValidiere Template: $template" -ForegroundColor Cyan

    # Template Properties
    $templateProps = certutil -v -template $template

    # Prüfe kritische Settings
    $checks = @{
        "Subject Name" = $templateProps -match "Supply in the request"
        "Private Key Exportable" = $templateProps -match "Allow private key to be exported"
        "Client Authentication" = $templateProps -match "1.3.6.1.5.5.7.3.2"
    }

    foreach ($check in $checks.GetEnumerator()) {
        $status = if ($check.Value) { "✅" } else { "❌" }
        Write-Host "$status $($check.Key)"
    }
}
```

**User Rules Validation:**
```powershell
# Teste User Rules
$rules = Get-FasRule
Write-Host "`nKonfigurierte Rules:" -ForegroundColor Cyan
$rules | Format-Table Name, Priority, UserFilter, CertificateLifetime -AutoSize

# Prüfe auf Konflikte
$duplicatePriorities = $rules | Group-Object Priority | Where-Object {$_.Count -gt 1}
if ($duplicatePriorities) {
    Write-Warning "⚠️  Duplicate Priorities gefunden:"
    $duplicatePriorities | ForEach-Object { Write-Warning "  Priority $($_.Name): $($_.Group.Name -join ', ')" }
}
```

### 3. Certificate Issuance Tests

**Single User Test:**
```powershell
# Teste Certificate Issuance für Test-User
$testUser = "testuser@domain.local"

Write-Host "`nTeste Certificate Issuance für: $testUser" -ForegroundColor Cyan

try {
    # Simuliere Certificate Request
    $cert = New-FasUserCertificate -UserPrincipalName $testUser -Verbose

    if ($cert) {
        Write-Host "✅ Certificate erfolgreich ausgestellt" -ForegroundColor Green
        Write-Host "   Thumbprint: $($cert.Thumbprint)"
        Write-Host "   Subject: $($cert.Subject)"
        Write-Host "   ValidTo: $($cert.NotAfter)"
        Write-Host "   Issuer: $($cert.Issuer)"

        # Validiere Certificate Properties
        $checks = @{
            "Valid Certificate" = $cert.Verify()
            "Client Authentication EKU" = $cert.EnhancedKeyUsageList.ObjectId -contains "1.3.6.1.5.5.7.3.2"
            "Private Key exists" = $cert.HasPrivateKey
        }

        foreach ($check in $checks.GetEnumerator()) {
            $status = if ($check.Value) { "✅" } else { "❌" }
            Write-Host "   $status $($check.Key)"
        }
    }
} catch {
    Write-Warning "❌ Certificate Issuance fehlgeschlagen: $($_.Exception.Message)"
    Write-Host "Fehlerdetails:" -ForegroundColor Yellow
    Write-Host $_.Exception | Format-List * -Force
}
```

**Bulk User Test:**
```powershell
# Teste Certificate Issuance für mehrere User
$testUsers = @(
    "user1@domain.local",
    "user2@domain.local",
    "admin1@domain.local"
)

$results = foreach ($user in $testUsers) {
    try {
        $cert = New-FasUserCertificate -UserPrincipalName $user -ErrorAction Stop
        [PSCustomObject]@{
            User = $user
            Status = "✅ Success"
            Thumbprint = $cert.Thumbprint
            ValidUntil = $cert.NotAfter
        }
    } catch {
        [PSCustomObject]@{
            User = $user
            Status = "❌ Failed"
            Error = $_.Exception.Message
            ValidUntil = $null
        }
    }
}

$results | Format-Table -AutoSize
```

**Performance Test:**
```powershell
# Teste Certificate Issuance Performance
$iterations = 10
$testUser = "perftest@domain.local"

Write-Host "`nPerformance Test: $iterations Iterations" -ForegroundColor Cyan

$measurements = 1..$iterations | ForEach-Object {
    Measure-Command {
        New-FasUserCertificate -UserPrincipalName $testUser
    }
}

$stats = $measurements | Measure-Object -Property TotalMilliseconds -Average -Minimum -Maximum

Write-Host "Results:" -ForegroundColor Green
Write-Host "  Average: $([math]::Round($stats.Average, 2)) ms"
Write-Host "  Minimum: $([math]::Round($stats.Minimum, 2)) ms"
Write-Host "  Maximum: $([math]::Round($stats.Maximum, 2)) ms"

# Threshold: < 500ms ist gut
if ($stats.Average -lt 500) {
    Write-Host "✅ Performance: Excellent" -ForegroundColor Green
} elseif ($stats.Average -lt 1000) {
    Write-Host "⚠️  Performance: Acceptable" -ForegroundColor Yellow
} else {
    Write-Warning "❌ Performance: Poor (> 1000ms)"
}
```

### 4. Authentication Flow Tests

**End-to-End Test:**
```powershell
# Simuliere kompletten Authentication Flow
Write-Host "`n=== End-to-End Authentication Test ===" -ForegroundColor Cyan

$testSteps = @(
    "1. User Authentication (StoreFront)",
    "2. FAS Certificate Request",
    "3. CA Certificate Issuance",
    "4. Certificate Delivery to VDA",
    "5. Kerberos Ticket Request",
    "6. Session Launch"
)

# Implementierung der einzelnen Test-Steps
# (Abhängig von StoreFront/VDA Integration)
```

**StoreFront Integration Test:**
```powershell
# Teste StoreFront FAS Integration
$storefrontUrl = "https://storefront.domain.local"

# Teste StoreFront Erreichbarkeit
$response = Invoke-WebRequest -Uri "$storefrontUrl/Citrix/StoreWeb" -UseBasicParsing

if ($response.StatusCode -eq 200) {
    Write-Host "✅ StoreFront erreichbar" -ForegroundColor Green
} else {
    Write-Warning "❌ StoreFront nicht erreichbar: $($response.StatusCode)"
}

# Teste FAS Authentication Service Endpoint
$fasEndpoint = "$storefrontUrl/Citrix/Authentication/FederatedAuthentication"
try {
    $fasResponse = Invoke-WebRequest -Uri $fasEndpoint -UseBasicParsing
    Write-Host "✅ FAS Authentication Service aktiv" -ForegroundColor Green
} catch {
    Write-Warning "❌ FAS Authentication Service Fehler: $($_.Exception.Message)"
}
```

### 5. Security Tests

**Certificate Validation:**
```powershell
# Teste Certificate Chain Validation
$cert = Get-FasUserCertificate -UserPrincipalName "testuser@domain.local"

# Build Certificate Chain
$chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
$chain.ChainPolicy.RevocationMode = [System.Security.Cryptography.X509Certificates.X509RevocationMode]::Online

$chainValid = $chain.Build($cert)

if ($chainValid) {
    Write-Host "✅ Certificate Chain: Valid" -ForegroundColor Green
} else {
    Write-Warning "❌ Certificate Chain: Invalid"
    $chain.ChainStatus | ForEach-Object {
        Write-Warning "   $($_.Status): $($_.StatusInformation)"
    }
}
```

**Revocation Test:**
```powershell
# Teste Certificate Revocation
$testCert = New-FasUserCertificate -UserPrincipalName "revoke-test@domain.local"

Write-Host "`nTeste Certificate Revocation..." -ForegroundColor Cyan

# Revoke Certificate
Revoke-FasUserCertificate -CertificateThumbprint $testCert.Thumbprint -Reason "Testing"

# Prüfe Revocation Status
Start-Sleep -Seconds 5  # Warte auf CRL Update

$revokedCert = Get-Certificate -Thumbprint $testCert.Thumbprint
$chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
$chain.Build($revokedCert) | Out-Null

$isRevoked = $chain.ChainStatus | Where-Object {$_.Status -eq "Revoked"}

if ($isRevoked) {
    Write-Host "✅ Certificate erfolgreich revoked" -ForegroundColor Green
} else {
    Write-Warning "❌ Certificate Revocation fehlgeschlagen"
}
```

**Permissions Test:**
```powershell
# Teste FAS Service Account Permissions
$serviceAccount = "domain\FAS-SVC$"

Write-Host "`nTeste Service Account Permissions..." -ForegroundColor Cyan

# AD Permissions
$adChecks = @{
    "Read userPrincipalName" = Test-ADPermission -Account $serviceAccount -Right "ReadProperty" -Property "userPrincipalName"
    "Write userCertificate" = Test-ADPermission -Account $serviceAccount -Right "WriteProperty" -Property "userCertificate"
    "Create Computer Objects" = Test-ADPermission -Account $serviceAccount -Right "CreateChild" -ObjectType "Computer"
}

foreach ($check in $adChecks.GetEnumerator()) {
    $status = if ($check.Value) { "✅" } else { "❌" }
    Write-Host "$status $($check.Key)"
}

# CA Permissions
$caPermission = certutil -getUserRoles $serviceAccount
if ($caPermission -match "Request Certificates") {
    Write-Host "✅ CA Request Certificates Permission" -ForegroundColor Green
} else {
    Write-Warning "❌ CA Request Certificates Permission fehlt"
}
```

## Automated Test Suite

**Comprehensive Test Suite:**
```powershell
function Invoke-FasTestSuite {
    [CmdletBinding()]
    param()

    $results = @()

    Write-Host "`n=== Citrix FAS Test Suite ===" -ForegroundColor Cyan
    Write-Host "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

    # Infrastructure Tests
    Write-Host "1. Infrastructure Tests..." -ForegroundColor Yellow
    $results += Test-FasInfrastructure

    # Configuration Tests
    Write-Host "2. Configuration Tests..." -ForegroundColor Yellow
    $results += Test-FasConfiguration

    # Certificate Tests
    Write-Host "3. Certificate Issuance Tests..." -ForegroundColor Yellow
    $results += Test-FasCertificateIssuance

    # Security Tests
    Write-Host "4. Security Tests..." -ForegroundColor Yellow
    $results += Test-FasSecurity

    # Performance Tests
    Write-Host "5. Performance Tests..." -ForegroundColor Yellow
    $results += Test-FasPerformance

    # Summary
    Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
    $totalTests = $results.Count
    $passedTests = ($results | Where-Object {$_.Status -eq "Passed"}).Count
    $failedTests = ($results | Where-Object {$_.Status -eq "Failed"}).Count
    $successRate = [math]::Round(($passedTests / $totalTests) * 100, 2)

    Write-Host "Total Tests: $totalTests"
    Write-Host "Passed: $passedTests" -ForegroundColor Green
    Write-Host "Failed: $failedTests" -ForegroundColor Red
    Write-Host "Success Rate: $successRate%"

    # Export Results
    $reportPath = "FAS-Test-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
    $results | ConvertTo-Html | Out-File $reportPath
    Write-Host "`nDetailed report saved to: $reportPath" -ForegroundColor Cyan

    return $results
}

# Run Test Suite
Invoke-FasTestSuite
```

## Test Checklist

**Pre-Test Preparation:**
- [ ] Test User Accounts erstellt
- [ ] Test AD Groups konfiguriert
- [ ] FAS Service running
- [ ] Network Connectivity validiert

**Infrastructure Tests:**
- [ ] FAS Service Health
- [ ] Network Connectivity
- [ ] CA Connectivity
- [ ] AD Connectivity

**Configuration Tests:**
- [ ] FAS Server Configuration
- [ ] Certificate Templates
- [ ] User Rules
- [ ] Revocation Policies

**Certificate Tests:**
- [ ] Single User Certificate Issuance
- [ ] Bulk Certificate Issuance
- [ ] Certificate Chain Validation
- [ ] Certificate Revocation

**Integration Tests:**
- [ ] StoreFront Integration
- [ ] VDA Integration
- [ ] End-to-End Authentication Flow

**Performance Tests:**
- [ ] Certificate Issuance Performance
- [ ] Concurrent User Load Test
- [ ] Peak Load Handling

**Security Tests:**
- [ ] Certificate Validation
- [ ] Revocation Test
- [ ] Permissions Test
- [ ] Audit Logging

## Troubleshooting Test Failures

**Certificate Issuance Fehler:**
1. Check CA Connectivity: `certutil -ping`
2. Check Template Permissions: `certutil -v -template <name>`
3. Check Service Account Permissions
4. Check FAS Logs: `C:\ProgramData\Citrix\FAS\Logs`

**Performance Issues:**
1. Check CA Performance
2. Check Network Latency
3. Check FAS Server Resources (CPU, Memory)
4. Check Certificate Cache Settings

**Integration Test Fehler:**
1. Validate StoreFront Configuration
2. Check Citrix Receiver/Workspace App Version
3. Validate VDA Configuration
4. Check Firewall Rules

## Best Practices

- **Automatisierung:** Nutze automatisierte Test Suite für regelmäßige Tests
- **CI/CD Integration:** Integriere Tests in Deployment Pipeline
- **Monitoring:** Kontinuierliches Monitoring der Test-Ergebnisse
- **Regression Testing:** Teste nach jedem Update/Patch
- **Load Testing:** Simuliere realistische User Loads
- **Documentation:** Dokumentiere Test-Ergebnisse und Trends
