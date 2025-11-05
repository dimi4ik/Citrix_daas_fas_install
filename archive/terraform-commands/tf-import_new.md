# /tf-import_new - Terraform Import and Configuration Generator: $ARG1 (Terraform provider name) $ARG2 (Full resource type) $ARG3 (Local Terraform resource identifier) [$ARG4 (Resource ID)]

# Terraform Import and Configuration Generation

## COMMAND USAGE


**Syntax**: `/tf-import_new <provider> <resource_type> <resource_name> [resource_id]`

**Arguments:**
- `$ARG1` (required): Terraform provider name (z.B. "citrix", "azurerm", "aws", "google", "vsphere")
- `$ARG2` (required): Full resource type from provider (z.B. "citrix_delivery_group", "azurerm_virtual_machine")
- `$ARG3` (required): Local Terraform resource identifier (z.B. "my_delivery_group", "main_vm")
- `$ARG4` (optional): Existing resource ID if known

### REQUIRED PARAMETERS:
1. **`provider`** - Terraform provider name
   - Examples: `citrix`, `azurerm`, `aws`, `google`, `vsphere`
   
2. **`resource_type`** - Full resource type from provider
   - Examples: `citrix_delivery_group`, `azurerm_virtual_machine`, `aws_instance`
   
3. **`resource_name`** - Local Terraform resource identifier
   - Examples: `my_delivery_group`, `main_vm`, `web_server`

### OPTIONAL PARAMETERS:
4. **`resource_id`** - Existing resource ID (if known)
   - Examples: `"/subscriptions/.../resourceGroups/my-rg"`, `"i-1234567890abcdef0"`

### USAGE EXAMPLES:
```bash
/tf-import_new citrix citrix_delivery_group my_delivery_group
/tf-import_new azurerm azurerm_resource_group main_rg "/subscriptions/12345/resourceGroups/my-rg"
/tf-import_new aws aws_instance web_server "i-1234567890abcdef0"
```

---

## Task Description

As an experienced Terraform Engineer and DevOps Expert, assist me in automating the import and configuration generation for Terraform resources using the experimental import and generation features.

## Task

I want to leverage the experimental Terraform feature that allows importing existing infrastructure resources and automatically generating the corresponding Terraform configuration.

1. **Import Resources**: Create import blocks for the specified `{provider}_{resource_type}` resource named `{resource_name}`. If `{resource_id}` is provided, use it directly; otherwise, help identify the correct resource ID from the existing infrastructure.
   Reference: https://registry.terraform.io/providers/{provider}/{provider}/latest/docs/resources/{resource_type}

2. **Generate Terraform Configuration (as an Automation Artifact)**: Generate the Terraform configuration for these imported resources as an executable automation artifact.
   Reference: https://developer.hashicorp.com/terraform/language/import/generating-configuration
   Example command: `terraform plan -generate-config-out="generated_{resource_name}.tf"`

3. **File Structure and Best Practices**: Place all import blocks in a file named `import.tf`. Strictly adhere to Terraform best practices for file structure and exact formatting.

## Verification (with Reflection and Chain of Thought)

Think step-by-step and thoroughly verify the generated configuration for:
- Correctness and syntax validation
- Adherence to Terraform and provider-specific best practices
- Security considerations and sensitive data handling
- Potential optimizations and improvements
- Compatibility with existing infrastructure code

Explain each step of your verification and justify your conclusions.

## Implementation Steps

1. **Resource Analysis**: Analyze the target `{provider}_{resource_type}` and identify required attributes
2. **Import Block Creation**: Create import blocks in `import.tf` with proper formatting:
   ```hcl
   import {
     to = {provider}_{resource_type}.{resource_name}
     id = "{resource_id}"
   }
   ```
3. **Configuration Generation**: Use `terraform plan -generate-config-out="generated_{resource_name}.tf"`
4. **Configuration Review**: Review and optimize the generated configuration
5. **Validation**: Run `terraform validate` and `terraform plan` to ensure correctness
6. **Documentation**: Document the import process and any manual adjustments required

## Expected Deliverables

- `import.tf` file with properly formatted import blocks for `{provider}_{resource_type}.{resource_name}`
- Generated Terraform configuration file (`generated_{resource_name}.tf`)
- Verification report with step-by-step analysis specific to the `{provider}` provider
- Documentation of the import process and best practices applied
- Provider-specific considerations and recommendations

## Provider-Specific Considerations

The command will automatically adapt to different providers:
- **Citrix**: Citrix DaaS resources, authentication requirements, site configuration
- **Azure**: Subscription context, resource group dependencies, managed identities
- **AWS**: Region settings, IAM permissions, account-specific resources
- **Google Cloud**: Project context, service account requirements, regional resources
- **VMware vSphere**: vCenter connection, datacenter hierarchy, permissions

## Security Notes

- Never expose sensitive data (passwords, keys, tokens) in generated configurations
- Use appropriate Terraform sensitive attribute markings
- Ensure imported resources maintain existing security configurations
- Validate that import operations don't disrupt production resources