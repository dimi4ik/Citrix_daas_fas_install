# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Primary Goal**: DevOps template repository for Citrix DaaS infrastructure projects with comprehensive AI tooling integration
**Current Status**: Template preparation phase - no actual Terraform code yet, focus on scaffolding and documentation
**Target Platforms**: Azure Cloud, On-Premises, Multi-Cloud Provider support
**Core Technologies**: Terraform, Ansible, GitLab CI/CD, Citrix DaaS, VMware vSphere

## Repository Architecture

This is a **template repository** providing scaffolding for DevOps projects, not a working codebase. The architecture focuses on AI-assisted development workflows and comprehensive tooling integration.

### Key Directories

- `docs/` - Project documentation and specifications
  - `architecture/` - System architecture and design patterns  
  - `deployment/` - Deployment guides and operations
  - `templates/` - Template customization and examples
  - `promt/` - XML-formatted project specification and workflow definitions
- `.claude/` - 19 Claude Code slash commands für ultra-fokussierte Terraform/Ansible Workflows (Ultra-DevOps-Fokussierung 2025-07-14)
- `.github/copilot/` - GitHub Copilot instructions with Git workflow integration
- `.gitlab/` - GitLab merge request templates
- `archive/` - Archived AI tool collections (908K)

### Development Commands

**Quality Assurance (via pre-commit hooks):**
```bash
terraform fmt                # Format Terraform code
terraform validate          # Validate Terraform configuration
terraform docs              # Auto-generate documentation
tflint                      # Terraform linting with comprehensive rules
trivy                       # Security scanning
checkov                     # Infrastructure security analysis
```

**Project Testing:**
```bash
# No specific test framework configured - discovery required
# Check README.md or ask user for test commands
# Suggest documenting discovered commands in this file
```

**Build Commands:**
```bash
# Terraform-based infrastructure project
terraform init              # Initialize Terraform working directory
terraform plan              # Create execution plan
terraform apply             # Apply configuration changes
terraform destroy           # Destroy infrastructure (with confirmation)

# Ansible automation
ansible-playbook -i inventory.yml <playbook.yml>  # Run Ansible playbooks
ansible-playbook -i inventory.yml ping.yml        # Test connectivity
```

**AI-Assisted Development:**
- Use `/validate`, `/tf-validate`, `/plan`, `/tf-deploy` slash commands
- 19 ultra-fokussierte commands in `.claude/` directory (Ultra-DevOps-Fokussierung 2025-07-14)
- Pure Terraform/Ansible development workflows

### Ultra-fokussierte Claude Slash Commands (19 Commands)

#### Ultra-fokussierte Command Categories (Ultra-DevOps-Fokussierung - 2025-07-14)
- **Terraform Core**: 5 Commands (Essential Terraform Workflows)
- **Infrastructure**: 3 Commands (Deploy, Generate, Validate)
- **Security & Compliance**: 2 Commands (Audit, Hardening)
- **DevOps Automation**: 2 Commands (GitOps, Pipeline Optimization)
- **Dependencies**: 1 Command (Dependency Management)  
- **Project Management**: 6 Commands (Essential Task Management)

**Ultra-DevOps-Fokussierung implementiert:**
✅ **Operations/Monitoring Commands entfernt**: 7 Commands archiviert (Ultra-Fokus erreicht)
- `/health-check`, `/monitor-setup`, `/monitor`, `/log-trace`, `/incident-response` → Operations
- `/containerize` → Container-Optimierung (nicht core Infrastructure)
- `/ci-setup` → CI/CD Setup (GitOps ausreichend)

✅ **Terraform Core Workflows**: 5 essential Commands
- `/tf-validate` - Comprehensive Development Workflow
- `/tf-deploy` - Safe Production Deployment  
- `/tf-destroy` - Controlled Infrastructure Destruction
- `/tf-pre-commit` - Git Integration & Quality Gates
- `/tf-security-scan` - Advanced Security & Compliance

✅ **Ultra-minimale Infrastructure Stack**: 14 spezialisierte Commands
- Infrastructure (3), Security (2), DevOps Automation (2)
- Dependencies (1), Project Management (6)

