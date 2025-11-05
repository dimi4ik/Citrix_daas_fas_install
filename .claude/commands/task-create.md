Create a new project task or subtask following the simplified structure.

Usage:

- `/task-create project "project-name" [--description="description"]`
- `/task-create subtask "project-name" "subtask-title" [--priority=high|medium|low]`

Arguments: $ARGUMENTS

## Instructions

🚨 **CRITICAL RULE: NEVER WORK IN MAIN BRANCH!**

1. **Branch Management (ALWAYS FIRST)**:
   - **Check current branch**: `git branch --show-current`
   - **If in main/master branch**: IMMEDIATELY create new branch and switch
   - **Branch naming**:
     - For Projects: `feature/{project-name}`
     - For Subtasks: `task/{project-name}-{subtask-index}`
   - **Create branch**: `git checkout -b {branch-name}`
   - **Branch status**: Confirm with `git status`

2. **Parse the arguments** to extract:
   - Type: project or subtask (required, first argument)
   - Project name: hyphenated lowercase (required, second argument)
   - For subtasks: title (required, third argument)
   - Optional flags: description, priority

3. **Validate inputs**:
   - Convert project names to lowercase, hyphenated format
   - Ensure names contain only alphanumeric characters and hyphens
   - For subtasks, ensure parent project exists

4. **Create the structure** based on type:

   **For Projects**:
   ```bash
   # Create project directory
   mkdir -p /tasks/{project-name}
   ```

   Create `/tasks/{project-name}/README.md`:
   ```markdown
   # Project: {Human Readable Title}

   **Status**: planning
   **Created**: {ISO date}
   **Updated**: {ISO date}

   ## Overview

   {description or placeholder}

   ## Tasks

   - [ ] 001-{first-subtask}.md - Description pending

   ## Progress

   - Total subtasks: 0
   - Completed: 0
   - Progress: 0%
   ```

   **For Subtasks**:
   - Find the next available index number (001, 002, etc.)
   - Create `/tasks/{project-name}/{index}-{hyphenated-title}.md`:

   ```markdown
   # {index}: {Human Readable Title}

   **Status**: pending
   **Created**: {ISO date}
   **Priority**: {priority}

   ## Description

   {Auto-generated or provided description}

   ## Action Items

   - [ ] Define specific implementation steps
   - [ ] Add acceptance criteria

   ## Notes

   {Empty section for implementation notes}
   ```

5. **Update the project README.md**:
   - Add the new subtask to the Tasks list
   - Update the progress statistics
   - Sort tasks by index number

6. **Update global plan.md if needed**:
   - For new projects, add entry under "Active Projects"
   - Include brief description and status

7. **Git Status Check**:
   - Confirm we are not in main branch
   - Show current branch with `git branch --show-current`

8. **Provide confirmation**:

   **For Projects**:
   ```
   ✓ Created project: {project-name}
   ✓ Created and switched to branch: feature/{project-name}

   Location: /tasks/{project-name}/
   Branch: feature/{project-name}

   Next steps:
   - Edit /tasks/{project-name}/README.md to add details
   - Create subtasks with: /task-create subtask "{project-name}" "task title"
   - NEVER work in main branch!
   ```

   **For Subtasks**:
   ```
   ✓ Created subtask: {index}-{title}
   ✓ Created and switched to branch: task/{project-name}-{subtask-index}

   Location: /tasks/{project-name}/{index}-{title}.md
   Branch: task/{project-name}-{subtask-index}

   Next steps:
   - Edit the file to add specific action items
   - Update status with: /task-update
   - NEVER work in main branch!
   ```

## Examples

Create a new project:

```
/task-create project "authentication-system" --description="Implement OAuth2 authentication"
```

**Expected Git Flow:**
1. Check current branch (if main/master → create new branch)
2. Create `feature/authentication-system` branch
3. Switch to new branch
4. Create project structure
5. Confirm branch status

Add subtasks to the project:

```
/task-create subtask "authentication-system" "setup database schema"
/task-create subtask "authentication-system" "implement jwt tokens"
/task-create subtask "authentication-system" "create login endpoints"
```

**Expected Git Flow for Subtasks:**
1. Create `task/authentication-system-001` branch
2. Switch to new branch
3. Create subtask file
4. Confirm branch status

## Error Handling

- **In main/master branch**: IMMEDIATELY throw error and create branch
- If project already exists, show current tasks and suggest adding subtasks
- If subtask title is too long, suggest a shorter version
- Ensure consistent index numbering (pad with zeros: 001, 002, etc.)
- **Branch conflicts**: Warn if branch already exists
