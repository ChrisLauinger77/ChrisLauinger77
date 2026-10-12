#!/usr/bin/env bash
# link-skills.sh – eigene Skills für Claude Code verfügbar machen
set -eu

target="$HOME/.claude/skills"
mkdir -p "$target"

for src in "$HOME"/.agents/skills/*/ "$HOME"/.codex/skills/gh/; do
  [ -d "$src" ] || continue
  src="${src%/}"
  name="$(basename "$src")"
  dest="$target/$name"

  if [ -L "$dest" ]; then
    echo "ok      $name"
  elif [ -e "$dest" ]; then
    echo "SKIP    $name (existiert bereits als echter Ordner)"
  else
    ln -s "$src" "$dest"
    echo "linked  $name"
  fi
done