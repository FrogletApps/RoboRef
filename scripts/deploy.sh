#!/usr/bin/env bash
set -e

ENV="test"
SKIP_BUILD=false
SKIP_WEB=false
SKIP_SERVER=false

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
    --skip-server)
      SKIP_SERVER=true
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

# Step 1: Server / Cloudflare Worker build
if [ "$SKIP_BUILD" = false ] && [ "$SKIP_SERVER" = false ]; then
  echo ">>> Step 1/3: Building & Typechecking Server (Cloudflare Worker)..."
  "$SCRIPT_DIR/build.sh" server
else
  echo ">>> Step 1/3: Skipping server build..."
fi

# Step 2: Flutter Web PWA build
if [ "$SKIP_BUILD" = false ] && [ "$SKIP_WEB" = false ]; then
  echo -e "\n>>> Step 2/3: Building Flutter Web PWA for $ENV..."
  "$SCRIPT_DIR/build.sh" web --dart-define=APP_ENV="$ENV"
else
  echo -e "\n>>> Step 2/3: Skipping web build..."
fi

# Step 3: Cloudflare deploy
echo -e "\n>>> Step 3/3: Deploying to Cloudflare ($ENV environment)..."
cd "$ROOT_DIR"
npx wrangler deploy --env "$ENV"
