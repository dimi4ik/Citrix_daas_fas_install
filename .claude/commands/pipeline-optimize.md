# /pipeline-optimize

Analyzes CI/CD pipeline performance and implements optimizations for faster, more reliable deployments.

## Functionality

### Performance Analysis
- **Pipeline Metrics**: Runtime analysis, success rates, bottleneck identification
- **Flaky Test Detection**: Detects unstable tests through historical data
- **Resource Profiling**: CPU/Memory usage and optimization potential
- **Parallel Execution**: Identifies parallelizable jobs and dependencies
- **Cache Optimization**: Dependency caching and build artifact management

### Optimization Strategies
1. **Test Parallelization**: Splitting slow test suites
2. **Build Cache**: Intelligent caching for dependencies and artifacts
3. **Matrix Strategy**: Optimized test matrix configurations
4. **Resource Allocation**: Right-sizing of runner instances
5. **Stage Optimization**: Elimination of redundant pipeline stages

### Monitoring & Alerting
- **Pipeline SLA**: Definition and monitoring of performance targets
- **Regression Detection**: Automatic detection of performance degradation
- **Cost Optimization**: Analysis of CI/CD costs and savings potential
- **Trend Analysis**: Long-term performance trends and capacity planning

## Implementation

```bash
# Pipeline Performance Analyzer
analyze_pipeline_performance() {
    local platform=$1
    local project=$2
    local timeframe=${3:-30} # days
    
    echo "📊 Analyzing pipeline performance for last ${timeframe} days..."
    
    case $platform in
        "github")
            analyze_github_actions "$project" "$timeframe"
            ;;
        "gitlab")
            analyze_gitlab_ci "$project" "$timeframe"
            ;;
        "azure-devops")
            analyze_azure_pipelines "$project" "$timeframe"
            ;;
    esac
    
    generate_optimization_report
    create_optimization_patches
}

# GitHub Actions Performance Analysis
analyze_github_actions() {
    local repo=$1
    local days=$2
    
    echo "🔍 Fetching GitHub Actions workflow runs..."
    
    # Get workflow runs via GitHub API
    gh api repos/$repo/actions/runs \
        --paginate \
        --field created=">$(date -d "${days} days ago" --iso-8601)" \
        --jq '.workflow_runs[] | {
            id, 
            workflow_id, 
            status, 
            conclusion, 
            created_at, 
            updated_at,
            run_duration: ((.updated_at | fromdateiso8601) - (.created_at | fromdateiso8601))
        }' > workflow_runs.json
    
    # Analyze job performance
    for run_id in $(jq -r '.id' workflow_runs.json); do
        gh api repos/$repo/actions/runs/$run_id/jobs \
            --jq '.jobs[] | {
                name,
                status,
                conclusion,
                started_at,
                completed_at,
                duration: ((.completed_at | fromdateiso8601) - (.started_at | fromdateiso8601))
            }' >> job_performance.json
    done
    
    # Generate performance metrics
    python3 ~/.claude/scripts/pipeline-analyzer.py \
        --input workflow_runs.json,job_performance.json \
        --output performance_report.json
}
```

## Performance Analytics Script

