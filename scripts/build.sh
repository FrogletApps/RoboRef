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
SERVER_DIR="$SCRIPT_DIR/../server"
APP_DIR="$SCRIPT_DIR/../app"

build_server() {
  echo -e "\n>>> Building & Typechecking Server..."
  cd "$SERVER_DIR"
  if [ ! -d "node_modules" ]; then
    echo "Installing server dependencies (npm install)..."
    npm install
  fi
  echo "Running server typecheck..."
  npm run typecheck
  echo "Compiling server (tsc)..."
  npm run build:node
  echo ">>> Server build completed successfully."
}

build_flutter() {
  local flutter_target="$1"
  shift || true
  echo -e "\n>>> Building Flutter Client ($flutter_target)..."
  cd "$APP_DIR"
  flutter build "$flutter_target" --build-name="$VERSION_NAME" --build-number="$BUILD_NUMBER" "$@"
  echo ">>> Flutter client ($flutter_target) build completed successfully."
}

case "$TARGET" in
  server)
    build_server
    ;;
  all)
    build_server
    build_flutter apk "$@"
    ;;
  *)
    build_flutter "$TARGET" "$@"
    ;;
esac