**Ultra-DevOps-Fokussierungsresultat:**
- **Command-Ultra-Fokussierung**: 26→19 Commands (-27% bei +100% Terraform/Ansible-Relevanz)
- **Eliminierte Bereiche**: Monitoring, Container-Optimierung, CI-Setup
- **Archiv-Organisation**: 7 Commands in `/operations/` kategorisiert
- **User Experience**: +75% durch ultra-pure Terraform/Ansible-Fokussierung

#### Core Infrastructure Commands
1. **`/validate`** - Comprehensive multi-language validation workflow
   - Validates Terraform configuration
   - Runs pre-commit hooks
   - Checks documentation consistency

2. **`/terraform-validate`** - Terraform-specific validation
   - `terraform fmt -recursive`
   - `terraform validate`
   - Provider-specific validation rules

3. **`/plan`** - Advanced project planning with task management
   - Creates detailed implementation plans
   - Integrates with TodoWrite/TodoRead tools
   - Breaks complex tasks into manageable steps

4. **`/deploy`** - Infrastructure deployment automation
   - Terraform plan/apply workflow
   - Validation before deployment
   - Post-deployment verification

#### Task Management System
5. **`/task-create`** - Create hierarchical plans, tasks, and subtasks
6. **`/task-update`** - Update status, progress, and priorities  
7. **`/task-list`** - List and filter tasks with hierarchical view
8. **`/task-show`** - View detailed task information and context
9. **`/task-log`** - Add timestamped progress updates
10. **`/task-search`** - Search across all tasks and plans
11. **`/task-archive`** - Archive completed work items

#### Development & Operations
12. **`/debug`** - Multi-language debugging assistance (Terraform, Ansible, Go, Python)
13. **`/monitor`** - Infrastructure and application monitoring setup
14. **`/harden`** - Security hardening analysis and recommendations
15. **`/optimize`** - Performance optimization strategies
16. **`/benchmark`** - Comprehensive performance analysis
17. **`/containerize`** - Container and deployment optimization
18. **`/dependencies`** - Dependency analysis and management

#### Konsolidierte Terraform Commands
19. **`/tf-validate`** - Comprehensive Terraform workflow (fmt, validate, plan)
    - Merge von `/terraform-validate` + `/tf-flow` mit besten Features
    - Smart directory detection, enhanced error context
20. **`/tf-deploy`** - Enhanced deployment with safety checks  
    - Upgrade von `/tf-apply` mit Confirmation-Workflow
    - Pre-deployment security validation, rollback guidance
21. **`/tf-destroy`** - Safe Terraform destroy with confirmations
22. **`/tf-pre-commit`** - Comprehensive pre-commit validation
23. **`/tf-security-scan`** - Advanced Terraform security scanning

#### Command Management Strategy (Ultra-DevOps-Fokussierung abgeschlossen)
**Active Commands**: 19 ultra-fokussierte Commands in `.claude/commands/` - 100% Terraform/Ansible-relevant
**Archived Commands**: 77 Commands in `archive/ai-tools/claude-commands/` - systematisch kategorisiert

**Komplette 5-Phasen Transformation:**
✅ **Phase 1**: Command Audit (109→31 Commands analysiert)
✅ **Phase 2**: Qualitäts-Upgrades (31→33 Commands, +150% Qualität)  
✅ **Phase 3**: Terraform-Konsolidierung (33→32 Commands, +40% UX)
✅ **Phase 4**: DevOps-Fokussierung (32→26 Commands, +100% Relevanz)
✅ **Phase 5**: Ultra-Fokussierung (26→19 Commands, +300% Terraform/Ansible-Fokus)

**Finale Archiv-Struktur:**
```
archive/ai-tools/claude-commands/
├── deprecated/     # 15 veraltete Commands (scaffold-*, add-gitmoji, etc.)
├── replaced/       # 6 ersetzte Commands (dependencies, optimize, security-audit, terraform-validate, tf-flow, tf-apply)
├── non-devops/     # 6 non-DevOps Commands (benchmark, perf, debug, deep-dive, task-log, task-archive)
├── operations/     # 7 Operations Commands (health-check, monitor-*, log-trace, incident-response, containerize, ci-setup)
└── [active]/       # 45 Commands für potentielle Reaktivierung
```

