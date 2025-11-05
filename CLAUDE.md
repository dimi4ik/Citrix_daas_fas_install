# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Primary Goal**: Citrix Federated Authentication Service (FAS) Installation und Konfiguration
**Current Status**: PowerShell-basierte FAS Deployment Automation
**Target Platform**: Windows Server mit Active Directory und Certificate Authority Integration
**Core Technologies**: PowerShell, Citrix FAS, Active Directory, PKI/Certificate Services

## Repository Purpose

Dieses Repository enthält **PowerShell-basierte Automatisierung** für die Citrix FAS Installation, Konfiguration und Verwaltung. FAS ermöglicht Single Sign-On für Citrix Virtual Apps and Desktops durch automatische Certificate-basierte Authentifizierung.

### Was ist Citrix FAS?

**Federated Authentication Service (FAS):**
- Ersetzt traditionelle Smartcard-Authentifizierung
- Automatische User Certificate Issuance
- Integration mit Certificate Authority (Microsoft CA)
- Nahtlose SSO Experience für Citrix Benutzer
- Keine Smartcard Hardware erforderlich

## Repository Architecture

### PowerShell Skripte (Hauptfokus)

**Die 3 Core PowerShell Skripte:**

1. **`scripts/Deploy-FAS.ps1`** - FAS Server Installation
   - FAS Binaries Installation
   - Service Account Konfiguration
   - Database Setup
   - Firewall Regeln

2. **`scripts/Configure-FAS.ps1`** - FAS Basis-Konfiguration
   - Certificate Authority Integration
   - Certificate Template Konfiguration
   - Active Directory Integration
   - StoreFront Integration

3. **`scripts/Configure-FAS-UserRules.ps1`** - User Certificate Rules
   - User Certificate Policies
   - Security Group Mappings
   - Certificate Lifetime Rules
   - Revocation Policies

### Verzeichnisstruktur

```
.
├── scripts/                    # PowerShell Skripte (HAUPTFOKUS)
│   ├── Deploy-FAS.ps1
│   ├── Configure-FAS.ps1
│   └── Configure-FAS-UserRules.ps1
├── .claude/commands/          # 7 FAS-spezifische Claude Commands
│   ├── fas-validate.md        # PowerShell Syntax & Konfigurations-Validierung
│   ├── fas-deploy.md          # Sichere FAS Installation
│   ├── fas-configure.md       # FAS Server Konfiguration
│   ├── fas-userrules.md       # User Certificate Rules
│   ├── fas-test.md            # Umfassende Test-Suite
│   ├── fas-troubleshoot.md    # Troubleshooting Guide
│   └── fas-backup.md          # Backup & Disaster Recovery
├── docs/                      # Dokumentation
├── config/                    # Konfigurationsdateien (JSON)
└── logs/                      # Deployment und Audit Logs
```

## Claude Code Commands - FAS Focus

### Ultra-fokussierte FAS Commands (7 Core Commands)

#### 1. `/fas-validate` - PowerShell & Configuration Validation
**Verwendung:** Validiere PowerShell Syntax, PSScriptAnalyzer, Konfigurationsdateien

**Was wird validiert:**
- PowerShell Syntax (Parser)
- PSScriptAnalyzer (Best Practices)
- JSON Konfigurationsdateien
- Umgebungsvoraussetzungen
- Security Checks

#### 2. `/fas-deploy` - Safe FAS Installation
**Verwendung:** Strukturierte FAS Installation mit Safety Checks

**Deployment Phasen:**
1. Pre-Deployment Checks
2. Deploy-FAS.ps1 Execution
3. Configure-FAS.ps1 Execution
4. Configure-FAS-UserRules.ps1 Execution
5. Post-Deployment Validation

#### 3. `/fas-configure` - FAS Server Configuration
**Verwendung:** Detaillierte FAS Server Konfiguration

**Konfigurations-Bereiche:**
- Certificate Authority Integration
- Certificate Templates
- Active Directory Integration
- StoreFront Integration

#### 4. `/fas-userrules` - User Certificate Rules
**Verwendung:** User Certificate Policies und Rules

**Rule Management:**
- Standard/High-Security/External User Rules
- Rule Priority Management
- Certificate Lifetime Policies
- Revocation Policies

#### 5. `/fas-test` - Comprehensive Testing
**Verwendung:** Umfassende Tests der FAS Installation

**Test-Kategorien:**
- Infrastructure Tests
- Configuration Tests
- Certificate Issuance Tests
- Security Tests
- Performance Tests

#### 6. `/fas-troubleshoot` - Advanced Troubleshooting
**Verwendung:** Systematische Problemanalyse

**Troubleshooting Areas:**
- Certificate Issuance Failures
- Service Issues
- Authentication Failures
- Performance Problems

#### 7. `/fas-backup` - Backup & Recovery
**Verwendung:** Backup und Disaster Recovery

**Backup Components:**
- FAS Configuration
- Certificate Templates
- User Rules
- Certificates

## PowerShell Best Practices

### Code Quality Standards

```powershell
# Immer verwenden:
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Try/Catch für Error Handling
try {
    # Operations
} catch {
    Write-Error "Failed: $($_.Exception.Message)"
}

# Comprehensive Logging
$logFile = "logs/deploy-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
```

