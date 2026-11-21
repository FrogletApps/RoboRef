#!/usr/bin/env bash
set -e

ENV="test"
SKIP_BUILD=false
SKIP_WEB=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    test|live)
      ENV="$1"
      shift
      ;;
    --skip-build)
      SKIP_BUILD=true
      shift
      ;;
    --skip-web)
      SKIP_WEB=true
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."

# Step 1: Flutter Web PWA build
if [ "$SKIP_BUILD" = false ] && [ "$SKIP_WEB" = false ]; then
  echo ">>> Step 1/2: Building Flutter Web PWA for $ENV..."
  "$SCRIPT_DIR/build.sh" web --dart-define=APP_ENV="$ENV"
else
  echo ">>> Step 1/2: Skipping web build (using existing app/build/web)..."
fi

# Step 2: Cloudflare deploy
echo -e "\n>>> Step 2/2: Deploying RoboRef Web to Cloudflare ($ENV environment)..."
cd "$ROOT_DIR"
npx wrangler deploy --env "$ENV"
