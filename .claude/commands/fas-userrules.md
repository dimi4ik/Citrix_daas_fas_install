---
description: "Konfiguration von FAS User Certificate Rules und Security Policies"
---

# FAS User Rules Configuration

Du bist ein Citrix FAS Security Experte. Konfiguriere umfassende User Certificate Rules und Policies.

## User Certificate Rules Übersicht

FAS User Rules bestimmen:
- Welche User Certificates erhalten
- Certificate Lifetime pro User/Gruppe
- Certificate Template Zuordnung
- Revocation Policies

## Rule Configuration

### 1. Standard User Rule

**Basis-Regel für alle Domain Users:**
```powershell
# Importiere FAS Module
Import-Module Citrix.Authentication.FederatedAuthenticationService.V1

# Standard Rule für Domain Users
$standardRule = @{
    Name = "StandardUsers"
    Description = "Standard FAS certificates für alle Domain Users"
    Priority = 100
    UserFilter = "Domain Users"
    CertificateTemplate = "CitrixFAS_UserCert"
    CertificateLifetime = (New-TimeSpan -Hours 8)
    Enabled = $true
}

New-FasRule @standardRule
```

### 2. High-Security User Rule

**Verkürzte Lifetime für privilegierte Accounts:**
```powershell
# High-Security Rule für Admin Accounts
$highSecRule = @{
    Name = "HighSecurityUsers"
    Description = "Verkürzte Certificate Lifetime für Admins"
    Priority = 50  # Höhere Priority = frühere Evaluierung
    UserFilter = "Domain Admins,Enterprise Admins"
    CertificateTemplate = "CitrixFAS_AdminCert"
    CertificateLifetime = (New-TimeSpan -Hours 1)
    Enabled = $true
}

New-FasRule @highSecRule
```

### 3. External User Rule

**Spezielle Regeln für externe Mitarbeiter:**
```powershell
# External Users (z.B. Contractors)
$externalRule = @{
    Name = "ExternalUsers"
    Description = "FAS Certificates für externe Mitarbeiter"
    Priority = 75
    UserFilter = "External-Users"
    CertificateTemplate = "CitrixFAS_ExternalCert"
    CertificateLifetime = (New-TimeSpan -Hours 4)
    RequireSmartCard = $false
    Enabled = $true
}

New-FasRule @externalRule
```

### 4. VIP User Rule

**Extended Lifetime für VIP Users:**
```powershell
# VIP Users (z.B. C-Level)
$vipRule = @{
    Name = "VIPUsers"
    Description = "Extended Certificate Lifetime für VIPs"
    Priority = 25
    UserFilter = "VIP-Users"
    CertificateTemplate = "CitrixFAS_UserCert"
    CertificateLifetime = (New-TimeSpan -Hours 12)
    Enabled = $true
}

New-FasRule @vipRule
```

## Rule Priority Management

**Priority Logik:**
- Niedrigere Nummer = Höhere Priority
- Erste matchende Rule wird angewendet
- Default Rule sollte niedrigste Priority haben

```powershell
# Zeige alle Rules sortiert nach Priority
Get-FasRule | Sort-Object Priority | Format-Table Name, Priority, UserFilter, CertificateLifetime
```

**Empfohlene Priority-Struktur:**
```
Priority 10-20:  Deny Rules (Blacklist)
Priority 25-50:  Special Users (VIP, High-Security)
Priority 75-90:  Department-specific Rules
Priority 100+:   Default/Catch-all Rules
```

## User Filter Syntax

### AD Group Filter
```powershell
# Einzelne Gruppe
UserFilter = "CitrixUsers"

# Mehrere Gruppen (OR)
UserFilter = "CitrixUsers,RemoteWorkers,VDI-Users"

# Nested Groups (automatisch unterstützt)
UserFilter = "AllCitrixUsers"  # Schließt alle Nested Groups ein
```

### LDAP Filter
```powershell
# Advanced LDAP Filter
UserFilter = "(memberOf=CN=CitrixUsers,OU=Groups,DC=domain,DC=local)"

# Kombinierte Filter
UserFilter = "(&(memberOf=CN=CitrixUsers,OU=Groups,DC=domain,DC=local)(department=IT))"
```

## Certificate Template Mapping

### Template per Security Level

**Standard User Certificate:**
- Subject: User UPN
- Validity: 8 Stunden
- Key Size: 2048 bit
- Extended Key Usage: Client Authentication

**High-Security Certificate:**
- Subject: User UPN + Department
- Validity: 1 Stunde
- Key Size: 4096 bit
- Extended Key Usage: Client Authentication + Smart Card Logon
- Require Smart Card: Ja

**External Certificate:**
- Subject: User UPN + "External"
- Validity: 4 Stunden
- Key Size: 2048 bit
- Network Location Restriction: Ja

```powershell
# Template Assignment Übersicht
Get-FasRule | Select-Object Name, CertificateTemplate, UserFilter | Format-Table -AutoSize
```

## Revocation Policies

### Automatische Revocation

**Event-basierte Revocation:**
```powershell
# Revoke bei User Disable
$revocationPolicy = @{
    Name = "RevokeOnDisable"
    EventTrigger = "UserAccountDisabled"
    Action = "RevokeCertificate"
    NotifyAdmin = $true
}

New-FasRevocationPolicy @revocationPolicy
```

**Zeitbasierte Revocation:**
```powershell
# Revoke expired Certificates
$cleanupPolicy = @{
    Name = "CleanupExpired"
    Schedule = "Daily"
    Time = "02:00 AM"
    Action = "RevokeExpiredCertificates"
    RetentionDays = 30
}

New-FasRevocationPolicy @cleanupPolicy
```

