# /gitlab-labels

Intelligent GitLab label management with automated workflows for consistent project organization and issue tracking.

## Functionality

### Label Operations
1. **`sync`** - Synchronize all labels according to docs/labels.md taxonomy
2. **`apply`** - Apply labels to MR/Issue with intelligent detection
3. **`audit`** - Audit current labels against project standards
4. **`auto`** - Auto-apply labels based on branch and file patterns
5. **`suggest`** - Suggest optimal labels for current context

### Intelligent Label Detection
- **File Pattern Analysis** - Detect areas based on changed files
- **Branch Pattern Recognition** - Auto-detect type and scope from branch names
- **Commit Message Analysis** - Extract type and scope from conventional commits
- **Project Context Awareness** - Apply labels based on current active projects

## Command Structure

```
/gitlab-labels [operation] [target] [options]

Arguments:
  operation       Required: sync, apply, audit, auto, suggest
  target         Optional: MR number, issue number, or "current" for current branch

Options:
  --project      Project namespace/name (default: current repository)
  --force        Force label creation/update
  --dry-run      Show what would be applied without executing
  --verbose      Show detailed reasoning and detection process
```

## Operations

### 1. Sync Operation
**Usage:** `/gitlab-labels sync --project="sintes/do/mvd-azu/citrix-resources"`

**Function:**
- Synchronizes all labels from docs/labels.md taxonomy
- Creates missing labels with correct colors and descriptions
- Updates existing labels if colors/descriptions changed
- Archives outdated labels (marks with gray color)

**Label Categories:**
- **Type Labels** (4): feature, bug, chore, docs
- **Status Labels** (5): ready, wip, review, blocked, needs-info
- **Area Labels** (8): terraform, scripts, infra, ci, docs, mcp, ai-tools, pre-commit
- **Scope Labels** (7): mcp-integration, pre-commit, provider-updates, ai-tools + 3 archived
- **Priority Labels** (4): p0, p1, p2, p3

### 2. Apply Operation
**Usage:** `/gitlab-labels apply 42 "type:feature,area:terraform,scope:mcp-integration"`

**Function:**
- Apply specific labels to MR or issue
- Validates labels exist before applying
- Suggests missing labels based on context
- Updates status labels intelligently

### 3. Audit Operation
**Usage:** `/gitlab-labels audit --verbose`

**Function:**
- Compare current GitLab labels with docs/labels.md
- Identify missing, outdated, or incorrectly configured labels
- Report compliance with project labeling standards
- Suggest improvements and cleanup actions

### 4. Auto Operation (Smart Detection)
**Usage:** `/gitlab-labels auto current --dry-run`

**Smart Detection Logic:**
```
Branch Pattern Analysis:
- feature/* → type:feature, status:wip
- docs/* → type:docs, area:docs
- terraform/* → area:terraform
- pre-commit/* → area:pre-commit, scope:pre-commit
- hotfix/* → type:bug, priority:p1

File Pattern Analysis:
- *.tf, *.tfvars → area:terraform
- scripts/*.sh → area:scripts
- docs/*.md → area:docs
- .pre-commit-config.yaml → area:pre-commit
- .claude/commands/*.md → area:ai-tools

Project Scope Detection:
- Tasks in /tasks/gitlab-label-create/ → scope:mcp-integration
- Tasks in /tasks/pre-commit-refactoring/ → scope:pre-commit
- Tasks in /tasks/citrix-provider-update/ → scope:provider-updates
```

### 5. Suggest Operation
**Usage:** `/gitlab-labels suggest --verbose`

**Function:**
- Analyze current branch, changed files, and project context
- Suggest optimal label combination
- Explain reasoning for each suggested label
- Provide alternative label options

## Automation Workflows

### Branch-Based Auto-Labeling
```bash
# Automatic labeling when creating MRs
git checkout -b feature/user-authentication
# → Auto-suggests: type:feature, status:wip, area:terraform (if touching .tf files)

git checkout -b docs/update-readme
# → Auto-suggests: type:docs, status:wip, area:docs
```

### File-Change Detection
```bash
# Labels suggested based on modified files
Modified: terraform/main.tf, terraform/variables.tf
# → Suggests: area:terraform

Modified: .pre-commit-config.yaml, scripts/validate.sh
# → Suggests: area:pre-commit, area:scripts

Modified: .claude/commands/new-command.md
# → Suggests: area:ai-tools, scope:ai-tools
```

