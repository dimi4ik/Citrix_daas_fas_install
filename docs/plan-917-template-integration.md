# Implementierungsplan: 917Citrix_SmartcardLogon Template Integration

**Datum:** 2025-11-05
**Ziel:** Integration des Custom Certificate Templates `917Citrix_SmartcardLogon` in FAS PowerShell-Automatisierung
**Status:** PLANUNG

---

## 📊 Template-Spezifikationen (aus Demo-Umgebung)

### Template-Details aus certutil-Ausgabe:

| Parameter | Wert | Beschreibung |
|-----------|------|--------------|
| **Template Name** | `917Citrix_SmartcardLogon` | Custom Template Name |
| **Schema Version** | 4 | Windows Server 2012 R2+ / Windows 10+ |
| **Major Revision** | 100 (0x64) | Template Version |
| **Minor Revision** | 4 | Update-Zähler |
| **Hash Algorithm** | SHA256 | Moderne Hash-Funktion |
| **Asymmetric Algorithm** | RSA | Public Key Algorithm |
| **Key Size** | 2048 bit | RSA Schlüssellänge |
| **RA Signature Count** | 1 | **KRITISCH für FAS!** |
| **Validity Period** | **1 Week** | Test/Demo (Production: 1 Jahr) |
| **Renewal Period** | 0 Seconds | Keine Auto-Renewal |
| **Subject Name Flags** | 0x82000000 | UPN + AD Directory Path |
| **Enrollment Flags** | 0x20 | Auto-Enrollment aktiviert |
| **Private Key Flags** | 0x6060000 | Server/Client Version Thresholds |

### Extended Key Usages (EKUs):
- ✅ `1.3.6.1.5.5.7.3.2` - Client Authentication
- ✅ `1.3.6.1.4.1.311.20.2.2` - Smart Card Logon

### Key Usage:
- ✅ Digital Signature
- ✅ Key Encipherment

### Crypto Provider:
- ✅ **Microsoft Software Key Storage Provider** (CNG)
- ✅ Microsoft Platform Crypto Provider (TPM-fähig, optional)

---

## 🎯 Implementierungsstrategie

### Entscheidungen:

1. **Template-Deployment:**
   - ❌ **Altes Template `Citrix_SmartCardLogon` NICHT deployen**
   - ✅ **Nur neues Template `917Citrix_SmartcardLogon` deployen**
   - ✅ `Citrix_RegistrationAuthority` bleibt unverändert

2. **Validity Period:**
   - ✅ **1 Woche** (Test/Demo-Umgebung)
   - ⚠️ **Production:** Auf 1 Jahr ändern!

3. **Crypto Provider:**
   - ✅ **Microsoft Software Key Storage Provider** (Standard CNG)

---

## 📝 Änderungen an PowerShell-Skripten

### 1. Configure-FAS.ps1

#### Betroffene Funktion: `Configure-FAS`

#### Aktuelle Implementierung (Standard Citrix):
```powershell
# Certificate Templates deployen
$TemplateParams = @{
    Address = $FASAddress
    SecurityGroupSID = $FASSecurityGroupSID
}

# ORIGINAL: Beide Citrix Templates
New-FasMsTemplate -Name "Citrix_SmartCardLogon" @TemplateParams
New-FasMsTemplate -Name "Citrix_RegistrationAuthority" @TemplateParams
```

#### NEUE Implementierung (Custom Template):
```powershell
# Certificate Templates deployen
$TemplateParams = @{
    Address = $FASAddress
    SecurityGroupSID = $FASSecurityGroupSID
}

# ❌ ENTFERNT: Altes Citrix Template
# New-FasMsTemplate -Name "Citrix_SmartCardLogon" @TemplateParams

# ✅ NEU: Custom Template 917Citrix_SmartcardLogon
New-FasMsTemplate -Name "917Citrix_SmartcardLogon" @TemplateParams

# ✅ UNVERÄNDERT: Citrix Registration Authority Template
New-FasMsTemplate -Name "Citrix_RegistrationAuthority" @TemplateParams
```

#### Erweiterte Parameter (Optional - für explizite Konfiguration):
```powershell
# Falls New-FasMsTemplate erweiterte Parameter unterstützt:
$CustomTemplateParams = @{
    Address = $FASAddress
    Name = "917Citrix_SmartcardLogon"
    SecurityGroupSID = $FASSecurityGroupSID

    # Template-spezifische Parameter (falls unterstützt von FAS SDK):
    # KeySize = 2048
    # HashAlgorithm = "SHA256"
    # ValidityPeriod = "1 Week"
    # SchemaVersion = 4
}

New-FasMsTemplate @CustomTemplateParams
```

**Hinweis:** Die Citrix FAS PowerShell SDK Version bestimmt, welche Parameter verfügbar sind. Basiskonfiguration verwendet nur Name + SecurityGroupSID.

---

### 2. Configure-FAS-UserRules.ps1

#### Betroffene Funktion: `Configure-FAS-UserRules`

