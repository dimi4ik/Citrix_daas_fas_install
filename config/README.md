# FAS Configuration Files - Usage Guide

## Übersicht

Die FAS PowerShell-Skripte unterstützen jetzt **umgebungsunabhängige Konfiguration** durch JSON-Dateien. Dies ermöglicht eine einheitliche Ausführung über mehrere Umgebungen (Dev, Test, Prod) hinweg.

## Konfigurationsdateien

### Verfügbare Umgebungen

- **`dev.json`** - Development Environment
- **`test.json`** - Test Environment
- **`prod.json`** - Production Environment

### JSON Struktur

```json
{
  "environment": "dev",
  "fas": {
    "msiPath": "D:\\x64\\Federated Authentication Service\\FederatedAuthenticationService_x64.msi",
    "address": "FAS-SERVER-DEV.contoso.com",
    "securityGroupSID": "S-1-5-21-xxx"
  },
  "certificateAuthority": [
    "CA-SERVER-DEV-01.contoso.com"
  ],
  "permissions": {
    "storeFront": [
      {"SID": "S-1-5-21-xxx", "Permission": "Allow", "Description": "StoreFront Servers"}
    ],
    "vda": [
      {"SID": "S-1-5-21-xxx", "Permission": "Allow", "Description": "VDA Servers"}
    ],
    "user": [
      {"SID": "S-1-5-21-xxx", "Permission": "Allow", "Description": "Citrix Users"}
    ]
  },
  "logging": {
    "deployLogPath": "C:\\Logs\\FAS\\Deploy-FAS-DEV.log",
    "configureLogPath": "C:\\Logs\\FAS\\Configure-FAS-DEV.log",
    "userRulesLogPath": "C:\\Logs\\FAS\\Configure-FAS-UserRules-DEV.log"
  }
}
```

## Verwendung

### Methode 1: Config-Datei (Empfohlen)

#### Development Environment

```powershell
# 1. FAS Installation
.\scripts\Deploy-FAS.ps1 -ConfigFile ".\config\dev.json" -Verbose

# 2. FAS Konfiguration (Templates & CA)
.\scripts\Configure-FAS.ps1 -ConfigFile ".\config\dev.json" -Verbose

# 3. User Rules Konfiguration
.\scripts\Configure-FAS-UserRules.ps1 -ConfigFile ".\config\dev.json" -Verbose
```

#### Test Environment

```powershell
# 1. FAS Installation
.\scripts\Deploy-FAS.ps1 -ConfigFile ".\config\test.json" -Verbose

# 2. FAS Konfiguration
.\scripts\Configure-FAS.ps1 -ConfigFile ".\config\test.json" -Verbose

# 3. User Rules Konfiguration
.\scripts\Configure-FAS-UserRules.ps1 -ConfigFile ".\config\test.json" -Verbose
```

#### Production Environment

```powershell
# 1. FAS Installation
.\scripts\Deploy-FAS.ps1 -ConfigFile ".\config\prod.json" -Verbose

# 2. FAS Konfiguration
.\scripts\Configure-FAS.ps1 -ConfigFile ".\config\prod.json" -Verbose

# 3. User Rules Konfiguration
.\scripts\Configure-FAS-UserRules.ps1 -ConfigFile ".\config\prod.json" -Verbose
```

### Methode 2: Manuelle Parameter (Legacy)

Die Skripte unterstützen weiterhin die alte Methode mit expliziten Parametern:

```powershell
# Deploy-FAS.ps1
.\scripts\Deploy-FAS.ps1 -FASMSIPath "D:\x64\FederatedAuthenticationService_x64.msi"

# Configure-FAS.ps1
.\scripts\Configure-FAS.ps1 `
    -CertificateAuthority @("CA-SERVER.domain.com") `
    -FASAddress "FAS-SERVER.domain.com" `
    -FASSecurityGroupSID "S-1-5-21-xxx"

# Configure-FAS-UserRules.ps1
$StoreFrontPerms = @(@{SID="S-1-5-21-xxx"; Permission="Allow"})
$VDAPerms = @(@{SID="S-1-5-21-xxx"; Permission="Allow"})
$UserPerms = @(@{SID="S-1-5-21-xxx"; Permission="Allow"})

