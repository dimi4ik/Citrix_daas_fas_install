# Security Tests Implementation Plan
## Automated Credential Management Security Testing

**Datum:** 2025-11-05
**Version:** 1.0.0
**Ziel:** Best-Practice Security Testing für FAS PowerShell Skripte mit SARIF Integration

---

## Executive Summary

Implementierung einer umfassenden Security Test Suite für Citrix FAS PowerShell Skripte mit Fokus auf:
- **Hardcoded Credentials Detection**
- **Plain-Text Password Scanning**
- **Invoke-Expression Security Risks**
- **AD-spezifische Validierung**
- **SARIF-Integration für GitLab Security Dashboard**

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   Security Test Framework                    │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────┐  ┌──────────────────┐                 │
│  │ PSScriptAnalyzer │  │  Custom Security │                 │
│  │   Settings       │  │      Rules       │                 │
│  └────────┬─────────┘  └────────┬─────────┘                 │
│           │                     │                            │
│           └──────────┬──────────┘                            │
│                      │                                       │
│           ┌──────────▼──────────┐                            │
│           │  Security Scanner   │                            │
│           │  (Invoke-Security   │                            │
│           │     Tests.ps1)      │                            │
│           └──────────┬──────────┘                            │
│                      │                                       │
│        ┌─────────────┼─────────────┐                         │
│        │             │             │                         │
│   ┌────▼────┐  ┌────▼────┐  ┌────▼────┐                     │
│   │  JSON   │  │  SARIF  │  │ Console │                     │
│   │ Report  │  │ Report  │  │  Output │                     │
│   └────┬────┘  └────┬────┘  └─────────┘                     │
│        │            │                                        │
│        │            │                                        │
│        │       ┌────▼─────────────────┐                      │
│        │       │  GitLab Security     │                      │
│        │       │     Dashboard        │                      │
│        │       └──────────────────────┘                      │
│        │                                                     │
│   ┌────▼──────────────┐                                      │
│   │  Audit Logs       │                                      │
│   │  (security-*.log) │                                      │
│   └───────────────────┘                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Component Details

### 2.1 PSScriptAnalyzerSettings.psd1

**Location:** `/PSScriptAnalyzerSettings.psd1` (Repository Root)

**Purpose:**
- Central configuration for PSScriptAnalyzer
- Custom rule definitions
- Severity classification
- Exclusion patterns

**Key Features:**
- ✅ Hardcoded Credential Detection (Critical)
- ✅ Plain-Text Password Detection (Critical)
- ✅ Invoke-Expression Usage (High)
- ✅ Secure String Validation (Medium)
- ✅ AD Consistency Checks (Medium)

**Structure:**
```powershell
@{
    # Rule Severity Configuration
    IncludeDefaultRules = $true
    ExcludeRules = @()  # No rules excluded for security

    # Custom Rules Path
    CustomRulePath = @(
        './tests/SecurityRules'
    )

    # Severity Levels
    Severity = @('Error', 'Warning', 'Information')

    # Critical Security Rules (ALWAYS Error)
    Rules = @{
        PSAvoidUsingPlainTextForPassword = @{
            Enable = $true
            Severity = 'Error'
        }
        PSAvoidUsingConvertToSecureStringWithPlainText = @{
            Enable = $true
            Severity = 'Error'
        }
        PSAvoidUsingInvokeExpression = @{
            Enable = $true
            Severity = 'Error'
        }
        PSUsePSCredentialType = @{
            Enable = $true
            Severity = 'Error'
        }
    }
}
```

---

### 2.2 Custom Security Rules

**Location:** `/tests/SecurityRules/`

#### 2.2.1 Rule: Measure-HardcodedCredentials.psm1

**Detection Patterns:**
- Username/Password string literals
- Connection strings with credentials
- API keys and tokens
- SID values (validate, not reject)

**AST Analysis:**
```powershell
# Detect patterns like:
$password = "MyPassword123"          # CRITICAL
$cred = "username:password"          # CRITICAL
$apiKey = "sk-abc123xyz"             # CRITICAL
```

