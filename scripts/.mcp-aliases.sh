#!/bin/bash
# MCP Tool Shell Aliases
# Source this file in your ~/.bashrc or ~/.zshrc:
# source /path/to/devops_tf_templates/.mcp-aliases.sh

# Universal MCP function
mcp() {
    ./bin/mcp-wrapper.sh "$@"
}

# === GitLab Quick Aliases ===
alias gl-search='claude --tool "mcp__gitlab__search_repositories"'
alias gl-fork='claude --tool "mcp__gitlab__fork_repository"'
alias gl-file='claude --tool "mcp__gitlab__get_file_contents"'
alias gl-branch='claude --tool "mcp__gitlab__create_branch"'

# === Terraform Quick Aliases ===
alias tf-search='claude --tool "mcp__hashicorp_terraform-mcp-server__searchModules"'
alias tf-docs='claude --tool "mcp__hashicorp_terraform-mcp-server__getProviderDocs"'
alias tf-resolve='claude --tool "mcp__hashicorp_terraform-mcp-server__resolveProviderDocID"'

# === Perplexity Quick Aliases ===
alias pp-ask='claude --tool "mcp__perplexity-ask__perplexity_ask"'
alias pp-research='claude --tool "mcp__perplexity-ask__perplexity_research"'
alias pp-reason='claude --tool "mcp__perplexity-ask__perplexity_reason"'

# === Usage Info ===
mcp-help() {
    echo "MCP Tool Aliases and Wrapper"
    echo ""
    echo "Universal wrapper:"
    echo "  mcp gitlab create_repository --name 'repo'"
    echo "  mcp terraform searchModules --query 'aws'"
    echo "  mcp perplexity perplexity_ask 'question'"
    echo ""
    echo "GitLab aliases:"
    echo "  gl-search, gl-fork, gl-file, gl-branch"
    echo ""
    echo "Terraform aliases:"
    echo "  tf-search, tf-docs, tf-resolve"
    echo ""
    echo "Perplexity aliases:"
    echo "  pp-ask, pp-research, pp-reason"
}

echo "MCP Tools loaded! Use 'mcp-help' for usage info."