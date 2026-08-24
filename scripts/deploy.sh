#!/usr/bin/env bash
set -e

ENV="${1:-test}"
SKIP_BUILD=false

if [ "$2" == "--skip-build" ] || [ "$1" == "--skip-build" ]; then
  SKIP_BUILD=true
  if [ "$1" == "--skip-build" ]; then
    ENV="test"
  fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."

if [ "$SKIP_BUILD" = false ]; then
  echo ">>> Step 1/2: Building Flutter Web PWA..."
  "$SCRIPT_DIR/build.sh" web
fi

echo ">>> Step 2/2: Deploying to Cloudflare ($ENV environment)..."
cd "$ROOT_DIR"
npx wrangler deploy --env "$ENV"