**Output:** DiagnosticRecord with Severity = Error

---

#### 2.2.2 Rule: Measure-PlainTextPassword.psm1

**Detection Patterns:**
- String parameters containing passwords
- Unencrypted password variables
- Password passed to -AsPlainText

**AST Analysis:**
```powershell
# Detect patterns like:
[string]$Password                    # WARNING - Should be SecureString
ConvertTo-SecureString -AsPlainText  # WARNING - Context required
```

**Output:** DiagnosticRecord with Severity = Warning/Error

---

#### 2.2.3 Rule: Measure-ADDomainConsistency.psm1

**Validation Checks:**
- Domain parameter consistency across functions
- SID format validation (S-1-5-21-xxx-xxx-xxx-xxx)
- UPN suffix validation
- Security group SID checks

**Example Check:**
```powershell
# Ensure domain consistency
if ($UserDomain -ne $ComputerDomain) {
    # WARNING - Potential cross-domain issue
}
```

---

#### 2.2.4 Rule: Measure-InvokeExpressionUsage.psm1

**Detection:**
- Any usage of Invoke-Expression
- Alias usage: iex
- Dynamic code execution patterns

**Rationale:**
- Code injection risk
- Difficult to audit
- Use of splatting/parameter binding instead

---

### 2.3 Security Scanner Script

**Location:** `/tests/Invoke-SecurityTests.ps1`

**Features:**
1. **Automated Scanning**
   - Scans all PowerShell scripts in repository
   - Applies PSScriptAnalyzerSettings.psd1
   - Executes custom security rules

2. **Intelligent Categorization**
   - **Critical (Error):** Hardcoded credentials, plain-text passwords
   - **High (Warning):** Invoke-Expression, insecure functions
   - **Medium (Information):** Best practice violations

3. **Output Formats**
   - **Console:** Color-coded summary
   - **JSON:** Detailed results for automation
   - **SARIF:** GitLab Security Dashboard integration
   - **Log Files:** Audit trail

4. **Integration Points**
   - GitLab CI/CD pipeline
   - Pre-commit hooks (optional)
   - Manual execution for development

---

### 2.4 SARIF Output Configuration

**SARIF Version:** 2.1.0 (Current standard)

**Structure:**
```json
{
  "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
  "version": "2.1.0",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "FAS-Security-Scanner",
          "version": "1.0.0",
          "informationUri": "https://github.com/dimi4ik/Citrix_daas_fas_install"
        }
      },
      "results": [
        {
          "ruleId": "FAS-CRED-001",
          "level": "error",
          "message": {
            "text": "Hardcoded credential detected"
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "scripts/Deploy-FAS.ps1"
                },
                "region": {
                  "startLine": 123
                }
              }
            }
          ]
        }
      ]
    }
  ]
}
```

**Benefits:**
- Native GitLab Security Dashboard support
- Standard format for security tools
- Rich contextual information
- Actionable remediation guidance

---

## 3. Security Rule Definitions

### 3.1 Critical Rules (Severity: Error)

| Rule ID | Name | Description | Action |
|---------|------|-------------|--------|
| FAS-CRED-001 | Hardcoded-Credentials | Detects hardcoded usernames/passwords | FAIL BUILD |
| FAS-CRED-002 | Plain-Text-Password | Detects plain-text password usage | FAIL BUILD |
| FAS-EXEC-001 | Invoke-Expression | Detects Invoke-Expression usage | FAIL BUILD |
| FAS-SEC-001 | Insecure-SecureString | Detects ConvertTo-SecureString -AsPlainText without validation | FAIL BUILD |

### 3.2 High Priority Rules (Severity: Warning)

| Rule ID | Name | Description | Action |
|---------|------|-------------|--------|
| FAS-AD-001 | Domain-Inconsistency | Cross-domain parameter issues | WARN |
| FAS-AD-002 | Invalid-SID-Format | Malformed SID parameters | WARN |
| FAS-CRED-003 | Weak-Credential-Type | String instead of PSCredential/SecureString | WARN |
| FAS-LOG-001 | Insufficient-Logging | Missing audit log entries for security operations | WARN |

