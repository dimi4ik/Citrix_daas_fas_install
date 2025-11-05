# FAS PowerShell Tests

Umfassende Test-Suite für FAS (Federated Authentication Service) PowerShell-Skripte mit Mock-basierten Tests ohne Backend-Abhängigkeiten.

## Schnellstart

### Voraussetzungen

```powershell
# Pester 5.x installieren
Install-Module -Name Pester -MinimumVersion 5.0.0 -Scope CurrentUser -Force

# PSScriptAnalyzer installieren (für Syntax-Tests)
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
```

### Alle Tests ausführen

```powershell
.\Invoke-Tests.ps1 -TestType All
```

### Spezifische Test-Typen

```powershell
# Nur Syntax-Validierung
.\Invoke-Tests.ps1 -TestType Syntax

# Nur Unit Tests
.\Invoke-Tests.ps1 -TestType Unit

# Nur Integration Tests
.\Invoke-Tests.ps1 -TestType Integration

# Mit Code Coverage
.\Invoke-Tests.ps1 -TestType All -CodeCoverage
```

## Verzeichnisstruktur

```
tests/
├── Mocks/                          # Mock-Module (keine Backend-Abhängigkeiten)
│   ├── FAS-SDK.psm1               # Citrix FAS SDK Mocks
│   ├── WindowsServices.psm1       # Windows Services & Registry
│   └── ActiveDirectory.psm1       # Active Directory & Event Logs
│
├── Unit/                          # Unit Tests
│   ├── Deploy-FAS.Tests.ps1      # Deploy-FAS.ps1 Tests
│   ├── Configure-FAS.Tests.ps1   # Configure-FAS.ps1 Tests (TODO)
│   └── Configure-FAS-UserRules.Tests.ps1  # UserRules Tests (TODO)
│
├── Integration/                   # Integration Tests
│   └── FullDeployment.Tests.ps1  # End-to-End Workflow Tests
│
├── Validation/                    # Syntax & Quality Tests
│   └── Syntax.Tests.ps1          # Parser, PSScriptAnalyzer, Security
│
├── Invoke-Tests.ps1              # Test Runner (Haupteinstieg)
└── README.md                     # Diese Datei
```

## Test-Kategorien

### 1. Validation Tests (`Syntax.Tests.ps1`)

**Zweck**: Statische Code-Analyse ohne Ausführung

- ✅ PowerShell Syntax Validation (Parser)
- ✅ PSScriptAnalyzer Rules
- ✅ Security Best Practices
- ✅ Code Quality Standards
- ✅ Documentation Completeness
- ✅ File Encoding Checks

**Ausführung**:
```powershell
.\Invoke-Tests.ps1 -TestType Validation
```

### 2. Unit Tests

**Zweck**: Isolierte Tests einzelner Funktionen/Skripte

- ✅ Deploy-FAS.ps1 (MSI Installation, Service Management)
- 🔲 Configure-FAS.ps1 (Certificate Templates, CA Integration)
- 🔲 Configure-FAS-UserRules.ps1 (User Rules, ACLs)

**Ausführung**:
```powershell
.\Invoke-Tests.ps1 -TestType Unit
```

### 3. Integration Tests

**Zweck**: End-to-End Workflows mit allen Mocks

- ✅ Full Deployment Workflow (Install → Configure → UserRules)
- ✅ Error Handling Scenarios
- ✅ Template Schema Validation (v2 vs. v4)
- ✅ Certificate Lifecycle Tests

**Ausführung**:
```powershell
.\Invoke-Tests.ps1 -TestType Integration
```

## Mock-Module

### FAS-SDK.psm1

**Gemockte FAS SDK Cmdlets**:
- `Get-FasServer`
- `New-FasMsTemplate`, `Publish-FasMsTemplate`
- `New-FasAuthorizationCertificate`, `Get-FasAuthorizationCertificate`
- `New-FasCertificateDefinition`, `Get-FasCertificateDefinition`
- `New-FasRule`, `Get-FasRule`

