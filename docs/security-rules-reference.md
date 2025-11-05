# Security Rules Reference
## Quick Reference Guide for FAS Security Testing

**Version:** 1.0.0
**Last Updated:** 2025-11-05

---

## Rule Categories

| Category | Rules Count | Severity | Description |
|----------|-------------|----------|-------------|
| **Credential Security** | 2 | Error | Hardcoded credentials, plain-text passwords |
| **Code Injection** | 1 | Error | Invoke-Expression, dynamic code execution |
| **AD Validation** | 1 | Warning | Domain consistency, SID format |
| **Built-in Security** | 6 | Error/Warning | PSScriptAnalyzer built-in security rules |
| **Best Practices** | 15+ | Information | Code style, error handling, documentation |

---

## Custom Security Rules (FAS-Specific)

### FAS-CRED-001: Hardcoded Credentials

| Property | Value |
|----------|-------|
| **Rule ID** | FAS-CRED-001-HardcodedCredentials |
| **Severity** | Error (Critical) |
| **Category** | Security - Credential Management |
| **Module** | Measure-HardcodedCredentials.psm1 |

#### What It Detects

- ✅ Hardcoded passwords in string literals
- ✅ API keys and tokens (e.g., `sk-abc123`, `key_xyz`)
- ✅ Connection strings with embedded credentials
- ✅ URLs with username:password format
- ✅ ConvertTo-SecureString with literal strings

#### Whitelist (NOT Flagged)

- ✅ SIDs: `S-1-5-21-1234567890-1234567890-1234567890-1234`
- ✅ Certificate templates: `917Citrix_SmartcardLogon`
- ✅ AD Distinguished Names: `CN=Users,DC=domain,DC=com`
- ✅ Variables: `$password = $userInput`
- ✅ Read-Host: `Read-Host -AsSecureString`
- ✅ Get-Credential: `Get-Credential`

#### Examples

**❌ Violations:**
```powershell
# Hardcoded password
$password = "MyPassword123"

# API key
$apiKey = "sk-abc123xyz789"

# Connection string
$connStr = "Server=db;User=admin;Password=pass123"

# URL with credentials
$url = "https://admin:password@api.example.com"

# ConvertTo-SecureString with literal
$secure = ConvertTo-SecureString -String "MyPass" -AsPlainText -Force
```

**✅ Correct Usage:**
```powershell
# Secure password input
$password = Read-Host "Enter password" -AsSecureString

# PSCredential
$credential = Get-Credential -Message "Enter credentials"

# SecureString parameter
param([SecureString]$Password)

# Variable (not hardcoded)
$password = $config.GetPassword()
```

#### Remediation

1. **For interactive scripts:**
   ```powershell
   $securePassword = Read-Host "Enter password" -AsSecureString
   ```

2. **For automation:**
   ```powershell
   # Use Azure Key Vault, HashiCorp Vault, or Windows Credential Manager
   $credential = Get-StoredCredential -Name "FASServiceAccount"
   ```

3. **For configuration:**
   ```powershell
   # Store as SecureString in config file (encrypted)
   $secureString = ConvertTo-SecureString $password -AsPlainText -Force
   $encrypted = ConvertFrom-SecureString $secureString
   # Save $encrypted to config, not plain-text password
   ```

---

### FAS-CRED-002: Plain-Text Password Parameters

| Property | Value |
|----------|-------|
| **Rule ID** | FAS-CRED-002-PlainTextPassword |
| **Severity** | Error (Critical) for parameters, Warning for ConvertTo-SecureString |
| **Category** | Security - Credential Management |
| **Module** | Measure-PlainTextPassword.psm1 |

#### What It Detects

- ✅ `[string]$Password` parameters (should be `[SecureString]`)
- ✅ `ConvertTo-SecureString -AsPlainText` usage
- ✅ `Get-Credential -Password $stringVariable`
- ✅ `New-Object PSCredential($user, $stringPassword)`

#### Examples

**❌ Violations:**
```powershell
# String password parameter
function Set-UserPassword {
    param([string]$Password)  # WRONG - Should be SecureString
}

# Plain-text in ConvertTo-SecureString
$secure = ConvertTo-SecureString $plainPassword -AsPlainText -Force

# Get-Credential with string password
$cred = Get-Credential -Username "admin" -Password $password

# PSCredential with non-SecureString
$cred = New-Object PSCredential($user, $password)
```

**✅ Correct Usage:**
```powershell
# SecureString parameter
function Set-UserPassword {
    param([SecureString]$Password)
}

# PSCredential parameter
function Deploy-FAS {
    param([PSCredential]$ServiceAccount)
}

# Proper SecureString usage
$securePassword = Read-Host -AsSecureString
$cred = New-Object PSCredential($user, $securePassword)
```

#### Remediation

1. **Change parameter type:**
   ```powershell
   # Before
   param([string]$Password)

   # After
   param([SecureString]$Password)
   # or
   param([PSCredential]$Credential)
   ```

