# FAS PowerShell Mock-Based Testing Guide

## Übersicht

Dieses Dokument beschreibt das Mock-basierte Testing-Framework für FAS PowerShell-Skripte. Das Framework ermöglicht isolierte Tests **ohne** Zugriff auf reale Backend-Systeme (FAS Server, PKI, Active Directory).

---

## Ziele

### Primäre Ziele
1. **Isoliertes Testing**: Tests ohne Backend-Abhängigkeiten (FAS, PKI, AD)
2. **Syntax-Validierung**: PowerShell Parser und PSScriptAnalyzer Integration
3. **Funktions-Tests**: Mock-basierte Unit- und Integration-Tests
4. **CI/CD Integration**: Automatisierte Tests in GitHub Actions
5. **Code Coverage**: Messung der Test-Abdeckung

### Nicht-Ziele
- **Keine** realen FAS Server Tests
- **Keine** echten Certificate Authority Operationen
- **Keine** Active Directory Modifikationen

---

## Architektur

### Verzeichnisstruktur

```
tests/
├── Mocks/                          # Mock-Module
│   ├── FAS-SDK.psm1               # FAS PowerShell SDK Mocks
│   ├── WindowsServices.psm1       # Windows Services & Registry Mocks
│   └── ActiveDirectory.psm1       # Active Directory & Event Log Mocks
├── Unit/                          # Unit Tests
│   ├── Deploy-FAS.Tests.ps1
│   ├── Configure-FAS.Tests.ps1
│   └── Configure-FAS-UserRules.Tests.ps1
├── Integration/                   # Integration Tests
│   └── FullDeployment.Tests.ps1
├── Validation/                    # Syntax & Quality Tests
│   └── Syntax.Tests.ps1
└── Invoke-Tests.ps1              # Test Runner
```

---

## Mock-Module

### 1. FAS-SDK.psm1

**Zweck**: Mock-Implementierung aller Citrix FAS PowerShell SDK Cmdlets

**Gemockte Cmdlets**:
- `Get-FasServer`
- `New-FasMsTemplate`
- `Publish-FasMsTemplate`
- `Get-FasAuthorizationCertificate`
- `New-FasAuthorizationCertificate`
- `Get-FasCertificateDefinition`
- `New-FasCertificateDefinition`
- `Remove-FasCertificateDefinition`
- `Get-FasRule`
- `New-FasRule`
- `Remove-FasRule`

**Verwendung**:

```powershell
# Import Mock-Modul
Import-Module ./tests/Mocks/FAS-SDK.psm1

# FAS Server erstellen
$server = Get-FasServer -Address "fas-test.local"

# Template erstellen
$template = New-FasMsTemplate -Address "fas-test.local" `
                             -Name "917Citrix_SmartcardLogon" `
                             -SecurityGroupSID "S-1-5-21-xxx"

# Template validieren
$template.SchemaVersion | Should -Be 4
$template.HashAlgorithm | Should -Be "SHA256"

# Mock-Daten zurücksetzen (BeforeEach)
Reset-FasMockData
```

**Wichtige Features**:
- Template Schema Version Simulation (v2 vs. v4)
- Hash Algorithm Detection (SHA1 vs. SHA256)
- Authorization Certificate Lifecycle
- Certificate Definition Management
- Rule und ACL Validierung

---

### 2. WindowsServices.psm1

**Zweck**: Mock für Windows Services, Registry und MSI Installation

**Gemockte Cmdlets**:
- `Get-Service`
- `Start-Service`
- `Stop-Service`
- `Restart-Service`
- `Set-Service`
- `Get-ItemProperty` (Registry)
- `Start-Process` (MSI Installation)

**Verwendung**:

