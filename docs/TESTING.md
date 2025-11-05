# FAS PowerShell Testing Guide für Windows Admins

Schnelle Anleitung für Mock-basiertes Testing der FAS PowerShell-Skripte **ohne** echte FAS/CA/AD-Infrastruktur.

---

## Warum Mock-Testing?

**Problem**: FAS-Tests benötigen normalerweise:
- ❌ FAS Server
- ❌ Certificate Authority
- ❌ Active Directory
- ❌ Komplexe Infrastruktur

**Lösung**: Mock-basierte Tests
- ✅ **Keine** Backend-Infrastruktur erforderlich
- ✅ **Schnell**: Tests in Sekunden
- ✅ **Wiederholbar**: Konsistente Ergebnisse
- ✅ **CI/CD Ready**: GitHub Actions Integration

---

## Quick Start

### 1. Pester installieren

```powershell
# Pester 5.x installieren (als Admin oder CurrentUser)
Install-Module -Name Pester -MinimumVersion 5.0.0 -Scope CurrentUser -Force -SkipPublisherCheck

# PSScriptAnalyzer (für Syntax-Tests)
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
```

### 2. Tests ausführen

```powershell
# Alle Tests ausführen
.\tests\Invoke-Tests.ps1 -TestType All

# Nur Syntax-Validierung (schnell)
.\tests\Invoke-Tests.ps1 -TestType Validation

# Nur Unit Tests
.\tests\Invoke-Tests.ps1 -TestType Unit

# Nur Integration Tests
.\tests\Invoke-Tests.ps1 -TestType Integration

# Mit Code Coverage
.\tests\Invoke-Tests.ps1 -TestType All -CodeCoverage
```

---

## Test-Typen

### 1️⃣ Validation Tests (Syntax)

**Was wird getestet?**
- ✅ PowerShell Syntax (Parser)
- ✅ PSScriptAnalyzer Rules (Best Practices)
- ✅ Security Checks (keine Hardcoded Credentials)
- ✅ Code Quality (Dokumentation, Parameter Validation)

**Ausführung**:
```powershell
.\tests\Invoke-Tests.ps1 -TestType Validation
```

**Dauer**: ~10-30 Sekunden

---

### 2️⃣ Unit Tests

**Was wird getestet?**
- ✅ `Deploy-FAS.ps1`: MSI Installation, Service Management
- ✅ Prerequisites Checks (Admin Rights, Windows Version)
- ✅ Error Handling (MSI Exit Codes 0, 3010, 1603, 1618)

**Ausführung**:
```powershell
.\tests\Invoke-Tests.ps1 -TestType Unit
```

**Dauer**: ~5-10 Sekunden

---

### 3️⃣ Integration Tests

**Was wird getestet?**
- ✅ End-to-End Workflow (Install → Configure → UserRules)
- ✅ Template Schema Validation (917Citrix_SmartcardLogon v4)
- ✅ Certificate Lifecycle (Authorization Certificate)
- ✅ User Rules mit ACLs

**Ausführung**:
```powershell
.\tests\Invoke-Tests.ps1 -TestType Integration
```

**Dauer**: ~10-20 Sekunden

---

## Mock-Module (Was wird simuliert?)

### 1. FAS-SDK.psm1

**Simulierte Cmdlets**:
```powershell
Get-FasServer
New-FasMsTemplate
Publish-FasMsTemplate
New-FasAuthorizationCertificate
Get-FasAuthorizationCertificate
New-FasCertificateDefinition
Get-FasCertificateDefinition
New-FasRule
Get-FasRule
```

**Beispiel**:
```powershell
# Echter Aufruf (benötigt FAS Server):
# Get-FasServer -Address "fas.domain.com"

# Mock-Aufruf (funktioniert ohne FAS Server):
Import-Module ./tests/Mocks/FAS-SDK.psm1
$server = Get-FasServer -Address "fas-test.local"
# Gibt Mock-Objekt zurück
```

---

### 2. WindowsServices.psm1

**Simuliert**:
- Windows Services (Get-Service, Start-Service)
- Registry (Get-ItemProperty, installierte Software)
- MSI Installation (Start-Process mit Exit Codes)

