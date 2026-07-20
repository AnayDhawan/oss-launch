#!/bin/bash

# generate-media.sh
# Automate screenshot + GIF generation for OSS demos
# Uses Playwright for browser automation + ffmpeg for GIF compilation
#
# Usage:
#   bash generate-media.sh --storyboard ./launch/screenshot-storyboard.yaml
#   bash generate-media.sh --url https://tourneyradar.com --output-dir ./docs/media

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
STORYBOARD=""
URL=""
OUTPUT_DIR="./docs/media"
TEMP_SCREENSHOTS_DIR=""
CLEANUP_TEMP=true

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --storyboard)
      STORYBOARD="$2"
      shift 2
      ;;
    --url)
      URL="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --keep-temp)
      CLEANUP_TEMP=false
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate inputs
if [ -z "$STORYBOARD" ] && [ -z "$URL" ]; then
  echo -e "${RED}Error: Provide --storyboard YAML or --url URL${NC}"
  echo "Usage: bash generate-media.sh --storyboard ./launch/screenshot-storyboard.yaml"
  exit 1
fi

# Check dependencies
check_dependency() {
  if ! command -v "$1" &> /dev/null; then
    echo -e "${RED}Error: $1 not found. Install via MEDIA_SETUP.md${NC}"
    exit 1
  fi
}

check_dependency "node"
check_dependency "npx"

# Check if ffmpeg is available (optional for GIF generation)
FFMPEG_AVAILABLE=true
if ! command -v ffmpeg &> /dev/null; then
  echo -e "${YELLOW}[!] ffmpeg not found — screenshots will be generated but GIF will be skipped${NC}"
  FFMPEG_AVAILABLE=false
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Temporary directory for screenshots
TEMP_SCREENSHOTS_DIR=$(mktemp -d)
trap '[ "$CLEANUP_TEMP" = true ] && rm -rf "$TEMP_SCREENSHOTS_DIR"' EXIT

echo -e "${YELLOW}[*] Starting media generation...${NC}"
echo -e "${YELLOW}[*] Temp screenshots: $TEMP_SCREENSHOTS_DIR${NC}"
echo -e "${YELLOW}[*] Output directory: $OUTPUT_DIR${NC}"

# If YAML storyboard provided, parse it
if [ -n "$STORYBOARD" ]; then
  if [ ! -f "$STORYBOARD" ]; then
    echo -e "${RED}Error: Storyboard file not found: $STORYBOARD${NC}"
    exit 1
  fi

  # Extract values from YAML using simple grep/awk (no yq dependency)
  URL=$(grep "^url:" "$STORYBOARD" | head -1 | awk -F': ' '{print $2}' | tr -d ' ')
  GIF_NAME=$(grep "^gif_name:" "$STORYBOARD" | head -1 | awk -F': ' '{print $2}' | tr -d ' ')
  VIEWPORT_WIDTH=$(grep "width:" "$STORYBOARD" | grep -v "^#" | head -1 | awk -F': ' '{print $2}' | tr -d ' ')
  VIEWPORT_HEIGHT=$(grep "height:" "$STORYBOARD" | grep -v "^#" | head -1 | awk -F': ' '{print $2}' | tr -d ' ')
  FPS=$(grep "fps:" "$STORYBOARD" | grep -v "^#" | head -1 | awk -F': ' '{print $2}' | tr -d ' ')

  # Defaults if not found in YAML
  VIEWPORT_WIDTH=${VIEWPORT_WIDTH:-1280}
  VIEWPORT_HEIGHT=${VIEWPORT_HEIGHT:-720}
  FPS=${FPS:-10}
  GIF_NAME=${GIF_NAME:-demo.gif}

  echo -e "${GREEN}[✓] Parsed storyboard: $STORYBOARD${NC}"
else
  VIEWPORT_WIDTH=1280
  VIEWPORT_HEIGHT=720
  FPS=10
  GIF_NAME="demo.gif"
fi

echo -e "${YELLOW}[*] URL: $URL${NC}"
echo -e "${YELLOW}[*] Viewport: ${VIEWPORT_WIDTH}x${VIEWPORT_HEIGHT}${NC}"
echo -e "${YELLOW}[*] Output GIF: $OUTPUT_DIR/$GIF_NAME${NC}"

# Determine project root first
PROJECT_ROOT=""
if [ -n "$STORYBOARD" ]; then
  PROJECT_ROOT=$(dirname "$(cd "$(dirname "$STORYBOARD")" && pwd)")
fi
if [ -z "$PROJECT_ROOT" ] || [ ! -f "$PROJECT_ROOT/package.json" ]; then
  PROJECT_ROOT=$(pwd)
fi

# Create Playwright script in project root so it can resolve node_modules
# Use .cjs extension to force CommonJS mode if project uses ES modules
PLAYWRIGHT_SCRIPT="$PROJECT_ROOT/.playwright-screenshot-$(date +%s).cjs"
cat > "$PLAYWRIGHT_SCRIPT" << 'EOF'
const fs = require('fs');
const path = require('path');