```powershell
Import-Module ./tests/Mocks/WindowsServices.psm1

# Service initialisieren
Initialize-MockService -Name "CitrixFederatedAuthenticationService" `
                      -Status "Stopped" `
                      -StartType "Automatic"

# Service starten
Start-Service -Name "CitrixFederatedAuthenticationService"

# Service Status prüfen
$service = Get-Service -Name "CitrixFederatedAuthenticationService"
$service.Status | Should -Be "Running"

# MSI Exit Code setzen
Set-MockMSIExitCode -MSIPath "C:\Temp\FAS.msi" -ExitCode 0

# MSI Installation simulieren
$process = Start-Process -FilePath "msiexec.exe" `
                        -ArgumentList @("/i", "C:\Temp\FAS.msi") `
                        -Wait -PassThru

# Registry Entry hinzufügen
Add-MockInstalledSoftware -DisplayName "Citrix FAS" `
                         -DisplayVersion "2112.0.1.0"

# Mock-Daten zurücksetzen
Reset-WindowsServicesMockData
```

**MSI Exit Codes**:
- `0`: Erfolgreiche Installation
- `3010`: Installation erfolgreich, Reboot erforderlich
- `1603`: Fataler Installationsfehler
- `1618`: Andere Installation läuft bereits

---

### 3. ActiveDirectory.psm1

**Zweck**: Mock für Active Directory, Security Principals und Event Logs

**Gemockte Klassen & Cmdlets**:
- `[System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()`
- `[System.DirectoryServices.DirectorySearcher]`
- `[System.DirectoryServices.DirectoryEntry]`
- `[Security.Principal.WindowsPrincipal]`
- `Get-WinEvent`

**Verwendung**:

```powershell
Import-Module ./tests/Mocks/ActiveDirectory.psm1

# Domain initialisieren
Initialize-MockDomain -DomainName "example.local"

# Certificate Template hinzufügen
Add-MockCertificateTemplate -Name "917Citrix_SmartcardLogon" `
                           -SchemaVersion 4 `
                           -AdditionalProperties @{
                               'msPKI-Cert-Template-OID' = "1.3.6.1.4.1.311.21.8.xxx"
                           }

# Template suchen (DirectorySearcher Mock)
$searcher = New-Object System.DirectoryServices.DirectorySearcher
$searcher.Filter = "(cn=917Citrix_SmartcardLogon)"
$result = $searcher.FindOne()

$result | Should -Not -BeNullOrEmpty

# Administrator Status setzen
Set-MockAdministrator -IsAdmin $true

# Event Log Entry hinzufügen
Add-MockEventLog -LogName "Citrix-FederatedAuthenticationService/Admin" `
                -EventID 100 `
                -Level "Information" `
                -Message "Test Event"

# Mock-Daten zurücksetzen
Reset-ActiveDirectoryMockData
```

---

## Test-Typen

### 1. Syntax Validation Tests

**Datei**: `tests/Validation/Syntax.Tests.ps1`

**Validierungen**:
- ✅ PowerShell Parser Syntax Check
- ✅ AST (Abstract Syntax Tree) Parsing
- ✅ PSScriptAnalyzer Rules
- ✅ Security Best Practices
- ✅ Code Quality Standards
- ✅ Documentation Completeness

**Ausführung**:

```powershell
.\tests\Invoke-Tests.ps1 -TestType Syntax
```

**PSScriptAnalyzer Rules**:
- `PSUseApprovedVerbs`
- `PSAvoidUsingPlainTextForPassword`
- `PSAvoidUsingConvertToSecureStringWithPlainText`
- Error & Warning Severity Checks

---

### 2. Unit Tests

**Datei**: `tests/Unit/Deploy-FAS.Tests.ps1`

**Test-Bereiche**:
- ✅ Prerequisites Checks (Admin Rights, Windows Version)
- ✅ MSI Installation (Success & Failure Scenarios)
- ✅ Service Validation (Start, Stop, Status)
- ✅ Registry Verification
- ✅ Parameter Validation

**Beispiel**:

```powershell
Describe "Deploy-FAS.ps1 - Service Verification" {
    BeforeEach {
        Reset-WindowsServicesMockData
    }

    It "Should start FAS service after installation" {
        # Arrange
        Initialize-MockService -Name "CitrixFederatedAuthenticationService" `
                              -Status "Stopped"

        # Act
        Start-Service -Name "CitrixFederatedAuthenticationService"

        # Assert
        $service = Get-Service -Name "CitrixFederatedAuthenticationService"
        $service.Status | Should -Be "Running"
    }
}
```

---

### 3. Integration Tests

**Datei**: `tests/Integration/FullDeployment.Tests.ps1`

**Test-Szenarien**:
- ✅ Phase 1: FAS Installation (Deploy-FAS.ps1)
- ✅ Phase 2: Template Deployment (Configure-FAS.ps1)
- ✅ Phase 3: User Rules (Configure-FAS-UserRules.ps1)
- ✅ Phase 4: End-to-End Workflow
- ✅ Error Handling Scenarios

**End-to-End Workflow**:

```powershell
It "Should complete full deployment workflow" {
    # Phase 1: Installation
    Set-MockMSIExitCode -MSIPath $msiPath -ExitCode 0
    $installProcess = Start-Process -FilePath "msiexec.exe" -Wait -PassThru
    Initialize-MockService -Name "CitrixFederatedAuthenticationService"

    # Phase 2: Template Configuration
    $template = New-FasMsTemplate -Name "917Citrix_SmartcardLogon"
    Publish-FasMsTemplate -Name "917Citrix_SmartcardLogon"
    $authCert = New-FasAuthorizationCertificate

    # Phase 3: User Rules
    $certDef = New-FasCertificateDefinition -MsTemplate "917Citrix_SmartcardLogon"
    $rule = New-FasRule -CertificateDefinitions @("default_Definition")

    # Assertions
    $installProcess.ExitCode | Should -Be 0
    $template.SchemaVersion | Should -Be 4
    $rule.CertificateDefinitions | Should -Contain "default_Definition"
}
```

---

## Test-Runner

**Datei**: `tests/Invoke-Tests.ps1`

### Parameter

| Parameter | Beschreibung | Werte |
|-----------|--------------|-------|
| `-TestType` | Art der Tests | `All`, `Unit`, `Integration`, `Validation`, `Syntax` |
| `-OutputFormat` | Ausgabeformat | `Console`, `NUnitXml`, `JUnitXml` |
| `-OutputPath` | Pfad für XML-Ausgabe | Beliebiger Pfad |
| `-CodeCoverage` | Code Coverage aktivieren | Switch |
| `-Tags` | Filter nach Tags | Array von Tags |

### Verwendung

```powershell
# Alle Tests ausführen
.\tests\Invoke-Tests.ps1 -TestType All

