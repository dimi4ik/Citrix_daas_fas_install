Run comprehensive Terraform workflow (fmt, validate, plan) on the configuration:

1. **Check current directory structure**:
   - Verify if Terraform files are in current directory or terraform/ subdirectory
   - Identify correct working directory for Terraform operations
   - Display detected Terraform file structure

2. **Run terraform fmt -recursive**:
   - Format all Terraform code recursively from correct directory
   - Report any files that were reformatted
   - Show formatting summary

3. **Run terraform validate**:
   - Validate Terraform configuration syntax from correct directory
   - Check for configuration errors
   - Verify provider requirements
   - Display validation status

4. **Run terraform plan**:
   - Generate execution plan from correct directory
   - Show what changes will be made
   - Save plan to tfplan file for potential apply
   - Display resource changes summary (add/change/destroy)

5. **Basic security checks**:
   - Check for common security misconfigurations
   - Verify no hardcoded secrets in plan output
   - Basic compliance validation

6. **Provide comprehensive summary**:
   - Format results (files changed/no changes needed)
   - Validation results (success/errors with details)
   - Plan summary (resources to add/change/destroy)
   - Security findings (if any)
   - Any warnings or recommendations
   - Next steps guidance

**Enhanced Features**:
- **Smart Directory Detection**: Automatically detects terraform/ subdirectory
- **Error Context**: Provides detailed error explanations and fix suggestions
- **Resource Impact**: Clear summary of infrastructure changes
- **Safety Guidance**: Recommends next steps based on plan results

**Usage**: Run from any directory - command will automatically detect if Terraform files are in current directory or terraform/ subdirectory and execute the complete validation workflow from the correct location.

**Integration**: Works seamlessly with `/tf-deploy` for deployment and `/tf-pre-commit` for git workflows.

**Note**: This command provides the complete Terraform development workflow validation and planning process, ensuring code is properly formatted, syntactically correct, secure, and ready for deployment. Combines the best features of validation and workflow commands into a single, comprehensive tool.