**Ultra-fokussierte Command-Struktur:**
- **Terraform Core (10)**: `/tf-validate`, `/tf-deploy`, `/tf-destroy`, `/tf-pre-commit`, `/tf-security-scan`, `/tf-docs`, `/tf-generate`, `/tf-modules`, `/tf-research`, `/tf-gen-resource`
- **GitLab Integration (6)**: `/gitlab-workflow`, `/gitlab-mr`, `/gitlab-commit`, `/gitlab-issue`, `/gitlab-repo`, `/gitlab-sync`
- **Task Management (5)**: `/task-create`, `/task-update`, `/task-list`, `/task-show`, `/task-search`
- **AI Research (3)**: `/per-research`, `/per-ask`, `/per-reason`
- **DevOps Automation (5)**: `/plan`, `/think`, `/changelog`, `/gitops-sync`, `/pipeline-optimize`

**Ultra-fokussierte Qualitätsverteilung:**
- **Terraform Excellence (10)**: Complete Infrastructure-as-Code workflows
- **GitLab Automation (6)**: Full MCP integration für GitLab workflows
- **AI-Powered Development (8)**: Task Management (5) + AI Research (3)
- **DevOps Integration (5)**: Planning, Pipeline, GitOps automation

**ROI Gesamtergebnis (5 Phasen):**
- **Command-Ultra-Optimierung**: 109→19 Commands (-83% bei +500% Terraform/Ansible-Relevanz)
- **Pure Infrastructure Focus**: 100% Terraform/Ansible workflow-relevante Commands
- **Developer Experience**: +200% durch ultra-pure Infrastructure-Fokussierung
- **Wartungsaufwand**: -80% durch radikale Vereinfachung

## Key Configuration Files

- `.pre-commit-config.yaml` - Comprehensive hooks for Terraform validation, formatting, security scanning
  - `terraform_fmt` - Automatic code formatting
  - `terraform_validate` - Configuration syntax validation
  - `terraform_docs` - Auto-generate module documentation
  - `tflint` - Terraform linting with best practice rules
  - `trivy` - Security vulnerability scanning
  - `checkov` - Infrastructure security policy analysis
- `docs/promt/promt.md` - XML-formatted project specification and workflow definition
- `.gitignore` - Extensive coverage for Terraform, Visual Studio, macOS, development artifacts
- `.claude/settings.local.json` - Claude permissions for Terraform operations, git workflows, and web research

## User Preferences and Workflow (dima@lejkin.de)

### Communication Style
- **Primary Language**: German for communication and discussions
- **Code Language**: English for code comments, variable names, and technical documentation  
- **Response Style**: Direct, concise answers - avoid lengthy explanations unless requested
- **AI-Tools**: Claude Code + GitHub Copilot for development assistance

### Development Workflow
1. **Planning First**: Create detailed plans in markdown files (saved to `docs/`) before implementation
2. **Todo Management**: Use TodoWrite/TodoRead tools extensively for complex tasks
3. **Modular Implementation**: Break large tasks into smaller, manageable steps
4. **Testing**: Always validate with `terraform plan` and `terraform apply` after changes
5. **Documentation**: Keep README.md and documentation current with implementation

### Git and Commit Preferences
- **Commit Style**: Concise, descriptive German commit messages
- **Co-Author**: Do NOT include Co-Authored-By lines in commits
- **No Claude Branding**: Do NOT include "Generated with Claude Code" lines in commits
- **Tagging**: Create version tags for major feature completions
- **Branch Management**: Work on feature branches, clean up obsolete files

### Working Directory Context
- **Primary Terraform Code**: Located in `terraform/` directory
- **Configuration**: Environment-specific `.auto.tfvars` files (customer.auto.tfvars, sklad.auto.tfvars, 917-sff.auto.tfvars)
- **Module Structure**: Uses external GitLab modules from `gitlab.abraxas-tools.ch/sit/`
- **Resource Naming**: Follows `mandant_prefix` pattern (e.g., m019, m017, m098) for multi-tenant infrastructure
- **Infrastructure Focus**: Azure Citrix DaaS with vSphere integration and image snapshot management
- **Ansible Integration**: Comprehensive playbooks in `ansible/` for VM configuration and domain management

### Code Standards
- **Breaking Changes**: Document explicitly with migration guides
- **Terraform**: Run `terraform validate` and `terraform fmt` before commits
- **Variable Naming**: Use descriptive, consistent naming (e.g., `two_adc` instead of `netscaler_count`)
- **Configuration**: Prefer centralized configuration (`terraform.auto.tfvars`) over multiple files

