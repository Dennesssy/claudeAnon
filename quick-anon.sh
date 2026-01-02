#!/usr/bin/env bash
# Quick config edit - Hide email by editing ~/.claude.json directly
# Usage: ./quick-anon.sh [email]

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Default email if none provided
DEFAULT_EMAIL="anonymous@claude.local"
CUSTOM_EMAIL="${1:-$DEFAULT_EMAIL}"

echo -e "${BLUE}🔒 Hiding email via config edit${NC}"
echo ""

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
  echo -e "${YELLOW}⚠️  jq not found. Install with: brew install jq${NC}"
  exit 1
fi

# Check if ~/.claude.json exists
if [[ ! -f ~/.claude.json ]]; then
  echo "❌ ~/.claude.json not found"
  echo "   Have you run Claude Code at least once?"
  exit 1
fi

# Backup original config
cp ~/.claude.json ~/.claude.json.backup."$(date +%Y%m%d_%H%M%S)"

# Show current email
CURRENT_EMAIL=$(jq -r '.oauthAccount.emailAddress // "not found"' ~/.claude.json)
echo "Current email: $CURRENT_EMAIL"
echo "Changing to: $CUSTOM_EMAIL"
echo ""

# Update email
jq ".oauthAccount.emailAddress = \"$CUSTOM_EMAIL\"" ~/.claude.json > /tmp/claude.json.tmp
mv /tmp/claude.json.tmp ~/.claude.json

# Verify
NEW_EMAIL=$(jq -r '.oauthAccount.emailAddress' ~/.claude.json)

if [[ "$NEW_EMAIL" == "$CUSTOM_EMAIL" ]]; then
  echo -e "${GREEN}✓ Email changed successfully${NC}"
  echo ""
  echo "Your header will now show:"
  echo "  claude-sonnet-4-5 · $CUSTOM_EMAIL · API Usage Billing"
  echo ""
  echo "Backup saved to: ~/.claude.json.backup.*"
  echo ""
  echo "⚠️  Note: This may be overwritten when Claude updates its config."
  echo "   For permanent solution, use the proxy method (Option 1)."
else
  echo "❌ Failed to update email"
  exit 1
fi
