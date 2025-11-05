# /gitlab-issue - GitLab Issue erstellen: $ARG1 (type) $ARG2 (title) [$ARG3 (description)]

Create comprehensive GitLab issues with proper categorization, templates, and workflow integration.

**Arguments:**
- `$ARG1` (required): Issue type - "bug"|"feature"|"infra"|"docs"|"security" 
- `$ARG2` (required): Issue title (z.B. "Terraform validation fails on Azure provider")
- `$ARG3` (optional): Issue description (wird durch Template ergänzt wenn leer)

## Usage

```
/gitlab-issue [type] [title] [description]
```

## Issue Types and Templates

### 1. Bug Report

**Template Structure:**
```markdown
## Bug Description
Brief description of the issue

## Steps to Reproduce
1. Step one
2. Step two  
3. Step three

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- OS: [e.g., Ubuntu 22.04]
- Version: [e.g., v2.1.0]
- Browser: [if applicable]
- Terraform Version: [if applicable]

## Additional Context
Screenshots, logs, or other relevant information

## Severity
- [ ] Critical - System down, data loss
- [ ] High - Major functionality broken
- [ ] Medium - Feature partially broken
- [ ] Low - Minor issue, workaround available

## Labels
~bug ~needs-investigation
```

### 2. Feature Request

**Template Structure:**
```markdown
## Feature Description
Clear description of the proposed feature

## Problem Statement
What problem does this solve?

## Proposed Solution
Detailed description of the solution

## Alternatives Considered
Other approaches that were considered

## User Stories
- As a [user type], I want [goal] so that [benefit]
- As a [user type], I want [goal] so that [benefit]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Implementation Notes
Technical considerations and constraints

## Labels
~feature ~enhancement ~needs-discussion
```

### 3. Infrastructure Issue

**Template Structure:**
```markdown
## Infrastructure Component
[e.g., Terraform module, Azure resource, networking]

## Issue Description
Detailed description of the infrastructure issue

## Impact Assessment
- Affected environments: [dev/staging/prod]
- Services impacted: [list services]
- User impact: [description]

## Terraform State
```hcl
# Current terraform configuration
resource "example" "name" {
  # configuration
}
```

## Diagnostics
```bash
# Commands run for diagnosis
terraform plan
terraform show
```

## Proposed Resolution
Step-by-step resolution plan

## Rollback Plan
How to revert if resolution fails

## Labels
~infrastructure ~terraform ~urgent
```

### 4. Documentation Issue

**Template Structure:**
```markdown
## Documentation Section
[e.g., README, API docs, architecture docs]

## Issue Type
- [ ] Missing documentation
- [ ] Outdated information
- [ ] Unclear instructions
- [ ] Broken links/examples

## Current State
Description of current documentation state

## Proposed Improvement
What needs to be added/changed/clarified

## Target Audience
Who will benefit from this documentation update

## Priority
- [ ] High - Blocking user onboarding
- [ ] Medium - Improves user experience  
- [ ] Low - Nice to have improvement

## Labels
~documentation ~improvement
```

### 5. GitLab Issue Creation via MCP

**MCP Integration:**
```bash
# Use GitLab MCP tool for issue creation
mcp__gitlab__create_issue with parameters:
{
  "project_id": "current-project-id",
  "title": "$ARG2",
  "description": "generated-template-content",
  "labels": ["auto-assigned-labels"],
  "assignee_ids": [user-id],
  "milestone_id": milestone-id
}
```

### 6. Smart Label Assignment

**Automatic Labels Based on Type:**
```bash
case "$ARG1" in
    "bug")
        LABELS=("bug" "needs-investigation")
        TEMPLATE="bug_report"
        ;;
    "feature")
        LABELS=("feature" "enhancement" "needs-discussion")
        TEMPLATE="feature_request"
        ;;
    "infrastructure"|"infra")
        LABELS=("infrastructure" "terraform")
        TEMPLATE="infrastructure_issue"
        ;;
    "docs"|"documentation")
        LABELS=("documentation" "improvement")
        TEMPLATE="documentation_issue"
        ;;
    "security")
        LABELS=("security" "urgent")
        TEMPLATE="security_issue"
        ;;
esac
```

### 7. Issue Linking and References

**Automatic Linking:**
```bash
# Link to current branch if feature branch
CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
if [[ $CURRENT_BRANCH =~ ^feature/ ]]; then
    DESCRIPTION+="\n\nRelated branch: \`$CURRENT_BRANCH\`"
fi

# Link to recent commits
RECENT_COMMITS=$(git log --oneline -5)
DESCRIPTION+="\n\nRecent commits:\n\`\`\`\n$RECENT_COMMITS\n\`\`\`"

# Reference configuration files
if [ -f "terraform.auto.tfvars" ]; then
    DESCRIPTION+="\n\nRelevant config: terraform.auto.tfvars"
fi
```

### 8. Priority and Milestone Assignment

**Smart Priority Assignment:**
```bash
# Determine priority based on type and keywords
if [[ "$ARG3" =~ (critical|urgent|production|security) ]]; then
    PRIORITY="high"
    LABELS+=("urgent")
elif [[ "$ARG3" =~ (important|major|blocking) ]]; then
    PRIORITY="medium"
else
    PRIORITY="low"
fi

# Assign to current milestone
CURRENT_MILESTONE=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/v//')
if [ -n "$CURRENT_MILESTONE" ]; then
    # Get next milestone
    NEXT_VERSION=$(echo $CURRENT_MILESTONE | awk -F. '{$3++; print $1"."$2"."$3}')
    MILESTONE_ID="milestone-$NEXT_VERSION"
fi
```

### 9. Issue Validation and Enhancement

**Content Validation:**
```bash
# Ensure minimum issue quality
if [ ${#ARG2} -lt 10 ]; then
    echo "❌ Issue title too short (minimum 10 characters)"
    exit 1
fi

if [ ${#ARG3} -lt 50 ]; then
    echo "⚠️  Consider adding more details to the description"
fi

# Check for sensitive information
if [[ "$ARG3" =~ (password|secret|key|token) ]]; then
    echo "⚠️  WARNING: Issue may contain sensitive information"
    echo "Please review before creating"
fi
```

### 10. Post-Creation Actions

**Issue Information Display:**
```bash
echo "✅ GitLab Issue Created"
echo "Type: $ARG1"
echo "Title: $ARG2"
echo "URL: $ISSUE_URL"
echo "Labels: ${LABELS[*]}"
echo "Priority: $PRIORITY"
echo ""
echo "Next Steps:"
echo "- Review issue details and add additional context"
echo "- Assign to appropriate team member"
echo "- Add to project board if using project management"
echo "- Link to related issues or merge requests"
```

## Parameters

- `$ARG1`: Issue type (bug, feature, infra, docs, security)
- `$ARG2`: Issue title (concise, descriptive)
- `$ARG3`: Issue description (detailed context)

## Integration Points

- Links to current git context (branch, commits)
- Integrates with project milestones and labels
- Connects to `/gitlab-mr` for issue resolution workflow
- Works with `/task-create` for project planning
- Compatible with external issue tracking systems

## Success Indicators

- Issue created with appropriate template
- Proper labels and priority assigned
- Relevant context automatically included
- Team members notified appropriately
- Issue trackable through project workflow