(async () => {
  // Import chromium using require (works in CommonJS)
  const { chromium } = require('playwright');

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  const url = process.argv[2];
  const storyboardPath = process.argv[3];
  let outputDir = process.argv[4];
  const viewportWidth = parseInt(process.argv[5], 10);
  const viewportHeight = parseInt(process.argv[6], 10);

  // Convert UNIX-style paths to Windows paths (handle /c/Users/... → C:/Users/...)
  if (process.platform === 'win32' && outputDir.startsWith('/')) {
    outputDir = outputDir.replace(/^\/([a-z])/, '$1:').replace(/\//g, path.sep);
  }
  if (process.platform === 'win32' && storyboardPath && storyboardPath.startsWith('/')) {
    storyboardPath = storyboardPath.replace(/^\/([a-z])/, '$1:').replace(/\//g, path.sep);
  }

  await page.setViewportSize({ width: viewportWidth, height: viewportHeight });

  let interactions = [];

  // Parse storyboard YAML manually (no external deps)
  if (storyboardPath && fs.existsSync(storyboardPath)) {
    const content = fs.readFileSync(storyboardPath, 'utf-8');
    const lines = content.split('\n');

    let inInteractions = false;
    let currentInteraction = {};

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];

      if (line.match(/^interactions:/)) {
        inInteractions = true;
        continue;
      }

      if (inInteractions && line.match(/^  - name:/)) {
        if (Object.keys(currentInteraction).length > 0) {
          interactions.push(currentInteraction);
        }
        currentInteraction = { name: line.split(': ')[1].trim().replace(/["']/g, '') };
      }

      if (inInteractions && line.match(/^    wait:/)) {
        currentInteraction.wait = parseInt(line.split(': ')[1], 10);
      }

      if (inInteractions && line.match(/^    screenshot:/)) {
        currentInteraction.screenshot = line.includes('true');
      }

      if (inInteractions && line.match(/^    screenshot_name:/)) {
        currentInteraction.screenshot_name = line.split(': ')[1].trim().replace(/["']/g, '');
      }
    }

    if (Object.keys(currentInteraction).length > 0) {
      interactions.push(currentInteraction);
    }
  }

  console.log(`[*] Loading ${url}...`);
  await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 });
  console.log(`[✓] Page loaded`);

  let screenshotCount = 0;

  // Execute interactions
  for (const interaction of interactions) {
    console.log(`[*] Executing: ${interaction.name}`);

    if (interaction.wait) {
      await page.waitForTimeout(interaction.wait);
    }

    if (interaction.screenshot !== false) {
      const filename = interaction.screenshot_name || `screenshot-${String(screenshotCount).padStart(2, '0')}`;
      const filepath = path.join(outputDir, `${filename}.png`);
      await page.screenshot({ path: filepath, fullPage: false });
      console.log(`[✓] Screenshot: ${filename}.png`);
      screenshotCount++;
    }
  }

  await browser.close();
  console.log(`[✓] Captured ${screenshotCount} screenshots`);
})().catch(err => {
  console.error(`[!] Error: ${err.message}`);
  process.exit(1);
});
EOF

echo -e "${YELLOW}[*] Generating screenshots with Playwright...${NC}"
echo -e "${YELLOW}[*] Project root: $PROJECT_ROOT${NC}"

# Run from project root so node_modules are resolvable
cd "$PROJECT_ROOT"
node "$PLAYWRIGHT_SCRIPT" "$URL" "$STORYBOARD" "$TEMP_SCREENSHOTS_DIR" "$VIEWPORT_WIDTH" "$VIEWPORT_HEIGHT" 2>&1 || {
  echo -e "${RED}Error: Playwright screenshot generation failed${NC}"
  rm -f "$PLAYWRIGHT_SCRIPT"
  exit 1
}

rm -f "$PLAYWRIGHT_SCRIPT"

# Verify screenshots were created
SCREENSHOT_COUNT=$(find "$TEMP_SCREENSHOTS_DIR" -maxdepth 1 -name '*.png' -type f 2>/dev/null | wc -l)
if [ "$SCREENSHOT_COUNT" -eq 0 ]; then
  echo -e "${RED}Error: No screenshots generated${NC}"
  exit 1
fi

echo -e "${GREEN}[✓] Generated $SCREENSHOT_COUNT screenshots${NC}"

# Compile GIF with ffmpeg (if available)
if [ "$FFMPEG_AVAILABLE" = true ]; then
  echo -e "${YELLOW}[*] Compiling GIF with ffmpeg...${NC}"

  ffmpeg -y \
    -pattern_type glob \
    -i "$TEMP_SCREENSHOTS_DIR/*.png" \
    -vf "fps=$FPS,scale=1280:-1:flags=lanczos,palettegen" \
    palette.png 2>&1 | grep -v "frame=" || true

  ffmpeg -y \
    -framerate "$FPS" \
    -pattern_type glob \
    -i "$TEMP_SCREENSHOTS_DIR/*.png" \
    -i palette.png \
    -lavfi "fps=$FPS,scale=1280:-1:flags=lanczos [x]; [x][1:v] paletteuse" \
    "$OUTPUT_DIR/$GIF_NAME" 2>&1 | grep -v "frame=" || true

  rm -f palette.png

  if [ ! -f "$OUTPUT_DIR/$GIF_NAME" ]; then
    echo -e "${RED}Error: GIF compilation failed${NC}"
    exit 1
  fi

  GIF_SIZE=$(du -h "$OUTPUT_DIR/$GIF_NAME" | awk '{print $1}')
  echo -e "${GREEN}[✓] GIF created: $OUTPUT_DIR/$GIF_NAME ($GIF_SIZE)${NC}"
else
  echo -e "${YELLOW}[!] Skipping GIF generation (ffmpeg not available)${NC}"
  echo -e "${YELLOW}[*] Screenshots saved to $OUTPUT_DIR — use ffmpeg to create GIF later${NC}"
fi

echo -e "${GREEN}[✓] Media generation complete!${NC}"