### Conventional Commit Integration
```bash
# Parse commit messages for automatic labeling
"feat(terraform): add new machine catalog module"
# → Suggests: type:feature, area:terraform, scope:machine-catalogs

"fix(pre-commit): resolve tflint validation errors"  
# → Suggests: type:bug, area:pre-commit, scope:pre-commit

"docs(mcp): update GitLab MCP integration guide"
# → Suggests: type:docs, area:mcp, scope:mcp-integration
```

## Integration with Existing Commands

### GitLab Workflow Integration
```bash
# Enhance /gitlab-workflow with automatic labeling
/gitlab-workflow feature-branch "user-auth" 
# → Automatically applies: type:feature, status:wip + detected areas/scopes
```

### Task Management Integration
```bash
# Integrate with /task-create and TodoWrite
# When working on task gitlab-label-create/002-*, auto-suggest:
# scope:mcp-integration, area:docs, area:scripts
```

## Implementation Examples

### Sync All Labels
```bash
/gitlab-labels sync --force
# Creates all 28+ labels from docs/labels.md
# Output: "✅ Synced 28 labels (12 created, 4 updated, 3 archived)"
```

### Smart MR Labeling
```bash
# Current context: feature/mcp-integration branch, modified files: docs/labels.md, scripts/gitlab-labels-sync.sh
/gitlab-labels auto current
# Suggests: type:feature, status:wip, area:docs, area:scripts, scope:mcp-integration
# Apply? [Y/n] → Automatically applies to current MR if exists
```

### Audit and Cleanup
```bash
/gitlab-labels audit --verbose
# Reports:
# ✅ 28/28 required labels present
# ⚠️  3 outdated labels need archiving
# ❌ 2 labels have incorrect colors
# 💡 Suggests: Update colors, archive old scopes
```

## Error Handling

### Authentication Issues
```
Error: GitLab authentication failed
Solution: Run 'glab auth login --hostname gitlab.com' or set GITLAB_TOKEN
Fallback: Use API mode with personal access token
```

### Permission Issues
```
Error: Insufficient permissions to create labels
Solution: Contact repository maintainer for Developer+ role
Fallback: Generate label creation script for manual execution
```

### Label Conflicts
```
Error: Label 'type:feature' already exists with different color
Solution: Use --force to update or --dry-run to preview changes
Options: 1) Update existing, 2) Skip conflicts, 3) Create with suffix
```

## Security and Compliance

### Label Validation
- Validate label names follow project conventions
- Check color consistency with docs/labels.md
- Ensure descriptions are meaningful and consistent
- Prevent creation of duplicate or conflicting labels

### Audit Trail
- Log all label operations with timestamps
- Track who applied which labels when
- Maintain history of label changes
- Support rollback of label operations

## Command Arguments

```
Arguments: $ARGUMENTS
```

The arguments are parsed as follows:
1. **operation** (required): sync, apply, audit, auto, suggest
2. **target** (optional): MR number, issue number, or "current"
3. **options** (optional): Various flags and parameters

## Instructions

🚨 **CRITICAL: Always validate GitLab authentication before operations!**

1. **Authentication Check**:
   - Verify glab auth status or GITLAB_TOKEN availability
   - Test basic GitLab API access
   - Provide clear authentication guidance if needed

2. **Operation Execution**:
   - **sync**: Use updated gitlab-labels-sync.sh script or MCP GitLab integration
   - **apply**: Use gitlab-mr-label.sh or MCP for label application
   - **audit**: Compare current labels with docs/labels.md taxonomy
   - **auto**: Analyze context and suggest optimal labels
   - **suggest**: Provide recommendations with reasoning

3. **Smart Detection Logic**:
   - Analyze current branch name for patterns
   - Check modified files in current branch vs main
   - Parse commit messages for conventional commit patterns
   - Consider current task context from /tasks/ directory

4. **Label Application**:
   - Validate labels exist before applying
   - Use batch operations for efficiency
   - Provide clear feedback on success/failure
   - Suggest next steps or improvements

5. **Error Recovery**:
   - Provide actionable error messages
   - Offer alternative approaches
   - Guide user through authentication setup
   - Generate manual scripts as fallback

6. **Integration**:
   - Update TodoWrite with progress tracking
   - Log operations for audit trail
   - Integrate with other .claude/ commands
   - Maintain consistency with project standards

The command will intelligently detect the operation and target, then execute the appropriate label management workflow with smart detection and automation capabilities.