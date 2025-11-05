Deploy Terraform infrastructure with enhanced safety checks and confirmation workflow:

1. **Pre-deployment validation**:
   - Check current directory structure for Terraform files
   - Verify Terraform configuration is valid (fmt, validate)
   - Ensure plan file exists or generate new plan
   - Display plan summary with resource changes

2. **Enhanced security checks**:
   - Scan for potential security misconfigurations
   - Check for hardcoded secrets or sensitive data
   - Validate IAM permissions and network security
   - Review resource configurations for compliance
   - Generate security risk assessment

3. **Safety confirmation workflow**:
   - Display comprehensive deployment summary
   - Show resources to be created/modified/destroyed
   - Highlight any potentially destructive changes
   - **Require explicit confirmation** (unless --auto-approve flag used)
   - Provide cost estimation if available

4. **Execute deployment**:
   - Run terraform apply with appropriate approval level
   - Monitor deployment progress with real-time updates
   - Capture deployment output and any errors
   - Handle deployment failures gracefully

5. **Post-deployment verification**:
   - Verify successful resource creation/modification
   - Test basic connectivity and functionality where possible
   - Validate expected outputs are generated
   - Check for any drift or inconsistencies

6. **Comprehensive deployment report**:
   - Resources created/modified/destroyed with details
   - Deployment time and performance metrics
   - Important outputs (IPs, connection strings, endpoints)
   - Security findings and recommendations
   - Next steps and operational guidance
   - Any warnings or issues encountered

**Safety Features**:
- **Confirmation Required**: Default behavior requires user confirmation
- **Risk Assessment**: Automatic evaluation of deployment impact
- **Rollback Guidance**: Provides rollback instructions if deployment fails
- **State Backup**: Ensures state backup before major changes

**Usage Options**:
```bash
/tf-deploy                    # Interactive mode with confirmation
/tf-deploy --auto-approve     # Automated mode (use with caution)
/tf-deploy --dry-run         # Show what would happen without applying
/tf-deploy --plan-only       # Generate and review plan without deployment
```

**Integration**: Works seamlessly with `/tf-validate` for pre-deployment validation and `/tf-security-scan` for advanced security checks.

**⚠️ Safety Note**: Unlike the previous auto-approve behavior, this command now defaults to interactive mode requiring confirmation for all infrastructure changes. Use `--auto-approve` flag only in trusted CI/CD environments.

**Note**: Provides comprehensive deployment workflow with multiple safety layers, detailed reporting, and enhanced user control over infrastructure changes. Handles both project structures: Terraform files in root directory or in terraform/ subdirectory.