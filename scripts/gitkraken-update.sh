#!/usr/bin/env bash
set -euo pipefail

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

usage() {
  cat <<'USAGE'
Usage: gitkraken-update.sh [all|gitkraken|kepler|gk-cli]...

With no parameters, or with "all", installs all GitKraken tools.
Multiple individual targets can be passed together.
USAGE
}

install_gitkraken() {
  wget https://release.gitkraken.com/linux/gitkraken-amd64.deb
  sudo apt install ./gitkraken-amd64.deb
}

install_kepler() {
  wget https://kepler.gitkraken.com/kepler-x64.deb
  sudo apt install ./kepler-x64.deb
}

install_gk_cli() {
  /usr/scripts/github-install-latest-deb.sh gitkraken/gk-cli
}

cd "${TMPDIR}"

if [[ $# -eq 0 ]]; then
  set -- all
fi

for target in "$@"; do
  case "$target" in
    all)
      install_gitkraken
      install_kepler
      install_gk_cli
      ;;
    gitkraken)
      install_gitkraken
      ;;
    kepler)
      install_kepler
      ;;
    gk-cli|gkcli|cli)
      install_gk_cli
      ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown target: $target" >&2
      usage >&2
      exit 1
      ;;
  esac
done
