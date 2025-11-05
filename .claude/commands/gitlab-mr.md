# /gitlab-mr - GitLab Merge Request erstellen: $ARG1 (title) [$ARG2 (source-branch)] [$ARG3 (target-branch)]

Create a GitLab merge request with comprehensive workflow using MCP GitLab integration.

**Arguments:**
- `$ARG1` (required): MR title (z.B. "feat: add terraform validation pipeline")
- `$ARG2` (optional): Source branch (default: current branch, z.B. "feature/tf-validation")
- `$ARG3` (optional): Target branch (default: main, z.B. "main"|"develop")

## Core Workflow

1. **Git Context Analysis**: Determine current branch, project, and changes
2. **MR Description Generation**: Create intelligent description from commits and file changes
3. **GitLab MCP Integration**: Use `mcp__gitlab__create_merge_request` to create MR
4. **Result Summary**: Display MR URL and next steps

## Implementation

### 1. Git Context Detection
First, analyze the current git context and determine the project information:

```bash
# Get current branch (if $ARG2 not provided)
CURRENT_BRANCH=$(git branch --show-current)
SOURCE_BRANCH=${ARG2:-$CURRENT_BRANCH}

# Get target branch (default: main)
TARGET_BRANCH=${ARG3:-main}

# Get project information from git remote
PROJECT_ID=$(git remote get-url origin | sed -n 's/.*gitlab\.com[:/]\([^.]*\)\.git/\1/p')

# Generate commit-based description
COMMITS=$(git log $TARGET_BRANCH..HEAD --pretty=format:"- %s" | head -10)
CHANGED_FILES=$(git diff --name-status $TARGET_BRANCH..HEAD | wc -l)
STATS=$(git diff --stat $TARGET_BRANCH..HEAD)
```

### 2. Smart MR Description Generation

Generate intelligent MR description based on git analysis:
```

```markdown
## Summary

{Analyze commits and generate intelligent summary based on $ARG1 and commit patterns}

## Changes Made

{Generate from git log $TARGET_BRANCH..HEAD}:
$COMMITS

## Files Changed

{Generate from git diff stats}:
$STATS

## Type of Change

{Auto-detect based on commit prefixes and file changes}:
- [x] 🚀 New feature (if commits contain "feat:")
- [x] 🐛 Bug fix (if commits contain "fix:")
- [x] 📚 Documentation (if commits contain "docs:" or many .md files)
- [x] 🔧 Maintenance/refactor (if commits contain "refactor:" or "chore:")

## Testing

- [x] All pre-submission checks passed
- [x] No breaking changes to existing functionality

## Checklist

- [x] Code follows project style guidelines
- [x] Self-review completed
- [x] Documentation updated (if applicable)
- [x] No sensitive data exposed
```

### 3. GitLab MCP Integration

**Direct MCP Tool Execution:**

Use the `mcp__gitlab__create_merge_request` tool with the following parameters:
```javascript
mcp__gitlab__create_merge_request({
  "project_id": PROJECT_ID,  // Auto-detected from git remote
  "title": "$ARG1",          // User-provided title
  "source_branch": SOURCE_BRANCH,  // Current branch or $ARG2
  "target_branch": TARGET_BRANCH,  // main or $ARG3
  "description": GENERATED_DESCRIPTION,  // Smart-generated from commits
  "allow_collaboration": true
})

