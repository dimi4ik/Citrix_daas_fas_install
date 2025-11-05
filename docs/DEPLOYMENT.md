# FAS Deployment Guide für Windows Admins

Schnelle Deployment-Anleitung für Citrix Federated Authentication Service mit PowerShell-Automatisierung.

---

## Voraussetzungen

### Infrastruktur
- ✅ Windows Server 2016+ (FAS Server)
- ✅ Active Directory Domain (Enterprise Admin Rechte)
- ✅ Microsoft Certificate Authority (Enterprise CA)
- ✅ Citrix Virtual Apps and Desktops (VDA + StoreFront)

### Accounts
- ✅ **Enterprise Admin**: Für Template-Deployment
- ✅ **CA Admin**: Für Template Publishing
- ✅ **Lokaler Admin**: Auf FAS Server

### Software
- ✅ FAS MSI Installer (`FederatedAuthenticationService_x64.msi`)
- ✅ PowerShell 5.1+
- ✅ .NET Framework 4.7.2+

---

## Quick Start (3 Skripte)

### 1️⃣ Installation (`Deploy-FAS.ps1`)

```powershell
# Als Administrator ausführen
.\scripts\Deploy-FAS.ps1 -FASMSIPath "D:\x64\Federated Authentication Service\FederatedAuthenticationService_x64.msi" -Verbose

# Optional: WhatIf für Dry-Run
.\scripts\Deploy-FAS.ps1 -FASMSIPath "..." -WhatIf
```

**Durchgeführte Schritte**:
- ✅ Prerequisites Check (Admin Rights, Windows Version)
- ✅ MSI Installation (Silent Mode)
- ✅ Service Verification (CitrixFederatedAuthenticationService)
- ✅ Registry Check

**Output**:
- Log: `$env:TEMP\FAS-Deploy.log`
- Exit Code: `0` (Success), `1` (Failure)

---

### 2️⃣ Konfiguration (`Configure-FAS.ps1`)

```powershell
# Parameter vorbereiten
$CAServers = @("CA-SERVER-01.domain.com")
$FASServer = "FAS-SERVER-01.domain.com"

# FAS Security Group SID ermitteln
$FASGroup = Get-ADGroup "FAS Servers"
$FASSID = $FASGroup.SID.Value

# Konfiguration ausführen
.\scripts\Configure-FAS.ps1 `
    -CertificateAuthority $CAServers `
    -FASAddress $FASServer `
    -FASSecurityGroupSID $FASSID `
    -Verbose
```

**Durchgeführte Schritte**:
- ✅ Template Deployment (917Citrix_SmartcardLogon + Citrix_RegistrationAuthority)
- ✅ Template Publishing zu CA
- ✅ Authorization Certificate Request

**WICHTIG**: Template `917Citrix_SmartcardLogon` (Custom)
- Schema Version: 4 (Windows Server 2016+)
- Hash Algorithm: SHA256
- Key: RSA 2048-bit
- Provider: Microsoft Software Key Storage Provider

**Manuelle Aktion erforderlich**:
```powershell
# Falls Certificate Request "Pending":
# 1. Öffne Certificate Authority Console auf CA Server
# 2. Navigiere zu "Pending Requests"
# 3. Rechtsklick auf FAS Request → "Issue"

# Dann validieren:
Get-FasAuthorizationCertificate -Address $FASServer
```

---

### 3️⃣ User Rules (`Configure-FAS-UserRules.ps1`)

```powershell
# Permissions definieren (SIDs ermitteln)
$StoreFrontGroup = Get-ADGroup "StoreFront Servers"
$VDAGroup = Get-ADGroup "VDA Servers"
$UserGroup = Get-ADGroup "Citrix Users"

$StoreFrontPerms = @(@{SID=$StoreFrontGroup.SID.Value; Permission="Allow"})
$VDAPerms = @(@{SID=$VDAGroup.SID.Value; Permission="Allow"})
$UserPerms = @(@{SID=$UserGroup.SID.Value; Permission="Allow"})

# User Rules konfigurieren
.\scripts\Configure-FAS-UserRules.ps1 `
    -StoreFrontPermissions $StoreFrontPerms `
    -VDAPermissions $VDAPerms `
    -UserPermissions $UserPerms `
    -CertificateAuthority $CAServers `
    -FASAddress $FASServer `
    -Verbose
```

