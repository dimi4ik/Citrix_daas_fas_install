# /gitlab-sync - GitLab Full Workflow: $ARG1 (feature-name) [$ARG2 (commit-message)] [$ARG3 (target-branch)]

Complete GitLab workflow automation: validate changes, create branch, push, and create merge request in one streamlined command.

**Arguments:**
- `$ARG1` (required): Feature name (z.B. "terraform-validation", wird zu Branch "feature/terraform-validation")
- `$ARG2` (optional): Commit message (auto-generiert wenn leer, z.B. "feat: add terraform validation")
- `$ARG3` (optional): Target branch (default: main, z.B. "main"|"develop")

## Usage

```
/gitlab-sync [feature-name] [commit-message] [target-branch]
```

## Complete GitLab Workflow

### 1. Pre-Sync Validation

**Repository Status Check:**
```bash
# Ensure clean working directory
git status --porcelain
if [ $? -ne 0 ]; then
    echo "❌ Working directory not clean"
    exit 1
fi

# Ensure we're on the right starting branch
CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "develop" ]; then
    echo "⚠️  Currently on branch: $CURRENT_BRANCH"
    echo "Consider switching to main/develop before creating feature branch"
fi

# Fetch latest changes
git fetch origin
```

**Code Quality Validation:**
```bash
# Run comprehensive validation
echo "🔍 Running code quality checks..."

# Pre-commit hooks
if [ -f ".pre-commit-config.yaml" ]; then
    pre-commit run --all-files
fi

# Terraform validation (if applicable)
if ls *.tf 1> /dev/null 2>&1; then
    echo "🏗️  Validating Terraform configuration..."
    terraform fmt -check
    terraform validate
    
    # Basic plan check (dry run)
    terraform plan -out=tfplan.tmp
    rm -f tfplan.tmp
fi

# Language-specific validation
if [ -f "package.json" ]; then
    npm test
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    python -m pytest
elif [ -f "Cargo.toml" ]; then
    cargo test
elif [ -f "go.mod" ]; then
    go test ./...
fi
```

### 2. Branch Creation and Management

**Smart Branch Creation:**
```bash
# Generate feature branch name
FEATURE_NAME="$ARG1"
TARGET_BRANCH="${ARG3:-main}"
BRANCH_NAME="feature/$FEATURE_NAME"

# Check if branch already exists
if git show-ref --verify --quiet refs/heads/$BRANCH_NAME; then
    echo "⚠️  Branch $BRANCH_NAME already exists"
    echo "Switching to existing branch..."
    git checkout $BRANCH_NAME
else
    echo "🌿 Creating new branch: $BRANCH_NAME"
    git checkout -b $BRANCH_NAME
fi

# Ensure branch is up to date with target
git merge origin/$TARGET_BRANCH
```

**GitLab Branch Creation via MCP:**
```bash
# Create branch in GitLab if it doesn't exist
mcp__gitlab__create_branch with parameters:
{
  "project_id": "current-project-id",
  "branch": "$BRANCH_NAME",
  "ref": "$TARGET_BRANCH"
}
```

### 3. Commit and Push Workflow

**Smart Commit Creation:**
```bash
# Add all changes
git add .

# Generate or use provided commit message
if [ -n "$ARG2" ]; then
    COMMIT_MSG="$ARG2"
else
    # Generate commit message based on changes
    CHANGED_FILES=$(git diff --cached --name-only)
    
    if echo "$CHANGED_FILES" | grep -q "\.tf$"; then
        COMMIT_MSG="feat: update Terraform configuration for $FEATURE_NAME"
    elif echo "$CHANGED_FILES" | grep -q "docs/"; then
        COMMIT_MSG="docs: update documentation for $FEATURE_NAME"
    elif echo "$CHANGED_FILES" | grep -q "test"; then
        COMMIT_MSG="test: add tests for $FEATURE_NAME"
    else
        COMMIT_MSG="feat: implement $FEATURE_NAME"
    fi
fi

# Create commit with conventional format
git commit -m "$COMMIT_MSG"

# Push to origin
echo "⬆️  Pushing changes to GitLab..."
git push -u origin $BRANCH_NAME
```

### 4. Merge Request Creation

**Automated MR via MCP:**
```bash
# Generate MR title and description
MR_TITLE="feat: $FEATURE_NAME"
MR_DESCRIPTION=$(generate_mr_description)

# Create merge request using GitLab MCP
mcp__gitlab__create_merge_request with parameters:
{
  "project_id": "current-project-id",
  "title": "$MR_TITLE",
  "source_branch": "$BRANCH_NAME",
  "target_branch": "$TARGET_BRANCH",
  "description": "$MR_DESCRIPTION",
  "draft": false,
  "allow_collaboration": true
}
```

