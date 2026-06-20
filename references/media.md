# media.md — demo GIF + screenshot generation

Automating an above-the-fold demo GIF is the highest-leverage README upgrade. Full
dependency install instructions: `setup/MEDIA_SETUP.md`.

## One-time setup
```bash
npm install --save-dev @playwright/test
npx playwright install chromium
# ffmpeg: choco install ffmpeg (Windows) / brew install ffmpeg (macOS) / apt-get install ffmpeg (Linux)
```

## Workflow
1. Write a storyboard YAML describing the demo interaction sequence
   (schema: `launch/screenshot-storyboard.yaml`).
2. `bash scripts/generate-media.sh --storyboard demo-storyboard.yaml`
   (Playwright captures screenshots, ffmpeg compiles the GIF).
3. `bash scripts/update-readme-with-gif.sh --readme README.md --gif docs/media/demo.gif`
   (inserts the GIF above `## Quick Start`).
4. Commit the README + the GIF asset.

## Storyboard tips
- Start with "Load homepage" to capture the initial state.
- Follow the natural demo flow (the order a user would click).
- Use 500-1500ms waits for animations / network.
- Name screenshots sequentially (`01-`, `02-`, ...).
- Keep under 8 interactions; viewers get lost after ~15s.
- Test at 1280x720 first; it scales well on GitHub.

## Windows note
Use Git Bash or WSL for the bash scripts. ffmpeg may need the Visual C++ Redistributable.