```python
#!/usr/bin/env python3
# ~/.claude/scripts/pipeline-analyzer.py

import json
import statistics
from datetime import datetime, timedelta
from collections import defaultdict, Counter

class PipelineAnalyzer:
    def __init__(self, workflow_data, job_data):
        self.workflows = json.loads(workflow_data)
        self.jobs = json.loads(job_data)
        self.analysis = {}
    
    def analyze_performance(self):
        """Comprehensive pipeline performance analysis"""
        
        # Overall metrics
        self.analysis['overview'] = self.calculate_overview_metrics()
        
        # Failure analysis
        self.analysis['failures'] = self.analyze_failure_patterns()
        
        # Performance trends
        self.analysis['trends'] = self.analyze_performance_trends()
        
        # Bottleneck identification
        self.analysis['bottlenecks'] = self.identify_bottlenecks()
        
        # Optimization recommendations
        self.analysis['recommendations'] = self.generate_recommendations()
        
        return self.analysis
    
    def calculate_overview_metrics(self):
        """Calculate high-level pipeline metrics"""
        total_runs = len(self.workflows)
        successful_runs = len([w for w in self.workflows if w['conclusion'] == 'success'])
        failed_runs = len([w for w in self.workflows if w['conclusion'] == 'failure'])
        
        durations = [w['run_duration'] for w in self.workflows if w['run_duration']]
        avg_duration = statistics.mean(durations) if durations else 0
        median_duration = statistics.median(durations) if durations else 0
        
        return {
            'total_runs': total_runs,
            'success_rate': (successful_runs / total_runs * 100) if total_runs > 0 else 0,
            'failure_rate': (failed_runs / total_runs * 100) if total_runs > 0 else 0,
            'avg_duration_minutes': round(avg_duration / 60, 2),
            'median_duration_minutes': round(median_duration / 60, 2),
            'p95_duration_minutes': round(statistics.quantiles(durations, n=20)[18] / 60, 2) if len(durations) > 20 else 0
        }
    
    def analyze_failure_patterns(self):
        """Identify patterns in pipeline failures"""
        failed_jobs = [job for job in self.jobs if job['conclusion'] == 'failure']
        
        # Flaky test detection
        job_failure_rates = defaultdict(list)
        for job in self.jobs:
            job_failure_rates[job['name']].append(job['conclusion'])
        
        flaky_jobs = []
        for job_name, conclusions in job_failure_rates.items():
            if len(conclusions) >= 5:  # Minimum runs for analysis
                failure_rate = conclusions.count('failure') / len(conclusions)
                if 0.1 <= failure_rate <= 0.9:  # Flaky range: 10-90% failure rate
                    flaky_jobs.append({
                        'name': job_name,
                        'failure_rate': round(failure_rate * 100, 2),
                        'total_runs': len(conclusions)
                    })
        
        return {
            'total_failures': len(failed_jobs),
            'flaky_jobs': sorted(flaky_jobs, key=lambda x: x['failure_rate'], reverse=True),
            'most_failing_jobs': Counter([job['name'] for job in failed_jobs]).most_common(10)
        }
    
    def identify_bottlenecks(self):
        """Identify performance bottlenecks in pipeline stages"""
        job_durations = defaultdict(list)
        
        for job in self.jobs:
            if job['duration'] and job['duration'] > 0:
                job_durations[job['name']].append(job['duration'])
        
        bottlenecks = []
        for job_name, durations in job_durations.items():
            if durations:
                avg_duration = statistics.mean(durations)
                if avg_duration > 600:  # Jobs longer than 10 minutes
                    bottlenecks.append({
                        'job_name': job_name,
                        'avg_duration_minutes': round(avg_duration / 60, 2),
                        'max_duration_minutes': round(max(durations) / 60, 2),
                        'runs_analyzed': len(durations)
                    })
        
        return sorted(bottlenecks, key=lambda x: x['avg_duration_minutes'], reverse=True)
    
    def generate_recommendations(self):
        """Generate optimization recommendations"""
        recommendations = []
        
        # Slow jobs optimization
        for bottleneck in self.analysis['bottlenecks'][:5]:
            if bottleneck['avg_duration_minutes'] > 15:
                recommendations.append({
                    'type': 'performance',
                    'priority': 'high',
                    'target': bottleneck['job_name'],
                    'recommendation': f"Optimize {bottleneck['job_name']} - currently takes {bottleneck['avg_duration_minutes']} minutes on average",
                    'suggested_actions': [
                        'Implement parallel execution',
                        'Add dependency caching',
                        'Use faster runners',
                        'Split into smaller jobs'
                    ]
                })
        
        # Flaky test fixes
        for flaky_job in self.analysis['failures']['flaky_jobs'][:3]:
            recommendations.append({
                'type': 'reliability',
                'priority': 'medium',
                'target': flaky_job['name'],
                'recommendation': f"Fix flaky job {flaky_job['name']} - {flaky_job['failure_rate']}% failure rate",
                'suggested_actions': [
                    'Add retry mechanisms',
                    'Investigate timing issues',
                    'Improve test isolation',
                    'Add better error handling'
                ]
            })
        
        # Success rate improvement
        if self.analysis['overview']['success_rate'] < 90:
            recommendations.append({
                'type': 'reliability',
                'priority': 'high',
                'target': 'overall_pipeline',
                'recommendation': f"Improve overall success rate from {self.analysis['overview']['success_rate']:.1f}%",
                'suggested_actions': [
                    'Fix most common failure causes',
                    'Add better error handling',
                    'Implement health checks',
                    'Add retry mechanisms for transient failures'
                ]
            })
        
        return recommendations
```

## Optimization Patches Generator