# Nur Validierungs-Tests
.\tests\Invoke-Tests.ps1 -TestType Validation

# Tests mit Code Coverage
.\tests\Invoke-Tests.ps1 -TestType All -CodeCoverage

# Tests mit XML-Ausgabe (für CI/CD)
.\tests\Invoke-Tests.ps1 -TestType Integration `
                        -OutputFormat JUnitXml `
                        -OutputPath "test-results.xml"

# Tests mit Tag-Filter
.\tests\Invoke-Tests.ps1 -Tags "Unit","Integration"
```

---

## CI/CD Integration (GitHub Actions)

**Workflow-Datei**: `.github/workflows/powershell-tests.yml`

### Jobs

1. **Test Matrix** (`Validation`, `Unit`, `Integration`)
   - Parallele Ausführung aller Test-Typen
   - JUnit XML Output
   - Test Result Publishing

2. **Code Coverage**
   - JaCoCo Coverage Report
   - Codecov Upload
   - Coverage Artifact Upload

3. **Summary**
   - Gesamtübersicht aller Tests

### Trigger

```yaml
on:
  push:
    branches: [ main, develop ]
    paths:
      - 'scripts/**/*.ps1'
      - 'tests/**/*.ps1'
  pull_request:
    branches: [ main, develop ]
```

---

## Best Practices

### Test-Struktur

```powershell
Describe "Script/Function Name - Test Category" -Tag 'Category' {

    BeforeEach {
        # Alle Mocks zurücksetzen
        Reset-FasMockData
        Reset-WindowsServicesMockData
        Reset-ActiveDirectoryMockData
    }

    Context "Specific Scenario" {

        It "Should do something specific" {
            # Arrange
            # ... Setup

            # Act
            # ... Aktion ausführen

            # Assert
            # ... Validierung
        }
    }
}
```

### Mock-Daten Management

```powershell
BeforeAll {
    # Einmalige Initialisierung
    Import-Module ./tests/Mocks/FAS-SDK.psm1
}

