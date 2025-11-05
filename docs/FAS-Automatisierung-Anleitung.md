# Citrix FAS Automatisierung - Einfache Anleitung

## 📋 Inhaltsverzeichnis

1. [Was ist Citrix FAS?](#was-ist-citrix-fas)
2. [Warum PowerShell-Automatisierung?](#warum-powershell-automatisierung)
3. [Überblick: Die 3 PowerShell-Skripte](#überblick-die-3-powershell-skripte)
4. [Voraussetzungen](#voraussetzungen)
5. [Schritt-für-Schritt-Anleitung](#schritt-für-schritt-anleitung)
   - [Schritt 1: Software Installation](#schritt-1-software-installation-deploy-fasps1)
   - [Schritt 2: Basis-Konfiguration](#schritt-2-basis-konfiguration-configure-fasps1)
   - [Schritt 3: Benutzer-Regeln](#schritt-3-benutzer-regeln-configure-fas-userrulesps1)
6. [Was passiert im Hintergrund?](#was-passiert-im-hintergrund)
7. [Fehlersuche und Validierung](#fehlersuche-und-validierung)
8. [Wichtige Sicherheitshinweise](#wichtige-sicherheitshinweise)
9. [Weiterführende Ressourcen](#weiterführende-ressourcen)

---

## Was ist Citrix FAS?

**Citrix Federated Authentication Service (FAS)** ist ein Dienst, der **Single Sign-On (SSO)** für Citrix Virtual Apps and Desktops ermöglicht.

### In einfachen Worten:

- **Problem:** Benutzer müssen sich mehrfach anmelden (z.B. an Windows, dann nochmal an Citrix)
- **Lösung:** FAS erstellt automatisch digitale Zertifikate für Benutzer
- **Ergebnis:** Benutzer melden sich nur einmal an (mit SAML, Azure AD, etc.) und haben automatisch Zugriff auf alle Citrix-Ressourcen

**Wichtig:** FAS ersetzt die traditionelle Smartcard-Authentifizierung, **ohne dass physische Smartcards benötigt werden**.

---

## Warum PowerShell-Automatisierung?

### Manuelle Installation vs. Automatisierung

| Manuelle Installation | PowerShell-Automatisierung |
|-----------------------|----------------------------|
| ⏰ Zeitaufwändig (mehrere Stunden) | ⚡ Schnell (wenige Minuten) |
| ❌ Fehleranfällig | ✅ Konsistent und wiederholbar |
| 📝 Dokumentation aufwändig | 📋 Selbstdokumentierend |
| 🔄 Upgrades kompliziert | 🚀 Einfach wiederholbar |

**DevOps-Ansatz:** Einmal schreiben, mehrfach verwenden → Zeit sparen, Fehler reduzieren!

---

## Überblick: Die 3 PowerShell-Skripte

Die FAS-Installation wird in **3 logische Schritte** aufgeteilt:

```
┌─────────────────────────────────────────────────────────┐
│  SCHRITT 1: Deploy-FAS.ps1                              │
│  ───────────────────────────────────────────────────    │
│  → Installiert FAS Server Software (MSI)                │
│  → Richtet Dienste ein                                  │
│  → Prüft erfolgreiche Installation                      │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│  SCHRITT 2: Configure-FAS.ps1                           │
│  ───────────────────────────────────────────────────    │
│  → Erstellt Zertifikats-Vorlagen (Certificate Templates)│
│  → Verbindet mit Certificate Authority (CA)             │
│  → Autorisiert FAS Server                               │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│  SCHRITT 3: Configure-FAS-UserRules.ps1                 │
│  ───────────────────────────────────────────────────    │
│  → Definiert Benutzer-Berechtigungen                    │
│  → Konfiguriert StoreFront-Zugriff                      │
│  → Konfiguriert VDA-Zugriff                             │
└─────────────────────────────────────────────────────────┘
```

---

## Voraussetzungen

### 🖥️ Systemanforderungen

- **Windows Server** (2016 oder neuer)
- **Active Directory** Domain-Umgebung
- **Certificate Authority (CA)** installiert und konfiguriert
- **Citrix StoreFront** bereits installiert
- **Citrix Virtual Delivery Agents (VDAs)** bereits installiert

### 👤 Berechtigungen (Wichtig!)

Der Benutzer, der die Skripte ausführt, benötigt:

1. **Lokale Administrator-Rechte** auf dem FAS-Server
2. **Enterprise Forest Administrator** (für Certificate Templates)
3. **Certificate Authority Administrator** (für CA-Konfiguration)

> ⚠️ **Warnung:** Ohne diese Berechtigungen werden die Skripte fehlschlagen!

### 📦 Software-Anforderungen

- **FAS MSI-Datei** (von Citrix ISO)
  - Typischer Pfad: `D:\x64\Federated Authentication Service\FederatedAuthenticationService_x64.msi`
- **PowerShell 5.1 oder höher**
- **Citrix FAS PowerShell SDK** (wird mit FAS installiert)

---

## Schritt-für-Schritt-Anleitung

### Schritt 1: Software Installation (`Deploy-FAS.ps1`)

#### Was macht dieses Skript?

1. **Installiert** FAS Server über die MSI-Datei
2. **Wartet** auf Abschluss der Installation
3. **Prüft** Event Viewer Logs auf Erfolg
4. **Verifiziert** Installation im Startmenü

#### Wie benutze ich es?

**Einfaches Beispiel:**

```powershell
# 1. PowerShell als Administrator öffnen

# 2. Zum Skript-Verzeichnis navigieren
cd C:\Citrix_FAS_Scripts

# 3. Skript "dot-sourcen" (laden)
. .\Deploy-FAS.ps1

# 4. Funktion ausführen mit Pfad zur MSI
Deploy-FAS -FASMSIPath "D:\x64\Federated Authentication Service\FederatedAuthenticationService_x64.msi"
```

**Was du sehen wirst:**
```
Starting FAS installation...
Installation process started (Process ID: 1234)
Waiting for installation to complete...
Installation completed successfully!
Checking Event Viewer logs...
✓ FAS Server installed successfully!
```

#### Was wird NICHT automatisch gemacht?

⚠️ **Firewall-Regeln** werden NICHT automatisch konfiguriert (anders als beim GUI-Installer)

**Manuelle Firewall-Konfiguration erforderlich:**
- Port **80** (HTTP) - StoreFront Kommunikation
- Port **443** (HTTPS) - Sichere Kommunikation
- [Vollständige Firewall-Regeln](https://docs.citrix.com/en-us/federated-authentication-service/install-configure.html#step-2-configure-windows-firewall)

---

### Schritt 2: Basis-Konfiguration (`Configure-FAS.ps1`)

#### Was macht dieses Skript?

Dieser Schritt entspricht dem **"Initial Setup"** Tab in der FAS GUI und führt 3 wichtige Aufgaben aus:

1. **Deploy Certificate Templates**
   - Erstellt Zertifikats-Vorlagen in Active Directory
   - Setzt Berechtigungen für FAS Server

2. **Setup Certificate Authority**
   - Verbindet FAS mit der Certificate Authority (CA)
   - Autorisiert CA zum Ausstellen von FAS-Zertifikaten

3. **Authorize FAS Server**
   - Beantragt ein Autorisierungs-Zertifikat
   - FAS kann nun Zertifikate im Namen von Benutzern ausstellen

#### Wie benutze ich es?

**Einfaches Beispiel:**

```powershell
# 1. PowerShell als Administrator öffnen

# 2. Skript laden
. .\Configure-FAS.ps1

# 3. Parameter vorbereiten
$CAServers = @("CA-SERVER-01.domain.com")  # Dein CA-Server Name
$FASServerFQDN = "FAS-SERVER-01.domain.com"  # Dein FAS-Server Name
$FASSecurityGroupSID = "S-1-5-21-xxxxxxxxxx-xxxxxxxxxx-xxxxxxxxxx-xxxx"  # SID der FAS Security Group

# 4. Funktion ausführen
Configure-FAS -CertificateAuthority $CAServers `
              -FASAddress $FASServerFQDN `
              -FASSecurityGroupSID $FASSecurityGroupSID
```

#### Wie finde ich die Security Group SID?

```powershell
# PowerShell-Befehl zum Finden der SID:
$group = Get-ADGroup -Identity "FAS_Servers"  # Dein Security Group Name
$group.SID.Value
```

#### Was passiert im Hintergrund?

```
┌─────────────────────────────────────────────┐
│ 1. New-FasMsTemplate                        │
│    → Zertifikats-Vorlagen in AD deployen    │
│    → Templates: Citrix_SmartCardLogon,      │
│      Citrix_RegistrationAuthority           │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ 2. Publish-FasMsTemplate                    │
│    → CA autorisieren für Templates          │
│    → CA kann jetzt Zertifikate ausstellen   │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ 3. New-FasAuthorizationCertificate          │
│    → Autorisierungs-Zertifikat beantragen   │
│    → FAS wird zum "Registration Authority"  │
│    → Automatische Genehmigung des Antrags   │
└─────────────────────────────────────────────┘
```

#### Was sollte ich sehen?

Nach erfolgreicher Ausführung:

1. **FAS GUI öffnen**
2. **Initial Setup Tab**: Alle 3 Balken sollten **grün** sein ✅
   - ✅ Deploy Certificate Templates
   - ✅ Setup Certificate Authority
   - ✅ Authorize this Service

#### Validierung:

```powershell
# Autorisierungs-Zertifikat prüfen:
Get-FasAuthorizationCertificate -Address "FAS-SERVER-01.domain.com"
```

**Erwartete Ausgabe:**
```
Id              : 12345678-1234-1234-1234-123456789012
Subject         : CN=FAS-SERVER-01
Issuer          : CN=CA-SERVER-01
NotBefore       : 05.01.2025 10:00:00
NotAfter        : 05.01.2026 10:00:00
Thumbprint      : ABCDEF1234567890...
```

---

### Schritt 3: Benutzer-Regeln (`Configure-FAS-UserRules.ps1`)

#### Was macht dieses Skript?

Dieses Skript definiert **wer darf was**:

- **Welche Benutzer** dürfen FAS-Zertifikate erhalten?
- **Welche StoreFront-Server** dürfen Zertifikate anfordern?
- **Welche VDA-Maschinen** dürfen Zertifikate verwenden?

#### Wie benutze ich es?

**Einfaches Beispiel:**

```powershell
# 1. Skript laden
. .\Configure-FAS-UserRules.ps1

# 2. StoreFront-Berechtigungen definieren
$StoreFrontPermissions = @(
    @{
        SID = "S-1-5-21-xxxxxxxxxx-xxxxxxxxxx-xxxxxxxxxx-1001"  # StoreFront Server SID
        Permission = "Allow"
    }
)

# 3. VDA-Berechtigungen definieren
$VDAPermissions = @(
    @{
        SID = "S-1-5-21-xxxxxxxxxx-xxxxxxxxxx-xxxxxxxxxx-1002"  # VDA Security Group SID
        Permission = "Allow"
    }
)

# 4. Benutzer-Berechtigungen definieren
$UserPermissions = @(
    @{
        SID = "S-1-5-21-xxxxxxxxxx-xxxxxxxxxx-xxxxxxxxxx-1003"  # User Security Group SID
        Permission = "Allow"
    }
)

# 5. Funktion ausführen
Configure-FAS-UserRules -StoreFrontPermissions $StoreFrontPermissions `
                        -VDAPermissions $VDAPermissions `
                        -UserPermissions $UserPermissions `
                        -CertificateAuthority @("CA-SERVER-01.domain.com") `
                        -FASAddress "FAS-SERVER-01.domain.com"
```

#### Praktisches Beispiel mit mehreren Gruppen:

```powershell
# Mehrere Benutzergruppen mit unterschiedlichen Berechtigungen:

$UserPermissions = @(
    @{
        SID = "S-1-5-21-xxx-1001"  # Standard-Benutzer
        Permission = "Allow"
    },
    @{
        SID = "S-1-5-21-xxx-1002"  # VIP-Benutzer
        Permission = "Allow"
    },
    @{
        SID = "S-1-5-21-xxx-1003"  # Externe Benutzer
        Permission = "Deny"  # Explizit verweigern!
    }
)
```

#### Was passiert im Hintergrund?

```
┌─────────────────────────────────────────────┐
│ 1. Get-FasAuthorizationCertificate          │
│    → Holt Authorization Certificate GUID    │
│    → Benötigt für Certificate Definition    │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ 2. New-FasCertificateDefinition             │
│    → Erstellt "default_Definition"          │
│    → Template: Citrix_SmartCardLogon        │
│    → Bindet an Authorization Certificate    │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ 3. Erstellt SDDL-Strings                    │
│    → StoreFront ACL (Access Control List)   │
│    → VDA ACL                                │
│    → User ACL                               │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ 4. New-FasRule                              │
│    → Erstellt "default" Rule                │
│    → Bindet alle ACLs                       │
│    → Aktiviert User Rules                   │
└─────────────────────────────────────────────┘
```

#### Was sind SDDL-Strings?

**SDDL = Security Descriptor Definition Language**

In einfachen Worten: Ein komplizierter Text, der Windows erklärt, wer Zugriff hat.

**Beispiel:**
```
D:(A;;GA;;;S-1-5-21-xxx-1001)(A;;GA;;;S-1-5-21-xxx-1002)
│  │  │   └─ SID (Security Identifier)
│  │  └───── Generic All (GA) - Volle Rechte
│  └──────── Allow (A)
└─────────── Discretionary ACL (D:)
```

**Wichtig:** Das Skript erstellt diese Strings automatisch - du musst sie nicht verstehen!

---

## Was passiert im Hintergrund?

### Die 3 Skripte im Zusammenspiel:

```
USER führt aus: Deploy-FAS.ps1
    │
    ├─► MSI Installation startet
    │       │
    │       ├─► FAS Dienst wird installiert
    │       ├─► Registry-Einträge werden erstellt
    │       ├─► PowerShell SDK wird installiert
    │       └─► Event Log Eintrag wird geschrieben
    │
    └─► Installation erfolgreich ✅

USER führt aus: Configure-FAS.ps1
    │
    ├─► Certificate Templates werden deployed
    │       │
    │       ├─► Citrix_SmartCardLogon Template → Active Directory
    │       ├─► Citrix_RegistrationAuthority Template → Active Directory
    │       └─► Berechtigungen werden gesetzt (SDDL)
    │
    ├─► Certificate Authority Setup
    │       │
    │       ├─► Templates werden zur CA hinzugefügt
    │       └─► CA darf jetzt Zertifikate ausstellen
    │
    └─► Authorization Certificate
            │
            ├─► FAS beantragt Zertifikat bei CA
            ├─► CA-Admin-Genehmigung (automatisiert!)
            └─► FAS erhält Authorization Certificate ✅

USER führt aus: Configure-FAS-UserRules.ps1
    │
    ├─► Certificate Definition erstellen
    │       │
    │       ├─► Name: "default_Definition"
    │       ├─► Template: Citrix_SmartCardLogon
    │       └─► Bindet Authorization Certificate
    │
    ├─► Access Control Lists (ACLs) erstellen
    │       │
    │       ├─► StoreFront ACL (welche StoreFront Server?)
    │       ├─► VDA ACL (welche VDAs?)
    │       └─► User ACL (welche Benutzer?)
    │
    └─► FAS Rule erstellen
            │
            ├─► Bindet Certificate Definition
            ├─► Bindet alle ACLs
            └─► Aktiviert User Rules ✅

ERGEBNIS:
    │
    └─► FAS ist vollständig konfiguriert und einsatzbereit! 🎉
```

---

## Fehlersuche und Validierung

### Nach jedem Schritt validieren!

#### Nach Schritt 1 (Deploy-FAS.ps1):

```powershell
# 1. FAS Service prüfen
Get-Service -Name "CitrixFederatedAuthenticationService"

# Erwartete Ausgabe:
# Status   : Running
# Name     : CitrixFederatedAuthenticationService
```

```powershell
# 2. Startmenü prüfen
# → Windows Startmenü öffnen
# → Suche nach "Citrix Federated Authentication Service"
# → Sollte vorhanden sein ✅
```

#### Nach Schritt 2 (Configure-FAS.ps1):

```powershell
# 1. Authorization Certificate prüfen
Get-FasAuthorizationCertificate -Address "FAS-SERVER-01.domain.com"

# Sollte ein gültiges Zertifikat zurückgeben ✅
```

```powershell
# 2. FAS GUI öffnen
# → Initial Setup Tab öffnen
# → Alle 3 Balken sollten GRÜN sein:
#   ✅ Deploy Certificate Templates
#   ✅ Setup Certificate Authority
#   ✅ Authorize this Service
```

#### Nach Schritt 3 (Configure-FAS-UserRules.ps1):

```powershell
# 1. FAS Rules anzeigen
Get-FasRule -Address "FAS-SERVER-01.domain.com"

# Erwartete Ausgabe:
# Name                : default
# CertificateDefinitions : {default_Definition}
# StoreFrontAcl       : D:(A;;GA;;;S-1-5-21-xxx)
# UserAcl             : D:(A;;GA;;;S-1-5-21-xxx)
# VdaAcl              : D:(A;;GA;;;S-1-5-21-xxx)
```

```powershell
# 2. Certificate Definitions anzeigen
Get-FasCertificateDefinition -Address "FAS-SERVER-01.domain.com"

# Erwartete Ausgabe:
# Name                    : default_Definition
# MsTemplate              : Citrix_SmartCardLogon
# CertificateAuthority    : CA-SERVER-01.domain.com
```

### Bekannte Probleme und Lösungen:

#### Problem 1: GUI zeigt leere Dropdowns (Multiple CAs)

**Symptom:**
- Certificate Authority Dropdown ist leer
- Certificate Template Dropdown ist leer

**Grund:**
- Bekanntes Problem bei mehreren Certificate Authorities
- GUI kann nicht korrekt mit mehreren CAs umgehen

**Lösung:**
```powershell
# PowerShell verwenden statt GUI:
Get-FasRule -Address "FAS-SERVER-01.domain.com"
Get-FasCertificateDefinition -Address "FAS-SERVER-01.domain.com"
```

**Dokumentation:** [Citrix Support Article](https://support.citrix.com/article/CTX234856)

#### Problem 2: Authorization Certificate Request bleibt "Pending"

**Symptom:**
- `New-FasAuthorizationCertificate` hängt
- Certificate Request in CA Console zeigt "Pending Requests"

**Lösung:**
```powershell
# Manuelle Genehmigung in CA Console:
# 1. Certificate Authority Console öffnen
# 2. Zu "Pending Requests" navigieren
# 3. Request rechtsklick → "Issue"

# ODER: Automatische Genehmigung (im Skript enthalten)
```

#### Problem 3: "Access Denied" Fehler

**Symptom:**
```
Access is denied. (Exception from HRESULT: 0x80070005)
```

**Lösung:**
1. **Prüfe Berechtigungen:**
   - Bist du lokaler Administrator?
   - Hast du Enterprise Forest Administrator Rechte?
   - Hast du Certificate Authority Administrator Rechte?

2. **PowerShell als Administrator ausführen:**
   ```
   Rechtsklick auf PowerShell → "Als Administrator ausführen"
   ```

#### Problem 4: "Template not found" Fehler

**Symptom:**
```
Certificate template 'Citrix_SmartCardLogon' not found
```

**Lösung:**
```powershell
# 1. Prüfen, ob Templates deployed wurden:
Get-ADObject -Filter {Name -like "Citrix_*"} -SearchBase "CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=domain,DC=com"

# 2. Falls nicht gefunden, Schritt 2 erneut ausführen:
. .\Configure-FAS.ps1
Configure-FAS -CertificateAuthority @("CA-SERVER-01.domain.com") -FASAddress "FAS-SERVER-01.domain.com" -FASSecurityGroupSID "S-1-5-21-xxx"
```

---

## Wichtige Sicherheitshinweise

### 🔐 Berechtigungen minimal halten!

**Prinzip der minimalen Berechtigung (Least Privilege):**

```powershell
# ❌ SCHLECHT: Alle Benutzer erlauben
$UserPermissions = @(
    @{
        SID = "S-1-1-0"  # "Everyone" - NIEMALS verwenden!
        Permission = "Allow"
    }
)

# ✅ GUT: Spezifische Gruppen verwenden
$UserPermissions = @(
    @{
        SID = "S-1-5-21-xxx-1001"  # Nur "Citrix_Users" Gruppe
        Permission = "Allow"
    }
)
```

### 🔒 Certificate Templates schützen

**Wichtig:** Certificate Templates haben sensible Berechtigungen!

**Empfohlene SDDL-Permissions (aus Citrix FAS Security Dokumentation):**

```
D:(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;FAS_Server_SID)
```

**Was bedeutet das?**
- Nur der FAS Server darf Templates verwenden
- Keine anderen Computer oder Benutzer
- Minimales Risiko für Missbrauch

### 🛡️ Firewall-Regeln (Manuell konfigurieren!)

**Wichtig:** Die Skripte konfigurieren KEINE Firewall-Regeln!

**Minimale Firewall-Regeln:**

| Port | Protokoll | Quelle | Ziel | Zweck |
|------|-----------|--------|------|-------|
| 80 | TCP | StoreFront | FAS Server | HTTP Kommunikation |
| 443 | TCP | StoreFront | FAS Server | HTTPS Kommunikation (empfohlen) |

**PowerShell-Befehl für Firewall-Regeln:**

```powershell
# HTTP-Regel (Port 80)
New-NetFirewallRule -DisplayName "FAS - HTTP Inbound" `
                    -Direction Inbound `
                    -LocalPort 80 `
                    -Protocol TCP `
                    -Action Allow `
                    -Profile Domain

# HTTPS-Regel (Port 443)
New-NetFirewallRule -DisplayName "FAS - HTTPS Inbound" `
                    -Direction Inbound `
                    -LocalPort 443 `
                    -Protocol TCP `
                    -Action Allow `
                    -Profile Domain
```

[Vollständige Firewall-Dokumentation](https://docs.citrix.com/en-us/federated-authentication-service/install-configure.html#step-2-configure-windows-firewall)

### 📝 Logging und Monitoring

**Event Logs überwachen:**

```powershell
# FAS Event Logs anzeigen
Get-WinEvent -LogName "Citrix-FederatedAuthenticationService/Admin" -MaxEvents 50

# Fehler filtern
Get-WinEvent -LogName "Citrix-FederatedAuthenticationService/Admin" | Where-Object {$_.LevelDisplayName -eq "Error"}
```

**Wichtige Events:**
- **Event ID 1000:** FAS Service gestartet
- **Event ID 1001:** Certificate erfolgreich ausgestellt
- **Event ID 2000:** Fehler bei Certificate Issuance

---

## Weiterführende Ressourcen

### 📚 Citrix Dokumentation

- [FAS Architecture Overview](https://docs.citrix.com/en-us/citrix-virtual-apps-desktops/secure/federated-authentication-service)
- [FAS Installation and Configuration](https://docs.citrix.com/en-us/federated-authentication-service/install-configure)
- [FAS Security Best Practices](https://docs.citrix.com/en-us/federated-authentication-service/security)
- [FAS PowerShell SDK Reference](https://developer-docs.citrix.com/projects/federated-authentication-service-powershell-sdk/en/latest/)

### 🔧 PowerShell Ressourcen

- [PowerShell Best Practices](https://poshcode.gitbook.io/powershell-practice-and-style/)
- [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) - Code Quality Tool
- [Pester Testing Framework](https://pester.dev/) - PowerShell Testing

### 🎓 Citrix Blog-Artikel

- **Original Blog Post:** [Automating Federated Authentication Services with PowerShell](https://www.citrix.com/blogs/2019/05/30/automating-federated-authentication-services-with-powershell/)
- [StoreFront FAS Configuration](https://docs.citrix.com/en-us/storefront/current-release/integrate-with-citrix-gateway-and-citrix-adc/configure-fas)

### 🆘 Support

- **Citrix Support:** [https://support.citrix.com](https://support.citrix.com)
- **Citrix Community Forums:** [https://discussions.citrix.com](https://discussions.citrix.com)
- **Known Issues:** [CTX234856 - FAS GUI issues with multiple CAs](https://support.citrix.com/article/CTX234856)

---

## Zusammenfassung: Der komplette Workflow

### Checkliste für erfolgreiche FAS-Automatisierung:

#### Vorbereitung:
- [ ] Windows Server vorbereitet
- [ ] Active Directory Domain läuft
- [ ] Certificate Authority installiert und konfiguriert
- [ ] FAS MSI-Datei verfügbar
- [ ] Berechtigungen verifiziert (Local Admin, Enterprise Admin, CA Admin)

#### Schritt 1: Installation
- [ ] `Deploy-FAS.ps1` ausgeführt
- [ ] FAS Service läuft (`Get-Service`)
- [ ] Firewall-Regeln manuell konfiguriert

#### Schritt 2: Konfiguration
- [ ] `Configure-FAS.ps1` ausgeführt
- [ ] Certificate Templates deployed
- [ ] CA konfiguriert
- [ ] Authorization Certificate erhalten
- [ ] FAS GUI zeigt 3 grüne Balken

#### Schritt 3: User Rules
- [ ] StoreFront SIDs gesammelt
- [ ] VDA SIDs gesammelt
- [ ] User Group SIDs gesammelt
- [ ] `Configure-FAS-UserRules.ps1` ausgeführt
- [ ] FAS Rules validiert (`Get-FasRule`)

#### Validierung:
- [ ] End-to-End Test durchgeführt
- [ ] Benutzer kann sich mit SSO anmelden
- [ ] Event Logs prüfen (keine Fehler)
- [ ] StoreFront FAS-Konfiguration abgeschlossen

---

**Version:** 1.0
**Erstellt:** 2025-01-05
**Basierend auf:** [Citrix Blog - Automating FAS with PowerShell](https://www.citrix.com/blogs/2019/05/30/automating-federated-authentication-services-with-powershell/)
**Maintainer:** dima@lejkin.de

---

## Nächste Schritte

Nach erfolgreicher FAS-Automatisierung:

1. **StoreFront konfigurieren:**
   ```powershell
   # StoreFront FAS-Konfiguration (separate Anleitung erforderlich)
   # Siehe: https://docs.citrix.com/en-us/storefront/current-release/integrate-with-citrix-gateway-and-citrix-adc/configure-fas
   ```

2. **Backup-Strategie implementieren:**
   - FAS Configuration Backup
   - Certificate Templates Backup
   - Authorization Certificate Backup

3. **Monitoring einrichten:**
   - Event Log Monitoring
   - Certificate Expiration Monitoring
   - Service Health Checks

4. **Disaster Recovery testen:**
   - FAS Server Restore-Test
   - Certificate Recovery-Test
   - Failover-Szenarien testen

---

**Viel Erfolg bei deiner FAS-Automatisierung! 🚀**