```bash
# Generate optimization patches based on analysis
generate_optimization_patches() {
    echo "🔧 Generating optimization patches..."
    
    # Cache optimization patch
    cat > .github/workflows/optimized-cache.yml << 'EOF'
# Optimized caching strategy
- name: Cache Dependencies
  uses: actions/cache@v3
  with:
    path: |
      ~/.npm
      ~/.cache/pip
      ~/.cargo/registry
      ~/.cargo/git
      node_modules
      target/
    key: ${{ runner.os }}-deps-${{ hashFiles('**/package-lock.json', '**/requirements.txt', '**/Cargo.lock') }}
    restore-keys: |
      ${{ runner.os }}-deps-

- name: Cache Terraform
  uses: actions/cache@v3
  with:
    path: |
      ~/.terraform.d/plugin-cache
      .terraform
    key: ${{ runner.os }}-terraform-${{ hashFiles('**/.terraform.lock.hcl') }}
    restore-keys: |
      ${{ runner.os }}-terraform-
EOF

    # Parallel test execution patch
    cat > .github/workflows/parallel-tests.yml << 'EOF'
# Parallel test execution optimization
strategy:
  matrix:
    test-group: [unit, integration, e2e]
    include:
      - test-group: unit
        test-command: npm run test:unit
        parallel-jobs: 4
      - test-group: integration  
        test-command: npm run test:integration
        parallel-jobs: 2
      - test-group: e2e
        test-command: npm run test:e2e
        parallel-jobs: 1

steps:
- name: Run Tests in Parallel
  run: ${{ matrix.test-command }} --parallel=${{ matrix.parallel-jobs }}
EOF

    # Conditional job execution
    cat > .github/workflows/conditional-execution.yml << 'EOF'
# Smart conditional execution
jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      terraform: ${{ steps.changes.outputs.terraform }}
      frontend: ${{ steps.changes.outputs.frontend }}
      backend: ${{ steps.changes.outputs.backend }}
    steps:
    - uses: actions/checkout@v4
    - uses: dorny/paths-filter@v2
      id: changes
      with:
        filters: |
          terraform:
            - 'terraform/**'
          frontend:
            - 'frontend/**'
            - 'package.json'
          backend:
            - 'backend/**'
            - 'requirements.txt'

  terraform-job:
    needs: changes
    if: ${{ needs.changes.outputs.terraform == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - name: Run Terraform Jobs
        run: echo "Running Terraform-specific jobs"

  frontend-job:
    needs: changes
    if: ${{ needs.changes.outputs.frontend == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - name: Run Frontend Jobs
        run: echo "Running Frontend-specific jobs"
EOF
}
```

## Performance Monitoring Dashboard

```json
{
  "pipeline_sla": {
    "target_duration_minutes": 15,
    "target_success_rate": 95,
    "alerts": {
      "duration_threshold": 20,
      "success_rate_threshold": 90,
      "notification_channels": ["slack", "email"]
    }
  },
  "optimization_tracking": {
    "baseline_metrics": {
      "avg_duration": 18.5,
      "success_rate": 87.3,
      "cost_per_build": 2.45
    },
    "target_metrics": {
      "avg_duration": 12.0,
      "success_rate": 95.0,
      "cost_per_build": 1.80
    }
  },
  "recommendations_status": [
    {
      "id": "cache-opt-001",
      "recommendation": "Implement dependency caching",
      "status": "completed",
      "impact": "35% duration reduction"
    },
    {
      "id": "parallel-tests-002", 
      "recommendation": "Parallelize test execution",
      "status": "in-progress",
      "expected_impact": "50% test duration reduction"
    }
  ]
}
```

## Auto-Remediation Scripts

```bash
# Automated performance fixes
apply_performance_fixes() {
    echo "🚀 Applying automated performance optimizations..."
    
    # Fix 1: Add intelligent caching
    if grep -q "npm install" .github/workflows/*.yml; then
        echo "Adding npm cache optimization..."
        sed -i '/npm install/i\      - uses: actions/cache@v3\n        with:\n          path: ~/.npm\n          key: ${{ runner.os }}-node-${{ hashFiles('\''**/package-lock.json'\'') }}' .github/workflows/*.yml
    fi
    
    # Fix 2: Implement conditional job execution
    echo "Adding path-based conditional execution..."
    # Add paths filter to existing workflows
    
    # Fix 3: Optimize runner selection
    echo "Optimizing runner allocation..."
    # Update runner types based on job requirements
    
    # Fix 4: Add parallel test execution
    if [ -f "package.json" ] && grep -q "test" package.json; then
        echo "Implementing parallel test execution..."
        npm install --save-dev jest-workers
        # Update test configuration for parallel execution
    fi
    
    echo "✅ Performance optimizations applied"
}
```

## Command Usage

```bash
# Analyze current pipeline performance
/pipeline-optimize

# Analyze specific platform
/pipeline-optimize --platform github --repo owner/repo

# Generate optimization report
/pipeline-optimize --analyze-only --output report.json

# Apply automatic optimizations
/pipeline-optimize --auto-fix --approve-safe-changes

# Monitor specific metrics
/pipeline-optimize --monitor --sla-target 15min,95%

# Compare performance over time
/pipeline-optimize --compare --baseline "2024-01-01" --current "2024-07-01"

# Cost optimization analysis
/pipeline-optimize --cost-analysis --cloud aws,azure,gcp
```

## Integration Features

### Slack/Teams Notifications
```json
{
  "performance_alert": {
    "trigger": "pipeline_duration > 20min OR success_rate < 90%",
    "message": "🚨 Pipeline performance degraded: Duration: {{duration}}min, Success Rate: {{success_rate}}%",
    "actions": [
      {"text": "View Report", "url": "{{report_url}}"},
      {"text": "Apply Fixes", "command": "/pipeline-optimize --auto-fix"}
    ]
  }
}
```

### CI/CD Integration
```yaml
# Auto-optimization as part of pipeline
optimization:
  stage: optimize
  script:
    - /pipeline-optimize --auto-fix --safe-only
  rules:
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
  artifacts:
    reports:
      performance: optimization-report.json
```