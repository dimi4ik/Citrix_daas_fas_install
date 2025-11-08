# Contributing to Citrix FAS Installation Automation

Vielen Dank für dein Interesse, zu diesem Projekt beizutragen! 🎉

## 📋 Inhaltsverzeichnis

- [Code of Conduct](#code-of-conduct)
- [Wie kann ich beitragen?](#wie-kann-ich-beitragen)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Commit Message Guidelines](#commit-message-guidelines)

## Code of Conduct

Dieses Projekt folgt dem [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). Durch deine Teilnahme erwartest du, diesen Code einzuhalten.

## Wie kann ich beitragen?

### 🐛 Bug Reports

Wenn du einen Bug findest, erstelle bitte ein [GitHub Issue](https://github.com/dimi4ik/Citrix_daas_fas_install/issues) mit folgenden Informationen:

- **Beschreibung**: Klare Beschreibung des Problems
- **Reproduktionsschritte**: Schritt-für-Schritt Anleitung
- **Erwartetes Verhalten**: Was sollte passieren?
- **Aktuelles Verhalten**: Was passiert stattdessen?
- **Environment**: Windows Version, PowerShell Version, Citrix Version
- **Logs**: Relevante Log-Ausgaben

### 💡 Feature Requests

Für neue Features, erstelle ein Issue mit:

- **Use Case**: Warum wird das Feature benötigt?
- **Beschreibung**: Detaillierte Beschreibung der Funktionalität
- **Beispiele**: Code-Beispiele oder Screenshots (optional)

### 📝 Documentation

Verbesserungen an der Dokumentation sind immer willkommen:

- README.md Erweiterungen
- Code-Kommentare
- Deployment-Guides in `docs/`
- Troubleshooting-Guides

### 🔧 Code Contributions

1. **Fork** das Repository
2. **Clone** deinen Fork
3. **Branch** erstellen: `git checkout -b feature/mein-feature`
4. **Entwickeln** und **testen**
5. **Commit** mit aussagekräftiger Message
6. **Push** zu deinem Fork
7. **Pull Request** erstellen

## Development Setup

### Voraussetzungen

```powershell
# PowerShell 5.1 oder höher
$PSVersionTable.PSVersion

# Pester 5.x installieren
Install-Module -Name Pester -MinimumVersion 5.0.0 -Scope CurrentUser -Force

# PSScriptAnalyzer installieren
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force

# Pre-Commit Hooks (optional)
pip install pre-commit
pre-commit install
```

### Repository Setup

```powershell
# Repository klonen
git clone https://github.com/dimi4ik/Citrix_daas_fas_install.git
cd Citrix_daas_fas_install

# Feature Branch erstellen
git checkout -b feature/mein-feature

# Konfiguration anpassen
Copy-Item .\config\dev.json .\config\local.json
# Editiere local.json mit deinen Einstellungen
```

## Coding Standards

### PowerShell Best Practices

#### 1. Strict Mode und Error Handling

**IMMER verwenden:**

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
```

**Proper Error Handling:**

```powershell
try {
    # Operationen
    Invoke-SomeCommand -ErrorAction Stop
}
catch {
    Write-Error "Failed: $($_.Exception.Message)"
    throw
}
finally {
    # Cleanup
}
```

#### 2. Parameter Validation

```powershell
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ConfigFile,

    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 3600)]
    [int]$Timeout = 300
)
```

#### 3. Funktionen mit Comment-Based Help

```powershell
function Get-FASConfiguration {
    <#
    .SYNOPSIS
        Retrieves FAS configuration from server

    .DESCRIPTION
        Detailed description of what the function does

    .PARAMETER Address
        FAS Server address (FQDN)

    .EXAMPLE
        Get-FASConfiguration -Address "fas.domain.com"

    .NOTES
        Author: Your Name
        Version: 1.0.0
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Address
    )

    # Implementation
}
```

#### 4. Logging

Verwende die zentrale `Write-Log` Funktion (wird in jedem Skript definiert):

```powershell
Write-Log "Starting operation..." -Level Info
Write-Log "Warning: Configuration incomplete" -Level Warning
Write-Log "Error occurred: $($_.Exception.Message)" -Level Error
Write-Log "Operation completed successfully" -Level Success
```

#### 5. Naming Conventions

- **Functions**: `Verb-Noun` (Get-FASServer, Set-FASConfiguration)
- **Variables**: `$camelCase` oder `$PascalCase`
- **Parameters**: `$PascalCase`
- **Constants**: `$UPPER_CASE`

### PSScriptAnalyzer Rules

**Alle Skripte müssen PSScriptAnalyzer-Clean sein:**

```powershell
# Lokale Validierung
Invoke-ScriptAnalyzer -Path .\scripts\ -Settings .\PSScriptAnalyzerSettings.psd1 -Recurse