#### Aktuelle Implementierung:
```powershell
# Certificate Definition erstellen
$CertDefParams = @{
    Address = $FASAddress
    Name = "default_Definition"
    MsTemplate = "Citrix_SmartCardLogon"  # ← ALTES TEMPLATE
    CertificateAuthority = $CertificateAuthority
    AuthorizationCertificateId = $AuthCertGuid
}

New-FasCertificateDefinition @CertDefParams
```

#### NEUE Implementierung:
```powershell
# Certificate Definition erstellen
$CertDefParams = @{
    Address = $FASAddress
    Name = "default_Definition"
    MsTemplate = "917Citrix_SmartcardLogon"  # ← NEUES TEMPLATE
    CertificateAuthority = $CertificateAuthority
    AuthorizationCertificateId = $AuthCertGuid
}

New-FasCertificateDefinition @CertDefParams
```

**Änderung:** Nur Template-Name von `Citrix_SmartCardLogon` → `917Citrix_SmartcardLogon`

---

### 3. Deploy-FAS.ps1

#### Status: **KEINE ÄNDERUNGEN ERFORDERLICH**

Deploy-FAS.ps1 installiert nur die FAS Server Software (MSI) und konfiguriert keine Templates.

---

## ✅ Validierungs-Schritte

### Nach Anpassung der Skripte:

#### 1. PowerShell Syntax-Validierung
```powershell
# Syntax Check
Get-Command -Syntax New-FasMsTemplate
Get-Command -Syntax New-FasCertificateDefinition

# Skript-Syntax prüfen
$null = [System.Management.Automation.PSParser]::Tokenize((Get-Content .\scripts\Configure-FAS.ps1 -Raw), [ref]$null)
$null = [System.Management.Automation.PSParser]::Tokenize((Get-Content .\scripts\Configure-FAS-UserRules.ps1 -Raw), [ref]$null)
```

#### 2. Template-Deployment validieren (nach Ausführung)
```powershell
# Templates in Active Directory prüfen
Get-ADObject -Filter {Name -eq "917Citrix_SmartcardLogon"} `
    -SearchBase "CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=m917,DC=local" `
    -Properties DisplayName, msPKI-Template-Schema-Version

# Erwartete Ausgabe:
# DisplayName: 917Citrix_SmartcardLogon
# msPKI-Template-Schema-Version: 4
```

#### 3. CA Template-Publishing prüfen
```powershell
# Templates auf CA prüfen
certutil -CATemplates

# Sollte enthalten:
# 917Citrix_SmartcardLogon
# Citrix_RegistrationAuthority
```

#### 4. FAS Certificate Definition prüfen
```powershell
# Certificate Definitions anzeigen
Get-FasCertificateDefinition -Address "FAS-SERVER.domain.com"

# Erwartete Ausgabe:
# Name: default_Definition
# MsTemplate: 917Citrix_SmartcardLogon
# CertificateAuthority: CA-SERVER.domain.com
```

#### 5. End-to-End Test (Certificate Issuance)
```powershell
# FAS Rules validieren
Get-FasRule -Address "FAS-SERVER.domain.com"

# Test Certificate Request (falls Test-Cmdlet verfügbar)
# Test-FasCertificateIssuance -Address "FAS-SERVER.domain.com" -UserName "testuser"
```

---

## 🔄 Migrations-Workflow

### Schritt 1: Backup erstellen
```powershell
# Aktuelle Konfiguration sichern
$BackupPath = "C:\Backup\FAS_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -Path $BackupPath -ItemType Directory

# FAS Configuration exportieren
Get-FasRule -Address "FAS-SERVER.domain.com" | Export-Clixml "$BackupPath\FasRules.xml"
Get-FasCertificateDefinition -Address "FAS-SERVER.domain.com" | Export-Clixml "$BackupPath\FasCertDefinitions.xml"
Get-FasAuthorizationCertificate -Address "FAS-SERVER.domain.com" | Export-Clixml "$BackupPath\FasAuthCert.xml"
```

### Schritt 2: PowerShell-Skripte anpassen
```bash
# Configure-FAS.ps1 bearbeiten
# → Template-Name von "Citrix_SmartCardLogon" zu "917Citrix_SmartcardLogon"

# Configure-FAS-UserRules.ps1 bearbeiten
# → MsTemplate-Parameter auf "917Citrix_SmartcardLogon" setzen
```

### Schritt 3: Template-Deployment (Test-Umgebung)
```powershell
# In Test-Umgebung ausführen:
. .\scripts\Configure-FAS.ps1

Configure-FAS `
    -CertificateAuthority @("CA-SERVER.domain.com") `
    -FASAddress "FAS-SERVER.domain.com" `
    -FASSecurityGroupSID "S-1-5-21-xxx-xxx-xxx-xxxx"
```

### Schritt 4: User Rules aktualisieren
```powershell
# User Rules mit neuem Template erstellen
. .\scripts\Configure-FAS-UserRules.ps1

