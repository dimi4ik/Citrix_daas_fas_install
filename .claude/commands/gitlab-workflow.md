# /gitlab-workflow

Intelligent GitLab workflow automation with sequential thinking capabilities for DevOps tasks. Combines MCP GitLab operations with adaptive reasoning to create robust, intelligent workflows.

## Functionality

### Workflow Types
1. **`feature-branch`** - Complete feature development workflow with intelligent branch management
2. **`hotfix`** - Critical fixes with fast-track process and automated validation
3. **`repository-setup`** - New project creation with standard compliance
4. **`multi-repo-sync`** - Cross-repository synchronization with conflict resolution
5. **`issue-to-mr`** - Issue-to-merge-request workflow with automatic linking

### Sequential Thinking Integration
- **Context Analysis** - Analyze current repository state and requirements
- **Decision Making** - Intelligent workflow path selection
- **Plan Generation** - Step-by-step execution plan with alternatives
- **Risk Assessment** - Identify potential issues and create mitigation strategies
- **Adaptive Execution** - Execute with real-time adjustments and error recovery

### Core Capabilities
- **Intelligent Automation** - Not just orchestration, but true reasoning
- **Adaptive Workflows** - Adjust to project context and current situation
- **Error Resilience** - Robust error handling with intelligent fallbacks
- **Learning Integration** - Continuous improvement through experience
- **TodoWrite Integration** - Automatic task tracking for complex workflows

## Implementation

### Command Structure
```
/gitlab-workflow [workflow-type] [target] [options]

Arguments:
  workflow-type    Required: feature-branch, hotfix, repository-setup, multi-repo-sync, issue-to-mr
  target          Required: Target name (branch name, repository name, issue number)
  
Options:
  --project       Project namespace/name (default: current repository)
  --template      Template to use for repository-setup
  --urgent        Priority flag for hotfix workflows
  --dry-run       Show execution plan without executing
  --verbose       Detailed logging of sequential thinking process
```

### Sequential Thinking Workflow Engine
The command uses a structured thinking process to analyze, plan, and execute GitLab workflows:

1. **Context Analysis Phase**
   - Analyze current repository state
   - Check branch structure and naming conventions
   - Evaluate project standards and compliance requirements
   - Assess user permissions and access levels

2. **Decision Making Phase**
   - Determine optimal workflow path
   - Evaluate potential conflicts and dependencies
   - Select appropriate MCP GitLab tool chain
   - Identify critical decision points

3. **Plan Generation Phase**
   - Create step-by-step execution plan
   - Generate alternative paths for error scenarios
   - Define validation checkpoints
   - Plan rollback strategies

4. **Risk Assessment Phase**
   - Identify potential failure points
   - Assess impact of workflow execution
   - Create mitigation strategies
   - Define success criteria

5. **Adaptive Execution Phase**
   - Execute plan with real-time monitoring
   - Adjust based on intermediate results
   - Handle errors with intelligent recovery
   - Validate each step before proceeding

## Workflow Templates

### 1. Feature Branch Workflow

**Usage:** `/gitlab-workflow feature-branch "user-authentication" --project="dimi4ik/devops_tf_templates"`

**Sequential Thinking Process:**
```
Thought 1: Analyze current repository state
- Check existing branches and naming conventions
- Evaluate project structure and standards
- Assess current main branch status

Thought 2: Evaluate workflow requirements
- Determine optimal branch naming strategy
- Check for existing related branches or issues
- Assess complexity and scope of feature

Thought 3: Generate execution plan
- Create feature branch from main
- Set up initial structure if needed
- Plan merge request creation strategy

Thought 4: Identify potential issues
- Check for naming conflicts
- Assess merge conflicts potential
- Evaluate CI/CD pipeline compatibility

Thought 5: Execute with monitoring
- Create branch with validation
- Set up initial files if needed
- Create tracking issue and MR template
```

**MCP GitLab Tool Chain:**
1. `search_repositories` - Verify project access
2. `get_file_contents` - Analyze current structure
3. `create_branch` - Create feature branch
4. `create_or_update_file` - Initialize structure
5. `create_issue` - Create tracking issue
6. `create_merge_request` - Prepare MR for review

### 2. Hotfix Workflow

**Usage:** `/gitlab-workflow hotfix "security-patch" --urgent --project="dimi4ik/devops_tf_templates"`

**Sequential Thinking Process:**
```
Thought 1: Assess urgency and impact
- Evaluate criticality of the fix
- Check current production state
- Assess security implications

Thought 2: Determine minimal change scope
- Identify specific files/components to fix
- Assess dependencies and side effects
- Plan minimal viable fix

Thought 3: Create fast-track process
- Create hotfix branch from main
- Plan accelerated review process
- Set up automated validation

Thought 4: Plan validation and testing
- Define minimal testing requirements
- Set up automated security scans
- Plan rollback procedures

Thought 5: Execute with monitoring
- Create hotfix branch
- Apply fix with validation
- Create urgent MR with appropriate labels
```

