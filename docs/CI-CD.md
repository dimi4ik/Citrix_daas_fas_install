# CI/CD Integration - GitHub Actions

Automatisierte Tests für alle FAS PowerShell-Skripte bei jedem Push und Pull Request.

---

## Übersicht

**Workflow-Datei**: `.github/workflows/powershell-tests.yml`

**Trigger**:
- ✅ Push zu `main` oder `develop` Branch
- ✅ Pull Requests zu `main` oder `develop`
- ✅ Änderungen an PowerShell-Skripten (`scripts/**/*.ps1`, `scripts/**/*.psm1`)
- ✅ Änderungen an Tests (`tests/**/*.ps1`)
- ✅ Manuelle Ausführung (workflow_dispatch)

**Status**: [![PowerShell Tests](https://github.com/dimi4ik/Citrix_daas_fas_install/actions/workflows/powershell-tests.yml/badge.svg)](https://github.com/dimi4ik/Citrix_daas_fas_install/actions/workflows/powershell-tests.yml)

---

## Workflow-Jobs

### 1️⃣ Test Matrix (Parallel)

**3 parallele Jobs**:
- **Validation Tests** - Syntax, PSScriptAnalyzer, Security
- **Unit Tests** - Mock-basierte Unit Tests
- **Integration Tests** - End-to-End Workflows

**Runner**: `windows-latest` (Windows Server 2022)

**Schritte**:
1. Repository Checkout
2. Pester 5.x Installation
3. PSScriptAnalyzer Installation (nur für Validation)
4. Test-Ausführung mit JUnit XML Output
5. Test Results Publishing
6. Artifacts Upload (30 Tage Retention)

---

### 2️⃣ Code Coverage

**Ausführung**: Nach erfolgreichen Tests

**Schritte**:
1. Repository Checkout
2. Pester Installation
3. Tests mit Code Coverage (JaCoCo Format)
4. Codecov Upload
5. Coverage Artifact Upload

**Output**:
- JaCoCo XML: `tests/coverage.xml`
- Codecov Dashboard: Automatischer Upload

---

### 3️⃣ Summary

**Ausführung**: Nach allen Jobs

**Funktion**: Gesamtübersicht aller Test-Ergebnisse

---

## Workflow-Konfiguration

### Matrix-basierte Test-Ausführung

```yaml
strategy:
  matrix:
    test-type: ['Validation', 'Unit', 'Integration']
```

**Vorteile**:
- ⚡ Parallele Ausführung (3x schneller)
- 🎯 Granulare Fehleranalyse
- 📊 Separate Test Reports

---

### Test-Ausführung

```yaml
- name: Run ${{ matrix.test-type }} Tests
  shell: pwsh
  run: |
    .\tests\Invoke-Tests.ps1 `
      -TestType ${{ matrix.test-type }} `
      -OutputFormat JUnitXml `
      -OutputPath "test-results-${{ matrix.test-type }}.xml" `
      -Verbose
```

**Output**: JUnit XML für GitHub Test Reporting

---

### Test Results Publishing

```yaml
- name: Publish Test Results
  uses: EnricoMi/publish-unit-test-result-action/windows@v2
  if: always()
  with:
    files: 'test-results-${{ matrix.test-type }}.xml'
    check_name: 'PowerShell Test Results (${{ matrix.test-type }})'
```

**Funktion**:
- ✅ Test Results als GitHub Check
- ✅ Kommentare in Pull Requests
- ✅ Übersichtliche Test-Statistiken

---

## Test Results

### GitHub Checks

**Ansicht**: Pull Request → "Checks" Tab

**Informationen**:
- Anzahl Tests (Total, Passed, Failed, Skipped)
- Test-Dauer
- Fehlerdetails mit Stack Trace

**Beispiel**:
```
PowerShell Test Results (Validation)
✅ 25 passed, ❌ 0 failed, ⏭️ 0 skipped
Duration: 15s
```

---

### Artifacts

**Retention**: 30 Tage

**Verfügbare Artifacts**:
1. `test-results-Validation` - Validation Test Results (JUnit XML)
2. `test-results-Unit` - Unit Test Results (JUnit XML)
3. `test-results-Integration` - Integration Test Results (JUnit XML)
4. `coverage-report` - Code Coverage Report (JaCoCo XML)

**Download**: GitHub Actions → Workflow Run → Artifacts

---

## Code Coverage

### Codecov Integration

**Upload**: Automatisch nach Test-Ausführung

**Dashboard**: https://codecov.io/gh/dimi4ik/Citrix_daas_fas_install

**Metriken**:
- Line Coverage
- Branch Coverage
- Function Coverage
- File-Level Coverage

**Beispiel-Badge**:
```markdown
[![codecov](https://codecov.io/gh/dimi4ik/Citrix_daas_fas_install/branch/main/graph/badge.svg)](https://codecov.io/gh/dimi4ik/Citrix_daas_fas_install)
```

---

## Lokale Simulation

### Workflow lokal testen

```powershell
# Alle Tests (wie in GitHub Actions)
.\tests\Invoke-Tests.ps1 -TestType All `
                        -OutputFormat JUnitXml `
                        -OutputPath "test-results-local.xml"

# Mit Code Coverage
.\tests\Invoke-Tests.ps1 -TestType All -CodeCoverage
```

**Output**:
- JUnit XML: `test-results-local.xml`
- Coverage: `tests/coverage.xml`

---

## Troubleshooting

### Problem: Tests schlagen in GitHub Actions fehl, lokal aber nicht

**Ursache**: Unterschiedliche PowerShell-Versionen oder Module

**Lösung**:
```powershell
# PowerShell Version prüfen
$PSVersionTable.PSVersion

# In GitHub Actions wird PowerShell 7.x verwendet (pwsh)
# Lokal testen mit:
pwsh -Command ".\tests\Invoke-Tests.ps1 -TestType All"
```

---

### Problem: Code Coverage nicht hochgeladen

**Ursache**: Codecov Token fehlt oder falsch

**Lösung**:
1. Codecov Account erstellen (https://codecov.io)
2. Repository hinzufügen
3. Token in GitHub Secrets speichern: `CODECOV_TOKEN`
4. Workflow aktualisieren:
```yaml
- name: Upload Coverage to Codecov
  uses: codecov/codecov-action@v4
  with:
    files: ./tests/coverage.xml
    token: ${{ secrets.CODECOV_TOKEN }}  # Hinzufügen
```

---

### Problem: Workflow läuft nicht bei Push

**Ursache**: Path-Filter ausschließt Änderungen

**Lösung**: Workflow-Trigger prüfen
```yaml
on:
  push:
    paths:
      - 'scripts/**/*.ps1'
      - 'scripts/**/*.psm1'
      - 'tests/**/*.ps1'
      # Weitere Pfade hinzufügen falls erforderlich
```

---

## Best Practices

### 1. Branching Strategy

```
main (protected)
  ↑
  └── develop (protected)
       ↑
       └── feature/... (Tests erforderlich)
```

**Branch Protection Rules**:
- ✅ Require status checks to pass (PowerShell Tests)
- ✅ Require branches to be up to date
- ✅ Include administrators

---

### 2. Pull Request Workflow

1. **Feature Branch erstellen**
   ```bash
   git checkout -b feature/neue-funktion
   ```

2. **Änderungen committen**
   ```bash
   git add .
   git commit -m "feat: Neue Funktion"
   ```

3. **Lokale Tests ausführen** (optional, aber empfohlen)
   ```powershell
   .\tests\Invoke-Tests.ps1 -TestType All
   ```

4. **Push und Pull Request**
   ```bash
   git push origin feature/neue-funktion
   ```

5. **GitHub Actions prüfen** - Tests müssen bestehen
6. **Review und Merge**

---

### 3. Test-Driven Development (TDD)

**Workflow**:
1. **Red**: Test schreiben (schlägt fehl)
2. **Green**: Code implementieren (Test besteht)
3. **Refactor**: Code optimieren (Test bleibt grün)

**Beispiel**:
```powershell
# 1. Test schreiben
It "Should start FAS service" {
    Start-Service -Name "CitrixFederatedAuthenticationService"
    $service = Get-Service -Name "CitrixFederatedAuthenticationService"
    $service.Status | Should -Be "Running"
}

# 2. Code implementieren (in Mock oder echtem Skript)

# 3. Test ausführen
.\tests\Invoke-Tests.ps1 -TestType Unit
```

---

## Performance

### Workflow-Laufzeiten

| Job | Durchschnitt | Varianz |
|-----|--------------|---------|
| Validation Tests | ~15-30s | ±5s |
| Unit Tests | ~10-20s | ±5s |
| Integration Tests | ~20-40s | ±10s |
| Code Coverage | ~30-60s | ±10s |

**Gesamt (parallel)**: ~40-60 Sekunden

---

## Sicherheit

### Secrets Management

**GitHub Secrets** (Repository Settings → Secrets and variables → Actions):
- `CODECOV_TOKEN` - Codecov Upload Token
- Weitere Secrets nach Bedarf (z.B. für Deployment)

**Verwendung**:
```yaml
- name: Upload to Codecov
  env:
    CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
  run: |
    # Upload mit Token
```

**Best Practices**:
- ❌ Keine Secrets in Logs ausgeben
- ❌ Keine Secrets in Test-Dateien hardcoden
- ✅ Secrets nur in verschlüsselten GitHub Secrets
- ✅ Least Privilege für Tokens

---

## Monitoring

### Workflow-Status überwachen

**GitHub Actions Dashboard**:
- Repository → "Actions" Tab
- Workflow Runs Übersicht
- Failure Notifications (GitHub Notifications)

**Email-Benachrichtigungen**:
- GitHub Account Settings → Notifications
- "Actions" Notifications aktivieren

**Status Badge**:
```markdown
[![PowerShell Tests](https://github.com/dimi4ik/Citrix_daas_fas_install/actions/workflows/powershell-tests.yml/badge.svg)](https://github.com/dimi4ik/Citrix_daas_fas_install/actions/workflows/powershell-tests.yml)
```

---

## Erweiterung

### Weitere Test-Typen hinzufügen

```yaml
strategy:
  matrix:
    test-type: ['Validation', 'Unit', 'Integration', 'Performance']  # Neu: Performance
```

### Deployment-Job hinzufügen

```yaml
deploy:
  name: Deploy to Production
  runs-on: windows-latest
  needs: [test, code-coverage]  # Nur nach erfolgreichen Tests
  if: github.ref == 'refs/heads/main'  # Nur auf main Branch

  steps:
    - name: Deploy FAS Scripts
      run: |
        # Deployment-Logik
```

---

## Cheat Sheet

```powershell
# === LOKALE TESTS (wie in CI/CD) ===
.\tests\Invoke-Tests.ps1 -TestType All -OutputFormat JUnitXml -OutputPath "results.xml"

# === CODE COVERAGE ===
.\tests\Invoke-Tests.ps1 -TestType All -CodeCoverage

# === GITHUB ACTIONS STATUS ===
# https://github.com/dimi4ik/Citrix_daas_fas_install/actions

# === ARTIFACTS DOWNLOAD ===
# GitHub Actions → Workflow Run → Artifacts (unten)

# === BRANCH PROTECTION ===
# Repository Settings → Branches → Branch protection rules
```

---

## Weiterführende Ressourcen

- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **Pester Docs**: https://pester.dev/docs/quick-start
- **Codecov Docs**: https://docs.codecov.com/docs

---

**Version**: 1.0.0
**Letztes Update**: 2025-11-05
**Maintainer**: FAS Automation Team
