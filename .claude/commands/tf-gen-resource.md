# /tf-gen-resource - Terraform Resource Generator: $ARG1 (resource-type) $ARG2 (provider) [$ARG3 (name)]

Creates optimized Terraform resource templates with integrated best practices, automatic tagging, and security hardening.

**Arguments:**
- `$ARG1` (required): Resource type (z.B. "vm", "bucket", "vpc", "database", "load-balancer")
- `$ARG2` (required): Cloud provider - "aws"|"azure"|"gcp"|"vsphere"
- `$ARG3` (optional): Resource name (default: auto-generated, z.B. "web-server", "data-storage")

## Functionality

### Intelligent Resource Scaffolding
- **Best-Practice Templates**: Generates Terraform code according to industry standards
- **Security-First Approach**: Implements defensive security configurations by default
- **Auto-Tagging**: Automatically adds compliance-compliant resource tags
- **IAM Least-Privilege**: Creates minimal necessary permissions
- **Testing Integration**: Generates Terratest-compatible unit tests

### Supported Resource Types
1. **Compute**: EC2, ECS, Lambda, Azure VMs, GCP Compute Engine
2. **Storage**: S3, EBS, Azure Storage, GCS mit Encryption
3. **Networking**: VPC, Subnets, Security Groups, Load Balancers
4. **Databases**: RDS, DynamoDB, Azure SQL, Cloud SQL
5. **Security**: IAM Roles, Key Vault, Secrets Manager
6. **Monitoring**: CloudWatch, Application Insights, Cloud Monitoring

### Template Features
- **Validation Rules**: Precondition blocks for critical parameters
- **Output Definitions**: Structured outputs for module integration
- **Variable Documentation**: Comprehensive descriptions and examples
- **Provider Versioning**: Pinned versions for production stability

## Implementation

```bash
# Resource Generator Script
generate_terraform_resource() {
    local resource_type=$1
    local resource_name=$2
    local cloud_provider=$3
    local environment=$4
    
    echo "🏗️  Generating ${resource_type} for ${cloud_provider}..."
    
    # Load resource template
    template_file="~/.claude/templates/terraform/${cloud_provider}/${resource_type}.tf.tpl"
    
    # Generate resource files
    envsubst < "$template_file" > "${resource_name}.tf"
    
    # Add variables file
    generate_variables_file "$resource_type" "$resource_name"
    
    # Add outputs file  
    generate_outputs_file "$resource_type" "$resource_name"
    
    # Generate test file
    generate_test_file "$resource_type" "$resource_name"
    
    # Apply security hardening
    apply_security_defaults "$resource_name.tf"
    
    echo "✅ Resource ${resource_name} generated successfully"
}
```

## Resource Templates

### AWS S3 Bucket Template
```hcl
# Generated S3 Bucket with Security Best Practices
resource "aws_s3_bucket" "${RESOURCE_NAME}" {
  bucket = "${PROJECT_NAME}-${ENVIRONMENT}-${RESOURCE_PURPOSE}-${random_id.bucket_suffix.hex}"

  tags = merge(local.common_tags, {
    Name        = "${PROJECT_NAME}-${ENVIRONMENT}-${RESOURCE_PURPOSE}"
    ResourceType = "Storage"
    BackupEnabled = "true"
  })
}

# Encryption Configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "${RESOURCE_NAME}_encryption" {
  bucket = aws_s3_bucket.${RESOURCE_NAME}.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.${RESOURCE_NAME}_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Block Public Access (Security Hardening)
resource "aws_s3_bucket_public_access_block" "${RESOURCE_NAME}_pab" {
  bucket = aws_s3_bucket.${RESOURCE_NAME}.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning
resource "aws_s3_bucket_versioning" "${RESOURCE_NAME}_versioning" {
  bucket = aws_s3_bucket.${RESOURCE_NAME}.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "${RESOURCE_NAME}_lifecycle" {
  bucket = aws_s3_bucket.${RESOURCE_NAME}.id

  rule {
    id     = "transition_rule"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = var.retention_days
    }
  }
}

# KMS Key for Encryption
resource "aws_kms_key" "${RESOURCE_NAME}_key" {
  description             = "KMS key for ${PROJECT_NAME} ${ENVIRONMENT} S3 bucket encryption"
  deletion_window_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${PROJECT_NAME}-${ENVIRONMENT}-s3-key"
  })
}

resource "aws_kms_alias" "${RESOURCE_NAME}_key_alias" {
  name          = "alias/${PROJECT_NAME}-${ENVIRONMENT}-s3-key"
  target_key_id = aws_kms_key.${RESOURCE_NAME}_key.key_id
}

# Random suffix for global uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}
```