**MCP GitLab Tool Chain:**
1. `search_repositories` - Verify project access
2. `create_branch` - Create hotfix branch from main
3. `push_files` - Apply fix files
4. `create_merge_request` - Create urgent MR
5. `create_issue` - Create post-mortem issue

### 3. Repository Setup Workflow

**Usage:** `/gitlab-workflow repository-setup "terraform-azure-vm" --template="terraform-module"`

**Sequential Thinking Process:**
```
Thought 1: Analyze template requirements
- Understand project type and requirements
- Check available templates and standards
- Assess compliance and security requirements

Thought 2: Plan repository structure
- Define optimal directory structure
- Plan initial files and documentation
- Set up CI/CD pipeline configuration

Thought 3: Configure project standards
- Apply naming conventions
- Set up pre-commit hooks
- Configure branch protection rules

Thought 4: Validate setup
- Check template completeness
- Verify security configurations
- Validate CI/CD pipeline setup

Thought 5: Execute setup
- Create repository with structure
- Initialize with template files
- Set up development branch and initial MR
```

**MCP GitLab Tool Chain:**
1. `create_repository` - Create new repository
2. `push_files` - Initialize with template files
3. `create_branch` - Create development branch
4. `create_issue` - Create setup todo issues
5. `create_merge_request` - Initial MR for review

### 4. Multi-Repository Sync Workflow

**Usage:** `/gitlab-workflow multi-repo-sync "security-update" --projects="repo1,repo2,repo3"`

**Sequential Thinking Process:**
```
Thought 1: Analyze target repositories
- Check access permissions for all repos
- Analyze current state of each repository
- Identify common patterns and differences

Thought 2: Plan synchronization strategy
- Determine optimal sync approach
- Plan conflict resolution strategies
- Set up parallel vs sequential execution

Thought 3: Create coordination plan
- Plan branch creation across repos
- Set up cross-repository issue linking
- Plan merge request coordination

Thought 4: Assess synchronization risks
- Identify potential conflicts
- Plan rollback strategies
- Set up monitoring and validation

Thought 5: Execute coordinated sync
- Create branches in all repositories
- Apply changes with conflict resolution
- Create linked MRs for review
```

**MCP GitLab Tool Chain:**
1. `search_repositories` - Verify access to all repos
2. `create_branch` - Create sync branches
3. `push_files` - Apply changes to all repos
4. `create_issue` - Create coordination issue
5. `create_merge_request` - Create linked MRs

### 5. Issue-to-MR Workflow

**Usage:** `/gitlab-workflow issue-to-mr "42" --project="dimi4ik/devops_tf_templates"`

**Sequential Thinking Process:**
```
Thought 1: Analyze issue requirements
- Parse issue description and requirements
- Identify scope and complexity
- Check for related issues or dependencies

Thought 2: Plan implementation approach
- Determine optimal solution strategy
- Plan code structure and files to modify
- Assess testing requirements

Thought 3: Create development plan
- Create feature branch for issue
- Plan implementation steps
- Set up tracking and validation

Thought 4: Link issue to implementation
- Create branch with issue reference
- Set up automatic issue closing
- Plan review and approval process

Thought 5: Execute implementation setup
- Create branch with issue link
- Set up initial implementation structure
- Create MR that closes issue
```

**MCP GitLab Tool Chain:**
1. `search_repositories` - Verify project access
2. `get_file_contents` - Read issue details
3. `create_branch` - Create branch with issue reference
4. `create_or_update_file` - Initialize implementation
5. `create_merge_request` - Create MR that closes issue

## Error Handling and Recovery

### Intelligent Error Recovery
```
Error Detection:
- MCP GitLab API failures
- Permission issues
- Conflict situations
- Network connectivity problems

Recovery Strategies:
- Automatic retry with exponential backoff
- Alternative workflow paths
- Graceful degradation
- User notification with actionable solutions

Fallback Mechanisms:
- Manual intervention guidance
- Partial workflow completion
- State preservation for retry
- Rollback to previous state
```

### Context-Aware Error Messages
```
Instead of: "API call failed"
Provide: "Cannot create branch 'feature/user-auth' - branch already exists. 
         Options: 1) Use existing branch, 2) Create with suffix, 3) Delete and recreate"

Instead of: "Permission denied"
Provide: "Insufficient permissions to create branches in dimi4ik/devops_tf_templates. 
         Contact repository owner or use fork workflow instead."
```

## Integration Points

### TodoWrite Integration
```
Automatic Task Creation:
- Complex workflows create sub-tasks
- Progress tracking for multi-step operations
- Intelligent prioritization based on workflow type
- Automatic task completion marking

Task Categories:
- workflow-setup: Initial configuration tasks
- workflow-execution: Implementation tasks
- workflow-validation: Testing and review tasks
- workflow-cleanup: Post-completion tasks
```

