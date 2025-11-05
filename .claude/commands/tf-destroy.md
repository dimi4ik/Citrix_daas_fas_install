Destroy Terraform infrastructure with automatic approval:

1. **Pre-destruction validation**:
   - Check current directory structure for Terraform files
   - Verify Terraform configuration and state
   - Confirm infrastructure exists and is managed by Terraform

2. **Safety checks and warnings**:
   - Display resources that will be destroyed
   - Warn about data loss and irreversible actions
   - Confirm destruction is intentional
   - Check for critical resources (databases, storage with data)

3. **Generate destruction plan**:
   - Run terraform plan -destroy to show what will be removed
   - Display comprehensive list of resources to be destroyed
   - Highlight any potential issues or dependencies

4. **Execute terraform destroy -auto-approve**:
   - Destroy infrastructure automatically
   - Monitor destruction progress
   - Capture destruction output and errors

5. **Post-destruction verification**:
   - Verify successful resource removal
   - Check for any remaining resources
   - Display destruction summary
   - Clean up local state if requested

6. **Provide destruction summary**:
   - Resources destroyed count and details
   - Destruction time and status
   - Any warnings or issues encountered
   - Cleanup recommendations

**Usage**: Run from any directory - command will automatically detect Terraform files and execute destruction from the correct location.

**⚠️ CRITICAL WARNING**: This command uses `-auto-approve` which bypasses confirmation prompts and will PERMANENTLY DESTROY all managed infrastructure. Use with extreme caution.

**Note**: Provides comprehensive safety checks and detailed feedback on infrastructure destruction. Handles both project structures: Terraform files in root directory or in terraform/ subdirectory.
