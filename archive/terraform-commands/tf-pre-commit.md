# Terraform Pre-commit Validation Command

**Name**: `/tf-pre-commit`

**Description**: Comprehensive pre-commit hook validation for Terraform projects with detailed reporting

**Usage**: `/tf-pre-commit [options]`

**Options**:
- `--fix` - Apply automatic corrections where possible
- `--verbose` - Detailed output of all checks
- `--terraform-only` - Run only Terraform-specific hooks
- `--security-only` - Run only security checks (TFLint, Trivy, Checkov)

## Implementation

Execute comprehensive pre-commit validation with the following workflow:

1. **Pre-validation Setup**:
   ```bash
   echo "🔍 Starting Pre-commit Validation..."
   echo "Current directory: $(pwd)"
   echo "Git status check:"
   git status --porcelain
   ```

2. **Core Pre-commit Execution**:
   ```bash
   echo "🚀 Running pre-commit hooks..."

   if [[ "$1" == "--terraform-only" ]]; then
     pre-commit run terraform_fmt --all-files
     pre-commit run terraform_validate --all-files
     pre-commit run terraform_tflint --all-files
     pre-commit run terraform_docs --all-files
   elif [[ "$1" == "--security-only" ]]; then
     pre-commit run terraform_tflint --all-files
     pre-commit run terraform_trivy --all-files
     pre-commit run terraform_checkov --all-files
   else
     pre-commit run --all-files
   fi
   ```

3. **Error Analysis and Reporting**:
   ```bash
   EXIT_CODE=$?

   if [ $EXIT_CODE -eq 0 ]; then
     echo "✅ All pre-commit hooks passed successfully!"
     echo "📊 Summary:"
     echo "  - Terraform formatting: ✅"
     echo "  - Terraform validation: ✅"
     echo "  - TFLint checks: ✅"
     echo "  - Security scans: ✅"
     echo "  - Code quality: ✅"
   else
     echo "❌ Pre-commit hooks failed (Exit code: $EXIT_CODE)"
     echo ""
     echo "🔧 Common fixes:"
     echo "  - Run 'terraform fmt -recursive' for formatting"
     echo "  - Check 'terraform validate' for syntax errors"
     echo "  - Review TFLint warnings for best practices"
     echo "  - Check Checkov output for security issues"
   fi
   ```

4. **Post-validation Actions**:
   ```bash
   if [[ "$1" == "--fix" && $EXIT_CODE -ne 0 ]]; then
     echo "🔨 Attempting automatic fixes..."
     terraform fmt -recursive
     pre-commit run --all-files
   fi

   if [[ "$1" == "--verbose" ]]; then
     echo "📋 Detailed hook information:"
     pre-commit run --help
     echo ""
     echo "🏗️ Current pre-commit configuration:"
     cat .pre-commit-config.yaml | grep -E "^\s*-\s*id:|^\s*rev:"
   fi
   ```

5. **Manual Execution Options**:
   ```bash
   echo ""
   echo "🛠️ Manual execution options:"
   echo "  Individual hooks:"
   echo "    - pre-commit run terraform_fmt --all-files"
   echo "    - pre-commit run terraform_tflint --all-files"
   echo "    - pre-commit run terraform_checkov --all-files"
   echo ""
   echo "  Direct tool execution:"
   echo "    - terraform fmt -recursive"
   echo "    - terraform validate"
   echo "    - checkov -d . --compact"
   echo "    - tflint"
   echo ""
   echo "📋 Use '/tf-pre-commit' for comprehensive validation"
   ```

## Expected Terraform Hooks

- **terraform_fmt**: Code formatting validation
- **terraform_docs**: Documentation generation and validation
- **terraform_tflint**: Linting and best practices (42+ rules)
- **terraform_validate**: Syntax and configuration validation
- **terraform_trivy**: Security vulnerability scanning
- **terraform_checkov**: Infrastructure security policy validation
- **infracost_breakdown**: Cost analysis and estimation

## Success Criteria

✅ **All hooks pass**:
- Zero syntax errors
- No security violations
- Code properly formatted
- Documentation up-to-date
- Best practices followed

❌ **Common failure scenarios**:
- Unused variables (tflint warnings)
- Security policy violations (checkov)
- Syntax errors (terraform validate)
- Formatting issues (terraform fmt)
- Missing documentation (terraform docs)

## Integration Notes

- **Git Workflow**: Automatically runs on `git commit`
- **CI/CD**: Can be integrated in GitLab CI pipeline
- **IDE**: Works with VS Code, Cursor, and other editors
- **Manual**: Use this command for on-demand validation

## Related Commands

- `/validate` - Comprehensive multi-language validation
- `/terraform-validate` - Terraform-specific validation
- `/harden` - Security hardening analysis
- `/debug` - Debugging assistance for failed hooks

**Note**: This command provides comprehensive pre-commit validation ensuring code quality, security, and best practices for Terraform infrastructure deployments.