2. **Update function calls:**
   ```powershell
   # Before
   Set-UserPassword -Password "MyPass123"

   # After
   $securePass = Read-Host "Password" -AsSecureString
   Set-UserPassword -Password $securePass
   ```

---

### FAS-EXEC-001: Invoke-Expression Usage

| Property | Value |
|----------|-------|
| **Rule ID** | FAS-EXEC-001-InvokeExpression |
| **Severity** | Error (Critical) |
| **Category** | Security - Code Injection |
| **Module** | Measure-InvokeExpressionUsage.psm1 |

#### What It Detects

- ✅ `Invoke-Expression` cmdlet
- ✅ `iex` alias
- ✅ `[ScriptBlock]::Create()` with dynamic content
- ✅ `Add-Type -TypeDefinition $variable`
- ✅ `Invoke-Command -ScriptBlock [ScriptBlock]::Create(...)`
- ✅ **CRITICAL:** `Invoke-WebRequest | iex`

#### Why It's Dangerous

- 🔴 **Code Injection**: Execute arbitrary code from untrusted input
- 🔴 **Difficult to Audit**: Hard to determine what code will execute
- 🔴 **Supply Chain Risk**: Downloaded scripts may be malicious

#### Examples

**❌ Violations:**
```powershell
# Invoke-Expression
Invoke-Expression "Get-Process"
iex $command

# Dynamic script block creation
$sb = [ScriptBlock]::Create($userInput)
$sb.Invoke()

# Add-Type with dynamic source
Add-Type -TypeDefinition $dynamicCode

# CRITICAL: Downloaded content execution
Invoke-WebRequest https://example.com/script.ps1 | iex
```

**✅ Correct Alternatives:**
```powershell
# Direct cmdlet call
Get-Process

# Call operator with pre-defined script block
$scriptBlock = {Get-Process}
& $scriptBlock

# Parameter splatting instead of dynamic command
$params = @{
    Name = "powershell"
}
Get-Process @params

# For remote execution, use predefined script blocks
Invoke-Command -ScriptBlock {Get-Process} -ComputerName $server
```

#### Remediation

1. **Replace Invoke-Expression with direct calls:**
   ```powershell
   # Before
   Invoke-Expression "Get-Service -Name $serviceName"

   # After
   Get-Service -Name $serviceName
   ```

2. **Use call operator for script blocks:**
   ```powershell
   # Before
   Invoke-Expression $command

   # After
   & $scriptBlock  # Only if script block is pre-defined and trusted
   ```

3. **Parameter splatting for dynamic parameters:**
   ```powershell
   # Before
   $cmd = "Get-Process -Name $processName"
   Invoke-Expression $cmd

   # After
   $params = @{Name = $processName}
   Get-Process @params
   ```

---

### FAS-AD-001: Domain Consistency

| Property | Value |
|----------|-------|
| **Rule ID** | FAS-AD-001-DomainConsistency |
| **Severity** | Warning (High) |
| **Category** | Security - AD Validation |
| **Module** | Measure-ADDomainConsistency.psm1 |

#### What It Detects

- ✅ Invalid SID format (not matching `S-1-5-21-xxx-xxx-xxx-xxx`)
- ✅ Multiple domain parameters without consistency validation
- ✅ Invalid UPN format
- ✅ FAS Security Group SID without validation attribute
- ✅ AD cmdlets without error handling

#### SID Format Validation

**Valid Formats:**
- Domain SID: `S-1-5-21-1234567890-1234567890-1234567890-1234`
- Well-known SIDs: `S-1-5-18` (LocalSystem), `S-1-5-32-544` (Administrators)

**Invalid Formats:**
- `S-1-5-21-INVALID`
- `S-1-5-21-123-456-789-12` (too short)
- `SID-123456` (wrong format)

#### Examples

**❌ Violations:**
```powershell
# Invalid SID format
$sid = "S-1-5-21-INVALID"

# Multiple domain parameters without validation
param(
    [string]$UserDomain,
    [string]$ComputerDomain
)
# Missing: if ($UserDomain -ne $ComputerDomain) { throw }

# FAS SID without validation
param([string]$FASSecurityGroupSID)

# AD cmdlet without error handling
Get-ADUser -Identity $username  # No try/catch
```

**✅ Correct Usage:**
```powershell
# SID with validation
[ValidatePattern('^S-1-5-21-\d+-\d+-\d+-\d+$')]
[string]$FASSecurityGroupSID

# Domain consistency check
param(
    [string]$UserDomain,
    [string]$ComputerDomain
)

if ($UserDomain -ne $ComputerDomain) {
    throw "Cross-domain authentication not supported. User and Computer must be in same domain."
}

# AD cmdlet with error handling
try {
    $user = Get-ADUser -Identity $username -ErrorAction Stop
}
catch {
    Write-Error "Failed to retrieve AD user: $($_.Exception.Message)"
}
```

#### Remediation

1. **Add SID validation:**
   ```powershell
   [Parameter(Mandatory=$true)]
   [ValidatePattern('^S-1-5-21-\d{10}-\d{10}-\d{10}-\d{4,5}$')]
   [string]$FASSecurityGroupSID
   ```

