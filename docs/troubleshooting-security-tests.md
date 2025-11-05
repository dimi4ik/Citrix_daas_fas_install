# Troubleshooting Security Tests
## Complete Guide to Resolving Security Scan Issues

**Version:** 1.0.0
**Last Updated:** 2025-11-05

---

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Scanning Errors](#scanning-errors)
3. [False Positives](#false-positives)
4. [Performance Problems](#performance-problems)
5. [Output and Reporting](#output-and-reporting)
6. [Integration Issues](#integration-issues)
7. [Common Violations and Fixes](#common-violations-and-fixes)

---

## Installation Issues

### Issue 1: PSScriptAnalyzer Module Not Found

**Error Message:**
```
ModuleNotFoundError: Module 'PSScriptAnalyzer' not found
```

**Diagnosis:**
```powershell
# Check if module is installed
Get-Module -Name PSScriptAnalyzer -ListAvailable
```

**Solutions:**

**Solution 1: Install from PowerShell Gallery**
```powershell
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
```

**Solution 2: Install for All Users (requires admin)**
```powershell
Install-Module -Name PSScriptAnalyzer -Force -Scope AllUsers
```

**Solution 3: Offline Installation**
```powershell
# On internet-connected machine:
Save-Module -Name PSScriptAnalyzer -Path C:\Temp\Modules

# Copy to target machine and import
Import-Module C:\Temp\Modules\PSScriptAnalyzer\<version>\PSScriptAnalyzer.psd1
```

**Verification:**
```powershell
Import-Module PSScriptAnalyzer
Get-Command Invoke-ScriptAnalyzer
```

---

### Issue 2: Custom Rules Not Loading

**Error Message:**
```
WARNING: Custom rules not detected
```

**Diagnosis:**
```powershell
# Check custom rules path
$settings = Import-PowerShellDataFile ./PSScriptAnalyzerSettings.psd1
$settings.CustomRulePath

# Verify files exist
Get-ChildItem ./tests/SecurityRules/*.psm1
```

**Solutions:**

**Solution 1: Verify File Structure**
```bash
# Expected structure:
tests/
  └── SecurityRules/
      ├── Measure-HardcodedCredentials.psm1
      ├── Measure-PlainTextPassword.psm1
      ├── Measure-InvokeExpressionUsage.psm1
      └── Measure-ADDomainConsistency.psm1
```

**Solution 2: Check Path in Settings**
```powershell
# In PSScriptAnalyzerSettings.psd1
@{
    CustomRulePath = @(
        './tests/SecurityRules'  # Must be relative to settings file
    )
    RecurseCustomRulePath = $true
}
```

**Solution 3: Manually Test Rule Loading**
```powershell
Import-Module ./tests/SecurityRules/Measure-HardcodedCredentials.psm1 -Force

# Should return function
Get-Command Measure-HardcodedCredentials
```

**Solution 4: Check Execution Policy**
```powershell
# View current policy
Get-ExecutionPolicy

# Set to allow local scripts (if needed)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

---

### Issue 3: Pester Module Version Conflict

**Error Message:**
```
Pester version 5.x required, but version 3.x installed
```

**Solution:**
```powershell
# Uninstall old version
Get-Module Pester -ListAvailable | Uninstall-Module -Force

# Install Pester 5.x
Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser

# Verify version
Get-Module Pester -ListAvailable | Select-Object Version
```

---

## Scanning Errors

### Issue 4: Settings File Not Found

**Error Message:**
```
ERROR: Settings file not found: ./PSScriptAnalyzerSettings.psd1
```

**Diagnosis:**
```powershell
# Check current directory
Get-Location

# Check if settings file exists
Test-Path ./PSScriptAnalyzerSettings.psd1
```

**Solution:**
```powershell
# Settings file must be in repository root
# Verify path in Invoke-SecurityTests.ps1

# Option 1: Run from repository root
cd C:\Path\To\Citrix_daas_fas_install
.\tests\Invoke-SecurityTests.ps1

# Option 2: Specify absolute path
$settingsPath = "C:\Path\To\Citrix_daas_fas_install\PSScriptAnalyzerSettings.psd1"
Invoke-ScriptAnalyzer -Path ./scripts/ -Settings $settingsPath
```

---

### Issue 5: AST Parsing Errors

**Error Message:**
```
Error in Measure-HardcodedCredentials: AST parsing failed
```

**Diagnosis:**
The target PowerShell script has syntax errors.

**Solution:**
```powershell
# Test script syntax first
$scriptPath = "./scripts/Deploy-FAS.ps1"
$null = [System.Management.Automation.Language.Parser]::ParseFile(
    $scriptPath,
    [ref]$null,
    [ref]$errors
)

if ($errors) {
    $errors | Format-List *
}
```

**Common Syntax Errors:**
- Missing closing braces `}`
- Unclosed strings `"`
- Invalid parameter attributes
- Typos in cmdlet names

**Fix:**
1. Open script in PowerShell ISE or VS Code
2. Look for red squiggly lines
3. Correct syntax errors
4. Re-run security scan

---

### Issue 6: Scan Timeout

**Error Message:**
```
ERROR: Scan timeout after 120 seconds
```

**Diagnosis:**
Script is too large or custom rules are inefficient.

**Solutions:**

**Solution 1: Increase Timeout**
```powershell
# In Invoke-SecurityTests.ps1, modify timeout
# (Currently not configurable - future enhancement)
```

**Solution 2: Scan Files Individually**
```powershell
# Instead of scanning entire directory
Get-ChildItem ./scripts/*.ps1 | ForEach-Object {
    Write-Host "Scanning: $($_.Name)"
    .\tests\Invoke-SecurityTests.ps1 -Path $_.FullName
}
```

**Solution 3: Reduce Scope**
```powershell
# Only scan for critical issues
.\tests\Invoke-SecurityTests.ps1 -Severity Error
```

---

## False Positives

### Issue 7: SID Values Flagged as Credentials

**Error Message:**
```
FAS-CRED-001: Hardcoded credential detected
$FASSecurityGroupSID = "S-1-5-21-1234567890..."
```

**Why This Happens:**
SIDs contain hyphens and numbers, which can look like passwords to pattern matching.

**Expected Behavior:**
Our custom rules are **AD-aware** and should NOT flag SIDs.

**If This Happens:**

**Solution 1: Verify Rule Version**
```powershell
# Check Measure-HardcodedCredentials.psm1
# Should contain whitelist pattern:
# 'S-1-5-21-\d+-\d+-\d+-\d+'
```

**Solution 2: Suppress Specific Finding**
```powershell
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('FAS-CRED-001', '',
    Justification='Valid SID value for FAS Security Group')]
$FASSecurityGroupSID = "S-1-5-21-1234567890-1234567890-1234567890-1234"
```

**Solution 3: Report Bug**
If SIDs are still flagged, this is a bug. Report at: https://github.com/dimi4ik/Citrix_daas_fas_install/issues

---

### Issue 8: Certificate Template Names Flagged

**Error Message:**
```
FAS-CRED-001: Hardcoded credential detected
$templateName = "917Citrix_SmartcardLogon"
```

**Solution:**
```powershell
# Certificate template names are whitelisted
# Check Measure-HardcodedCredentials.psm1 whitelist:
$whitelistPatterns = @(
    '917Citrix_SmartcardLogon',
    'Citrix_RegistrationAuthority',
    'SmartcardLogon'
)

# If template name not in whitelist, suppress:
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('FAS-CRED-001', '',
    Justification='Certificate template name, not a credential')]
$templateName = "CustomTemplate_Name"
```

---

### Issue 9: Read-Host Flagged as Insecure

**Error Message:**
```
FAS-CRED-002: Plain-text password detected
$password = Read-Host "Enter password"
```

**Why This Happens:**
Read-Host without `-AsSecureString` returns plain-text.

**Solution:**
```powershell
# WRONG
$password = Read-Host "Enter password"

# CORRECT
$password = Read-Host "Enter password" -AsSecureString
```

**If using Read-Host correctly but still flagged:**
```powershell
# Suppress (should not be necessary if using -AsSecureString)
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('FAS-CRED-002', '',
    Justification='Interactive input with SecureString')]
$password = Read-Host "Enter password" -AsSecureString
```

---

## Performance Problems

### Issue 10: Scan Takes Too Long

**Symptoms:**
- Scan takes > 5 minutes for small codebase
- High CPU/memory usage
- "Not Responding" in console

**Diagnosis:**
```powershell
# Measure scan time
Measure-Command {
    .\tests\Invoke-SecurityTests.ps1
}
```

**Solutions:**

**Solution 1: Scan Specific Files**
```powershell
# Instead of all scripts
.\tests\Invoke-SecurityTests.ps1 -Path ./scripts/Deploy-FAS.ps1
```

**Solution 2: Reduce Severity**
```powershell
# Only critical errors
.\tests\Invoke-SecurityTests.ps1 -Severity Error
```

**Solution 3: Disable Custom Rules Temporarily**
```powershell
# Use only built-in rules
Invoke-ScriptAnalyzer -Path ./scripts/ -Severity Error,Warning
```

**Solution 4: Parallel Scanning**
```powershell
# Scan files in parallel
Get-ChildItem ./scripts/*.ps1 | ForEach-Object -Parallel {
    Invoke-ScriptAnalyzer -Path $_.FullName -Settings ../PSScriptAnalyzerSettings.psd1
} -ThrottleLimit 4
```

---

### Issue 11: High Memory Usage

**Symptoms:**
- PowerShell process using > 1GB RAM
- OutOfMemoryException

**Solutions:**

**Solution 1: Scan in Batches**
```powershell
# Scan 5 files at a time
$scripts = Get-ChildItem ./scripts/*.ps1
for ($i = 0; $i -lt $scripts.Count; $i += 5) {
    $batch = $scripts[$i..($i+4)]
    $batch | ForEach-Object {
        .\tests\Invoke-SecurityTests.ps1 -Path $_.FullName
    }
}
```

**Solution 2: Restart PowerShell Session**
```powershell
# Add to long-running scripts
if ((Get-Process -Id $PID).WorkingSet64 -gt 1GB) {
    Write-Warning "High memory usage detected, restart recommended"
}
```

---

## Output and Reporting

### Issue 12: SARIF File Invalid

**Error Message:**
```
GitLab: Invalid SARIF schema
```

**Diagnosis:**
```powershell
# Validate SARIF file
$sarif = Get-Content ./security-reports/security-report.sarif | ConvertFrom-Json

# Check schema version
$sarif.'$schema'  # Should be 2.1.0

# Check required fields
$sarif.version
$sarif.runs
```

**Solution:**
```powershell
# Re-generate SARIF with latest version
.\tests\Invoke-SecurityTests.ps1 -OutputFormat SARIF -OutputPath ./reports/

# Validate against schema
$schema = Invoke-RestMethod "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json"

# Use JSON schema validator (if available)
Test-Json -Json (Get-Content ./reports/security-report.sarif -Raw) -Schema $schema
```

---

### Issue 13: No Console Output

**Symptoms:**
- Script runs but no output shown
- Exit code 0 but no results

**Diagnosis:**
```powershell
# Check if output is being redirected
.\tests\Invoke-SecurityTests.ps1 -Verbose
```

**Solutions:**

**Solution 1: Check Output Format**
```powershell
# Ensure Console output is selected
.\tests\Invoke-SecurityTests.ps1 -OutputFormat Console
```

**Solution 2: Check Severity Filter**
```powershell
# Ensure matching severity
.\tests\Invoke-SecurityTests.ps1 -Severity Error,Warning,Information
```

**Solution 3: Check for Errors**
```powershell
# Run with error capture
.\tests\Invoke-SecurityTests.ps1 -ErrorVariable err
$err
```

---

### Issue 14: JSON File Not Created

**Symptoms:**
- SARIF/JSON files missing from output directory

**Diagnosis:**
```powershell
# Check output path exists
Test-Path ./security-reports/

# Check permissions
Get-Acl ./security-reports/
```

**Solutions:**

**Solution 1: Create Output Directory**
```powershell
New-Item -Path ./security-reports/ -ItemType Directory -Force
```

**Solution 2: Specify Absolute Path**
```powershell
$outputPath = "C:\FAS\Reports"
.\tests\Invoke-SecurityTests.ps1 -OutputFormat JSON -OutputPath $outputPath
```

**Solution 3: Check Disk Space**
```powershell
Get-PSDrive C | Select-Object Free
```

---

## Integration Issues

### Issue 15: Pre-Commit Hook Not Triggering

**Symptoms:**
- Commits succeed without running security scan

**Diagnosis:**
```bash
# Check if hook exists
ls -la .git/hooks/pre-commit

# Check if executable (Linux/Mac)
ls -la .git/hooks/pre-commit | grep x
```

**Solutions:**

**Solution 1: Create Hook File**
```bash
# Create .git/hooks/pre-commit
#!/bin/bash
pwsh -File ./tests/Invoke-SecurityTests.ps1 -Severity Error
exit $?
```

**Solution 2: Make Executable (Linux/Mac)**
```bash
chmod +x .git/hooks/pre-commit
```

**Solution 3: Windows Execution**
```powershell
# Windows doesn't use executable bit
# Ensure Git Bash or WSL is used for hooks
```

---

### Issue 16: GitLab CI/CD Pipeline Fails

**Error Message:**
```
Job failed: PSScriptAnalyzer not found
```

**Solution:**
```yaml
# In .gitlab-ci.yml
security:test:
  image: mcr.microsoft.com/powershell:latest
  before_script:
    - pwsh -Command "Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser"
  script:
    - pwsh -File ./tests/Invoke-SecurityTests.ps1 -OutputFormat SARIF
  artifacts:
    reports:
      sast: security-report.sarif
```

---

## Common Violations and Fixes

### Violation 1: Hardcoded Password

**Finding:**
```
FAS-CRED-001: Hardcoded password detected
Line 45: $password = "MyPassword123"
```

**Fix:**
```powershell
# Before
$password = "MyPassword123"

# After
$password = Read-Host "Enter FAS service account password" -AsSecureString
```

---

### Violation 2: String Password Parameter

**Finding:**
```
FAS-CRED-002: Plain-text password parameter
Line 12: param([string]$Password)
```

**Fix:**
```powershell
# Before
function Set-FASPassword {
    param([string]$Password)
}

# After
function Set-FASPassword {
    param([SecureString]$Password)
}

# Or use PSCredential
function Set-FASPassword {
    param([PSCredential]$Credential)
}
```

---

### Violation 3: Invoke-Expression

**Finding:**
```
FAS-EXEC-001: Invoke-Expression detected
Line 78: Invoke-Expression "Get-Service -Name $serviceName"
```

**Fix:**
```powershell
# Before
$command = "Get-Service -Name $serviceName"
Invoke-Expression $command

# After
Get-Service -Name $serviceName

# Or with dynamic parameters
$params = @{Name = $serviceName}
Get-Service @params
```

---

### Violation 4: Invalid SID Format

**Finding:**
```
FAS-AD-001: Invalid SID format
Line 23: $sid = "S-1-5-21-INVALID"
```

**Fix:**
```powershell
# Get correct SID from AD
$group = Get-ADGroup "FAS Servers"
$FASSecurityGroupSID = $group.SID.Value

# Or add validation
[ValidatePattern('^S-1-5-21-\d+-\d+-\d+-\d+$')]
[string]$FASSecurityGroupSID
```

---

## Emergency Bypass (Not Recommended)

**If you MUST bypass security scan temporarily:**

```powershell
# Disable all custom rules (NOT RECOMMENDED)
Invoke-ScriptAnalyzer -Path ./scripts/ -ExcludeRule FAS-*

# Suppress all findings for specific file (LAST RESORT)
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('*', '*',
    Justification='TEMPORARY - DO NOT COMMIT')]

# Skip CI/CD security check (requires approval)
# In .gitlab-ci.yml:
security:test:
  allow_failure: true  # DANGEROUS - must be temporary
```

**⚠️ WARNING:** Only use bypass in emergency situations with documented justification and plan to fix.

---

## Getting Help

### 1. Check Logs

```powershell
# Security scan logs
Get-Content ./security-reports/security-scan-*.log

# PowerShell transcripts
Get-Content $env:TEMP/PowerShell_transcript.*.txt
```

### 2. Enable Verbose Output

```powershell
.\tests\Invoke-SecurityTests.ps1 -Verbose -Debug
```

### 3. Run Unit Tests

```powershell
# Validate security rules
Invoke-Pester ./tests/SecurityRules.Tests/ -Output Detailed
```

### 4. Report Issues

**GitHub Issues:** https://github.com/dimi4ik/Citrix_daas_fas_install/issues

**Include:**
- PowerShell version (`$PSVersionTable`)
- PSScriptAnalyzer version
- Error message (full stack trace)
- Minimal reproducible example

---

## Resources

- [Security Tests Guide](./security-tests-guide.md)
- [Security Rules Reference](./security-rules-reference.md)
- [PSScriptAnalyzer Documentation](https://github.com/PowerShell/PSScriptAnalyzer)

---

**Version:** 1.0.0
**Last Updated:** 2025-11-05
**Maintained by:** FAS Security Team