**Durchgeführte Schritte**:
- ✅ Certificate Definition (mit 917Citrix_SmartcardLogon Template)
- ✅ FAS Rule mit ACLs (StoreFront, VDA, User)
- ✅ SDDL Validation

---

## Deployment-Workflow

```
┌─────────────────────────────────────────────────────────┐
│ 1. Deploy-FAS.ps1                                       │
│    └─ MSI Installation + Service Start                  │
├─────────────────────────────────────────────────────────┤
│ 2. Configure-FAS.ps1                                    │
│    ├─ Template Deployment (AD)                          │
│    ├─ Template Publishing (CA)                          │
│    └─ Authorization Certificate                         │
│       └─ [MANUELL] Pending Request auf CA approven      │
├─────────────────────────────────────────────────────────┤
│ 3. Configure-FAS-UserRules.ps1                          │
│    ├─ Certificate Definition                            │
│    └─ FAS Rules (StoreFront, VDA, User ACLs)            │
├─────────────────────────────────────────────────────────┤
│ 4. StoreFront Konfiguration                             │
│    └─ FAS URL in StoreFront Stores hinzufügen           │
├─────────────────────────────────────────────────────────┤
│ 5. Testing                                              │
│    └─ .\scripts\Test-FASInstallation.ps1                │
└─────────────────────────────────────────────────────────┘
```

---

## Validation & Testing

### Automatische Validierung

```powershell
.\scripts\Test-FASInstallation.ps1 -FASAddress "FAS-SERVER-01.domain.com" -GenerateReport

# Prüft:
# ✅ FAS Service Status
# ✅ Certificate Templates (917Citrix_SmartcardLogon)
# ✅ Authorization Certificate
# ✅ Certificate Definitions
# ✅ FAS Rules
# ✅ Event Logs
```

### Manuelle Checks

```powershell
# Service Status
Get-Service -Name CitrixFederatedAuthenticationService

# FAS Server Connectivity
Get-FasServer -Address "FAS-SERVER-01.domain.com"

# Templates in AD
$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$configNC = "CN=Configuration," + $domain.GetDirectoryEntry().distinguishedName[0]
Get-ADObject -SearchBase "CN=Certificate Templates,CN=Public Key Services,CN=Services,$configNC" `
             -Filter {cn -eq "917Citrix_SmartcardLogon"}

# Authorization Certificate
Get-FasAuthorizationCertificate -Address "FAS-SERVER-01.domain.com"

# Certificate Definitions
Get-FasCertificateDefinition -Address "FAS-SERVER-01.domain.com"

# FAS Rules
Get-FasRule -Address "FAS-SERVER-01.domain.com"

# Event Logs (letzte 20 Events)
Get-WinEvent -LogName "Citrix-FederatedAuthenticationService/Admin" -MaxEvents 20
```

---

## StoreFront Integration

```powershell
# StoreFront PowerShell SDK laden
Add-PSSnapin Citrix.StoreFront.Stores

# FAS URL zu Store hinzufügen
$store = Get-STFStoreService -SiteId 1 -VirtualPath "/Citrix/Store"
Set-STFStoreService -StoreService $store -FederatedAuthenticationService "https://fas-server-01.domain.com"

# Validieren
Get-STFStoreService | Select-Object FriendlyName, FederatedAuthenticationService
```

**Alternative**: StoreFront GUI
1. Öffne StoreFront Console
2. Navigiere zu "Stores" → Dein Store → "Manage Authentication Methods"
3. Aktiviere "Federated Authentication Service"
4. URL eingeben: `https://fas-server-01.domain.com`

---

## Troubleshooting

### Problem: MSI Installation fehlschlägt

```powershell
# Log prüfen
Get-Content "$env:TEMP\FAS-Deploy.log"
Get-Content "$env:TEMP\FAS-Deploy.log.msi.log"

# Exit Codes:
# 0     = Success
# 3010  = Success (Reboot required)
# 1603  = Fatal error
# 1618  = Another installation in progress
```