**Beispiel**:
```powershell
Import-Module ./tests/Mocks/WindowsServices.psm1

# Service erstellen
Initialize-MockService -Name "CitrixFederatedAuthenticationService" -Status "Stopped"

# Service starten
Start-Service -Name "CitrixFederatedAuthenticationService"

# Service Status prüfen
$service = Get-Service -Name "CitrixFederatedAuthenticationService"
# $service.Status = "Running"
```

---

### 3. ActiveDirectory.psm1

**Simuliert**:
- Active Directory Domain
- Certificate Templates
- Event Logs (Get-WinEvent)
- Security Principals (Administrator Check)

**Beispiel**:
```powershell
Import-Module ./tests/Mocks/ActiveDirectory.psm1

# Domain initialisieren
Initialize-MockDomain -DomainName "example.local"

# Template hinzufügen
Add-MockCertificateTemplate -Name "917Citrix_SmartcardLogon" -SchemaVersion 4
```

---

## Eigene Tests schreiben

### Basis-Template

```powershell
#Requires -Modules Pester

BeforeAll {
    # Mocks importieren
    Import-Module ./tests/Mocks/FAS-SDK.psm1 -Force
    Import-Module ./tests/Mocks/WindowsServices.psm1 -Force
}

Describe "Mein Test" {

    BeforeEach {
        # Mocks zurücksetzen (wichtig!)
        Reset-FasMockData
        Reset-WindowsServicesMockData
    }

    Context "Szenario 1" {

        It "Sollte XYZ tun" {
            # Arrange (Setup)
            Initialize-MockService -Name "CitrixFederatedAuthenticationService"

            # Act (Aktion)
            Start-Service -Name "CitrixFederatedAuthenticationService"

            # Assert (Validierung)
            $service = Get-Service -Name "CitrixFederatedAuthenticationService"
            $service.Status | Should -Be "Running"
        }
    }
}
```

### Test ausführen

```powershell
Invoke-Pester -Path ./tests/Unit/MeinTest.Tests.ps1 -Output Detailed
```

---

## CI/CD Integration (GitHub Actions)

**Automatische Tests** bei Push/Pull Request:

```yaml
# .github/workflows/powershell-tests.yml
# Führt automatisch aus:
# - Validation Tests
# - Unit Tests
# - Integration Tests
# - Code Coverage Upload
```

**Status prüfen**:
- GitHub → Actions Tab
- Badge im README (nach erstem Run)

---

## Troubleshooting

### Problem: Pester nicht gefunden

```powershell
# Lösung: Pester installieren
Install-Module -Name Pester -MinimumVersion 5.0.0 -Scope CurrentUser -Force
```

---

### Problem: Tests schlagen fehl mit "Cmdlet not found"

**Symptom**:
```
Get-FasServer: The term 'Get-FasServer' is not recognized
```

**Lösung**: Mocks werden nicht importiert
```powershell
# In BeforeAll Block:
BeforeAll {
    Import-Module ./tests/Mocks/FAS-SDK.psm1 -Force
}
```

---

### Problem: Tests beeinflussen sich gegenseitig

**Symptom**: Test 2 schlägt fehl, wenn Test 1 vorher läuft

**Lösung**: Mocks in `BeforeEach` zurücksetzen
```powershell
BeforeEach {
    Reset-FasMockData
    Reset-WindowsServicesMockData
    Reset-ActiveDirectoryMockData
}
```

---

### Problem: PSScriptAnalyzer Warnings

**Symptom**: Validation Tests zeigen PSScriptAnalyzer Warnings

**Lösung**: Skript korrigieren oder Rule deaktivieren
```powershell
# Temporär Rule ausschließen (nicht empfohlen):
Invoke-ScriptAnalyzer -Path "script.ps1" -ExcludeRule PSAvoidUsingWriteHost
```

---

## Test-Ausgabe Formate

### Console (Standard)

```powershell
.\tests\Invoke-Tests.ps1 -TestType All
```

**Output**: Farbige Console-Ausgabe

---

### JUnit XML (für CI/CD)

