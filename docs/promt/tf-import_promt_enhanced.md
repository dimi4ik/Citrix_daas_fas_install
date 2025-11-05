# Enhanced Terraform Citrix DaaS Import & Automation Prompt

## Role & Expertise
As an experienced **Terraform Infrastructure Engineer** and **DevOps Automation Specialist** with deep expertise in:
- Citrix DaaS (Desktop as a Service) architecture and operations
- Multi-cloud infrastructure automation (Azure, AWS, GCP)  
- Enterprise-grade Terraform state management and CI/CD integration
- Infrastructure security and compliance frameworks

## Mission Statement
Automate the complete lifecycle of Citrix DaaS resource import, configuration generation, and infrastructure optimization using Terraform's experimental import capabilities, ensuring production-ready, maintainable, and secure infrastructure as code.

## Context Assessment Framework

### Pre-Execution Environment Analysis
Before proceeding, gather and validate the following context:

1. **Infrastructure Environment:**
   - Current Terraform project structure and conventions
   - State management approach (local, S3, Terraform Cloud, etc.)
   - Provider versions and constraints
   - Team collaboration workflows

2. **Citrix DaaS Environment:**
   - Target cloud provider (Azure/AWS/GCP) and regions
   - Citrix Cloud tenant configuration and authentication
   - Existing resource locations, zones, and hypervisor connections
   - Resource naming conventions and tagging strategies

3. **Organizational Requirements:**
   - Security and compliance frameworks (SOC2, ISO27001, etc.)
   - Change management and approval processes
   - Documentation standards and requirements
   - Testing and validation protocols

## Comprehensive Workflow Framework

### Phase 1: Discovery & Assessment
```bash
# Pre-flight checklist
- [ ] Terraform and provider versions verified
- [ ] Authentication credentials validated
- [ ] State backend accessibility confirmed
- [ ] Target resources identified and mapped
- [ ] Dependency relationships documented
- [ ] Risk assessment completed
```

### Phase 2: Resource Import Strategy
**Input Parameters:**
- Resource Type: `[RESOURCE_TYPE]` (e.g., citrix_image_definition, citrix_machine_catalog)
- Resource Identifier: `[RESOURCE_ID]` (specific GUID or name)
- Import Scope: `[SCOPE]` (single resource, resource group, full environment)

**Import Execution:**
```hcl
# import.tf - Structured import declarations
# Import format: ResourceType.resource_name = "resource_id"
import {
  to = [RESOURCE_TYPE].[RESOURCE_NAME]
  id = "[RESOURCE_ID]"
}
```

### Phase 3: Configuration Generation & Optimization
```bash
# Generate base configuration
terraform plan -generate-config-out="generated_resources.tf"

# Post-generation optimization tasks:
- Extract variables and create variables.tf
- Implement proper resource references
- Apply naming conventions and tagging
- Security hardening and compliance validation
```

### Phase 4: Code Organization & Structure
**File Structure Standard:**
```
terraform/
├── import.tf                    # All import blocks
├── main.tf                      # Core resource definitions  
├── variables.tf                 # Input variables
├── outputs.tf                   # Resource outputs
├── locals.tf                    # Local value computations
├── terraform.tfvars.example     # Configuration templates
├── generated_resources.tf       # Initial generated config (temporary)
└── docs/
    ├── import_log.md           # Import execution documentation
    ├── resource_dependencies.md # Dependency mapping
    └── rollback_procedures.md   # Recovery documentation
```

### Phase 5: Validation & Quality Assurance
**Multi-layer Validation Process:**

1. **Syntax and Configuration Validation:**
```bash
terraform fmt -check -diff
terraform validate
terraform plan -detailed-exitcode
```

2. **Security and Compliance Scanning:**
```bash
# Example security checks
checkov -f main.tf --framework terraform
tflint --config .tflint.hcl
```

3. **Best Practices Verification:**
- [ ] Resource naming follows conventions
- [ ] Sensitive data properly managed
- [ ] Dependencies correctly referenced
- [ ] Documentation complete and accurate
- [ ] Rollback procedures tested

### Phase 6: Integration & Deployment Readiness
**Production Integration Checklist:**
- [ ] CI/CD pipeline integration configured
- [ ] State backup and recovery procedures tested  
- [ ] Team documentation and handoff completed
- [ ] Monitoring and alerting configured
- [ ] Maintenance procedures documented

## Deliverables Specification

### 1. Code Artifacts Package
```
deliverables/
├── terraform/                   # Complete Terraform configuration
├── scripts/                     # Automation and helper scripts
├── docs/                        # Comprehensive documentation
└── tests/                       # Validation and testing scripts
```

### 2. Documentation Portfolio
- **Import Execution Report:** Timestamped log with success/failure details
- **Resource Dependency Map:** Visual and textual dependency relationships
- **Configuration Change Analysis:** Before/after comparison and impact assessment
- **Security & Compliance Report:** Validation results and recommendations
- **Rollback Procedures:** Step-by-step recovery instructions
- **Maintenance Guide:** Ongoing management and update procedures

### 3. Quality Assurance Evidence
- Terraform validate output
- Security scan results
- Best practices compliance checklist
- Performance impact analysis
- Integration test results

## Error Handling & Recovery Framework

### Error Detection and Logging
```bash
# Comprehensive logging strategy
export TF_LOG=DEBUG
terraform plan 2>&1 | tee import_execution.log
```

### Common Error Scenarios & Solutions
1. **Resource Not Found:** Verification steps and alternative discovery methods
2. **Permission Issues:** Authentication troubleshooting guide  
3. **State Conflicts:** State reconciliation and recovery procedures
4. **Configuration Errors:** Syntax validation and correction workflows

### Rollback Procedures
- State backup and restoration steps
- Configuration reversal processes
- Impact assessment and communication protocols

## Success Criteria & Acceptance Tests

### Technical Success Metrics
- [ ] All targeted resources successfully imported
- [ ] Generated configuration passes validation
- [ ] No security vulnerabilities detected
- [ ] Performance impact within acceptable limits
- [ ] Documentation complete and accurate

### Operational Success Metrics  
- [ ] Team can maintain and modify the configuration
- [ ] CI/CD integration functions correctly
- [ ] Rollback procedures verified and documented
- [ ] Compliance requirements satisfied
- [ ] Knowledge transfer completed

## Advanced Automation Patterns

### Batch Import Operations
```bash
# Script for handling multiple resource imports
for resource in $(cat resource_list.txt); do
  terraform import $resource
done
```

### Dynamic Configuration Generation
```hcl
# Template for dynamic resource configuration
locals {
  imported_resources = {
    for r in var.resources_to_import : r.name => r
  }
}
```

### Integration with External Systems
- GitLab CI/CD pipeline integration
- Monitoring and alerting setup
- Documentation automation
- State management optimization

## Continuous Improvement Framework

### Feedback Collection
- Import process efficiency metrics
- Configuration quality assessments  
- Team productivity measurements
- Error rate and resolution time tracking

### Process Optimization
- Template and pattern refinement
- Automation script enhancement
- Documentation improvement
- Training and knowledge sharing

---

## Execution Template

When ready to execute, provide:

1. **Context Information:**
   - Environment details and constraints
   - Resource scope and identifiers
   - Organizational requirements

2. **Expected Outcomes:**
   - Specific deliverables needed
   - Timeline and priority requirements
   - Integration and deployment targets

3. **Success Criteria:**
   - Technical acceptance criteria
   - Operational readiness requirements
   - Quality and compliance standards

This enhanced framework ensures comprehensive, production-ready Terraform automation for Citrix DaaS resource management with robust error handling, quality assurance, and operational excellence.