### 3.3 Medium Priority Rules (Severity: Information)

| Rule ID | Name | Description | Action |
|---------|------|-------------|--------|
| FAS-BP-001 | Missing-Error-Handling | No try/catch for critical operations | INFO |
| FAS-BP-002 | Missing-Validation | No parameter validation | INFO |
| FAS-BP-003 | Inconsistent-Naming | Naming convention violations | INFO |

---

## 4. GitLab CI/CD Integration

### 4.1 Pipeline Stage: Security Testing

**File:** `/.gitlab-ci.yml` (to be created)

```yaml
stages:
  - validate
  - security
  - deploy

# Security Testing Stage
security:test:
  stage: security
  image: mcr.microsoft.com/powershell:latest
  script:
    # Install PSScriptAnalyzer
    - pwsh -Command "Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser"

    # Run Security Tests
    - pwsh -File ./tests/Invoke-SecurityTests.ps1 -OutputFormat SARIF -Verbose

  artifacts:
    reports:
      sast: security-report.sarif
    paths:
      - security-report.sarif
      - logs/security-*.log
    expire_in: 30 days

  allow_failure: false  # Critical - Security must pass

  only:
    - branches
    - merge_requests
```

### 4.2 Security Dashboard Integration

**Configuration:**
1. Upload SARIF to GitLab Security Dashboard
2. Vulnerability tracking
3. Remediation workflow
4. Historical trending

---

## 5. Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create PSScriptAnalyzerSettings.psd1
- [ ] Implement basic credential detection rules
- [ ] Create Invoke-SecurityTests.ps1 scaffold
- [ ] Test with existing PowerShell scripts

### Phase 2: Custom Rules (Week 1-2)
- [ ] Develop Measure-HardcodedCredentials.psm1
- [ ] Develop Measure-PlainTextPassword.psm1
- [ ] Develop Measure-InvokeExpressionUsage.psm1
- [ ] Develop Measure-ADDomainConsistency.psm1
- [ ] Unit testing for each rule

### Phase 3: SARIF Integration (Week 2)
- [ ] Implement SARIF output format
- [ ] Test SARIF schema compliance
- [ ] Validate GitLab Security Dashboard import

### Phase 4: CI/CD Integration (Week 2-3)
- [ ] Create .gitlab-ci.yml
- [ ] Configure security stage
- [ ] Test pipeline execution
- [ ] Configure failure policies

### Phase 5: Documentation & Training (Week 3)
- [ ] Write comprehensive documentation
- [ ] Create troubleshooting guide
- [ ] Prepare security best practices guide
- [ ] Team training sessions

---

## 6. Testing Strategy

### 6.1 Unit Tests for Custom Rules

**Location:** `/tests/SecurityRules.Tests/`

**Framework:** Pester 5.x

**Example:**
```powershell
Describe "Measure-HardcodedCredentials" {
    Context "When hardcoded password detected" {
        It "Should return Error severity" {
            $testScript = '$password = "MyPassword123"'
            $result = Invoke-ScriptAnalyzer -ScriptDefinition $testScript
            $result.Severity | Should -Be 'Error'
        }
    }
}
```

### 6.2 Integration Tests

**Scenarios:**
1. Scan all repository scripts
2. Validate SARIF output format
3. Test GitLab CI/CD pipeline
4. Verify Security Dashboard upload

---

## 7. Success Criteria

### 7.1 Functional Requirements
- ✅ Detect 100% of hardcoded credentials in test cases
- ✅ Zero false positives for SID parameters
- ✅ SARIF format validates against schema
- ✅ GitLab Security Dashboard displays findings
- ✅ CI/CD pipeline fails on Critical findings

### 7.2 Performance Requirements
- ✅ Full repository scan < 60 seconds
- ✅ Custom rule execution < 5 seconds per script
- ✅ SARIF generation < 10 seconds