# Sollte keine Errors oder Warnings zurückgeben
```

**Kritische Rules:**

- ✅ `PSAvoidUsingPlainTextForPassword` - Keine Klartext-Passwörter
- ✅ `PSAvoidUsingInvokeExpression` - Kein `Invoke-Expression`
- ✅ `PSUsePSCredentialType` - PSCredential für Credentials verwenden
- ✅ `PSAvoidUsingComputerNameHardcoded` - Keine hardcoded Hostnamen

### Security Standards

#### 1. Keine Hardcoded Credentials

**❌ FALSCH:**

```powershell
$password = "MyPassword123"
$username = "domain\administrator"
```

**✅ RICHTIG:**

```powershell
$credential = Get-Credential -Message "Enter FAS Service Account"
# oder
$securePassword = Read-Host -AsSecureString -Prompt "Password"
```

#### 2. Keine Secrets in Config-Dateien

**❌ Niemals committen:**
- Passwörter
- API Keys
- Certificates (private keys)
- SIDs von Production-Accounts

**✅ Stattdessen:**
- Verwende Platzhalter in Beispiel-Configs
- Dokumentiere erforderliche Secrets
- Nutze Environment Variables oder Credential Manager

#### 3. Input Validation

```powershell
[ValidateScript({
    if (-not (Test-Path $_)) {
        throw "File not found: $_"
    }
    if ($_ -notmatch '\.json$') {
        throw "Must be JSON file: $_"
    }
    return $true
})]
[string]$ConfigFile
```

## Testing

### Test-Kategorien

1. **Validation Tests** - Syntax, PSScriptAnalyzer
2. **Unit Tests** - Einzelne Funktionen (mit Mocks)
3. **Integration Tests** - End-to-End Workflows
4. **Security Tests** - Credential Scanning, Injection Tests

### Tests ausführen

```powershell
# Alle Tests
.\tests\Invoke-Tests.ps1 -TestType All -Verbose

# Nur Validation
.\tests\Invoke-Tests.ps1 -TestType Validation

# Nur Unit Tests
.\tests\Invoke-Tests.ps1 -TestType Unit

# Mit Code Coverage
.\tests\Invoke-Tests.ps1 -TestType All -CodeCoverage
```

### Test Coverage Anforderungen

- **Minimum**: 70% Code Coverage
- **Target**: 80% Code Coverage
- **Kritische Funktionen**: 90%+ Coverage

### Neue Tests schreiben

Beispiel für Pester 5.x Test:

```powershell
BeforeAll {
    # Setup
    . "$PSScriptRoot/../scripts/Deploy-FAS.ps1"
}

Describe "Deploy-FAS" {
    Context "Parameter Validation" {
        It "Should require ConfigFile parameter" {
            { Deploy-FAS } | Should -Throw
        }

        It "Should validate ConfigFile exists" {
            { Deploy-FAS -ConfigFile "nonexistent.json" } | Should -Throw
        }
    }

    Context "Deployment Process" {
        BeforeEach {
            # Mock external dependencies
            Mock Get-Service { return @{ Status = "Running" } }
        }

        It "Should check prerequisites" {
            # Test implementation
            $result = Test-Prerequisites
            $result | Should -Be $true
        }
    }
}
```

## Pull Request Process

### 1. Pre-PR Checklist

- [ ] **Tests**: Alle Tests laufen erfolgreich
- [ ] **PSScriptAnalyzer**: Keine Errors oder Warnings
- [ ] **Code Coverage**: Mindestens 70% (idealerweise 80%)
- [ ] **Documentation**: Code-Kommentare und README Updates
- [ ] **Security**: Keine hardcoded Credentials
- [ ] **Commits**: Aussagekräftige Commit Messages
- [ ] **Branch**: Aktuell mit `main` Branch

### 2. PR Erstellen

```bash
# Aktuelle Änderungen
git status

# Staging
git add .

# Commit (siehe Commit Guidelines unten)
git commit -m "feat: Add certificate validation function"

# Push zu deinem Fork
git push origin feature/mein-feature
```

**PR Template verwenden:**

```markdown
## Description
Kurze Beschreibung der Änderungen

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit Tests hinzugefügt
- [ ] Integration Tests aktualisiert
- [ ] Manuelle Tests durchgeführt

## Checklist
- [ ] PSScriptAnalyzer Clean
- [ ] Tests erfolgreich
- [ ] Documentation aktualisiert
- [ ] Keine hardcoded Secrets
```

### 3. Code Review Process

1. **Automated Checks**: GitHub Actions müssen grün sein
2. **Code Review**: Mindestens 1 Approval erforderlich
3. **Discussion**: Feedback konstruktiv diskutieren
4. **Updates**: Änderungen basierend auf Review einarbeiten
5. **Merge**: Nach Approval wird gemerged

## Commit Message Guidelines

### Format

Wir verwenden [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: Neues Feature
- **fix**: Bug Fix
- **docs**: Dokumentation
- **style**: Code-Formatierung (kein funktionaler Change)
- **refactor**: Code-Refactoring
- **test**: Tests hinzufügen/ändern
- **chore**: Build-Prozess, Dependencies

### Scope (Optional)

- `deploy`: Deployment-Skripte
- `config`: Konfiguration
- `test`: Tests
- `docs`: Dokumentation
- `security`: Security-bezogene Änderungen

### Beispiele

```bash
# Feature
git commit -m "feat(deploy): Add retry logic for MSI installation"

# Bug Fix
git commit -m "fix(config): Correct CA server validation regex"

# Documentation
git commit -m "docs(readme): Add troubleshooting section for certificate errors"

# Test
git commit -m "test(integration): Add full deployment test with mocks"

# Security
git commit -m "security(config): Remove hardcoded test credentials"
```

### Commit Message Body (Optional)

Für komplexere Changes:

```
feat(deploy): Add retry logic for MSI installation

MSI installations can fail due to transient issues. This commit adds
exponential backoff retry logic with configurable attempts.

- Default: 3 retry attempts
- Backoff: 2s, 4s, 8s
- Configurable via -RetryAttempts parameter

Closes #123
```

## Fragen?

- **Issues**: [GitHub Issues](https://github.com/dimi4ik/Citrix_daas_fas_install/issues)
- **Discussions**: [GitHub Discussions](https://github.com/dimi4ik/Citrix_daas_fas_install/discussions)
- **Email**: dima@lejkin.de

---

**Danke für deinen Beitrag!** 🚀