**Lösung**:
- Exit 1603: Windows Installer Log prüfen, Prerequisites checken
- Exit 1618: Andere Installationen beenden, neu versuchen

---

### Problem: Template Deployment schlägt fehl

```powershell
# FAS Service Status
Get-Service CitrixFederatedAuthenticationService

# FAS Connectivity
Test-NetConnection -ComputerName "FAS-SERVER-01.domain.com" -Port 80

# Enterprise Admin Rechte prüfen
whoami /groups | Select-String "Enterprise Admins"
```

**Lösung**:
- Service muss laufen
- Enterprise Admin Rechte erforderlich
- Netzwerk-Connectivity zu FAS Server

---

### Problem: Authorization Certificate "Pending"

```powershell
# Certificate Status prüfen
Get-FasAuthorizationCertificate -Address "FAS-SERVER-01.domain.com"
```

**Lösung**:
1. CA Console öffnen (certsrv.msc auf CA Server)
2. "Pending Requests" → FAS Request finden
3. Rechtsklick → "All Tasks" → "Issue"
4. Nach 30 Sekunden erneut prüfen

---

### Problem: Certificate Issuance schlägt fehl

```powershell
# Event Log prüfen
Get-WinEvent -LogName "Citrix-FederatedAuthenticationService/Admin" -MaxEvents 50 |
    Where-Object {$_.LevelDisplayName -eq "Error"}

# CA Connectivity testen
certutil -ping -config "CA-SERVER-01.domain.com\Enterprise CA Name"

# Template auf CA prüfen
certutil -CATemplates -config "CA-SERVER-01.domain.com\Enterprise CA Name" |
    Select-String "917Citrix"
```

**Lösung**:
- Template muss auf CA published sein
- FAS Server muss Enroll-Rechte auf Template haben
- CA muss erreichbar sein

---

### Problem: User Certificate wird nicht ausgestellt

```powershell
# FAS Rule prüfen
Get-FasRule -Address "FAS-SERVER-01.domain.com" | Format-List

# User SID ermitteln
$user = Get-ADUser "testuser"
$user.SID.Value

# Certificate Definition prüfen
Get-FasCertificateDefinition -Address "FAS-SERVER-01.domain.com" | Format-List
```

**Lösung**:
- User muss in UserAcl der FAS Rule sein
- Certificate Definition muss korrektes Template verwenden (917Citrix_SmartcardLogon)
- StoreFront Server muss in StoreFrontAcl sein
- VDA muss in VdaAcl sein

---

## Firewall-Konfiguration

**FAS Server Inbound**:
```powershell
# HTTP (80) - FAS API
New-NetFirewallRule -DisplayName "FAS - HTTP" `
                   -Direction Inbound `
                   -Protocol TCP `
                   -LocalPort 80 `
                   -Action Allow

# HTTPS (443) - FAS API (Optional, wenn HTTPS konfiguriert)
New-NetFirewallRule -DisplayName "FAS - HTTPS" `
                   -Direction Inbound `
                   -Protocol TCP `
                   -LocalPort 443 `
                   -Action Allow
```

**FAS Server Outbound**:
- Port 135 (RPC) zu CA Server
- Port 445 (SMB) zu Domain Controllers
- Port 389/636 (LDAP/LDAPS) zu Domain Controllers

---

## Backup & Disaster Recovery

### Backup

```powershell
# FAS Configuration exportieren
$backupPath = "C:\FAS-Backup\$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -Path $backupPath -ItemType Directory

# Authorization Certificate
$authCert = Get-FasAuthorizationCertificate -Address "FAS-SERVER-01.domain.com"
$authCert | Export-Clixml "$backupPath\AuthorizationCertificate.xml"

# Certificate Definitions
$certDefs = Get-FasCertificateDefinition -Address "FAS-SERVER-01.domain.com"
$certDefs | Export-Clixml "$backupPath\CertificateDefinitions.xml"

# FAS Rules
$rules = Get-FasRule -Address "FAS-SERVER-01.domain.com"
$rules | Export-Clixml "$backupPath\FasRules.xml"

# Registry Backup (optional)
reg export "HKLM\SOFTWARE\Citrix\Authentication" "$backupPath\FAS-Registry.reg"
```

