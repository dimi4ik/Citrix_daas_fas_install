# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Primary Goal**: DevOps template repository for Citrix DaaS FAS (Federated Authentication Service) installation
**Current Status**: Initial project scaffolding with Claude Code commands and PowerShell automation scripts
**Target Platforms**: Citrix DaaS with Federated Authentication Service
**Core Technologies**: PowerShell (FAS configuration), Terraform (future IaC), GitLab CI/CD, Claude Code AI workflows

## Repository Architecture

This is a **template repository** providing scaffolding for DevOps projects, not a working codebase. The architecture focuses on AI-assisted development workflows and comprehensive tooling integration.

### Key Directories

- `docs/` - Project documentation and specifications
  - `architecture/` - System architecture and design patterns
  - `deployment/` - Deployment guides and operations
  - `templates/` - Template customization and examples
  - `promt/` - XML-formatted project specification and Terraform import workflow definitions
- `.claude/commands/` - **32 Claude Code slash commands** for Terraform, GitLab, task management, and AI-assisted workflows
- `scripts/` - PowerShell automation scripts for Citrix FAS
  - `Configure-FAS.ps1` - Main FAS configuration script
  - `Configure-FAS-UserRules.ps1` - FAS user rules configuration
  - `Deploy-FAS.ps1` - FAS deployment automation
  - `copy-mcp-servers.py` - MCP server management utility
  - `.mcp-aliases.sh` - MCP command aliases
- `tasks/` - Task management and planning files (empty placeholder)

### Development Commands

**PowerShell Scripts (Citrix FAS):**
```powershell
# FAS configuration and deployment
.\scripts\Deploy-FAS.ps1                    # Deploy FAS infrastructure
.\scripts\Configure-FAS.ps1                 # Configure FAS server
.\scripts\Configure-FAS-UserRules.ps1       # Configure user authentication rules
```

**Python Utilities:**
```bash
python scripts/copy-mcp-servers.py          # Manage MCP server configurations
source scripts/.mcp-aliases.sh              # Load MCP command aliases
```

**Terraform (Future Implementation):**
```bash
terraform init              # Initialize Terraform working directory
terraform plan              # Create execution plan
terraform apply             # Apply configuration changes
terraform destroy           # Destroy infrastructure (with confirmation)
```

**Quality Assurance:**
```bash
# Pre-commit hooks not yet configured
# Use Claude Code slash commands for validation:
# /tf-validate, /tf-security-scan, /tf-pre-commit
```

**AI-Assisted Development:**
- Use `/tf-validate`, `/plan`, `/tf-deploy`, `/tf-security-scan` slash commands
- 32 specialized commands in `.claude/commands/` directory
- GitLab workflow integration via `/gitlab-*` commands
- Task management via `/task-*` commands

### Claude Code Slash Commands (32 Commands)

#### Command Categories
- **Terraform Core**: 11 Commands (Complete Terraform lifecycle)
- **GitLab Integration**: 7 Commands (Full GitLab workflow automation)
- **Task Management**: 5 Commands (Project planning and tracking)
- **AI Research**: 3 Commands (AI-powered research and reasoning)
- **DevOps Automation**: 6 Commands (Planning, pipeline, GitOps, changelog)

#### Terraform Commands (11)
1. **`/tf-validate`** - Comprehensive validation workflow (fmt, validate, plan)
2. **`/tf-deploy`** - Safe production deployment with security checks
3. **`/tf-destroy`** - Controlled infrastructure destruction with confirmations
4. **`/tf-pre-commit`** - Git integration and quality gates
5. **`/tf-security-scan`** - Advanced security and compliance scanning
6. **`/tf-docs`** - Terraform documentation generation
7. **`/tf-generate`** - Generate Terraform configurations
8. **`/tf-modules`** - Terraform module management
9. **`/tf-research`** - Research Terraform providers and resources
10. **`/tf-gen-resource`** - Generate specific Terraform resources
11. **`/tf-import_new`**, **`/tf-import_promt`** - Terraform import workflows