```powershell
.\tests\Invoke-Tests.ps1 -TestType All `
                        -OutputFormat JUnitXml `
                        -OutputPath "test-results.xml"
```

**Output**: XML-Datei für Jenkins, Azure DevOps, etc.

---

### NUnit XML

```powershell
.\tests\Invoke-Tests.ps1 -TestType All `
                        -OutputFormat NUnitXml `
                        -OutputPath "test-results.xml"
```

**Output**: XML-Datei für NUnit-kompatible Tools

---

## Code Coverage

### Aktivieren

```powershell
.\tests\Invoke-Tests.ps1 -TestType All -CodeCoverage
```

**Output**:
- JaCoCo XML: `tests/coverage.xml`
- Console-Report mit Coverage %

**Beispiel-Output**:
```
Code Coverage Summary
========================================
Commands Analyzed:  245
Commands Executed:  198
Commands Missed:    47
Coverage:           80.82%
```

---

## Performance-Tipps

### Nur geänderte Tests ausführen

```powershell
# Nur Validation (schnellste Tests)
.\tests\Invoke-Tests.ps1 -TestType Validation

# Nur spezifische Datei
Invoke-Pester -Path ./tests/Unit/Deploy-FAS.Tests.ps1
```

---

### Tag-Filter verwenden

```powershell
# Nur Unit Tests
.\tests\Invoke-Tests.ps1 -Tags "Unit"

# Nur Security Tests
.\tests\Invoke-Tests.ps1 -Tags "Security"
```

---

## Cheat Sheet

```powershell
# === SETUP ===
Install-Module Pester -MinimumVersion 5.0.0 -Force
Install-Module PSScriptAnalyzer -Force

# === TESTS AUSFÜHREN ===
.\tests\Invoke-Tests.ps1 -TestType All              # Alle Tests
.\tests\Invoke-Tests.ps1 -TestType Validation       # Nur Syntax
.\tests\Invoke-Tests.ps1 -TestType Unit             # Nur Unit Tests
.\tests\Invoke-Tests.ps1 -TestType Integration      # Nur Integration
.\tests\Invoke-Tests.ps1 -TestType All -CodeCoverage # Mit Coverage

# === EINZELNE TEST-DATEI ===
Invoke-Pester -Path ./tests/Unit/Deploy-FAS.Tests.ps1 -Output Detailed

# === CI/CD OUTPUT ===
.\tests\Invoke-Tests.ps1 -TestType All `
                        -OutputFormat JUnitXml `
                        -OutputPath "results.xml"

# === TAG-FILTER ===
.\tests\Invoke-Tests.ps1 -Tags "Unit","Integration"

# === MOCKS MANUELL TESTEN ===
Import-Module ./tests/Mocks/FAS-SDK.psm1
$server = Get-FasServer -Address "test.local"
$server  # Zeigt Mock-Objekt
```

---

## Wichtige Hinweise

### ⚠️ Einschränkungen

**Mock-Tests validieren NICHT**:
- ❌ Echte FAS Server Funktionalität
- ❌ Certificate Authority Integration
- ❌ Active Directory Änderungen
- ❌ Netzwerk-Konnektivität
- ❌ PKI Infrastructure

**Mock-Tests validieren**:
- ✅ PowerShell Syntax
- ✅ Logik und Error Handling
- ✅ Parameter Validation
- ✅ Code Quality
- ✅ Best Practices

### ✅ Best Practices

1. **Immer Mocks zurücksetzen** in `BeforeEach`
2. **Spezifische Assertions** verwenden (`Should -Be` statt `Should -Not -BeNullOrEmpty`)
3. **Tests isoliert** halten (keine Dependencies zwischen Tests)
4. **Dokumentation** in Test-Namen (`It "Should start FAS service after installation"`)

---

## Weiterführende Dokumentation

- **Umfassende Anleitung**: `docs/testing/MOCK-TESTING-GUIDE.md`
- **Test README**: `tests/README.md`
- **Pester Docs**: https://pester.dev/docs/quick-start

---

**Version**: 1.0.0
**Zielgruppe**: Windows Admins mit PowerShell-Kenntnissen
**Test-Ausführungszeit**: ~30-60 Sekunden (alle Tests)