### Branch Management
```
Strict Branch Policy:
- NEVER work in main branch
- Automatic branch creation with conventions
- Intelligent branch naming based on workflow type
- Automatic branch cleanup after successful merge

Branch Naming Conventions:
- feature/[feature-name] - Feature development
- hotfix/[issue-description] - Critical fixes
- setup/[repo-name] - Repository setup
- sync/[sync-target] - Multi-repo sync
- issue/[issue-number] - Issue implementation
```

### CLAUDE.md Compliance
```
Automatic Standards Application:
- Apply project-specific naming conventions
- Enforce security best practices
- Apply consistent code formatting
- Validate against project standards

Compliance Checks:
- Terraform formatting and validation
- Security scanning integration
- Documentation requirements
- Git commit message standards
```

## Usage Examples

### Basic Feature Development
```bash
# Create feature branch with full workflow
/gitlab-workflow feature-branch "user-authentication" --project="dimi4ik/devops_tf_templates"

# With verbose sequential thinking output
/gitlab-workflow feature-branch "user-authentication" --project="dimi4ik/devops_tf_templates" --verbose

# Dry run to see execution plan
/gitlab-workflow feature-branch "user-authentication" --project="dimi4ik/devops_tf_templates" --dry-run
```

### Critical Hotfix
```bash
# Urgent security patch
/gitlab-workflow hotfix "security-patch" --urgent --project="dimi4ik/devops_tf_templates"

# Hotfix with specific project
/gitlab-workflow hotfix "critical-bug-fix" --project="dimi4ik/production-app" --urgent
```

### Repository Setup
```bash
# Create new Terraform module
/gitlab-workflow repository-setup "terraform-azure-vm" --template="terraform-module"

# Create new project with specific template
/gitlab-workflow repository-setup "new-microservice" --template="golang-service"
```

### Multi-Repository Operations
```bash
# Sync security updates across multiple repos
/gitlab-workflow multi-repo-sync "security-update" --projects="repo1,repo2,repo3"

# Update dependencies across project family
/gitlab-workflow multi-repo-sync "dependency-update" --projects="api,web,mobile"
```

### Issue-to-Implementation
```bash
# Implement solution for issue #42
/gitlab-workflow issue-to-mr "42" --project="dimi4ik/devops_tf_templates"

# Implement with specific branch strategy
/gitlab-workflow issue-to-mr "156" --project="dimi4ik/production-app" --verbose
```

## Monitoring and Logging

### Sequential Thinking Logging
```
When --verbose flag is used:
- Log each thinking step with reasoning
- Show decision points and alternatives considered
- Display risk assessment and mitigation strategies
- Track execution progress with timestamps
```

### Workflow Metrics
```
Track workflow performance:
- Execution time by workflow type
- Success/failure rates
- Most common error patterns
- Learning effectiveness metrics
```

### Integration with GitLab
```
Automatic GitLab Integration:
- Create workflow tracking issues
- Link related merge requests
- Add appropriate labels and milestones
- Update project boards and wikis
```

## Security Considerations

### Permission Validation
```
Before execution:
- Verify user permissions for target repositories
- Check branch protection rules
- Validate merge request creation rights
- Ensure compliance with project policies
```

### Sensitive Data Handling
```
Security measures:
- Never log sensitive information
- Validate input for injection attacks
- Use secure GitLab API authentication
- Encrypt workflow state if persisted
```

### Audit Trail
```
Comprehensive logging:
- All workflow executions with timestamps
- User attribution for all actions
- Changes made by workflow
- Rollback actions taken
```

## Command Arguments

The command accepts the following arguments format:

```
Arguments: $ARGUMENTS
```

The arguments are parsed as follows:
1. **workflow-type** (required): One of feature-branch, hotfix, repository-setup, multi-repo-sync, issue-to-mr
2. **target** (required): Target name (branch name, repository name, issue number)
3. **options** (optional): Various flags and parameters

## Instructions

🚨 **CRITICAL RULE: NEVER WORK IN MAIN BRANCH!**

1. **Sequential Thinking Analysis**:
   - Start sequential thinking session with current context
   - Analyze repository state and requirements
   - Generate adaptive execution plan
   - Identify risks and mitigation strategies

2. **Workflow Execution**:
   - Execute planned workflow with monitoring
   - Handle errors with intelligent recovery
   - Validate each step before proceeding
   - Update progress with TodoWrite integration

3. **Branch Management**:
   - Always create feature/task branches
   - Never work directly in main branch
   - Use intelligent branch naming conventions
   - Clean up branches after successful merge

4. **Error Handling**:
   - Provide context-aware error messages
   - Offer actionable solutions
   - Implement automatic retry mechanisms
   - Preserve state for manual intervention

5. **Integration**:
   - Use TodoWrite for progress tracking
   - Apply CLAUDE.md compliance standards
   - Integrate with existing .claude/ commands
   - Maintain audit trail of all actions

The command will automatically detect the workflow type and target from the arguments, then execute the appropriate sequential thinking workflow with intelligent MCP GitLab tool orchestration.