#### GitLab Integration (7)
12. **`/gitlab-workflow`** - Complete GitLab workflow automation
13. **`/gitlab-mr`** - Merge request management
14. **`/gitlab-commit`** - Automated commit workflows
15. **`/gitlab-issue`** - Issue tracking and management
16. **`/gitlab-repo`** - Repository operations
17. **`/gitlab-sync`** - Repository synchronization
18. **`/gitlab-labels`** - Label management

#### Task Management (5)
19. **`/task-create`** - Create hierarchical plans, tasks, and subtasks
20. **`/task-update`** - Update status, progress, and priorities
21. **`/task-list`** - List and filter tasks with hierarchical view
22. **`/task-show`** - View detailed task information and context
23. **`/task-search`** - Search across all tasks and plans

#### AI Research & Reasoning (3)
24. **`/per-research`** - AI-powered research with Perplexity integration
25. **`/per-ask`** - Ask questions with AI reasoning
26. **`/per-reason`** - Deep reasoning and analysis

#### DevOps Automation (6)
27. **`/plan`** - Advanced project planning with task management
28. **`/think`** - Strategic thinking and problem-solving
29. **`/changelog`** - Automated changelog generation
30. **`/gitops-sync`** - GitOps workflow synchronization
31. **`/pipeline-optimize`** - CI/CD pipeline optimization

#### Command Overview
All 32 commands are actively maintained in `.claude/commands/` and provide comprehensive coverage for:
- **Infrastructure as Code**: Complete Terraform development lifecycle
- **Source Control Integration**: Full GitLab workflow automation with MCP
- **Project Management**: Hierarchical task planning and tracking
- **AI-Assisted Development**: Research, reasoning, and code generation
- **DevOps Workflows**: Pipeline optimization, GitOps, changelog automation

These commands are optimized for Citrix DaaS infrastructure projects and integrate seamlessly with GitLab CI/CD workflows.

## Key Configuration Files

- `.gitignore` - Comprehensive patterns for Terraform state, MCP configurations, and development artifacts
  - Terraform state files and directories (`.terraform/`, `*.tfstate`)
  - MCP server configurations with sensitive data (`backups/mcp-config/`)
  - Terraform override files and crash logs
  - Environment-specific tfvars files
- `.claudeignore` - Files excluded from Claude Code context
- `docs/promt/` - XML-formatted project specifications
  - `promt.md` - Main project specification and workflow definition
  - `tf-import_promt.md` - Terraform import workflow prompts
  - `tf-import_promt_enhanced.md` - Enhanced import workflows
- `.claude/commands/` - 32 specialized slash commands for development workflows
- `scripts/.mcp-aliases.sh` - MCP command aliases for shell integration

**Note**: Pre-commit hooks and additional configuration files should be added during project initialization.

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
- **Current Focus**: Citrix Federated Authentication Service (FAS) installation and configuration
- **PowerShell Scripts**: Located in `scripts/` directory for FAS deployment and configuration
- **MCP Integration**: Python utilities and shell aliases for MCP server management
- **Documentation**: Comprehensive docs in `docs/` with architecture, deployment guides, and XML prompts
- **Future Terraform**: Infrastructure as Code implementation planned (currently no `.tf` files)
- **Task Management**: Empty `tasks/` directory ready for project planning files
- **Git Workflow**: Development on `claude/init-project-*` branches, commits in German

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

### Pre-Commit Hook Integration (Planned)
**Status**: Not yet configured - to be implemented during project initialization

**Planned Configuration**:
- **Terraform Quality**: `terraform_fmt`, `terraform_validate`, `terraform_docs`
- **Linting**: `tflint` with comprehensive rules for best practices
- **Security Scanning**: `trivy` (vulnerability scanning), `checkov` (policy checks)
- **Code Quality**: Conventional commits, trailing whitespace detection, private key detection
- **Branch Protection**: Prevent commits to main/master branches
- **Automatic Fixes**: Auto-format and auto-generate documentation

**Current Workaround**: Use Claude Code slash commands for validation:
- `/tf-validate` - Format, validate, and plan
- `/tf-security-scan` - Security and compliance scanning
- `/tf-pre-commit` - Comprehensive pre-commit checks

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