**Verwendung**:
```powershell
Import-Module ./Mocks/FAS-SDK.psm1

# Template erstellen
$template = New-FasMsTemplate -Address "fas.local" `
                             -Name "917Citrix_SmartcardLogon" `
                             -SecurityGroupSID "S-1-5-21-xxx"

# Validierung
$template.SchemaVersion | Should -Be 4
$template.HashAlgorithm | Should -Be "SHA256"
```

### WindowsServices.psm1

**Gemockte Windows Cmdlets**:
- `Get-Service`, `Start-Service`, `Stop-Service`
- `Get-ItemProperty` (Registry)
- `Start-Process` (MSI Installation)

**Verwendung**:
```powershell
Import-Module ./Mocks/WindowsServices.psm1

# Service erstellen
Initialize-MockService -Name "CitrixFederatedAuthenticationService"

# MSI Exit Code setzen
Set-MockMSIExitCode -MSIPath "C:\FAS.msi" -ExitCode 0
```

### ActiveDirectory.psm1

**Gemockte AD Funktionen**:
- `[System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()`
- `DirectorySearcher`, `DirectoryEntry`
- `Get-WinEvent` (Event Logs)
- Security Principal Checks

**Verwendung**:
```powershell
Import-Module ./Mocks/ActiveDirectory.psm1

# Domain initialisieren
Initialize-MockDomain -DomainName "example.local"

# Template hinzufügen
Add-MockCertificateTemplate -Name "917Citrix_SmartcardLogon" -SchemaVersion 4
```

## Test-Runner (`Invoke-Tests.ps1`)

### Parameter

| Parameter | Beschreibung | Beispiel |
|-----------|--------------|----------|
| `-TestType` | Art der Tests: `All`, `Unit`, `Integration`, `Validation` | `-TestType All` |
| `-OutputFormat` | Format: `Console`, `NUnitXml`, `JUnitXml` | `-OutputFormat JUnitXml` |
| `-OutputPath` | Pfad für XML-Ausgabe | `-OutputPath "results.xml"` |
| `-CodeCoverage` | Code Coverage aktivieren | `-CodeCoverage` |
| `-Tags` | Filter nach Pester Tags | `-Tags "Unit","Security"` |

### Beispiele

```powershell
# Alle Tests mit Console-Ausgabe
.\Invoke-Tests.ps1 -TestType All

# Nur Unit Tests mit XML-Ausgabe (für CI/CD)
.\Invoke-Tests.ps1 -TestType Unit `
                  -OutputFormat JUnitXml `
                  -OutputPath "unit-results.xml"

# Integration Tests mit Code Coverage
.\Invoke-Tests.ps1 -TestType Integration -CodeCoverage

# Tests mit Tag-Filter
.\Invoke-Tests.ps1 -Tags "Unit","Integration"
```

## CI/CD Integration

### GitHub Actions

**Workflow**: `.github/workflows/powershell-tests.yml`

**Features**:
- ✅ Automatische Tests bei Push/PR
- ✅ Matrix-basierte parallele Ausführung
- ✅ Test Result Publishing
- ✅ Code Coverage (Codecov)
- ✅ Artifact Upload

**Trigger**:
- Push zu `main` oder `develop`
- Pull Requests
- Manuelle Ausführung (`workflow_dispatch`)

**Jobs**:
1. **Test Matrix**: Validation, Unit, Integration (parallel)
2. **Code Coverage**: JaCoCo Coverage Report
3. **Summary**: Gesamtübersicht

## Pester Best Practices

### Test-Struktur

```powershell
Describe "Script Name - Category" -Tag 'TagName' {

    BeforeAll {
        # Einmalige Setup-Operationen
        Import-Module ./Mocks/FAS-SDK.psm1
    }

    BeforeEach {
        # Vor jedem Test: Mocks zurücksetzen
        Reset-FasMockData
        Reset-WindowsServicesMockData
        Reset-ActiveDirectoryMockData
    }

    Context "Specific Scenario" {

        It "Should perform specific action" {
            # Arrange
            # ... Setup

            # Act
            # ... Aktion

            # Assert
            $result | Should -Be "Expected" -Because "Clear reason"
        }
    }
}
```

### Mocks zurücksetzen

```powershell
BeforeEach {
    Reset-FasMockData                    # FAS SDK Mocks
    Reset-WindowsServicesMockData        # Windows Services/Registry
    Reset-ActiveDirectoryMockData        # Active Directory/Event Logs
}
```

