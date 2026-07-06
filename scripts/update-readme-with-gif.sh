#!/bin/bash

# update-readme-with-gif.sh
# Automatically insert demo GIF reference into README
# Finds "## Quick Start" section and inserts GIF above it
# Git-safe: shows diff before modifying
#
# Usage:
#   bash update-readme-with-gif.sh --readme README.md --gif docs/media/demo.gif
#   bash update-readme-with-gif.sh --readme README.md --gif docs/media/demo.gif --auto

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Defaults
README=""
GIF_PATH=""
AUTO_COMMIT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --readme)
      README="$2"
      shift 2
      ;;
    --gif)
      GIF_PATH="$2"
      shift 2
      ;;
    --auto)
      AUTO_COMMIT=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate inputs
if [ -z "$README" ] || [ -z "$GIF_PATH" ]; then
  echo -e "${RED}Error: Provide --readme and --gif${NC}"
  echo "Usage: bash update-readme-with-gif.sh --readme README.md --gif docs/media/demo.gif"
  exit 1
fi

if [ ! -f "$README" ]; then
  echo -e "${RED}Error: README not found: $README${NC}"
  exit 1
fi

if [ ! -f "$GIF_PATH" ]; then
  echo -e "${RED}Error: GIF not found: $GIF_PATH${NC}"
  exit 1
fi

echo -e "${YELLOW}[*] Checking if GIF already referenced...${NC}"

# Check if GIF is already in README
if grep -q "$(basename "$GIF_PATH")" "$README"; then
  echo -e "${GREEN}[✓] GIF already referenced in README${NC}"
  exit 0
fi

# Find line number of "## Quick Start" section
QUICK_START_LINE=$(grep -n "^## Quick Start" "$README" | head -1 | cut -d: -f1)

if [ -z "$QUICK_START_LINE" ]; then
  echo -e "${YELLOW}[!] Warning: '## Quick Start' section not found${NC}"
  echo -e "${YELLOW}    Searching for common alternatives...${NC}"

  # Try alternate section names
  for alt_section in "## Usage" "## Installation" "## Getting Started" "## Demo"; do
    QUICK_START_LINE=$(grep -n "^$alt_section" "$README" | head -1 | cut -d: -f1)
    if [ -n "$QUICK_START_LINE" ]; then
      echo -e "${YELLOW}    Found: $alt_section at line $QUICK_START_LINE${NC}"
      break
    fi
  done

  if [ -z "$QUICK_START_LINE" ]; then
    echo -e "${RED}[!] No suitable section found for GIF insertion${NC}"
    echo -e "${RED}    Add '## Quick Start' section to your README${NC}"
    exit 1
  fi
fi

echo -e "${GREEN}[✓] Found insertion point at line $QUICK_START_LINE${NC}"

# Create temporary file with GIF reference inserted
TEMP_README=$(mktemp)
trap 'rm -f "$TEMP_README"' EXIT

# Insert blank line + GIF markdown before the Quick Start section
head -n $((QUICK_START_LINE - 1)) "$README" > "$TEMP_README"

# Add GIF reference
cat >> "$TEMP_README" << EOF

![Demo]($GIF_PATH)

EOF

# Add rest of file
tail -n +"$QUICK_START_LINE" "$README" >> "$TEMP_README"

echo -e "${BLUE}[*] Diff preview:${NC}"
diff -u "$README" "$TEMP_README" || true

echo ""
echo -e "${YELLOW}[?] Apply changes? (y/n)${NC}"

if [ "$AUTO_COMMIT" = true ]; then
  echo "y"
  RESPONSE="y"
else
  read -r RESPONSE
fi

if [ "$RESPONSE" = "y" ] || [ "$RESPONSE" = "yes" ]; then
  cp "$TEMP_README" "$README"
  echo -e "${GREEN}[✓] README updated with GIF reference${NC}"
  echo -e "${GREEN}[✓] GIF path: $GIF_PATH${NC}"
  echo ""
  echo -e "${YELLOW}[*] Next steps:${NC}"
  echo "    git add README.md"
  echo "    git add $GIF_PATH"
  echo "    git commit -m 'Add demo GIF to README'"
else
  echo -e "${YELLOW}[*] Cancelled. No changes made.${NC}"
fi
