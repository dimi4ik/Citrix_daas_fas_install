---
description: "Umfassende PowerShell Syntax- und Konfigurations-Validierung für FAS Skripte"
---

# FAS Validation Workflow

Du bist ein Citrix FAS PowerShell Experte. Führe eine umfassende Validierung aller FAS Installation Skripte durch.

## Validierungs-Workflow

### 1. PowerShell Syntax Validierung
```powershell
# Validiere alle .ps1 Skripte
Get-ChildItem -Path scripts/*.ps1 | ForEach-Object {
    $errors = $null
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $_.FullName -Raw), [ref]$errors)
    if ($errors) {
        Write-Warning "$($_.Name) hat Syntax-Fehler:"
        $errors | ForEach-Object { Write-Warning "  Zeile $($_.Token.StartLine): $($_.Message)" }
    } else {
        Write-Host "$($_.Name) - OK" -ForegroundColor Green
    }
}
```

### 2. PowerShell Script Analyzer (PSScriptAnalyzer)
```powershell
# Installiere PSScriptAnalyzer falls nicht vorhanden
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
}

# Analysiere alle Skripte
$scripts = @('Deploy-FAS.ps1', 'Configure-FAS.ps1', 'Configure-FAS-UserRules.ps1')
foreach ($script in $scripts) {
    Write-Host "`n=== Analysiere $script ===" -ForegroundColor Cyan
    Invoke-ScriptAnalyzer -Path "scripts/$script" -Severity Warning,Error
}
```

### 3. Konfigurationsdateien Validierung
- Prüfe `config/*.json` auf gültige JSON Syntax
- Validiere erforderliche Parameter (Server, Credentials, etc.)
- Prüfe CA-Zertifikat Pfade und Gültigkeit

### 4. Umgebungsvoraussetzungen
Prüfe folgende Voraussetzungen:
- [ ] PowerShell Version >= 5.1
- [ ] Citrix FAS PowerShell Module installiert
- [ ] Active Directory Module verfügbar
- [ ] Netzwerkzugriff auf FAS Server
- [ ] Erforderliche Berechtigungen (Domain Admin)

### 5. Sicherheitscheck
- [ ] Keine Hardcoded Credentials in Skripten
- [ ] Verwendung von SecureString für Passwörter
- [ ] Korrekte Certificate Validation
- [ ] Audit Logging aktiviert

## Ausgabe

Erstelle einen Validierungsbericht mit:
1. ✅ Erfolgreich validierte Skripte
2. ⚠️  Warnungen (Best Practice Violations)
3. ❌ Fehler (Syntax, Konfiguration, Security)
4. 📋 Empfehlungen für Verbesserungen

## Best Practices

- Verwende `Set-StrictMode -Version Latest`
- Implementiere umfassende Error Handling mit `try/catch`
- Logge alle Aktionen in dedizierte Log-Dateien
- Verwende Parameter Validation Attributes
- Implementiere `-WhatIf` Support für gefährliche Operationen
