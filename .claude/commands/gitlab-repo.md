# /gitlab-repo - GitLab Repository erstellen: $ARG1 (repository-name) [$ARG2 (description)] [$ARG3 (visibility)]

Create a new GitLab repository with comprehensive setup and configuration options.

**Arguments:**
- `$ARG1` (required): Repository name (kebab-case empfohlen, z.B. "my-terraform-project")
- `$ARG2` (optional): Repository description (z.B. "Infrastructure as Code for MyApp")  
- `$ARG3` (optional): Visibility level - "private"|"internal"|"public" (default: private)

## Usage

```
/gitlab-repo [repository-name] [description] [visibility]
```

## Repository Creation Workflow

### 1. Repository Setup

**Basic Repository Creation:**
```bash
# Create public repository
/gitlab-repo "my-terraform-project" "Infrastructure as Code for MyApp" "public"

# Create private repository (default)
/gitlab-repo "internal-tools" "Internal development tools"

# Interactive creation (prompt for details)
/gitlab-repo
```

**Repository Configuration:**
- Initialize with README.md
- Set appropriate visibility (private, internal, public)
- Configure description and topics
- Set up default branch protection

### 2. Post-Creation Setup

**Clone and Initial Setup:**
```bash
# Clone the newly created repository
git clone <repository-url>
cd <repository-name>

# Set up initial project structure
mkdir -p {docs,src,tests,scripts}
touch README.md .gitignore

# Initial commit
git add .
git commit -m "feat: initial project setup"
git push origin main
```

**GitLab CI/CD Setup:**
```yaml
# .gitlab-ci.yml template
stages:
  - validate
  - test
  - deploy

variables:
  TF_ROOT: ${CI_PROJECT_DIR}
  TF_ADDRESS: ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/production

before_script:
  - terraform --version
  - terraform init

validate:
  stage: validate
  script:
    - terraform fmt -check
    - terraform validate
```

### 3. MCP Integration Commands

Use the GitLab MCP tools for repository operations:

```bash
# Create repository via MCP
mcp__gitlab__create_repository with parameters:
- name: Repository name (required)
- description: Repository description
- visibility: private|internal|public
- initialize_with_readme: true|false

# Example MCP call structure:
{
  "name": "$ARG1",
  "description": "$ARG2", 
  "visibility": "$ARG3",
  "initialize_with_readme": true
}
```

### 4. Template Integration

**Terraform Project Template:**
```bash
# Copy from template if this is a Terraform project
cp -r templates/terraform/* .
cp templates/terraform/.terraform-version .
cp templates/terraform/.pre-commit-config.yaml .

# Update template variables
sed -i "s/PROJECT_NAME/$ARG1/g" terraform.auto.tfvars
sed -i "s/PROJECT_DESCRIPTION/$ARG2/g" README.md
```

**DevOps Template:**
```bash
# Copy DevOps project structure
cp -r templates/devops/* .
cp templates/devops/.gitlab-ci.yml .

# Set up project-specific configuration
echo "PROJECT_NAME=$ARG1" > .env
echo "PROJECT_DESC=$ARG2" >> .env
```

### 5. Repository Security Configuration

**Branch Protection:**
- Require merge requests for main branch
- Require approval from code owners
- Dismiss stale reviews when new commits are pushed
- Require status checks to pass

**Access Control:**
- Set up project access levels
- Configure deploy keys if needed
- Set up project tokens for CI/CD

### 6. Documentation Setup

**README.md Template:**
```markdown
# $ARG1

$ARG2

## Quick Start

## Architecture

## Development

### Prerequisites
### Setup
### Testing
### Deployment

## Contributing

## License
```

**Project Documentation:**
```bash
# Create documentation structure
mkdir -p docs/{architecture,deployment,api}
touch docs/CHANGELOG.md
touch docs/CONTRIBUTING.md
touch docs/DEPLOYMENT.md
```

## Success Indicators

- Repository created successfully in GitLab
- Initial project structure established
- CI/CD pipeline configured and functional
- Documentation framework in place
- Team access and permissions configured
- First successful commit and push completed

## Common Parameters

- `$ARG1`: Repository name (kebab-case recommended)
- `$ARG2`: Repository description (1-2 sentences)
- `$ARG3`: Visibility level (private, internal, public)

## Integration Points

- Works with `/tf-validate` for Terraform projects
- Integrates with `/deploy` for infrastructure deployment
- Connects to `/task-create` for project planning
- Compatible with `/validate` for code quality checks