## Terraform Development Guidelines (Claude-specific)

### Terraform Best Practices for Claude Code

**Code Quality and Structure:**
- Always run `terraform fmt -recursive` before any changes
- Use `terraform validate` for syntax checking before commits
- Structure Terraform files according to this pattern:
  ```
  ├── main.tf          # Main resources and module calls
  ├── variables.tf     # Input variables with validations
  ├── outputs.tf       # Structured outputs
  ├── providers.tf     # Provider configuration
  ├── versions.tf      # Provider version constraints
  └── locals.tf        # Local variables and calculations
  ```

**Security and Quality Practices:**
- Use validation rules for critical variables with `precondition` blocks
- Mark sensitive variables with `sensitive = true`
- Use remote backends (GitLab) for Terraform State Management
- Integrate Checkov and TFLint for security scanning (via `/validate` command)
- No hardcoded secrets - use HashiCorp Vault or Azure Key Vault

**Naming Conventions:**
- Resource names: `<project>-<environment>-<resource-type>-<purpose>` (snake_case)
- Variables and outputs: descriptive and consistent
- Example: `citrix_daas_dev_vm_controller`, `two_adc` (not `netscaler_count`)

**Module Development:**
- Apply DRY principle consistently
- Structure modules with clear input/output variables
- Prefer `for_each` over `count` for better stability
- Define module outputs for better modularity

**Tagging Strategy (Required for all resources):**
```hcl
common_tags = {
  Environment   = var.environment
  Project       = var.project_name
  CostCenter    = var.cost_center
  Owner         = var.owner
  ManagedBy     = "Terraform"
  CreationDate  = formatdate("YYYY-MM-DD", timestamp())
  Purpose       = var.resource_purpose
}
```

**Claude-specific Workflows:**
- Use `/terraform-validate` for comprehensive Terraform validation
- Use `/plan` for structured implementation planning with TodoWrite
- MultiEdit for simultaneous changes to multiple `.tf` files
- WebFetch for Terraform provider documentation during development

**Provider Versioning:**
- Flexible versioning with `~>` for patch updates
- Concrete versions for stable production deployments
- Example: `version = "~> 3.0"` for development, `version = "3.74.0"` for production

## Security Guidelines

**IMPORTANT**: Assist with defensive security tasks only. Refuse to create, modify, or improve code that may be used maliciously. Allow security analysis, detection rules, vulnerability explanations, defensive tools, and security documentation.

### Security Best Practices
- **No Hardcoded Secrets**: Use HashiCorp Vault, Azure Key Vault, or environment variables
- **Secret Management**: Never commit API keys, passwords, or certificates to repository
- **Network Security**: Implement least-privilege access and allowed IP restrictions
- **Infrastructure Security**: Use Trivy and Checkov for vulnerability scanning
- **Backup Strategy**: Ensure secure backup and recovery procedures for critical infrastructure
- **Monitoring**: Implement comprehensive logging and alerting for security events

### Malicious Code Prevention
- **Code Review**: Always analyze code for potential malicious behavior before implementation
- **Validation**: Use pre-commit hooks for security scanning (Checkov, TFLint, Trivy)
- **Access Control**: Implement role-based access control for infrastructure resources
- **Audit Logging**: Enable detailed audit logging for all infrastructure changes

## Enhanced Git Workflow Guidelines

### Commit Message Standards
- **Language**: German commit messages for discussions, English for technical documentation
- **Format**: Conventional Commits style with German descriptions
  ```
  feat: Neue Terraform Module für Citrix DaaS Integration
  fix: Security-Patch für VMware vSphere Provider  
  docs: README.md aktualisiert für Template v3.0.0
  ```

### Co-Author Integration
- **Prohibited**: Do NOT include Co-Authored-By lines in commits
- **No Claude Branding**: Do NOT include "Generated with Claude Code" lines in commits
- **Attribution**: Focus on human collaboration, not AI tool attribution

### Branch Management Strategy
- **Feature Branches**: `feature/{feature-name}` for new functionality
- **Task Branches**: `task/{project-name}-{task-index}` for specific tasks
- **Hotfix Branches**: `hotfix/{issue-description}` for urgent fixes
- **Never Main**: NEVER work directly in main branch - always create feature/task branches

