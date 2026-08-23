#!/usr/bin/env bash
set -e

TARGET="${1:-apk}"
shift || true

# Get current date formatted as YYYY.M.D (e.g., 2026.8.23)
VERSION_NAME="$(date +'%Y.%-m.%-d')"

# Get commit count from git
BUILD_NUMBER="$(git rev-list --count HEAD 2>/dev/null || echo "1")"

echo "========================================"
echo " Building RoboRef ($TARGET)"
echo " Version Name: $VERSION_NAME"
echo " Build Number: $BUILD_NUMBER"
echo " Full Version: $VERSION_NAME+$BUILD_NUMBER"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../app"

flutter build "$TARGET" --build-name="$VERSION_NAME" --build-number="$BUILD_NUMBER" "$@"
