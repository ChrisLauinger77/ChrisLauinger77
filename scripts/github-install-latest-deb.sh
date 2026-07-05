#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <owner/repo> [asset-pattern]"
    echo
    echo "Examples:"
    echo "  $0 totoshko88/RustConn"
    echo "  $0 totoshko88/RustConn 'rustconn_.*_amd64\\.deb$'"
}

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    usage
    exit 1
fi

REPO="$1"
ASSET_PATTERN="${2:-.*_amd64\\.deb$}"

if [[ ! "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    echo "Error: repository must be in the form owner/repo"
    echo "Example: totoshko88/RustConn"
    exit 1
fi

for cmd in curl jq apt; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: required command not found: $cmd"
        exit 1
    fi
done

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

API_URL="https://api.github.com/repos/${REPO}/releases/latest"

echo "Checking latest release for ${REPO}..."

RELEASE_JSON=$(curl -fsSL "$API_URL")

TAG=$(echo "$RELEASE_JSON" | jq -r '.tag_name // empty')

if [ -z "$TAG" ]; then
    echo "Error: could not determine latest release."
    exit 1
fi

URL=$(
    echo "$RELEASE_JSON" | jq -r \
        --arg pattern "$ASSET_PATTERN" '
            .assets[]
            | select(.name | test($pattern))
            | .browser_download_url
        ' | head -n1
)

if [ -z "$URL" ]; then
    echo "Error: no matching asset found."
    echo
    echo "Release: $TAG"
    echo "Pattern: $ASSET_PATTERN"
    echo
    echo "Available assets:"
    echo "$RELEASE_JSON" | jq -r '.assets[].name'
    exit 1
fi

FILENAME=$(basename "$URL")
FILE="${TMPDIR}/${FILENAME}"

echo "Latest release: $TAG"
echo "Downloading: $FILENAME"

curl -fL "$URL" -o "$FILE"

echo "Installing: $FILENAME"
sudo apt install -y "$FILE"

echo
echo "Installation completed successfully."