### Azure Virtual Machine Template
```hcl
# Generated Azure VM with Security Hardening
resource "azurerm_linux_virtual_machine" "${RESOURCE_NAME}" {
  name                = "${PROJECT_NAME}-${ENVIRONMENT}-vm-${RESOURCE_PURPOSE}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username

  # Disable password authentication (Security Best Practice)
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.${RESOURCE_NAME}_nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    
    # Encryption at host
    encryption_at_host_enabled = true
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  # Boot diagnostics
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.${RESOURCE_NAME}_diag.primary_blob_endpoint
  }

  # Security features
  secure_boot_enabled = true
  vtpm_enabled       = true

  tags = merge(local.common_tags, {
    Name         = "${PROJECT_NAME}-${ENVIRONMENT}-vm-${RESOURCE_PURPOSE}"
    ResourceType = "Compute"
    OS           = "Linux"
  })
}

# Network Security Group with minimal access
resource "azurerm_network_security_group" "${RESOURCE_NAME}_nsg" {
  name                = "${PROJECT_NAME}-${ENVIRONMENT}-vm-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # SSH access only from management subnet
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.management_subnet_cidr
    destination_address_prefix = "*"
  }

  tags = merge(local.common_tags, {
    Name = "${PROJECT_NAME}-${ENVIRONMENT}-vm-nsg"
  })
}
```

## Variables Template Generation

```hcl
# Auto-generated variables.tf
variable "project_name" {
  description = "Name of the project"
  type        = string
  
  validation {
    condition     = length(var.project_name) > 2 && length(var.project_name) <= 50
    error_message = "Project name must be between 3 and 50 characters."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "dima@lejkin.de"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
}

variable "enable_monitoring" {
  description = "Enable CloudWatch/Azure Monitor for the resource"
  type        = bool
  default     = true
}

variable "backup_enabled" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

# Resource-specific variables
variable "retention_days" {
  description = "Data retention period in days"
  type        = number
  default     = 90
  
  validation {
    condition     = var.retention_days >= 1 && var.retention_days <= 2557
    error_message = "Retention days must be between 1 and 2557 (7 years)."
  }
}
```

## Test Generation (Terratest)

```go
// Auto-generated test file: test/${RESOURCE_NAME}_test.go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func Test${RESOURCE_NAME_CAMEL}(t *testing.T) {
    t.Parallel()

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../",
        Vars: map[string]interface{}{
            "project_name": "test-project",
            "environment":  "dev",
            "cost_center":  "engineering",
        },
    })

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    // Test resource creation
    resourceId := terraform.Output(t, terraformOptions, "${RESOURCE_NAME}_id")
    assert.NotEmpty(t, resourceId)

    // Test security configurations
    encryptionEnabled := terraform.Output(t, terraformOptions, "${RESOURCE_NAME}_encryption_enabled")
    assert.Equal(t, "true", encryptionEnabled)

    // Test tagging
    tags := terraform.OutputMap(t, terraformOptions, "${RESOURCE_NAME}_tags")
    assert.Equal(t, "test-project", tags["Project"])
    assert.Equal(t, "dev", tags["Environment"])
}
```

## Command Usage

```bash
# Generate AWS S3 Bucket
/generate-resource s3_bucket data-lake aws dev

# Generate Azure VM with Custom Config
/generate-resource virtual_machine web-server azure prod --size Standard_D2s_v3

# Generate Lambda Function with API Gateway
/generate-resource lambda_api user-service aws staging --runtime python3.9

# Generate Kubernetes Deployment
/generate-resource k8s_deployment microservice gcp dev --replicas 3

# Batch generation from template
/generate-resource --from-template web-tier-template --environment prod

# With security profile
/generate-resource database postgres azure prod --security-profile high-compliance
```

## Template Customization

```yaml
# .claude/resource-templates.yaml
templates:
  web_tier:
    resources:
      - type: "load_balancer"
        name: "web-lb"
      - type: "auto_scaling_group" 
        name: "web-asg"
      - type: "database"
        name: "web-db"
        
  security_profiles:
    high_compliance:
      encryption_required: true
      mfa_required: true
      audit_logging: true
      network_isolation: true
```