**Smart MR Description Generation:**
```bash
generate_mr_description() {
    cat <<EOF
## Summary

Implementation of $FEATURE_NAME feature.

## Changes Made

$(git log $TARGET_BRANCH..HEAD --pretty=format:"- %s")

## Files Modified

$(git diff --name-status $TARGET_BRANCH..HEAD)

## Testing

- [ ] Unit tests pass
- [ ] Integration tests pass  
- [ ] Manual testing completed
- [ ] Terraform plan validates (if applicable)

## Deployment Notes

- [ ] No breaking changes
- [ ] Configuration updates: $([ -f "terraform.auto.tfvars" ] && echo "Yes" || echo "No")
- [ ] Documentation updated: $(git diff --name-only $TARGET_BRANCH..HEAD | grep -q "docs/" && echo "Yes" || echo "No")

## Checklist

- [x] Code follows project conventions
- [x] Pre-commit hooks pass
- [x] Self-review completed
- [ ] Ready for team review

Created via /gitlab-sync command
EOF
}
```

### 5. Integration Validation

**Pipeline Status Check:**
```bash
# Wait for initial pipeline to start
sleep 10

# Check pipeline status (if GitLab CI integration available)
echo "🔄 Checking CI/CD pipeline status..."
PIPELINE_STATUS=$(get_pipeline_status $BRANCH_NAME)

case $PIPELINE_STATUS in
    "running")
        echo "⏳ Pipeline is running... Monitor at: $PIPELINE_URL"
        ;;
    "success")
        echo "✅ Pipeline passed successfully"
        ;;
    "failed")
        echo "❌ Pipeline failed - check logs at: $PIPELINE_URL"
        ;;
    *)
        echo "ℹ️  Pipeline status: $PIPELINE_STATUS"
        ;;
esac
```

### 6. Notification and Summary

**Workflow Summary:**
```bash
echo ""
echo "🚀 GitLab Sync Completed Successfully!"
echo "=================================="
echo "Feature: $FEATURE_NAME"
echo "Branch: $BRANCH_NAME"
echo "Target: $TARGET_BRANCH"
echo "Commit: $COMMIT_MSG"
echo "MR URL: $MR_URL"
echo ""
echo "Next Steps:"
echo "1. Monitor CI/CD pipeline: $PIPELINE_URL"
echo "2. Request code review from team members"
echo "3. Address any review feedback"
echo "4. Merge when approved and pipeline passes"
echo ""
echo "Commands for follow-up:"
echo "- Check MR status: git log --oneline $TARGET_BRANCH..$BRANCH_NAME"
echo "- Update MR: git push (after additional commits)"
echo "- Clean up: git branch -d $BRANCH_NAME (after merge)"
```

### 7. Error Handling and Rollback

**Failure Recovery:**
```bash
handle_sync_failure() {
    local FAILURE_STAGE="$1"
    
    echo "❌ Sync failed at stage: $FAILURE_STAGE"
    
    case $FAILURE_STAGE in
        "validation")
            echo "Fix validation errors and retry"
            ;;
        "branch_creation")
            echo "Check branch permissions and try again"
            ;;
        "push")
            echo "Check network connection and repository access"
            git reset --soft HEAD~1  # Undo commit
            ;;
        "merge_request")
            echo "MR creation failed, but code is pushed successfully"
            echo "Create MR manually at: $GITLAB_PROJECT_URL/-/merge_requests/new"
            ;;
    esac
    
    echo ""
    echo "Rollback options:"
    echo "- Undo commit: git reset --soft HEAD~1"
    echo "- Delete branch: git branch -D $BRANCH_NAME"
    echo "- Return to $TARGET_BRANCH: git checkout $TARGET_BRANCH"
}
```

### 8. Advanced Configuration

**Custom Workflow Hooks:**
```bash
# Pre-sync hook
if [ -f ".gitlab/hooks/pre-sync" ]; then
    echo "🔧 Running pre-sync hook..."
    .gitlab/hooks/pre-sync "$FEATURE_NAME" "$COMMIT_MSG"
fi

# Post-sync hook  
if [ -f ".gitlab/hooks/post-sync" ]; then
    echo "🔧 Running post-sync hook..."
    .gitlab/hooks/post-sync "$MR_URL" "$BRANCH_NAME"
fi
```

## Parameters

- `$ARG1`: Feature name (used for branch and descriptions)
- `$ARG2`: Commit message (optional, auto-generated if not provided)
- `$ARG3`: Target branch (default: main)

## Integration Points

- Uses `/validate` for pre-sync quality checks
- Integrates with `/tf-validate` for Terraform projects
- Connects with GitLab CI/CD pipelines
- Links to project issue tracking
- Works with team notification systems

## Success Criteria

- All validation checks pass
- Feature branch created successfully
- Changes committed and pushed to GitLab
- Merge request created with proper metadata
- CI/CD pipeline triggered successfully
- Team notified of new MR for review