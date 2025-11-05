---
description: "Sichere FAS Installation und Deployment mit umfassenden Safety Checks"
---

# FAS Deployment Workflow

Du bist ein Citrix FAS Deployment Experte. Führe eine sichere, strukturierte FAS Installation durch.

## Pre-Deployment Checks

### 1. Umgebungsvalidierung
```powershell
# Prüfe Systemvoraussetzungen
$checks = @{
    'PowerShell Version' = $PSVersionTable.PSVersion.Major -ge 5
    'Domain Joined' = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
    'Admin Rights' = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$checks.GetEnumerator() | ForEach-Object {
    $status = if ($_.Value) { "✅" } else { "❌" }
    Write-Host "$status $($_.Key): $($_.Value)"
}
```

### 2. Netzwerk-Konnektivität
```powershell
# Teste Verbindung zu FAS Server
$fasServer = "fas-server.domain.local"
Test-NetConnection -ComputerName $fasServer -Port 443
Test-NetConnection -ComputerName $fasServer -Port 80
```

### 3. Certificate Authority Zugriff
```powershell
# Prüfe CA Erreichbarkeit
certutil -ping
```

## Deployment Phasen

### Phase 1: Deploy-FAS.ps1
**Zweck:** Initiale FAS Server Installation

**Schritte:**
1. FAS Binaries Installation
2. Service Account Konfiguration
3. Database Setup (falls erforderlich)
4. Firewall Regeln konfigurieren

**Sicherheitscheck vor Ausführung:**
- [ ] Backup der bestehenden Konfiguration erstellt
- [ ] Rollback-Plan dokumentiert
- [ ] Change-Ticket erstellt
- [ ] Wartungsfenster gebucht

```powershell
# Deployment mit Logging
.\scripts\Deploy-FAS.ps1 -Verbose -WhatIf
# Nach Überprüfung: ohne -WhatIf ausführen
.\scripts\Deploy-FAS.ps1 -Verbose | Tee-Object -FilePath "logs/deploy-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
```

### Phase 2: Configure-FAS.ps1
**Zweck:** FAS Server Basiskonfiguration

**Schritte:**
1. Verbindung zur Certificate Authority
2. Certificate Template Konfiguration
3. FAS Server Registration in Active Directory
4. Group Policy Einstellungen

```powershell
# Konfiguration mit Logging
.\scripts\Configure-FAS.ps1 -Verbose | Tee-Object -FilePath "logs/configure-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
```

### Phase 3: Configure-FAS-UserRules.ps1
**Zweck:** User Certificate Rules und Policies

**Schritte:**
1. User Certificate Rules erstellen
2. Security Group Mappings
3. Certificate Lifetime Policies
4. Revocation Rules

```powershell
# User Rules mit Logging
.\scripts\Configure-FAS-UserRules.ps1 -Verbose | Tee-Object -FilePath "logs/userrules-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
```

## Post-Deployment Validation

### 1. Service Status
```powershell
Get-Service -Name "CitrixFederatedAuthenticationService" | Format-List *
```

### 2. Certificate Template Validation
```powershell
certutil -CATemplates
```

### 3. Test User Certificate Issuance
```powershell
# Teste Certificate Ausstellung für Test-User
# (Implementierung im Skript)
```

### 4. Citrix Studio Integration
- [ ] FAS Server in Citrix Studio sichtbar
- [ ] StoreFront Integration erfolgreich
- [ ] Test-Login mit FAS erfolgreich

## Rollback Procedure

Falls Deployment fehlschlägt:

1. **Stop FAS Services**
   ```powershell
   Stop-Service -Name "CitrixFederatedAuthenticationService"
   ```

2. **Restore Backup Configuration**
   ```powershell
   # Restore aus Backup
   ```

3. **Deregister from AD**
   ```powershell
   # AD Objects entfernen
   ```

4. **Uninstall FAS**
   ```powershell
   # FAS deinstallieren
   ```

## Deployment Checklist

- [ ] Pre-Deployment Checks erfolgreich
- [ ] Backup erstellt
- [ ] Phase 1: Deploy-FAS.ps1 erfolgreich
- [ ] Phase 2: Configure-FAS.ps1 erfolgreich
- [ ] Phase 3: Configure-FAS-UserRules.ps1 erfolgreich
- [ ] Post-Deployment Validation erfolgreich
- [ ] Dokumentation aktualisiert
- [ ] Change-Ticket geschlossen

## Best Practices

- **Nie direkt in Production:** Teste immer in Test-Umgebung
- **Logging:** Umfassende Logs für Audit und Troubleshooting
- **Idempotenz:** Skripte sollten mehrfach ausführbar sein
- **Error Handling:** Graceful Failure mit klaren Error Messages
- **Monitoring:** Post-Deployment Monitoring für 48h