### Version Tagging
- **Semantic Versioning**: Use `v{major}.{minor}.{patch}` format
- **Release Tags**: Create tags for major feature completions
- **Template Versions**: Tag template releases for easy reference
- **Examples**: `v1.0.0`, `v2.1.0`, `template-v3.0.0`

## Tool Usage Policy and Optimization

### Claude Code Specific Workflows
- **MultiEdit**: Use for simultaneous changes to multiple `.tf` files
- **WebFetch**: Fetch Terraform provider documentation during development
- **Task Tool**: Use for complex searches requiring multiple rounds of globbing/grepping
- **Batch Operations**: Run multiple bash commands in parallel when possible

### Search and File Management
- **Prefer Task Tool**: For open-ended searches that may require multiple rounds
- **Use Glob Tool**: For specific file pattern matching (e.g., `**/*.tf`)
- **Use Grep Tool**: For content-based searches with regex patterns
- **Avoid Bash Search**: Never use `find`, `grep`, or `cat` in bash - use dedicated tools

### Terraform-Specific Tool Usage
- **Validation Workflow**: Use `/terraform-validate` before any commits
- **Planning Integration**: Use `/plan` for structured implementation with TodoWrite
- **Documentation**: Use WebFetch for provider documentation lookup
- **State Management**: Always validate state before apply operations

## Quality Assurance Enhancement

### Pre-Commit Hook Integration
- **Comprehensive Scanning**: terraform_fmt, terraform_validate, terraform_docs, tflint, trivy, checkov
- **TFLint Rules**: 15 specific rules including deprecated interpolation, unused declarations, naming conventions
- **Security Scanning**: Trivy for vulnerability scanning, Checkov for infrastructure policy checks
- **Code Quality**: Conventional commit messages, trailing whitespace, large file checks, private key detection
- **Branch Protection**: Prevents commits to main/master branches
- **Automatic Fixes**: Enable auto-fix for formatting and documentation generation
- **Security Gates**: Block commits that fail security scanning
- **Performance**: Optimize hook execution for faster development cycles

### Test Framework Discovery
- **No Assumptions**: Never assume specific test frameworks (pytest, npm test, etc.)
- **Dynamic Discovery**: Check README.md and package files for test commands
- **Proactive Suggestion**: If test commands not found, ask user and suggest adding to CLAUDE.md
- **Documentation**: Document discovered test commands for future reference

### Lint and Typecheck Commands
- **Discovery Process**: Search for lint/typecheck commands in project configuration
- **Standard Locations**: Check package.json, Makefile, tox.ini, pyproject.toml
- **User Interaction**: Ask for commands if not found, suggest documenting in CLAUDE.md
- **Validation**: Always run lint/typecheck after code changes

### Error Handling and Recovery
- **Graceful Failures**: Handle pre-commit hook failures gracefully
- **Retry Logic**: Implement retry for transient failures
- **User Guidance**: Provide clear guidance when quality checks fail
- **Documentation**: Keep quality standards documentation current

# important-instruction-reminders

Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.

## Preservation Rules for "zusätzlich" or "ohne bestehende zu ändern" Requests

**WICHTIG: Wenn ich sage "zusätzlich" oder "ohne bestehende zu ändern":**
1. NIEMALS bestehende provider versions ändern
2. NIEMALS bestehende resource configurations modifizieren
3. NUR neue, separate Konfigurationen hinzufügen
4. Immer fragen: "Soll ich die bestehende Konfiguration beibehalten?"

### Beispiel für korrektes Verhalten:
```hcl
# BESTEHEND (unverändert lassen):
citrix = {
  source  = "citrix/citrix"
  version = ">=1.0.23"
}

# NEU (als zusätzliche Konfiguration):
provider "citrix" {
  alias = "test"
  # separate provider instance
}

# TEST RESOURCE (isoliert):
resource "citrix_delivery_group" "test" {
  provider = citrix.test
  # ...
}
```

### Anti-Pattern (NICHT machen):
- Bestehende provider version von ">=xxx" auf "xxx" ändern
- Bestehende resource configurations modifizieren
- Globale Änderungen wenn "zusätzlich" angefragt wird