### Manuelle Revocation

**Certificate für einzelnen User revoken:**
```powershell
# Revoke alle Certificates eines Users
Revoke-FasUserCertificate -UserPrincipalName "user@domain.local" -Reason "AccountCompromise"

# Revoke spezifisches Certificate
Revoke-FasUserCertificate -CertificateThumbprint "A1B2C3D4..." -Reason "SecurityIncident"
```

## Compliance und Audit

### Audit Logging

**Certificate Issuance Tracking:**
```powershell
# Aktiviere umfassendes Audit Logging
Set-FasAuditConfiguration -LogLevel "Verbose" -LogRetention 90

# Log Locations:
# - Certificate Issuance: Event ID 4886
# - Certificate Revocation: Event ID 4887
# - Rule Evaluation: Event ID 4888
```

### Compliance Reports

```powershell
# Generiere Compliance Report
$report = @{
    StartDate = (Get-Date).AddDays(-30)
    EndDate = Get-Date
    IncludeCertificateIssuance = $true
    IncludeRevocations = $true
    IncludeFailedAttempts = $true
    OutputPath = "C:\Reports\FAS-Compliance-$(Get-Date -Format 'yyyyMMdd').html"
}

New-FasComplianceReport @report
```

**Report Inhalte:**
- Total Certificates Issued
- Certificates per Rule
- Failed Issuance Attempts
- Revoked Certificates
- Average Certificate Lifetime
- User Distribution

## Security Best Practices

### 1. Least Privilege
```powershell
# Deny Rule für Service Accounts
$denyRule = @{
    Name = "DenyServiceAccounts"
    Description = "Service Accounts sollten keine FAS Certificates erhalten"
    Priority = 10
    UserFilter = "Service-Accounts"
    Action = "Deny"
    Enabled = $true
}

New-FasRule @denyRule
```

### 2. Certificate Lifetime Strategy

**Security vs. User Experience:**
- **Standard Users:** 8 Stunden (Balance)
- **Admin Accounts:** 1 Stunde (High Security)
- **External Users:** 4 Stunden (Medium Security)
- **Kiosk/Shared:** 30 Minuten (Sehr kurz)

### 3. Multi-Factor Authentication

```powershell
# MFA Requirement für High-Security Users
$mfaRule = @{
    Name = "MFA-Required"
    Priority = 30
    UserFilter = "High-Security-Users"
    RequireMFA = $true
    MFAMethod = "DuoPush,TOTPToken"
}

New-FasRule @mfaRule
```

## Rule Testing und Validation

### Test Rule Evaluation

```powershell
# Teste welche Rule für einen User angewendet wird
Test-FasRuleEvaluation -UserPrincipalName "testuser@domain.local" -Verbose

# Erwartete Ausgabe:
# Evaluating rules for: testuser@domain.local
# Rule 'HighSecurityUsers' (Priority: 50): No Match
# Rule 'ExternalUsers' (Priority: 75): No Match
# Rule 'StandardUsers' (Priority: 100): Match ✅
# Applied Rule: StandardUsers
# Certificate Template: CitrixFAS_UserCert
# Certificate Lifetime: 08:00:00
```

### Bulk User Testing

```powershell
# Teste Rules für alle User einer Gruppe
$testUsers = Get-ADGroupMember -Identity "CitrixUsers" | Select-Object -ExpandProperty SamAccountName

$results = foreach ($user in $testUsers) {
    $upn = "$user@domain.local"
    $rule = Test-FasRuleEvaluation -UserPrincipalName $upn

    [PSCustomObject]@{
        User = $upn
        AppliedRule = $rule.RuleName
        CertificateLifetime = $rule.CertificateLifetime
        Template = $rule.CertificateTemplate
    }
}

$results | Export-Csv -Path "FAS-Rule-Test-Results.csv" -NoTypeInformation
```

## Konfigurations-Checkliste

**Rule Setup:**
- [ ] Standard User Rule konfiguriert
- [ ] High-Security User Rule konfiguriert
- [ ] External User Rule konfiguriert (falls erforderlich)
- [ ] Deny Rules für Service Accounts
- [ ] Rule Priorities korrekt gesetzt

**Certificate Templates:**
- [ ] Templates in CA erstellt
- [ ] Templates published
- [ ] Permissions korrekt gesetzt
- [ ] Template-to-Rule Mapping dokumentiert

**Revocation:**
- [ ] Automatische Revocation Policies konfiguriert
- [ ] Manuelle Revocation getestet
- [ ] Cleanup Jobs geplant

**Audit:**
- [ ] Audit Logging aktiviert
- [ ] Log Retention konfiguriert
- [ ] Compliance Reports geplant
- [ ] Alert Notifications konfiguriert

## Troubleshooting

**User erhält kein Certificate:**
1. Prüfe Rule Evaluation: `Test-FasRuleEvaluation`
2. Prüfe AD Group Membership
3. Prüfe Certificate Template Permissions
4. Prüfe FAS Service Account Permissions

**Falsche Rule wird angewendet:**
1. Prüfe Rule Priority
2. Prüfe UserFilter Syntax
3. Prüfe für überlappende Rules
4. Teste mit `-Verbose` Flag

**Certificate Lifetime nicht korrekt:**
1. Prüfe Rule Certificate Lifetime Setting
2. Prüfe CA Maximum Validity Override
3. Prüfe Group Policy Settings
