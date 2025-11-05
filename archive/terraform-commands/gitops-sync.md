# /gitops-sync

Implements GitOps workflow with automatic drift detection, configuration synchronization, and four-eyes principle for infrastructure changes.

## Functionality

### GitOps Synchronization
- **Drift Detection**: Automatic detection of configuration deviations between Git and live environment
- **Auto-Sync**: Secure synchronization of Git repository changes to target environments
- **Approval Workflows**: Four-eyes principle for critical infrastructure changes
- **Rollback Mechanism**: Quick rollback for failed deployments
- **Audit Trail**: Complete tracking of all configuration changes

### Multi-Platform Support
1. **Kubernetes**: ArgoCD, Flux, Custom Controllers
2. **Terraform**: Terraform Cloud, Atlantis, Custom Automation
3. **Ansible**: AWX, Ansible Tower, Custom Playbooks
4. **Cloud-Provider**: AWS Config, Azure Policy, GCP Config Connector
5. **Configuration Management**: Helm, Kustomize, Jsonnet

### Security & Compliance
- **RBAC Integration**: Role-Based Access Control for repository and environments
- **Encryption**: Git-Crypt, SOPS for secrets management
- **Signing**: GPG-Signing for all configuration changes
- **Compliance**: SOX, SOC2, PCI-DSS audit trails

## Implementation

```bash
# GitOps Synchronization Engine
gitops_sync() {
    local environment=$1
    local dry_run=${2:-false}
    local auto_approve=${3:-false}
    
    echo "🔄 Starting GitOps synchronization for ${environment}..."
    
    # Step 1: Fetch current state from Git
    fetch_git_state "$environment"
    
    # Step 2: Get live environment state
    fetch_live_state "$environment"
    
    # Step 3: Calculate drift
    calculate_drift "$environment"
    
    # Step 4: Generate reconciliation plan
    generate_reconciliation_plan "$environment"
    
    # Step 5: Apply changes (if approved)
    if [ "$dry_run" = "false" ]; then
        apply_changes "$environment" "$auto_approve"
    fi
    
    # Step 6: Update audit trail
    update_audit_trail "$environment"
}

# Drift Detection Engine
calculate_drift() {
    local environment=$1
    
    echo "🔍 Calculating configuration drift for ${environment}..."
    
    # Kubernetes Drift Detection
    if [ -d "k8s/${environment}" ]; then
        kubectl diff -R -f k8s/${environment}/ > drift-k8s-${environment}.log 2>&1 || true
        
        # Parse drift and categorize changes
        python3 ~/.claude/scripts/drift-analyzer.py \
            --input drift-k8s-${environment}.log \
            --type kubernetes \
            --output drift-report-k8s-${environment}.json
    fi
    
    # Terraform Drift Detection  
    if [ -d "terraform/${environment}" ]; then
        cd terraform/${environment}
        terraform init -backend=true
        terraform plan -detailed-exitcode -out=drift-plan-${environment} > drift-terraform-${environment}.log 2>&1
        drift_exit_code=$?
        
        if [ $drift_exit_code -eq 2 ]; then
            echo "⚠️  Terraform drift detected in ${environment}"
            terraform show -json drift-plan-${environment} > drift-terraform-${environment}.json
        fi
        cd - > /dev/null
    fi
    
    # Generate consolidated drift report
    python3 ~/.claude/scripts/consolidate-drift.py \
        --environment "$environment" \
        --output "drift-report-${environment}.json"
}
```

## Drift Analysis Script

