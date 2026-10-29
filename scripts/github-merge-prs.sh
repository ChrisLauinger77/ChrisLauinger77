#!/usr/bin/env bash
set -euo pipefail

# Print directly so a pager cannot pause the script.
export GH_PAGER=cat

# Merge GitHub pull requests sequentially using squash.
# Usage: ./merge-prs.sh 101 102 103
#        ./merge-prs.sh --repo owner/repo 101 102 103

repo_args=()

if [[ "${1:-}" == "--repo" ]]; then
    if [[ -z "${2:-}" ]]; then
        echo "Error: Missing repository (owner/repo)." >&2
        exit 1
    fi
    repo_args=(--repo "$2")
    shift 2
fi

if ! command -v gh >/dev/null 2>&1; then
    echo "Error: GitHub CLI (gh) is not installed." >&2
    exit 1
fi

if [[ $# -eq 0 ]]; then
    read -r -p "Enter PR numbers (space-separated): " -a prs
else
    prs=("$@")
fi

if [[ ${#prs[@]} -eq 0 ]]; then
    echo "No PR numbers provided."
    exit 1
fi

for pr in "${prs[@]}"; do
    if [[ ! "$pr" =~ ^[0-9]+$ ]]; then
        echo "Invalid PR number: $pr" >&2
        exit 1
    fi
done

echo "Repository:"
gh repo view ${repo_args[@]+"${repo_args[@]}"} \
    --json nameWithOwner \
    --jq '.nameWithOwner'
echo
echo "PRs to squash-merge: ${prs[*]}"
read -r -p "Continue? [y/N] " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Cancelled."
    exit 0
fi

for pr in "${prs[@]}"; do
    echo
    echo "Merging PR #$pr ..."

    if ! gh pr merge "$pr" "${repo_args[@]}" --squash --delete-branch; then
        echo "Merge failed for PR #$pr. Stopping." >&2
        exit 1
    fi

    echo "PR #$pr merged successfully."
done

echo
echo "All requested PRs merged successfully."