Configure-FAS-UserRules `
    -StoreFrontPermissions $StoreFrontPermissions `
    -VDAPermissions $VDAPermissions `
    -UserPermissions $UserPermissions `
    -CertificateAuthority @("CA-SERVER.domain.com") `
    -FASAddress "FAS-SERVER.domain.com"
```

### Schritt 5: Validierung
```powershell
# Alle Validierungs-Schritte durchführen (siehe oben)
```

---

## ⚠️ Wichtige Hinweise

### 1. Template bereits in AD vorhanden
Das Template `917Citrix_SmartcardLogon` wurde **manuell in der Demo-Umgebung erstellt**.

**Wichtig:** `New-FasMsTemplate` wird:
- ✅ **Template verwenden**, falls es bereits existiert
- ❌ **Fehler werfen**, falls Template fehlt
- ⚠️ **Template NICHT überschreiben** (nur Berechtigungen setzen)

### 2. RA Signature Count = 1
```
TemplatePropRASignatureCount = 1
```
**KRITISCH:** Dies bedeutet, dass FAS als **Registration Authority** agiert und Zertifikate im Namen von Benutzern ausstellen kann. Dies ist **essentiell für FAS-Funktionalität**.

### 3. Validity Period: 1 Woche
```
TemplatePropValidityPeriod = 1 Weeks
```
**Warnung:** In Production sollte dies auf **1 Jahr** geändert werden:
- Test/Demo: 1 Woche ✅
- Production: 52 Wochen (1 Jahr) ⚠️

**Änderung in Certificate Template:**
```powershell
# In Demo-Umgebung (auf CA-Server):
certutil -setreg ca\ValidityPeriodUnits 52
certutil -setreg ca\ValidityPeriod "Weeks"
net stop certsvc && net start certsvc
```

### 4. Security Descriptor
```
Allow Enroll: M917\Domain Admins
Allow Enroll: M917\Domain Computers
Allow Full Control: M917\administrator
```

**Wichtig:** `New-FasMsTemplate` wird die Security-Berechtigungen basierend auf `$FASSecurityGroupSID` setzen.

---

## 🧪 Testing-Plan

### Test-Szenarien:

#### Test 1: Template-Deployment
- [ ] `New-FasMsTemplate` erfolgreich für `917Citrix_SmartcardLogon`
- [ ] Template in AD sichtbar
- [ ] Berechtigungen korrekt gesetzt

#### Test 2: CA-Integration
- [ ] `Publish-FasMsTemplate` erfolgreich
- [ ] Template auf CA verfügbar
- [ ] CA kann Zertifikate ausstellen

#### Test 3: Certificate Definition
- [ ] `New-FasCertificateDefinition` mit neuem Template erfolgreich
- [ ] FAS GUI zeigt `917Citrix_SmartcardLogon` an
- [ ] Definition ist aktiv

#### Test 4: Certificate Issuance
- [ ] Test-User kann Zertifikat anfordern
- [ ] Zertifikat wird mit SHA256 + RSA 2048 ausgestellt
- [ ] Zertifikat ist 1 Woche gültig
- [ ] EKUs sind korrekt (Client Auth + Smart Card Logon)

#### Test 5: End-to-End SSO
- [ ] StoreFront kann FAS-Zertifikat anfordern
- [ ] VDA akzeptiert FAS-Zertifikat
- [ ] User kann sich ohne weitere Passwort-Eingabe anmelden

---

## 📚 Referenzen

### Citrix FAS PowerShell SDK Cmdlets:
- `New-FasMsTemplate` - [SDK Docs](https://developer-docs.citrix.com/projects/federated-authentication-service-powershell-sdk/en/latest/)
- `Publish-FasMsTemplate`
- `New-FasCertificateDefinition`
- `Get-FasAuthorizationCertificate`

### Certificate Template Properties:
- **msPKI-Template-Schema-Version**: Schema Version (4 = modernste)
- **msPKI-Minimal-Key-Size**: RSA Key Size in Bits
- **msPKI-RA-Signature**: Registration Authority Signature Count
- **pKIDefaultCSPs**: Crypto Service Providers
- **msPKI-Certificate-Name-Flag**: Subject Name Format

### Wichtige Event Log IDs:
- **Event ID 1000**: FAS Service gestartet
- **Event ID 1001**: Certificate erfolgreich ausgestellt
- **Event ID 2000**: Fehler bei Certificate Issuance
- **Event ID 5000**: Template-Deployment erfolgreich

---

## 🚀 Nächste Schritte

1. **Plan Review** - Diesen Plan mit dem Team reviewen
2. **Skript-Anpassung** - PowerShell-Skripte gemäß Plan anpassen
3. **Test-Deployment** - In Test-Umgebung ausführen
4. **Validierung** - Alle Test-Szenarien durchführen
5. **Dokumentation** - README.md und FAS-Anleitung aktualisieren
6. **Production-Rollout** - Nach erfolgreichen Tests in Production deployen

---

**Version:** 1.0
**Erstellt:** 2025-11-05
**Maintainer:** dima@lejkin.de
**Status:** BEREIT FÜR IMPLEMENTIERUNG ✅
