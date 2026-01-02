#!/usr/bin/env bash
# Claude Code with Anonymous Mode (email hidden)
# Usage: claudeanon [args...]

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_SCRIPT="${SCRIPT_DIR}/email-hiding-proxy.js"
PROXY_PORT=3738
PROXY_PID_FILE="${HOME}/.claude/.anon-proxy.pid"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔒 Starting Claude in Anonymous Mode${NC}"
echo -e "${BLUE}   (Email hidden from header)${NC}"
echo ""

# Get API key - check environment first, then keychain
API_KEY="${ANTHROPIC_API_KEY:-}"

if [[ -z "$API_KEY" ]]; then
  # Try keychain
  for account in "claude" "aicodetracker" "anthropic"; do
    KEY=$(security find-generic-password -a "$account" -s "ANTHROPIC_API_KEY" -w 2>/dev/null)
    if [[ -n "$KEY" ]]; then
      API_KEY="$KEY"
      break
    fi
  done
fi

if [[ -z "$API_KEY" ]]; then
  echo "❌ ANTHROPIC_API_KEY not found in environment or Keychain"
  echo "   Set it with: export ANTHROPIC_API_KEY=sk-ant-..."
  exit 1
fi

# Kill any existing proxy
if [[ -f "$PROXY_PID_FILE" ]]; then
  OLD_PID=$(cat "$PROXY_PID_FILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    kill "$OLD_PID" 2>/dev/null || true
  fi
  rm -f "$PROXY_PID_FILE"
fi

# Start proxy in background
PROXY_LOG=$(mktemp -t claude-anon.XXXXXXXX.log)

UPSTREAM_URL="https://api.anthropic.com" \
UPSTREAM_API_KEY="$API_KEY" \
PORT="$PROXY_PORT" \
node "$PROXY_SCRIPT" >"$PROXY_LOG" 2>&1 &

PROXY_PID=$!
echo "$PROXY_PID" > "$PROXY_PID_FILE"

# Wait for proxy to start
sleep 1

if ! kill -0 "$PROXY_PID" 2>/dev/null; then
  echo "❌ Proxy failed to start. Log:"
  cat "$PROXY_LOG"
  rm -f "$PROXY_LOG"
  exit 1
fi

echo -e "${GREEN}✓ Proxy active on port $PROXY_PORT${NC}"
echo ""

# Clean environment
unset OPENAI_BASE_URL OPENAI_MODEL OPENAI_API_KEY 2>/dev/null || true
unset ANTHROPIC_BASE_URL ANTHROPIC_MODEL ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY 2>/dev/null || true

# Set proxy as endpoint
export ANTHROPIC_BASE_URL="http://127.0.0.1:${PROXY_PORT}"
export ANTHROPIC_API_KEY="proxy-placeholder"
# Use default model - user can override with env var
export ANTHROPIC_MODEL="${ANTHROPIC_MODEL:-claude-sonnet-4-5-20250929}"

# Trap to cleanup proxy on exit
cleanup() {
  if [[ -f "$PROXY_PID_FILE" ]]; then
    PID=$(cat "$PROXY_PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
      kill "$PID" 2>/dev/null || true
    fi
    rm -f "$PROXY_PID_FILE"
  fi
  rm -f "$PROXY_LOG" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

# Launch Claude
claude "$@"