### Restore (nach Neuinstallation)

```powershell
# Nach Deploy-FAS.ps1 und Configure-FAS.ps1:

# 1. Authorization Certificate restore (manuell via CA)
# 2. Certificate Definitions neu erstellen (gleiche Parameter wie Backup)
# 3. FAS Rules neu erstellen (gleiche ACLs wie Backup)

# Backup-Daten als Referenz:
$authCert = Import-Clixml "$backupPath\AuthorizationCertificate.xml"
$certDefs = Import-Clixml "$backupPath\CertificateDefinitions.xml"
$rules = Import-Clixml "$backupPath\FasRules.xml"
```

---

## Performance Tuning

### FAS Server Sizing

| Deployment | vCPU | RAM | Concurrent Users |
|------------|------|-----|------------------|
| Small | 2 | 4 GB | < 1,000 |
| Medium | 4 | 8 GB | 1,000 - 5,000 |
| Large | 8 | 16 GB | 5,000 - 15,000 |

### Certificate Caching

```powershell
# Certificate Validity (Default: 8 Stunden)
# Längere Validity = weniger CA-Load, aber längere Revocation-Delay
# Kürzer Validity = höherer CA-Load, aber schnellere Revocation

# Konfiguration: FAS GUI → "Initial Setup" → "Certificate Lifetime"
```

---

## Security Best Practices

### 1. FAS Server Hardening

```powershell
# Nur benötigte Ports öffnen
# Windows Firewall aktiviert lassen
# Antivirus Exclusions (falls Performance-Probleme):
Add-MpPreference -ExclusionPath "C:\Program Files\Citrix\Federated Authentication Service"
```

### 2. Template Permissions

- ✅ **Nur** FAS Security Group darf enrollen
- ✅ Enterprise Admins für Template Management
- ❌ Keine "Domain Users" Enroll-Rechte

### 3. Certificate Lifetime

- ✅ **Empfohlen**: 8 Stunden (Default)
- ⚠️ **Maximum**: 24 Stunden
- ❌ **Nicht**: > 24 Stunden (Security Risk)

### 4. Monitoring

```powershell
# Daily Check: Authorization Certificate Expiration
$authCert = Get-FasAuthorizationCertificate -Address "FAS-SERVER-01.domain.com"
$daysUntilExpiry = ($authCert.NotAfter - (Get-Date)).Days

if ($daysUntilExpiry -lt 30) {
    Write-Warning "Authorization Certificate expires in $daysUntilExpiry days!"
}
```

---

## Cheat Sheet

```powershell
# === DEPLOYMENT ===
# 1. Installation
.\scripts\Deploy-FAS.ps1 -FASMSIPath "..." -Verbose

# 2. Konfiguration
.\scripts\Configure-FAS.ps1 -CertificateAuthority @("CA.domain.com") `
                            -FASAddress "FAS.domain.com" `
                            -FASSecurityGroupSID "S-1-5-21-..." -Verbose

# 3. User Rules
.\scripts\Configure-FAS-UserRules.ps1 -StoreFrontPermissions $sfPerms `
                                      -VDAPermissions $vdaPerms `
                                      -UserPermissions $userPerms `
                                      -CertificateAuthority @("CA.domain.com") `
                                      -FASAddress "FAS.domain.com" -Verbose

# === VALIDATION ===
Get-Service CitrixFederatedAuthenticationService
Get-FasServer -Address "FAS.domain.com"
Get-FasAuthorizationCertificate -Address "FAS.domain.com"
Get-FasCertificateDefinition -Address "FAS.domain.com"
Get-FasRule -Address "FAS.domain.com"

# === TESTING ===
.\scripts\Test-FASInstallation.ps1 -FASAddress "FAS.domain.com" -GenerateReport

# === TROUBLESHOOTING ===
Get-WinEvent -LogName "Citrix-FederatedAuthenticationService/Admin" -MaxEvents 50
Get-Content "$env:TEMP\FAS-Deploy.log"
```

---

**Version**: 1.0.0
**Zielgruppe**: Erfahrene Windows Admins mit Citrix-Kenntnissen
**Deployment-Zeit**: ~30-60 Minuten (inkl. Validierung)