.\scripts\Configure-FAS-UserRules.ps1 `
    -StoreFrontPermissions $StoreFrontPerms `
    -VDAPermissions $VDAPerms `
    -UserPermissions $UserPerms `
    -CertificateAuthority @("CA-SERVER.domain.com") `
    -FASAddress "FAS-SERVER.domain.com"
```

## Konfiguration anpassen

### 1. Neue Umgebung hinzufügen

Erstelle eine neue JSON-Datei (z.B. `uat.json`):

```powershell
Copy-Item .\config\dev.json .\config\uat.json
# Bearbeite uat.json mit deinen UAT-spezifischen Werten
```

### 2. SIDs ermitteln

```powershell
# Active Directory Gruppe SID ermitteln
$group = Get-ADGroup -Identity "StoreFront-Servers"
$group.SID.Value

# Oder mit PowerShell ohne AD-Modul
([System.Security.Principal.NTAccount]"DOMAIN\GroupName").Translate([System.Security.Principal.SecurityIdentifier]).Value
```

### 3. Certificate Authority ermitteln

```powershell
# Alle CAs im AD Forest anzeigen
certutil -ADConfig -CAList

# Oder mit PowerShell
Get-ADObject -Filter {objectClass -eq "pKIEnrollmentService"} -SearchBase "CN=Configuration,$((Get-ADDomain).DistinguishedName)"
```

### 4. FAS Security Group SID

```powershell
# FAS Servers Security Gruppe erstellen (falls noch nicht vorhanden)
New-ADGroup -Name "FAS-Servers" -GroupScope Global -GroupCategory Security

# SID ermitteln
$fasGroup = Get-ADGroup -Identity "FAS-Servers"
$fasGroup.SID.Value
```

## Best Practices

### 1. Config-Dateien versionieren

```bash
git add config/*.json
git commit -m "feat: FAS Konfiguration für alle Umgebungen"
```

### 2. Sensible Daten schützen

Config-Dateien enthalten keine Passwörter, aber SIDs können sensibel sein:

```bash
# Optional: .gitignore anpassen
echo "config/prod.json" >> .gitignore
```

### 3. Validierung vor Ausführung

```powershell
# Config-Datei validieren
$config = Get-Content ".\config\dev.json" | ConvertFrom-Json

Write-Host "Environment: $($config.environment)"
Write-Host "FAS Server: $($config.fas.address)"
Write-Host "CA Servers: $($config.certificateAuthority -join ', ')"
```

### 4. WhatIf Mode nutzen

```powershell
# Dry-Run ohne tatsächliche Änderungen
.\scripts\Deploy-FAS.ps1 -ConfigFile ".\config\prod.json" -WhatIf
.\scripts\Configure-FAS.ps1 -ConfigFile ".\config\prod.json" -WhatIf
.\scripts\Configure-FAS-UserRules.ps1 -ConfigFile ".\config\prod.json" -WhatIf
```

## Troubleshooting

### Config-Datei wird nicht gefunden

```powershell
# Prüfe aktuelles Verzeichnis
Get-Location

# Verwende absoluten Pfad
.\scripts\Deploy-FAS.ps1 -ConfigFile "C:\Citrix_daas_fas_install\config\dev.json"
```

### JSON Parsing Fehler

```powershell
# JSON Syntax validieren
Get-Content ".\config\dev.json" | ConvertFrom-Json

# Bei Fehlern: JSON online validieren (https://jsonlint.com/)
```

### Parameter Override

Config-Datei kann mit expliziten Parametern überschrieben werden:

```powershell
# Config-Datei verwendet, aber LogPath überschrieben
.\scripts\Deploy-FAS.ps1 `
    -ConfigFile ".\config\dev.json" `
    -LogPath "C:\CustomPath\deploy.log"
```

## Weitere Informationen

- **FAS Dokumentation**: https://docs.citrix.com/en-us/federated-authentication-service
- **PowerShell Best Practices**: https://poshcode.gitbook.io/powershell-practice-and-style/
- **CLAUDE.md**: Projekt-spezifische Guidelines

---

**Version:** 1.0.0
**Letzte Aktualisierung:** 2025-11-05
**Maintainer:** dima@lejkin.de
