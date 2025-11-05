# /tf-security-scan

Performs comprehensive security scans for Terraform configurations with integration of Wiz, HashiCorp, and compliance tools.

## Functionality

### Pre-Apply Security Validation
- Scans Terraform plans before apply for security vulnerabilities
- Integrates Wiz Security Platform for cloud resource analysis
- Enforcement level: Advisory or Mandatory (blocks insecure deployments)
- Creates risk score reports with CVSS ratings

### Security Checks
1. **Secrets Detection**: Detects hardcoded API keys, passwords, certificates
2. **IAM Policy Analysis**: Reviews overly permissive permissions
3. **Network Security**: Analyzes Security Groups, NACLs, public access
4. **Storage Security**: Checks publicly accessible S3 buckets, storage accounts
5. **CVE Scanning**: Matches provider versions against known vulnerabilities

### Compliance Frameworks
- CIS Benchmarks (AWS, Azure, GCP)
- SOC 2 Type II Controls
- PCI DSS Requirements
- NIST Cybersecurity Framework

## Implementation

```bash
# Terraform Plan Security Scan
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# Wiz CLI Integration (falls verfügbar)
if command -v wiz &> /dev/null; then
    wiz iac scan tfplan.json --format json --output wiz-report.json
fi

# Checkov Security Scan
checkov -f tfplan.json --framework terraform_plan --output json --output-file checkov-report.json

# TFSec Analysis
tfsec . --format json --out tfsec-report.json

# Custom Security Rules
python3 ~/.claude/scripts/tf-security-analyzer.py --plan tfplan.json --output security-summary.json
```

## Output Format

```json
{
  "scan_timestamp": "2025-07-13T10:30:00Z",
  "terraform_plan": "tfplan.json",
  "security_score": 85,
  "risk_level": "MEDIUM",
  "findings": [
    {
      "severity": "HIGH",
      "rule_id": "CKV_AWS_20",
      "resource": "aws_s3_bucket.data_lake",
      "description": "S3 Bucket has an ACL defined which allows public access",
      "remediation": "Set bucket ACL to private and use bucket policies"
    }
  ],
  "compliance_status": {
    "cis_aws": "PASSED",
    "soc2": "FAILED",
    "pci_dss": "PASSED"
  },
  "blocked": false,
  "enforcement_level": "advisory"
}
```

## Prerequisites

```bash
# Required Tools Installation
pip install checkov
go install github.com/aquasecurity/tfsec/cmd/tfsec@latest
# Optional: Wiz CLI (enterprise)
```

## Integration Points

- **Pre-Commit Hook**: Automatic scan on Terraform changes
- **GitLab CI**: Integration as pipeline stage before apply
- **Slack/Teams**: Alert notifications for critical findings
- **SIEM**: Export of security events for monitoring

## Command Usage

```bash
# Basic scan
/tf-security-scan

# Scan with enforcement level
/tf-security-scan --enforce mandatory

# Scan for specific compliance
/tf-security-scan --compliance cis-aws,soc2

# Scan with custom rules
/tf-security-scan --rules-dir ./security-rules/
```