BeforeEach {
    # Vor jedem Test zurücksetzen
    Reset-FasMockData
}

AfterAll {
    # Cleanup (falls erforderlich)
}
```

### Assertion Best Practices

```powershell
# ✅ Gut: Spezifische Assertions mit Because
$result | Should -Be "Expected" -Because "Clear reason"

# ✅ Gut: Mehrere Assertions für komplexe Objekte
$object.Property1 | Should -Be "Value1"
$object.Property2 | Should -Be "Value2"

# ❌ Schlecht: Unspezifische Assertions
$result | Should -Not -BeNullOrEmpty
```

---

## Fehlersuche

### Problem: Tests schlagen fehl mit "Cmdlet not found"

**Lösung**: Mock-Module importieren

```powershell
BeforeAll {
    $mockPath = Join-Path $PSScriptRoot '..' 'Mocks'
    Import-Module (Join-Path $mockPath 'FAS-SDK.psm1') -Force
}
```

### Problem: Mock-Daten persistent zwischen Tests

**Lösung**: `BeforeEach` verwenden

```powershell
BeforeEach {
    Reset-FasMockData
    Reset-WindowsServicesMockData
    Reset-ActiveDirectoryMockData
}
```

### Problem: Pester Version Konflikte

**Lösung**: Pester 5.x installieren

```powershell
Install-Module -Name Pester -MinimumVersion 5.0.0 -Force -SkipPublisherCheck
```

---

## Erweiterung

### Neue Mocks hinzufügen

1. **Mock-Funktion erstellen** in entsprechendem Modul
2. **Export-ModuleMember** aktualisieren
3. **Tests schreiben** mit neuem Mock
4. **Dokumentation aktualisieren**

**Beispiel**:

```powershell
# In FAS-SDK.psm1
function Get-FasUserCertificate {
    [CmdletBinding()]
    param(
        [string]$Address,
        [string]$UserName
    )

    # Mock-Implementierung
    return [PSCustomObject]@{
        UserName = $UserName
        Certificate = "Mock Certificate"
        Issued = Get-Date
    }
}

# Export hinzufügen
Export-ModuleMember -Function @(
    # ... existing functions
    'Get-FasUserCertificate'
)
```

### Neue Test-Kategorie hinzufügen

1. **Verzeichnis erstellen**: `tests/NewCategory/`
2. **Test-Datei erstellen**: `tests/NewCategory/NewTest.Tests.ps1`
3. **Test-Runner aktualisieren**: `Invoke-Tests.ps1`
4. **CI/CD Workflow aktualisieren**: `.github/workflows/powershell-tests.yml`

---

## Zusammenfassung

### Vorteile

✅ **Isolation**: Keine Backend-Abhängigkeiten
✅ **Geschwindigkeit**: Tests laufen in Sekunden
✅ **Wiederholbarkeit**: Konsistente Ergebnisse
✅ **CI/CD Ready**: GitHub Actions Integration
✅ **Code Coverage**: Messbare Test-Abdeckung

### Einschränkungen

⚠️ **Keine realen FAS Tests**: Nur Mock-basiert
⚠️ **Keine CA Integration**: Nur Simulation
⚠️ **Keine AD Änderungen**: Nur Lese-Operationen simuliert

### Nächste Schritte

1. ✅ Mock-Module erweitern (bei Bedarf)
2. ✅ Weitere Unit Tests hinzufügen
3. ✅ Code Coverage auf >80% erhöhen
4. ✅ Performance Tests implementieren
5. ✅ Dokumentation erweitern

---

**Version**: 1.0.0
**Letztes Update**: 2025-11-05
**Maintainer**: FAS Automation Team