### Assertions

```powershell
# ✅ Gut: Spezifisch mit Because
$result | Should -Be "Value" -Because "Clear reason"

# ✅ Gut: Mehrere Assertions
$object.Property1 | Should -Be "Value1"
$object.Property2 | Should -Be "Value2"

# ❌ Vermeiden: Unspezifisch
$result | Should -Not -BeNullOrEmpty
```

## Code Coverage

### Ausführung

```powershell
.\Invoke-Tests.ps1 -TestType All -CodeCoverage
```

### Output

- **JaCoCo XML**: `tests/coverage.xml`
- **Console Report**: Zusammenfassung in Terminal

### Ziele

- 🎯 **Minimum**: 60% Coverage
- 🎯 **Target**: 80% Coverage
- 🎯 **Ideal**: >90% Coverage

## Fehlersuche

### Problem: "Pester module not found"

**Lösung**:
```powershell
Install-Module -Name Pester -MinimumVersion 5.0.0 -Scope CurrentUser -Force
```

### Problem: "PSScriptAnalyzer not found" (nur Validation Tests)

**Lösung**:
```powershell
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
```

### Problem: Tests schlagen fehl mit "Cmdlet not found"

**Lösung**: Mock-Module korrekt importieren
```powershell
BeforeAll {
    $mockPath = Join-Path $PSScriptRoot '..' 'Mocks'
    Import-Module (Join-Path $mockPath 'FAS-SDK.psm1') -Force
}
```

### Problem: Mock-Daten bleiben persistent zwischen Tests

**Lösung**: `BeforeEach` mit Reset-Funktionen verwenden
```powershell
BeforeEach {
    Reset-FasMockData
    Reset-WindowsServicesMockData
    Reset-ActiveDirectoryMockData
}
```

## Erweiterung

### Neue Tests hinzufügen

1. **Test-Datei erstellen** in `Unit/`, `Integration/` oder `Validation/`
2. **Pester Struktur** verwenden (`Describe`, `Context`, `It`)
3. **Mocks importieren** in `BeforeAll`
4. **Mocks zurücksetzen** in `BeforeEach`
5. **Tests ausführen** mit `Invoke-Tests.ps1`

### Neue Mocks hinzufügen

1. **Mock-Funktion** in `Mocks/FAS-SDK.psm1`, `WindowsServices.psm1` oder `ActiveDirectory.psm1`
2. **Export-ModuleMember** aktualisieren
3. **Tests schreiben** mit neuem Mock
4. **Dokumentation aktualisieren**

## Dokumentation

- **Umfassende Anleitung**: [`docs/testing/MOCK-TESTING-GUIDE.md`](../docs/testing/MOCK-TESTING-GUIDE.md)
- **Mock-Module Details**: Siehe `Mocks/*.psm1` Dateien
- **Test-Beispiele**: Siehe `Unit/*.Tests.ps1`, `Integration/*.Tests.ps1`

## Status

### ✅ Implementiert

- [x] FAS-SDK Mock-Modul
- [x] WindowsServices Mock-Modul
- [x] ActiveDirectory Mock-Modul
- [x] Syntax Validation Tests
- [x] Deploy-FAS Unit Tests
- [x] Full Deployment Integration Tests
- [x] Test-Runner (`Invoke-Tests.ps1`)
- [x] GitHub Actions CI/CD
- [x] Umfassende Dokumentation

### 🔲 TODO

- [ ] Configure-FAS Unit Tests (vollständig)
- [ ] Configure-FAS-UserRules Unit Tests (vollständig)
- [ ] Performance/Benchmark Tests
- [ ] Erweiterte Error Handling Tests
- [ ] Mock-Daten Persistence Tests

## Support

Bei Fragen oder Problemen:

1. **Dokumentation prüfen**: `docs/testing/MOCK-TESTING-GUIDE.md`
2. **Beispiele ansehen**: `Unit/*.Tests.ps1`, `Integration/*.Tests.ps1`
3. **Issue erstellen**: GitHub Issues

---

**Version**: 1.0.0
**Letztes Update**: 2025-11-05
**Maintainer**: FAS Automation Team
