---
description: "FAS Server Konfiguration und Certificate Authority Integration"
---

# FAS Configuration Workflow

Du bist ein Citrix FAS Konfigurations-Experte. Führe die detaillierte FAS Server Konfiguration durch.

## Konfigurations-Bereiche

### 1. Certificate Authority Integration

**Konfiguration der CA-Verbindung:**
```powershell
# Importiere FAS PowerShell Module
Import-Module Citrix.Authentication.FederatedAuthenticationService.V1

# Konfiguriere CA
$caConfig = @{
    CertificateAuthority = "DC-CA.domain.local\CompanyCA"
    CertificateTemplate = "CitrixFAS_UserCert"
    CertificateDefinition = "Standard"
    MsTemplate = $true
}

Set-FasAuthorizationCertificate @caConfig
```

**Certificate Template Requirements:**
- Subject Name: Supplied in request
- Private Key exportierbar
- Extended Key Usage: Client Authentication
- Key Usage: Digital Signature, Key Encipherment
- Validity Period: 8 Stunden (empfohlen)

### 2. Active Directory Integration

**FAS Service Account:**
```powershell
# Prüfe Service Account Permissions
$serviceAccount = "domain\FAS-SVC$"
$requiredGroups = @(
    "Certificate Service DCOM Access",
    "Domain Computers"
)

foreach ($group in $requiredGroups) {
    $isMember = Get-ADGroupMember -Identity $group | Where-Object {$_.SamAccountName -eq "FAS-SVC$"}
    if ($isMember) {
        Write-Host "✅ $group: OK" -ForegroundColor Green
    } else {
        Write-Warning "❌ $group: Fehlende Mitgliedschaft"
    }
}
```

**AD Permissions:**
- Read: userPrincipalName, sAMAccountName
- Write: userCertificate attribute
- Create/Delete: Computer Objects (für Device Certificates)

### 3. FAS Server Autorisation

**Authorize FAS Server in AD:**
```powershell
# Autorisiere FAS Server
Grant-FasAuthorization -ADGroup "Domain Controllers" -Rule "Allow certificate enrollment"
```

**Security Groups Mapping:**
```powershell
# Definiere welche AD Groups FAS nutzen dürfen
$authorizedGroups = @(
    "CitrixUsers",
    "RemoteWorkers",
    "VDI-Users"
)

foreach ($group in $authorizedGroups) {
    Grant-FasAuthorization -ADGroup $group -Rule "Allow FAS authentication"
}
```

### 4. Certificate Policies

**Certificate Lifetime:**
```powershell
# Standard: 8 Stunden für User Certificates
Set-FasCertificateDefinition -Name "Standard" -ValidityPeriod (New-TimeSpan -Hours 8)

# Kurze Lifetime für High-Security Umgebungen: 1 Stunde
Set-FasCertificateDefinition -Name "HighSecurity" -ValidityPeriod (New-TimeSpan -Hours 1)
```

**Certificate Renewal:**
```powershell
# Automatische Erneuerung bei 50% Restlaufzeit
Set-FasRenewalSettings -RenewalThreshold 0.5
```

### 5. StoreFront Integration

**FAS Deployment in StoreFront:**
```powershell
# Konfiguriere StoreFront für FAS
$storefront = "https://storefront.domain.local"
$fasServer = "https://fas-server.domain.local"

# StoreFront Authentication Service Konfiguration
# (Manuelle Konfiguration in StoreFront Console erforderlich)
```

**StoreFront Configuration Steps:**
1. Öffne Citrix StoreFront Konsole
2. Wähle Store → Manage Authentication Methods
3. Aktiviere "Certificate Authentication"
4. Konfiguriere FAS Server URL
5. Teste Authentication Flow

### 6. Citrix Virtual Apps and Desktops Integration

**FAS in Delivery Controller registrieren:**
```powershell
# Citrix PowerShell Snapins laden
Add-PSSnapin Citrix.*

# FAS Server registrieren
New-BrokerAccessPolicyRule -Name "FAS-Authentication" `
    -AuthenticationMethod SmartCard `
    -AllowedConnections "NotViaAG" `
    -Enabled $true
```

### 7. Logging und Monitoring

**Event Log Konfiguration:**
```powershell
# Aktiviere detailliertes FAS Logging
Set-FasLoggingConfiguration -Level "Verbose" -MaxLogSize 100MB
```

**Log Locations:**
- FAS Service Logs: `C:\ProgramData\Citrix\FAS\Logs`
- Windows Event Log: `Application and Services Logs\Citrix\FederatedAuthenticationService`
- Certificate Issuance: `Application and Services Logs\Microsoft\Windows\CertificateServicesClient-CertEnroll`

### 8. Firewall und Network

**Erforderliche Firewall Regeln:**
```powershell
# FAS Server Inbound Rules
New-NetFirewallRule -DisplayName "Citrix FAS HTTPS" `
    -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow

New-NetFirewallRule -DisplayName "Citrix FAS HTTP" `
    -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
```

**Netzwerk-Ports:**
- TCP 443: HTTPS (FAS API)
- TCP 80: HTTP (Optional, Redirect to HTTPS)
- TCP 135, 139, 445: Active Directory Communication
- UDP 88: Kerberos Authentication

## Konfigurations-Validierung

### Health Check
```powershell
# FAS Health Check
Test-FasConfiguration -Verbose

# Erwartete Ausgabe:
# ✅ Certificate Authority: Erreichbar
# ✅ Certificate Template: Verfügbar
# ✅ AD Integration: OK
# ✅ Service Account: Korrekte Permissions
# ✅ Certificate Issuance: Erfolgreich getestet
```

### Test Certificate Issuance
```powershell
# Test User Certificate
New-FasUserCertificate -UserPrincipalName "testuser@domain.local" -Test
```

## Konfigurations-Checkliste

**Certificate Authority:**
- [ ] CA erreichbar und konfiguriert
- [ ] Certificate Template erstellt und published
- [ ] Template Permissions korrekt gesetzt

**Active Directory:**
- [ ] Service Account erstellt
- [ ] Service Account Permissions gesetzt
- [ ] AD Schema bereit für userCertificate attribute

**FAS Server:**
- [ ] FAS Service läuft
- [ ] CA Integration konfiguriert
- [ ] Authorization Rules erstellt
- [ ] Logging aktiviert

**Integration:**
- [ ] StoreFront konfiguriert
- [ ] Delivery Controller konfiguriert
- [ ] Firewall Regeln erstellt
- [ ] Network Connectivity validiert

## Troubleshooting

**Häufige Konfigurationsfehler:**

1. **CA nicht erreichbar:**
   - Prüfe Network Connectivity
   - Validiere Certificate Authority DNS Name
   - Prüfe Service Account Permissions

2. **Certificate Template Fehler:**
   - Template muss published sein
   - Permissions für FAS Service Account
   - Subject Name = "Supplied in request"

3. **AD Integration Fehler:**
   - Service Account in korrekten AD Groups
   - userCertificate attribute Write Permission
   - Kerberos Delegation konfiguriert

## Best Practices

- **Hochverfügbarkeit:** Minimum 2 FAS Server in Production
- **Load Balancing:** NetScaler/Citrix ADC für FAS Server
- **Certificate Lifetime:** 8 Stunden für Balance zwischen Security und UX
- **Monitoring:** Aktives Monitoring der Certificate Issuance Rate
- **Backup:** Regelmäßige Backups der FAS Konfiguration