### 7.3 Quality Requirements
- ✅ 100% of PowerShell scripts pass security scan
- ✅ Zero Critical or High severity findings
- ✅ Complete audit trail for all scans

---

## 8. Maintenance & Updates

### 8.1 Regular Updates
- **Monthly:** Review and update security rules
- **Quarterly:** PSScriptAnalyzer version update
- **Annually:** Security testing strategy review

### 8.2 Rule Management
- Version control for custom rules
- Changelog for rule modifications
- Backward compatibility testing

---

## 9. Deliverables

### 9.1 Code Artifacts
1. `/PSScriptAnalyzerSettings.psd1` - Central configuration
2. `/tests/SecurityRules/*.psm1` - Custom security rules (4 modules)
3. `/tests/Invoke-SecurityTests.ps1` - Security scanner script
4. `/.gitlab-ci.yml` - CI/CD pipeline configuration

### 9.2 Documentation
1. `/docs/security-tests-guide.md` - Complete user guide
2. `/docs/security-rules-reference.md` - Rule reference documentation
3. `/docs/troubleshooting-security-tests.md` - Troubleshooting guide
4. `/README.md` - Updated with security testing section

### 9.3 Test Artifacts
1. `/tests/SecurityRules.Tests/` - Pester unit tests
2. `/tests/fixtures/` - Test data and sample violations
3. `/logs/` - Security scan logs (gitignored)

---

## 10. Risk Mitigation

### 10.1 Identified Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| False Positives | Medium | Extensive testing, whitelist mechanism |
| Performance Impact | Low | Optimize AST parsing, parallel execution |
| GitLab Integration Failure | Medium | Fallback to JSON output, manual review |
| Rule Maintenance Burden | Low | Comprehensive documentation, automated tests |

### 10.2 Rollback Plan
1. Disable security stage in GitLab CI/CD
2. Revert to manual security reviews
3. Fix and re-deploy

---

## 11. References

### 11.1 Documentation
- [PSScriptAnalyzer Official Docs](https://github.com/PowerShell/PSScriptAnalyzer)
- [SARIF Specification v2.1.0](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html)
- [GitLab Security Dashboard](https://docs.gitlab.com/ee/user/application_security/security_dashboard/)

### 11.2 Best Practices
- [PowerShell Security Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/security/security-best-practices)
- [Credential Management Guidelines](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/)

---

## Appendix A: Rule Priority Matrix

```
┌─────────────────────────────────────────────────────────┐
│                   SEVERITY MATRIX                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  CRITICAL (Error) │ High (Warning) │ Medium (Info)      │
│  ─────────────────┼────────────────┼────────────────    │
│  • Hardcoded Cred │ • Domain Check │ • Code Style       │
│  • Plain-Text PWD │ • SID Format   │ • Naming Conv.     │
│  • Invoke-Expr    │ • Weak Types   │ • Documentation    │
│  • Insecure Conv. │ • Logging      │ • Error Handling   │
│                   │                │                     │
│  ACTION: FAIL     │ ACTION: WARN   │ ACTION: INFO       │
└─────────────────────────────────────────────────────────┘
```

---

## Appendix B: Example Violations

### B.1 Critical Violation Example
```powershell
# ❌ CRITICAL - Hardcoded Credential
$username = "administrator"
$password = "P@ssw0rd123"

# ✅ CORRECT - Use SecureString and Credential
$securePassword = Read-Host "Enter Password" -AsSecureString
$credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)
```

### B.2 High Priority Violation Example
```powershell
# ❌ HIGH - Invoke-Expression Usage
Invoke-Expression "Get-Process"

# ✅ CORRECT - Direct Execution
Get-Process
```

### B.3 Medium Priority Violation Example
```powershell
# ⚠️ MEDIUM - String instead of SecureString
param([string]$Password)

# ✅ CORRECT - Use SecureString
param([SecureString]$Password)
```

---

**END OF IMPLEMENTATION PLAN**
