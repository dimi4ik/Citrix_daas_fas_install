# Citrix FAS Installation - PowerShell Automation

[![PowerShell Tests](https://github.com/dimi4ik/Citrix_daas_fas_install/actions/workflows/powershell-tests.yml/badge.svg)](https://github.com/dimi4ik/Citrix_daas_fas_install/actions/workflows/powershell-tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)

PowerShell-basierte Automatisierung für die Installation, Konfiguration und Verwaltung von Citrix Federated Authentication Service (FAS).

## Überblick

**Citrix Federated Authentication Service (FAS)** ermöglicht Single Sign-On für Citrix Virtual Apps and Desktops durch automatische Certificate-basierte Authentifizierung - ohne physische Smartcards.

### Hauptfunktionen

- ✅ **Automatische Installation** - Vollständig automatisierte FAS Deployment
- ✅ **CA Integration** - Nahtlose Integration mit Microsoft Certificate Authority
- ✅ **User Certificate Management** - Automatische Certificate Issuance und Lifecycle Management
- ✅ **Security Policies** - Granulare User Rules und Certificate Lifetime Policies
- ✅ **Comprehensive Testing** - Umfassende Test-Suite für Validation
- ✅ **Backup & Recovery** - Disaster Recovery Procedures
- ✅ **Troubleshooting** - Systematische Problemanalyse und Lösungen

## Voraussetzungen

### Infrastructure

- Windows Server 2019/2022
- Active Directory Domain
- Microsoft Certificate Authority (Enterprise CA)
- Citrix Virtual Apps and Desktops 2402 oder höher
- StoreFront 2402 oder höher

### PowerShell

- PowerShell 5.1 oder höher
- PowerShell Module:
  - `ActiveDirectory`
  - `Citrix.Authentication.FederatedAuthenticationService.V1`
  - `PSScriptAnalyzer` (für Validierung)

### Permissions

- **Installation:** Local Administrator auf FAS Server
- **Configuration:** Domain Admin oder delegierte Permissions für:
  - Certificate Authority (Request Certificates)
  - Active Directory (Read/Write userCertificate)
  - Certificate Template Management

## Quick Start

### 1. Repository klonen

```powershell
git clone https://github.com/dimi4ik/Citrix_daas_fas_install.git
cd Citrix_daas_fas_install
```

### 2. Tests ausführen (optional, empfohlen)

```powershell
# Pester installieren
Install-Module -Name Pester -MinimumVersion 5.0.0 -Force

# Alle Tests ausführen
.\tests\Invoke-Tests.ps1 -TestType All
```

### 3. Konfiguration anpassen

```powershell
# Editiere config/fas-config.json
notepad config\fas-config.json
```

### 4. Validierung

```powershell
# PowerShell Syntax und Konfiguration validieren
# Nutze Claude Code: /fas-validate
```

### 5. Installation (Development/Testing)

```powershell
# Test mit -WhatIf flag
.\scripts\Deploy-FAS.ps1 -WhatIf -Verbose
.\scripts\Configure-FAS.ps1 -WhatIf -Verbose
.\scripts\Configure-FAS-UserRules.ps1 -WhatIf -Verbose
```

### 6. Production Deployment

```powershell
# Production Deployment mit Logging
# Siehe: docs/DEPLOYMENT.md für Details
```

## Die 3 Core PowerShell Skripte

### 1. Deploy-FAS.ps1

**Zweck:** FAS Server Installation

```powershell
# Installation mit Logging
.\scripts\Deploy-FAS.ps1 -Verbose | Tee-Object -FilePath "logs\deploy.log"
```

**Funktionen:**
- FAS Binaries Installation
- Service Account Konfiguration
- Database Setup (optional)
- Firewall Regeln
- Service Registration

### 2. Configure-FAS.ps1

**Zweck:** FAS Basis-Konfiguration

```powershell
# Konfiguration
.\scripts\Configure-FAS.ps1 -Verbose | Tee-Object -FilePath "logs\configure.log"
```

**Funktionen:**
- Certificate Authority Integration
- Certificate Template Konfiguration
- Active Directory Integration
- Service Account Permissions
- StoreFront Integration

### 3. Configure-FAS-UserRules.ps1

**Zweck:** User Certificate Rules und Policies

```powershell
# User Rules Konfiguration
.\scripts\Configure-FAS-UserRules.ps1 -Verbose | Tee-Object -FilePath "logs\userrules.log"
```

**Funktionen:**
- User Certificate Rules (Standard, High-Security, External)
- Security Group Mappings
- Certificate Lifetime Policies
- Revocation Rules

## Claude Code Commands

Dieses Repository enthält **7 spezialisierte Claude Code Slash Commands** für FAS Installation:

| Command | Beschreibung | Verwendung |
|---------|-------------|-----------|
| `/fas-validate` | PowerShell Syntax & Configuration Validation | Vor jedem Deployment |
| `/fas-deploy` | Sichere FAS Installation mit Safety Checks | Production Deployment |
| `/fas-configure` | Detaillierte FAS Server Konfiguration | CA Integration, Templates |
| `/fas-userrules` | User Certificate Rules Management | User Policies, Lifetime |
| `/fas-test` | Comprehensive Test Suite | Post-Deployment Validation |
| `/fas-troubleshoot` | Advanced Troubleshooting Guide | Problem Analysis |
| `/fas-backup` | Backup & Disaster Recovery | Backup/Restore Procedures |

### Verwendung mit Claude Code

```bash
# In Claude Code:
/fas-validate      # Validiere Skripte und Konfiguration
/fas-deploy        # Starte FAS Deployment
/fas-test          # Teste Installation
/fas-backup        # Erstelle Backup
```

## FAS Architektur

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│  StoreFront │─────>│  FAS Server │─────>│Certificate  │
│             │      │             │      │  Authority  │
└─────────────┘      └─────────────┘      └─────────────┘
       │                    │                     │
       │                    v                     │
       │            ┌─────────────┐              │
       └───────────>│   Active    │<─────────────┘
                    │  Directory  │
                    └─────────────┘
                           │
                           v
                    ┌─────────────┐
                    │     VDA     │
                    │  (Session)  │
                    └─────────────┘
```

### Authentication Flow

1. **User Login** - User authentifiziert sich an StoreFront (Username/Password)
2. **FAS Request** - StoreFront kontaktiert FAS Server
3. **Certificate Request** - FAS requested Certificate von CA
4. **Certificate Issuance** - CA issued short-lived Certificate (8h)
5. **Certificate Delivery** - FAS liefert Certificate an VDA
6. **Kerberos Authentication** - VDA verwendet Certificate für Kerberos
7. **Session Start** - Session startet (SSO - kein weiteres Passwort)

## Testing & CI/CD

### Automated Testing (GitHub Actions)

Alle PowerShell-Skripte werden automatisch getestet bei jedem Push/Pull Request:

- ✅ **Syntax Validation** - PowerShell Parser & PSScriptAnalyzer
- ✅ **Unit Tests** - Mock-basierte Tests ohne Backend-Abhängigkeiten
- ✅ **Integration Tests** - End-to-End Workflow Validation
- ✅ **Code Coverage** - Automatische Coverage Reports

**Status**: ![Tests](https://github.com/dimi4ik/Citrix_daas_fas_install/actions/workflows/powershell-tests.yml/badge.svg)

### Lokale Tests ausführen

```powershell
# Pester 5.x installieren
Install-Module -Name Pester -MinimumVersion 5.0.0 -Force

# Alle Tests ausführen
.\tests\Invoke-Tests.ps1 -TestType All

# Nur Syntax-Validierung (schnell)
.\tests\Invoke-Tests.ps1 -TestType Validation

# Mit Code Coverage
.\tests\Invoke-Tests.ps1 -TestType All -CodeCoverage
```

### Test-Kategorien

#### 1. **Validation Tests** (Syntax & Quality)
- PowerShell Parser Validation
- PSScriptAnalyzer Rules (Best Practices)
- Security Checks (keine Hardcoded Credentials)
- Code Quality Standards

#### 2. **Unit Tests** (Isoliert mit Mocks)
- Deploy-FAS.ps1 - Installation, Service Management
- Configure-FAS.ps1 - Template Deployment, CA Integration
- Configure-FAS-UserRules.ps1 - User Rules, ACLs

#### 3. **Integration Tests** (End-to-End)
- Full Deployment Workflow (Install → Configure → UserRules)
- Template Schema Validation (917Citrix_SmartcardLogon)
- Certificate Lifecycle (Authorization Certificate)
- Error Handling Scenarios

### Mock-basiertes Testing

**Keine Backend-Infrastruktur erforderlich**:
- ❌ Kein FAS Server
- ❌ Keine Certificate Authority
- ❌ Kein Active Directory
- ✅ **100% isolierte Tests**

**Vorteile**:
- ⚡ Tests in Sekunden (nicht Minuten)
- 🔄 Wiederholbar und konsistent
- 🚀 CI/CD ready
- 🎯 Fokus auf Logik und Error Handling

**Dokumentation**: Siehe [`docs/TESTING.md`](docs/TESTING.md) für Details.

## Troubleshooting

### Quick Reference

| Problem | Claude Command | Lösung |
|---------|---------------|--------|
| Certificate Issuance Failed | `/fas-troubleshoot` | CA Connectivity, Template Permissions |
| FAS Service Won't Start | `/fas-troubleshoot` | Database Connection, Port Conflicts |
| User Authentication Failed | `/fas-test` | User Rules, AD Account Status |
| Performance Issues | `/fas-test` | CA Performance, Network Latency |

### Log Locations

```powershell
# FAS Service Logs
C:\ProgramData\Citrix\FAS\Logs\

# Windows Event Logs
Application and Services Logs\Citrix\FederatedAuthenticationService

# Certificate Enrollment Logs
Application and Services Logs\Microsoft\Windows\CertificateServicesClient-CertEnroll
```

## Backup & Recovery

### Automated Backup

```powershell
# Create comprehensive backup
# Nutze Claude Code: /fas-backup
```

### Disaster Recovery

```powershell
# Complete disaster recovery
Invoke-FasDisasterRecovery -BackupPath "C:\Backup\FAS\FAS-Backup-20250105.zip"
```

## Security Best Practices

### Certificate Lifetime Strategy

| User Type | Certificate Lifetime | Use Case |
|-----------|---------------------|----------|
| Standard Users | 8 Stunden | Balance Security/UX |
| Admin Accounts | 1 Stunde | High Security |
| External Users | 4 Stunden | Medium Security |
| Kiosk/Shared | 30 Minuten | Sehr kurz |

### Security Checklist

- [ ] Keine Hardcoded Credentials in Skripten
- [ ] Service Account mit Least Privilege
- [ ] Certificate Templates korrekt konfiguriert
- [ ] Audit Logging aktiviert
- [ ] Revocation Policies implementiert
- [ ] Regular Security Reviews

## Monitoring

### Health Checks

```powershell
# Daily Health Check
Invoke-FasHealthCheck

# Certificate Issuance Monitoring
Get-WinEvent -LogName "Citrix-FederatedAuthenticationService/Admin" |
    Where-Object {$_.Id -eq 4886}
```

### Performance Monitoring

```powershell
# Performance Counters
Get-Counter -Counter "\Citrix FAS\Certificates Issued/sec"
Get-Counter -Counter "\Citrix FAS\Certificate Issuance Failures/sec"
```

## Contributing

Contributions sind willkommen! Bitte beachten Sie:

1. **PowerShell Best Practices** - PSScriptAnalyzer Clean
2. **Testing** - Alle Tests müssen erfolgreich sein
3. **Documentation** - Code Comments und README Updates
4. **Security** - Keine Credentials in Code

## Support

### Citrix Resources

- [FAS Documentation](https://docs.citrix.com/en-us/citrix-virtual-apps-desktops/secure/federated-authentication-service)
- [FAS Installation Guide](https://docs.citrix.com/en-us/federated-authentication-service/install-configure)
- [Citrix Support](https://support.citrix.com)

### Issues

Bei Problemen bitte GitHub Issues verwenden oder `/fas-troubleshoot` Command nutzen.

## License

MIT License - siehe [LICENSE](LICENSE) Datei für Details.

## Maintainer

**Dima Lejkin** - dima@lejkin.de

---

**Version:** 1.0
**Last Updated:** 2025-01-05

## Changelog

### Version 1.0 (2025-01-05)

- ✅ Initial Release
- ✅ 3 Core PowerShell Skripte
- ✅ 7 Claude Code Commands
- ✅ Comprehensive Testing Suite
- ✅ Backup & Recovery Procedures
- ✅ Troubleshooting Guide