// NOTE: labels Parameter wird von GitLab MCP nicht unterstützt
// Workaround: Labels werden via glab mr update nachträglich zugewiesen
```

### 4. Enhanced Label Auto-Detection + Assignment (AUTOMATICALLY EXECUTED)

**🔄 WICHTIG: Labels werden automatisch nach MR-Erstellung zugewiesen!**

**Verfügbare GitLab Labels:**
- `area:ai-tools`, `area:docs`, `area:scripts`
- `documentation`, `type:feature`, `enhancement` 
- `bug`, `critical`, `confirmed`
- `scope:mcp-integration`, `status:review`, `status:wip`

**Enhanced Label Auto-Detection + Assignment Implementation:**

```bash
# AUTOMATIC LABEL DETECTION FUNCTION
detect_and_apply_labels() {
    local mr_id=$1
    local target_branch=$2
    
    # Step 1: Analyze git context
    local changed_files=$(git diff --name-only $target_branch..HEAD)
    local commits=$(git log $target_branch..HEAD --pretty=format:"%s")
    local branch_name=$(git branch --show-current)
    
    echo "🔍 Analyzing changes for automatic label detection..."
    
    # Step 2: Smart label detection
    local labels=()
    
    # File-based detection (Enhanced)
    if echo "$changed_files" | grep -q '\.tf$'; then
        labels+=("area:scripts")
        echo "   📄 Terraform files detected → area:scripts"
    fi
    if echo "$changed_files" | grep -q -E '\.(md|txt)$'; then
        labels+=("documentation")
        echo "   📝 Documentation files detected → documentation"
    fi
    if echo "$changed_files" | grep -q 'docs/\|tasks/\|\.claude/'; then
        labels+=("area:docs")
        echo "   📚 Documentation directory detected → area:docs"
    fi
    if echo "$changed_files" | grep -q '\.claude/commands/'; then
        labels+=("area:ai-tools")
        echo "   🤖 Claude commands detected → area:ai-tools"
    fi
    if echo "$changed_files" | grep -q 'scripts/\|\.sh$'; then
        labels+=("area:scripts")
        echo "   🔧 Script files detected → area:scripts"
    fi
    
    # Commit-based detection (Enhanced)
    if echo "$commits" | grep -q '^feat[:(]'; then
        labels+=("type:feature" "enhancement")
        echo "   🚀 Feature commit detected → type:feature, enhancement"
    fi
    if echo "$commits" | grep -q '^fix[:(]'; then
        labels+=("bug")
        echo "   🐛 Bug fix commit detected → bug"
    fi
    if echo "$commits" | grep -q '^docs[:(]'; then
        labels+=("documentation")
        echo "   📖 Documentation commit detected → documentation"
    fi
    if echo "$commits" | grep -q '^chore[:(]'; then
        labels+=("enhancement")
        echo "   🔧 Maintenance commit detected → enhancement"
    fi
    if echo "$commits" | grep -q '^refactor[:(]'; then
        labels+=("enhancement")
        echo "   ♻️ Refactor commit detected → enhancement"
    fi
    
    # Branch-based detection (Enhanced)
    if echo "$branch_name" | grep -q '^task/'; then
        labels+=("status:wip")
        echo "   🚧 Task branch detected → status:wip"
    fi
    if echo "$branch_name" | grep -q '^feature/'; then
        labels+=("type:feature")
        echo "   🌟 Feature branch detected → type:feature"
    fi
    if echo "$branch_name" | grep -q '^fix/\|^hotfix/'; then
        labels+=("bug" "critical")
        echo "   🚨 Fix/Hotfix branch detected → bug, critical"
    fi
    
    # Content-based detection (NEW)
    if echo "$commits" | grep -q -i 'terraform\|tf\|infrastructure'; then
        labels+=("area:scripts")
        echo "   🏗️ Infrastructure content detected → area:scripts"
    fi
    if echo "$commits" | grep -q -i 'mcp\|claude\|ai'; then
        labels+=("scope:mcp-integration")
        echo "   🔗 MCP/AI integration detected → scope:mcp-integration"
    fi
    
    # Step 3: Remove duplicates and prepare labels
    local unique_labels=($(printf "%s\n" "${labels[@]}" | sort -u))
    local labels_string=$(IFS=','; echo "${unique_labels[*]}")
    
    # Step 4: Apply labels to MR
    if [ ${#unique_labels[@]} -gt 0 ]; then
        echo "🏷️ Applying ${#unique_labels[@]} labels: ${labels_string}"
        glab mr update $mr_id --label "$labels_string"
        
        if [ $? -eq 0 ]; then
            echo "✅ Labels successfully applied!"
            return 0
        else
            echo "⚠️ Failed to apply labels via glab"
            return 1
        fi
    else
        echo "ℹ️ No labels detected - MR created without labels"
        return 0
    fi
}
```

### 5. Complete Workflow Implementation (ENHANCED)

**Automatisierter Workflow (IMMER AUSFÜHREN):**

1. **Git Context Analysis**: Analyze current branch, commits, and file changes
2. **Create MR** via `mcp__gitlab__create_merge_request`
3. **🔄 AUTOMATIC LABEL DETECTION** using `detect_and_apply_labels()` function
4. **Apply Labels** via `glab mr update $MR_ID --label "$LABELS_STRING"`
5. **Enhanced Result Summary** with detailed label detection results

**Workflow-Code (COPY THIS EXACT IMPLEMENTATION):**

```bash
# COMPLETE MR CREATION WORKFLOW WITH AUTOMATIC LABELS
create_mr_with_labels() {
    local title="$1"
    local source_branch="${2:-$(git branch --show-current)}"
    local target_branch="${3:-main}"
    
    # Get project ID from git remote
    local project_id=$(git remote get-url origin | sed -n 's/.*gitlab\.com[:/]\([^.]*\)\.git/\1/p')
    
    # Generate intelligent MR description
    local commits=$(git log $target_branch..HEAD --pretty=format:"- %s" | head -10)
    local stats=$(git diff --stat $target_branch..HEAD)
    local changed_files_count=$(git diff --name-only $target_branch..HEAD | wc -l)
    
    echo "🚀 Creating GitLab MR: '$title'"
    echo "📊 Source: $source_branch → $target_branch"
    echo "📁 Files Changed: $changed_files_count"
    
    # Create MR via MCP
    local mr_result=$(mcp__gitlab__create_merge_request "$project_id" "$title" "$source_branch" "$target_branch" "$description" true)
    
    # Extract MR ID from result
    local mr_id=$(echo "$mr_result" | grep -o '"iid":[0-9]*' | cut -d':' -f2)
    local mr_url=$(echo "$mr_result" | grep -o '"web_url":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$mr_id" ]; then
        echo "✅ MR Created: #$mr_id"
        
        # 🔄 AUTOMATIC LABEL DETECTION AND ASSIGNMENT
        detect_and_apply_labels "$mr_id" "$target_branch"
        
        # Display enhanced results
        echo ""
        echo "🎉 GitLab Merge Request Created Successfully!"
        echo "🔗 URL: $mr_url"
        echo "🆔 MR ID: #$mr_id"
        echo "📝 Title: $title"
        echo "🌿 Branch: $source_branch → $target_branch"
        
        return 0
    else
        echo "❌ Failed to create MR"
        return 1
    fi
}

# USAGE INSTRUCTIONS:
# Instead of complex manual implementation, use this function:
# create_mr_with_labels "$ARG1" "$ARG2" "$ARG3"
```

### 6. Enhanced Success Response (AUTOMATIC OUTPUT)

The command will AUTOMATICALLY output detailed results after successful MR creation and label assignment:

```markdown
🎉 **GitLab Merge Request Created Successfully!**

## MR Details:
- **URL**: {mr_web_url}
- **ID**: #{mr_iid}  
- **Title**: {mr_title}
- **Source**: {source_branch} → {target_branch}
- **Status**: {mr_state}
- **Author**: {mr_author}

## Changes Summary:
- **Files Changed**: {changed_files_count}
- **Commits**: {commit_count}

## 🏷️ Auto-Applied Labels:
✅ {detected_labels} (automatisch erkannt und zugewiesen)

## 🔍 Label Detection Results:
- 📁 **File-based**: {file_based_labels}
- 💬 **Commit-based**: {commit_based_labels}  
- 🌿 **Branch-based**: {branch_based_labels}
- 🧠 **Content-based**: {content_based_labels}

## 🚀 Next Steps:
1. **Review MR**: {mr_web_url}
2. **Monitor CI/CD pipeline** (if configured)
3. **Address review feedback** from team members
4. **Merge when approved** ✅

---
*Labels automatically detected and applied via enhanced /gitlab-mr command*
```

### 7. Critical Implementation Instructions

**🔥 WICHTIGE REGEL FÜR CLAUDE:**

**IMMER** nach dem Erstellen eines MR via `mcp__gitlab__create_merge_request`:

1. ✅ **Extract MR ID** from the response
2. ✅ **CALL detect_and_apply_labels()** function automatically  
3. ✅ **Display enhanced results** with label detection details
4. ✅ **No manual intervention required** - everything is automated

**NEVER** create an MR without running the label detection function!

## Error Handling

**Common Issues:**
- **Project ID Detection Failed**: Verify git remote is set to GitLab project
- **Branch Not Found**: Ensure source branch exists and is pushed to remote
- **Permission Issues**: Verify GitLab access token has merge request creation permissions
- **MCP Authentication**: Ensure GitLab MCP server is properly configured

**Fallback Actions:**
- If MCP tool fails, provide manual MR creation URL
- Display all gathered information for manual entry
- Suggest authentication troubleshooting steps

Always use the `mcp__gitlab__create_merge_request` tool directly - no manual GitLab web interface instructions.