2. **Add domain consistency checks:**
   ```powershell
   if ($UserDomain -ne $ComputerDomain) {
       throw "Domain mismatch: User domain ($UserDomain) != Computer domain ($ComputerDomain)"
   }
   ```

3. **Wrap AD cmdlets in try/catch:**
   ```powershell
   try {
       Get-ADUser -Identity $username -ErrorAction Stop
   }
   catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
       Write-Error "User not found: $username"
   }
   catch {
       Write-Error "AD query failed: $($_.Exception.Message)"
   }
   ```

---

## Built-in PSScriptAnalyzer Security Rules

### Critical Rules (Error)

| Rule ID | Description | Example Violation |
|---------|-------------|-------------------|
| **PSAvoidUsingPlainTextForPassword** | Password parameters should be SecureString | `param([string]$Password)` |
| **PSAvoidUsingConvertToSecureStringWithPlainText** | Avoid -AsPlainText with ConvertTo-SecureString | `ConvertTo-SecureString "pass" -AsPlainText` |
| **PSUsePSCredentialType** | Use [PSCredential] for credential parameters | `param($Credential)` without type |
| **PSAvoidUsingInvokeExpression** | Avoid Invoke-Expression | `Invoke-Expression $cmd` |
| **PSAvoidUsingUserNameAndPasswordParams** | Use PSCredential instead of separate params | `param($User, $Pass)` |
| **PSAvoidUsingComputerNameHardcoded** | Avoid hardcoded computer names | `$server = "PROD-01"` |

### High Priority Rules (Warning)

| Rule ID | Description | Recommendation |
|---------|-------------|----------------|
| **PSAvoidUsingWriteHost** | Use Write-Output instead | Better for pipeline support |
| **PSAvoidUsingCmdletAliases** | Use full cmdlet names | Improves readability |
| **PSAvoidUsingPositionalParameters** | Use named parameters | Better maintainability |
| **PSAvoidUsingUninitializedVariable** | Initialize variables | Prevents null reference errors |
| **PSAvoidGlobalVars** | Minimize global scope | Better modularity |

### Best Practice Rules (Information)

| Rule ID | Description | Benefit |
|---------|-------------|---------|
| **PSUseShouldProcessForStateChangingFunctions** | Implement -WhatIf/-Confirm | Safer operations |
| **PSUseSingularNouns** | Use singular nouns in cmdlet names | PowerShell convention |
| **PSUseApprovedVerbs** | Use approved PowerShell verbs | Consistency |
| **PSUseBOMForUnicodeEncodedFile** | UTF-8 with BOM | Compatibility |
| **PSUseConsistentIndentation** | 4-space indentation | Readability |
| **PSUseCorrectCasing** | Correct cmdlet casing | Best practice |

---

## Rule Suppression

### When to Suppress

✅ **Legitimate reasons:**
- Template names containing "password" (not actual credentials)
- Well-known SID values in documentation
- Test/example code with intentional violations
- Third-party code you cannot modify

❌ **NOT legitimate:**
- "It's too much work to fix"
- "We'll fix it later"
- "It works fine, why change it?"

### How to Suppress

#### Method 1: Inline Suppression
```powershell
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('FAS-CRED-001', '',
    Justification='Template name contains "password" keyword but is not a credential')]
$templateName = "917Citrix_SmartcardLogon_Password_Enabled"
```

#### Method 2: Settings File Exclusion
```powershell
# In PSScriptAnalyzerSettings.psd1
@{
    ExcludeRules = @(
        # NEVER exclude security rules without documented reason
    )

    ExcludePath = @(
        './scripts/ThirdParty/*',  # Third-party code
        './scripts/Examples/*'      # Example code
    )
}
```

#### Method 3: Per-File Suppression
```powershell
# At top of file
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
    Justification='Interactive script requires Write-Host for colored output', Scope='Function')]
function Show-Menu {
    Write-Host "Menu" -ForegroundColor Green
}
```

---

## Rule Performance

### Benchmark Results

| Rule | Avg Time per Script | Memory Usage |
|------|---------------------|--------------|
| FAS-CRED-001 | 150ms | 2MB |
| FAS-CRED-002 | 120ms | 1.5MB |
| FAS-EXEC-001 | 100ms | 1MB |
| FAS-AD-001 | 180ms | 2.5MB |
| **Total (300-line script)** | **<2 seconds** | **<10MB** |

### Optimization Tips

1. **Scan specific files** instead of entire repository
2. **Reduce severity levels** if only checking critical issues
3. **Use file filters** to exclude test/example code
4. **Run in parallel** for large codebases

---

## Resources

- [PSScriptAnalyzer GitHub](https://github.com/PowerShell/PSScriptAnalyzer)
- [PowerShell Security Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/security/security-best-practices)
- [SARIF Specification](https://docs.oasis-open.org/sarif/sarif/v2.1.0/)

---

**Version:** 1.0.0
**Last Updated:** 2025-11-05
**Maintained by:** FAS Security Team