```python
#!/usr/bin/env python3
# ~/.claude/scripts/drift-analyzer.py

import json
import re
import sys
from datetime import datetime
from typing import Dict, List, Any

class DriftAnalyzer:
    def __init__(self):
        self.drift_categories = {
            'critical': ['security', 'rbac', 'secrets', 'certificates'],
            'high': ['resources', 'networking', 'storage'],
            'medium': ['configurations', 'labels', 'annotations'],
            'low': ['metadata', 'descriptions']
        }
    
    def analyze_kubernetes_drift(self, diff_output: str) -> Dict[str, Any]:
        """Analyze Kubernetes kubectl diff output"""
        changes = []
        current_resource = None
        
        for line in diff_output.split('\n'):
            # Resource header detection
            if line.startswith('diff -u'):
                current_resource = self.extract_resource_info(line)
            
            # Change detection
            elif line.startswith('+') and not line.startswith('+++'):
                changes.append({
                    'type': 'addition',
                    'resource': current_resource,
                    'line': line[1:].strip(),
                    'severity': self.categorize_change(line)
                })
            elif line.startswith('-') and not line.startswith('---'):
                changes.append({
                    'type': 'deletion',
                    'resource': current_resource,
                    'line': line[1:].strip(),
                    'severity': self.categorize_change(line)
                })
        
        return {
            'drift_detected': len(changes) > 0,
            'total_changes': len(changes),
            'changes_by_severity': self.group_by_severity(changes),
            'affected_resources': list(set([c['resource']['name'] for c in changes if c['resource']])),
            'changes': changes
        }
    
    def analyze_terraform_drift(self, plan_json: str) -> Dict[str, Any]:
        """Analyze Terraform plan JSON output"""
        plan_data = json.loads(plan_json)
        
        changes = []
        for change in plan_data.get('resource_changes', []):
            if change['change']['actions'] != ['no-op']:
                changes.append({
                    'resource_type': change['type'],
                    'resource_name': change['name'],
                    'actions': change['change']['actions'],
                    'before': change['change'].get('before'),
                    'after': change['change'].get('after'),
                    'severity': self.categorize_terraform_change(change)
                })
        
        return {
            'drift_detected': len(changes) > 0,
            'total_changes': len(changes),
            'changes_by_action': self.group_by_action(changes),
            'changes_by_severity': self.group_by_severity(changes),
            'changes': changes
        }
    
    def categorize_change(self, line: str) -> str:
        """Categorize change severity based on content"""
        line_lower = line.lower()
        
        for severity, keywords in self.drift_categories.items():
            if any(keyword in line_lower for keyword in keywords):
                return severity
        
        return 'low'
    
    def generate_remediation_plan(self, drift_report: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Generate step-by-step remediation plan"""
        plan = []
        
        # Sort changes by severity
        critical_changes = [c for c in drift_report['changes'] if c.get('severity') == 'critical']
        high_changes = [c for c in drift_report['changes'] if c.get('severity') == 'high']
        
        # Critical changes require immediate attention
        if critical_changes:
            plan.append({
                'priority': 'immediate',
                'description': 'Address critical security and RBAC changes',
                'changes': critical_changes,
                'approval_required': True,
                'auto_rollback': True
            })
        
        # High priority changes
        if high_changes:
            plan.append({
                'priority': 'high',
                'description': 'Apply resource and networking changes',
                'changes': high_changes,
                'approval_required': True,
                'auto_rollback': False
            })
        
        return plan
```

## GitOps Automation Workflows

### ArgoCD Integration
```yaml
# .argocd/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: infrastructure-${ENVIRONMENT}
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "1"
spec:
  project: default
  source:
    repoURL: https://gitlab.com/company/infrastructure
    targetRevision: ${ENVIRONMENT}
    path: k8s/${ENVIRONMENT}
    helm:
      valueFiles:
        - values-${ENVIRONMENT}.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: ${ENVIRONMENT}
  syncPolicy:
    automated:
      prune: false  # Manual approval required for deletions
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
    retry:
      limit: 3
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  revisionHistoryLimit: 10
  ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/replicas  # Ignore HPA-managed replica counts
```

### Terraform Atlantis Integration
```yaml
# atlantis.yaml
version: 3
projects:
  - name: infrastructure-dev
    dir: terraform/environments/dev
    workspace: dev
    terraform_version: v1.5.0
    autoplan:
      when_modified: ["*.tf", "*.tfvars"]
      enabled: true
    apply_requirements: ["approved", "mergeable"]
    workflow: terraform-workflow

  - name: infrastructure-prod
    dir: terraform/environments/prod
    workspace: prod
    terraform_version: v1.5.0
    autoplan:
      when_modified: ["*.tf", "*.tfvars"]
      enabled: true
    apply_requirements: ["approved", "mergeable", "undiverged"]
    workflow: terraform-workflow-prod

workflows:
  terraform-workflow:
    plan:
      steps:
        - init
        - plan:
            extra_args: ["-lock-timeout=10m"]
        - run: |
            # Generate cost estimation
            infracost breakdown --path . --format json --out-file infracost.json
            infracost comment github --path infracost.json --repo $BASE_REPO_OWNER/$BASE_REPO_NAME --pull-request $PULL_NUM
    apply:
      steps:
        - apply

  terraform-workflow-prod:
    plan:
      steps:
        - init
        - plan:
            extra_args: ["-lock-timeout=10m"]
        - run: |
            # Security scan before production apply
            checkov -f $PLANFILE --framework terraform_plan
            tfsec . --force-all-dirs
    apply:
      steps:
        - run: |
            # Backup current state
            terraform state pull > backup-$(date +%Y%m%d-%H%M%S).tfstate
        - apply
        - run: |
            # Post-apply validation
            python3 scripts/validate-infrastructure.py
```

## Four-Eyes Principle Implementation

### GitHub Branch Protection
```json
{
  "branch_protection": {
    "main": {
      "required_status_checks": {
        "strict": true,
        "contexts": [
          "security/checkov",
          "terraform/plan",
          "infrastructure/validate"
        ]
      },
      "required_pull_request_reviews": {
        "required_approving_review_count": 2,
        "dismiss_stale_reviews": true,
        "require_code_owner_reviews": true,
        "require_last_push_approval": true
      },
      "restrictions": {
        "users": [],
        "teams": ["infrastructure-admins", "security-team"]
      },
      "enforce_admins": true,
      "allow_force_pushes": false,
      "allow_deletions": false
    }
  },
  "codeowners": {
    "terraform/": "@infrastructure-team @security-team",
    "k8s/production/": "@infrastructure-team @security-team @platform-team",
    "secrets/": "@security-team"
  }
}
```

