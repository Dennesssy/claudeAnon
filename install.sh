#!/usr/bin/env bash
# Quick install script for claudeanon

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔒 Installing claudeanon${NC}"
echo ""

# Create scripts directory if needed
mkdir -p ~/.claude/scripts

# Copy files
echo "Copying files to ~/.claude/scripts/..."
cp email-hiding-proxy.js ~/.claude/scripts/
cp claudeanon.sh ~/.claude/scripts/
chmod +x ~/.claude/scripts/claudeanon.sh

# Check if alias already exists
if grep -q "alias claudeanon=" ~/.zshrc 2>/dev/null; then
  echo -e "${GREEN}✓ Alias already exists in ~/.zshrc${NC}"
else
  echo ""
  echo "Adding alias to ~/.zshrc..."
  echo "" >> ~/.zshrc
  echo "# claudeanon alias - Anthropic with email hidden" >> ~/.zshrc
  echo "alias claudeanon='bash ~/.claude/scripts/claudeanon.sh'" >> ~/.zshrc
  echo -e "${GREEN}✓ Alias added to ~/.zshrc${NC}"
fi

echo ""
echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo "Run: source ~/.zshrc"
echo "Then: claudeanon"
echo ""
