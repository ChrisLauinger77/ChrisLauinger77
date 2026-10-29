#!/usr/bin/env bash
set -euo pipefail

# Print directly so a pager cannot pause the script.
export GH_PAGER=cat

# List open GitHub pull requests.
# Usage: ./list-prs.sh
#        ./list-prs.sh --repo owner/repo

repo_args=()

if [[ "${1:-}" == "--repo" ]]; then
    if [[ -z "${2:-}" ]]; then
        echo "Error: Missing repository (owner/repo)." >&2
        exit 1
    fi
    repo_args=(--repo "$2")
    shift 2
fi

if [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--repo owner/repo]" >&2
    exit 1
fi

echo "Repository:"
gh repo view ${repo_args[@]+"${repo_args[@]}"} \
    --json nameWithOwner \
    --jq '.nameWithOwner'

echo
echo "Open pull requests:"
echo

gh pr list "${repo_args[@]}" \
    --state open \
    --limit 100 \
    --json number,title,author,headRefName,isDraft,mergeable \
    --template '{{tablerow "PR" "TITLE" "AUTHOR" "BRANCH" "STATUS"}}{{range .}}{{$status := .mergeable}}{{if .isDraft}}{{$status = "DRAFT"}}{{else if eq .mergeable "MERGEABLE"}}{{$status = "READY"}}{{end}}{{tablerow (printf "#%v" .number) .title .author.login .headRefName $status}}{{end}}'