### Approval Workflow Automation
```bash
# Auto-approval for low-risk changes
auto_approve_safe_changes() {
    local pr_number=$1
    
    # Get changed files
    changed_files=$(gh pr view $pr_number --json files --jq '.files[].path')
    
    # Define safe change patterns
    safe_patterns=(
        "^docs/"
        "^README"
        ".*\.md$"
        "^.*\/values-dev\.yaml$"  # Only dev environment values
    )
    
    # Check if all changes are safe
    all_safe=true
    for file in $changed_files; do
        is_safe=false
        for pattern in "${safe_patterns[@]}"; do
            if [[ $file =~ $pattern ]]; then
                is_safe=true
                break
            fi
        done
        
        if [ "$is_safe" = "false" ]; then
            all_safe=false
            break
        fi
    done
    
    # Auto-approve if all changes are safe
    if [ "$all_safe" = "true" ]; then
        gh pr review $pr_number --approve --body "Auto-approved: Only safe documentation/dev configuration changes detected"
        echo "✅ PR $pr_number auto-approved (safe changes only)"
    else
        echo "⏸️  PR $pr_number requires manual review (infrastructure changes detected)"
    fi
}
```

## Rollback Mechanisms

### Kubernetes Rollback
```bash
# Kubernetes application rollback
rollback_kubernetes_deployment() {
    local namespace=$1
    local deployment=$2
    local revision=${3:-previous}
    
    echo "🔄 Rolling back ${deployment} in ${namespace} to ${revision} revision..."
    
    # Get current deployment info
    kubectl get deployment $deployment -n $namespace -o yaml > backup-deployment-$(date +%Y%m%d-%H%M%S).yaml
    
    # Perform rollback
    kubectl rollout undo deployment/$deployment -n $namespace --to-revision=$revision
    
    # Wait for rollback completion
    kubectl rollout status deployment/$deployment -n $namespace --timeout=300s
    
    # Verify rollback success
    if kubectl get deployment $deployment -n $namespace | grep -q "Available"; then
        echo "✅ Rollback completed successfully"
        
        # Update GitOps repository
        git checkout HEAD~1 -- k8s/${namespace}/${deployment}.yaml
        git commit -m "Rollback ${deployment} in ${namespace} to working state"
        git push origin main
    else
        echo "❌ Rollback failed - manual intervention required"
        exit 1
    fi
}
```

### Terraform State Rollback
```bash
# Terraform state rollback with validation
rollback_terraform_state() {
    local environment=$1
    local backup_file=$2
    
    echo "🔄 Rolling back Terraform state for ${environment}..."
    
    cd terraform/environments/$environment
    
    # Validate backup file
    if [ ! -f "$backup_file" ]; then
        echo "❌ Backup file not found: $backup_file"
        exit 1
    fi
    
    # Create safety backup of current state
    terraform state pull > emergency-backup-$(date +%Y%m%d-%H%M%S).tfstate
    
    # Restore from backup
    terraform state push "$backup_file"
    
    # Validate restored state
    terraform plan -detailed-exitcode
    plan_exit_code=$?
    
    if [ $plan_exit_code -eq 0 ]; then
        echo "✅ State rollback completed - no drift detected"
    else
        echo "⚠️  State rollback completed but drift detected - review required"
        terraform plan > rollback-plan.txt
    fi
}
```

## Command Usage

```bash
# Full GitOps synchronization
/gitops-sync production

# Drift detection only
/gitops-sync staging --drift-check-only

# Dry run with detailed report
/gitops-sync development --dry-run --verbose

# Auto-sync for non-critical environments
/gitops-sync development --auto-approve-safe

# Emergency rollback
/gitops-sync production --rollback --to-commit abc123def

# Multi-environment sync
/gitops-sync --environments dev,staging,prod --parallel

# Compliance audit
/gitops-sync --audit-mode --compliance sox,pci --output audit-report.json
```

## Monitoring Integration

### Drift Detection Alerts
```json
{
  "drift_monitoring": {
    "schedule": "*/15 * * * *",
    "environments": ["production", "staging"],
    "alert_thresholds": {
      "critical_changes": 0,
      "high_priority_changes": 3,
      "drift_age_hours": 1
    },
    "notification_channels": {
      "slack": "#infrastructure-alerts",
      "email": ["infrastructure-team@company.com"],
      "pagerduty": "infrastructure-escalation"
    }
  }
}
```

### GitOps Metrics Dashboard
```yaml
# Prometheus metrics for GitOps
gitops_sync_duration_seconds:
  help: "Time taken to complete GitOps synchronization"
  type: histogram
  
gitops_drift_detected_total:
  help: "Total number of configuration drift instances detected"
  type: counter
  
gitops_sync_success_rate:
  help: "Success rate of GitOps synchronization operations"
  type: gauge
  
gitops_approval_time_seconds:
  help: "Time from change detection to approval"
  type: histogram
```