### Parameter Validation

```powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$CertificateAuthority,

    [ValidateRange(1, 24)]
    [int]$CertificateLifetimeHours = 8
)
```

### WhatIf Support

```powershell
[CmdletBinding(SupportsShouldProcess=$true)]
param()

if ($PSCmdlet.ShouldProcess("FAS Server", "Deploy")) {
    # Deployment Logic
}
```

## Security Guidelines

### Critical Security Requirements

1. **No Hardcoded Credentials:**
```powershell
# ✅ Correct:
$credential = Get-Credential -Message "Enter credentials"
```

2. **Certificate Security:**
- Private Keys never in logs
- Secure Certificate Storage
- 8 hour Certificate Lifetime

3. **Service Account Security:**
- Least Privilege
- Dedicated Service Account
- Regular Password Rotation

4. **Audit Logging:**
```powershell
Set-FasAuditConfiguration -LogLevel "Verbose" -LogRetention 90
```

## FAS Architecture

### Authentication Flow

```
StoreFront → FAS Server → Certificate Authority
     ↓            ↓               ↓
     └───→ Active Directory ←────┘
                  ↓
              VDA (Session)
```

**Flow Steps:**
1. User authenticates at StoreFront
2. FAS requests Certificate from CA
3. CA issues short-lived Certificate (8h)
4. Certificate delivered to VDA
5. VDA uses Certificate for Kerberos
6. Session starts (SSO)

## User Preferences (dima@lejkin.de)

### Communication
- **Primary Language:** Deutsch
- **Code Language:** English
- **Response Style:** Direkt, präzise

### Development Workflow
1. Planning First (markdown in `docs/`)
2. Todo Management (TodoWrite)
3. Modular Implementation
4. Testing with `-WhatIf`
5. Documentation Updates

### Git Preferences
- **Commit Style:** Conventional Commits (Deutsch)
- **Format:** `feat: Description`, `fix: Description`
- **No Co-Author Lines**
- **No Claude Branding**
- **Branch Management:** Feature Branches

## Testing Strategy

### Test Execution

```powershell
# Run all tests
Invoke-Pester -Path .\tests\ -Output Detailed

# Run specific test
Invoke-Pester -Path .\tests\Certificate-Issuance.Tests.ps1
```

## Quality Assurance

### Pre-Deployment Checklist
- [ ] PowerShell Syntax Validation
- [ ] PSScriptAnalyzer Clean
- [ ] Configuration Files Validated
- [ ] Security Check
- [ ] Backup Created
- [ ] Test Environment Success

### Post-Deployment Validation
- [ ] FAS Service Running
- [ ] CA Connectivity OK
- [ ] Certificate Test Success
- [ ] StoreFront Integration OK
- [ ] End-to-End Test Success
- [ ] Logging Functional

## Tool Usage Policy

### Claude Code Workflows
- **Slash Commands:** Use FAS-specific commands
- **TodoWrite:** For complex deployments
- **Read/Write Tools:** For PowerShell editing
- **Bash:** Only for git operations

### PowerShell Execution

```powershell
# Development/Testing:
.\scripts\Deploy-FAS.ps1 -WhatIf -Verbose

# Production:
.\scripts\Deploy-FAS.ps1 -Verbose | Tee-Object -FilePath "logs/deploy.log"
```

## Important Reminders

### Core Rules
- Do only what has been asked
- NEVER create files unless necessary
- ALWAYS prefer editing over creating
- NEVER proactively create documentation

### PowerShell-Specific Rules

When "zusätzlich" or "ohne bestehende zu ändern":
1. NEVER modify existing functions
2. NEVER change existing parameters
3. ONLY add new, separate functions
4. Always ask for confirmation

## Monitoring & Maintenance

### Service Monitoring

```powershell
# Health Check
Get-Service -Name "CitrixFederatedAuthenticationService"

# Certificate Issuance Monitoring
Get-WinEvent -LogName "Citrix-FederatedAuthenticationService/Admin"
```

### Maintenance Tasks
- **Daily:** Automated Backup
- **Daily:** Health Check
- **Weekly:** Template Review
- **Monthly:** User Rules Review
- **Monthly:** Restore Test

## Troubleshooting Quick Reference

| Issue | Command | Check |
|-------|---------|-------|
| Certificate Issuance Failed | `/fas-troubleshoot` | CA, Template, Account |
| Service Won't Start | `/fas-troubleshoot` | Database, Ports, Config |
| Authentication Failed | `/fas-test` | Rules, AD Account |
| Performance Issues | `/fas-test` | CA, Network, Cache |

## Resources

### Citrix Documentation
- [FAS Architecture](https://docs.citrix.com/en-us/citrix-virtual-apps-desktops/secure/federated-authentication-service)
- [FAS Installation](https://docs.citrix.com/en-us/federated-authentication-service/install-configure)

### PowerShell Resources
- [PowerShell Best Practices](https://poshcode.gitbook.io/powershell-practice-and-style/)
- [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)
- [Pester Testing](https://pester.dev/)

---

**Version:** 1.0 - Citrix FAS PowerShell Focus
**Last Updated:** 2025-01-05
**Maintainer:** dima@lejkin.de
