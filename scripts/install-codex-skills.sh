#!/bin/sh

set -eu

usage() {
    cat <<'EOF'
Usage: install-codex-skills.sh [--dry-run]

Create or update symlinks for all skills in this repository under
$HOME/.agents/skills.

Options:
  --dry-run  Show the changes without modifying the filesystem.
  -h, --help Show this help message.

For tests or custom setups, set CODEX_USER_SKILLS_DIR to use a different
destination directory.
EOF
}

dry_run=false

case "${1:-}" in
    "")
        ;;
    --dry-run)
        dry_run=true
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    *)
        printf 'Unknown option: %s\n\n' "$1" >&2
        usage >&2
        exit 2
        ;;
esac

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
repository_root=$(dirname "$script_dir")
source_dir="$repository_root/skills"
target_dir=${CODEX_USER_SKILLS_DIR:-"$HOME/.agents/skills"}

if [ ! -d "$source_dir" ]; then
    printf 'Skill source directory not found: %s\n' "$source_dir" >&2
    exit 1
fi

if [ "$dry_run" = true ]; then
    printf 'Would ensure target directory exists: %s\n' "$target_dir"
else
    mkdir -p "$target_dir"
fi

found=0
created=0
updated=0
unchanged=0
conflicts=0

for skill_dir in "$source_dir"/*; do
    if [ ! -d "$skill_dir" ] || [ ! -f "$skill_dir/SKILL.md" ]; then
        continue
    fi

    found=$((found + 1))
    skill_name=${skill_dir##*/}
    link_path="$target_dir/$skill_name"

    if [ -L "$link_path" ]; then
        current_target=$(readlink "$link_path")

        if [ "$current_target" = "$skill_dir" ]; then
            printf 'Unchanged: %s\n' "$skill_name"
            unchanged=$((unchanged + 1))
        elif [ "$dry_run" = true ]; then
            printf 'Would update: %s -> %s\n' "$link_path" "$skill_dir"
            updated=$((updated + 1))
        else
            ln -sfn "$skill_dir" "$link_path"
            printf 'Updated: %s -> %s\n' "$link_path" "$skill_dir"
            updated=$((updated + 1))
        fi
    elif [ -e "$link_path" ]; then
        printf 'Conflict: %s already exists and is not a symlink; skipped.\n' "$link_path" >&2
        conflicts=$((conflicts + 1))
    elif [ "$dry_run" = true ]; then
        printf 'Would create: %s -> %s\n' "$link_path" "$skill_dir"
        created=$((created + 1))
    else
        ln -s "$skill_dir" "$link_path"
        printf 'Created: %s -> %s\n' "$link_path" "$skill_dir"
        created=$((created + 1))
    fi
done

if [ "$found" -eq 0 ]; then
    printf 'No valid skills containing SKILL.md found in %s\n' "$source_dir" >&2
    exit 1
fi

printf '\nSummary: %s found, %s created, %s updated, %s unchanged, %s conflicts.\n' \
    "$found" "$created" "$updated" "$unchanged" "$conflicts"

if [ "$conflicts" -gt 0 ]; then
    exit 1
fi
