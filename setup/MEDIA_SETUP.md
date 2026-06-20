# Media Setup Guide

## Overview
Automated screenshot + GIF generation for OSS demos. Cross-platform compatible.

## Dependencies

### Playwright (npm)
Headless browser automation for interaction scripting and screenshots.

**Installation:**
```bash
npm install --save-dev @playwright/test
npx playwright install chromium
```

**Verification:**
```bash
npx playwright --version
```

### ffmpeg
Video codec and GIF compilation.

#### Windows 11 (Chocolatey)
```bash
choco install ffmpeg
```

#### Windows 11 (Manual)
1. Download from https://ffmpeg.org/download.html
2. Extract to `C:\ffmpeg`
3. Add to PATH: Settings > Environment Variables > Path > Add `C:\ffmpeg\bin`
4. Verify: `ffmpeg -version`

#### macOS (Homebrew)
```bash
brew install ffmpeg
```

#### Linux (apt)
```bash
sudo apt-get install ffmpeg
```

**Verification:**
```bash
ffmpeg -version
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `playwright: command not found` | Run `npx playwright install chromium` |
| `ffmpeg: command not found` | Add to PATH or reinstall |
| Screenshot directory permission denied | Check folder write permissions |
| GIF output corrupt | Verify ffmpeg version >= 4.0 |
| Playwright timeout | Increase `timeout` in storyboard YAML |

## Platform-Specific Notes

**Windows 11:**
- Use Git Bash or WSL for bash scripts
- Path separators: forward slashes work in bash context
- ffmpeg may require Visual C++ Redistributable

**macOS:**
- Homebrew installation recommended for updates
- Playwright installs per node_modules (npm install)

**Linux:**
- ffmpeg available in most distros
- May need build tools for Playwright: `sudo apt-get install libnss3`
