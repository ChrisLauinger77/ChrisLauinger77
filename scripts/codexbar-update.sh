#!/usr/bin/env bash

set -euo pipefail

REPO="steipete/CodexBar"
BIN_NAME="codexbar"
INSTALL_DIR="/usr/local/bin"
STATE_DIR="/usr/local/share/codexbar"
VERSION_FILE="${STATE_DIR}/version"

usage() {
    cat << EOF
Usage:
  sudo $0           Install or update CodexBar
  $0 --check        Check for updates only
  $0 --help         Show this help
EOF
}

check_only=false

case "${1:-}" in
    --check)
        check_only=true
        ;;
    --help|-h)
        usage
        exit 0
        ;;
    "")
        ;;
    *)
        echo "Unknown option: $1"
        usage
        exit 1
        ;;
esac

get_latest_release() {
    curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest"
}

get_latest_tag() {
    python3 -c '
import json,sys
print(json.load(sys.stdin)["tag_name"])
'
}

get_asset_url() {
    local arch="$1"

    python3 -c '
import json,sys

arch=sys.argv[1]
data=json.load(sys.stdin)

for asset in data["assets"]:
    name=asset["name"]

    if name.endswith(f"linux-{arch}.tar.gz"):
        print(asset["browser_download_url"])
        sys.exit(0)

raise SystemExit(f"No matching asset found for {arch}")
' "$arch"
}

get_current_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        cat "$VERSION_FILE"
    elif command -v "$BIN_NAME" >/dev/null 2>&1; then
        "$BIN_NAME" --version 2>/dev/null \
            | grep -oE 'v?[0-9]+(\.[0-9]+)+' \
            | head -n1 || true
    fi
}

release_json="$(get_latest_release)"
latest_tag="$(get_latest_tag <<< "$release_json")"
current_tag="$(get_current_version || true)"

if [[ -n "$current_tag" && "$current_tag" != v* ]]; then
    current_tag="v${current_tag}"
fi

if $check_only; then
    echo "Installed: ${current_tag:-none}"
    echo "Latest:    $latest_tag"

    if [[ "$current_tag" == "$latest_tag" ]]; then
        echo "Status: Up to date"
        exit 0
    else
        echo "Status: Update available"
        exit 1
    fi
fi

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root:"
    echo "  sudo $0"
    exit 1
fi

if [[ "$current_tag" == "$latest_tag" ]]; then
    echo "CodexBar is already up to date ($latest_tag)"
    exit 0
fi

case "$(uname -m)" in
    x86_64|amd64)
        asset_arch="x86_64"
        ;;
    aarch64|arm64)
        asset_arch="aarch64"
        ;;
    *)
        echo "Unsupported architecture: $(uname -m)"
        exit 1
        ;;
esac

asset_url="$(get_asset_url "$asset_arch" <<< "$release_json")"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "Downloading $latest_tag ..."
curl -fL "$asset_url" -o "$tmpdir/codexbar.tar.gz"

echo "Extracting ..."
tar -xzf "$tmpdir/codexbar.tar.gz" -C "$tmpdir"

candidate="$(
find "$tmpdir" -type f \
    \( -name "codexbar" -o -name "CodexBarCLI" \) \
    | head -n1
)"

if [[ -z "$candidate" ]]; then
    echo "Could not find executable in archive"
    exit 1
fi

chmod +x "$candidate"

echo "Installing ..."
install -Dm755 "$candidate" "${INSTALL_DIR}/${BIN_NAME}"

install -d "$STATE_DIR"
echo "$latest_tag" > "$VERSION_FILE"

echo
echo "Successfully installed $latest_tag"

if command -v "$BIN_NAME" >/dev/null 2>&1; then
    echo
    "$BIN_NAME" --version || true
fi
