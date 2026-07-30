#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <owner/repo> [asset-pattern]"
    echo
    echo "Downloads and installs a .flatpak asset from the latest GitHub release."
    echo "The optional asset-pattern is a jq/PCRE regular expression."
    echo
    echo "Examples:"
    echo "  $0 SoftARV/Slipmat"
    echo "  $0 nextcloud-releases/talk-desktop"
    echo "  $0 owner/repo 'x86_64.*\\.flatpak$'"
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage
    exit 1
fi

REPO="$1"
ASSET_PATTERN="${2:-\\.flatpak$}"

if [[ ! "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    echo "Error: repository must be in the form owner/repo" >&2
    exit 1
fi

for cmd in curl jq flatpak; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: required command not found: $cmd" >&2
        exit 1
    fi
done

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

API_URL="https://api.github.com/repos/${REPO}/releases/latest"

echo "Checking latest release for ${REPO}..."
RELEASE_JSON=$(curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "$API_URL")

TAG=$(jq -r '.tag_name // empty' <<<"$RELEASE_JSON")
mapfile -t MATCHING_ASSETS < <(
    jq -r --arg pattern "$ASSET_PATTERN" '
        .assets[]
        | select(.name | test($pattern; "i"))
        | [.name, .browser_download_url]
        | @tsv
    ' <<<"$RELEASE_JSON"
)

if [ -z "$TAG" ]; then
    echo "Error: could not determine the latest release." >&2
    exit 1
fi

if [ "${#MATCHING_ASSETS[@]}" -eq 0 ]; then
    echo "Error: no release asset matches: ${ASSET_PATTERN}" >&2
    echo "Latest release: ${TAG}" >&2
    echo "Available assets:" >&2
    jq -r '.assets[].name' <<<"$RELEASE_JSON" >&2
    exit 1
fi

if [ "${#MATCHING_ASSETS[@]}" -gt 1 ]; then
    echo "Error: more than one release asset matches: ${ASSET_PATTERN}" >&2
    echo "Use a more specific asset-pattern. Matching assets:" >&2
    printf '  %s\n' "${MATCHING_ASSETS[@]%%$'\t'*}" >&2
    exit 1
fi

IFS=$'\t' read -r FILENAME DOWNLOAD_URL <<<"${MATCHING_ASSETS[0]}"
FLATPAK_FILE="${TEMP_DIR}/${FILENAME}"

echo "Latest release: ${TAG}"
echo "Downloading: ${FILENAME}"
curl -fL --retry 3 --output "$FLATPAK_FILE" "$DOWNLOAD_URL"

echo "Installing: ${FILENAME}"
sudo /usr/bin/flatpak install --noninteractive -y "$FLATPAK_FILE"

echo "Installation completed successfully."
