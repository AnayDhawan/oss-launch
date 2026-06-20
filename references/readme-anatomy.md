# readme-anatomy.md — what separates a 50-star README from a 1000-star one

| Element | 50-star README | 1000-star README |
|---------|---------------|-----------------|
| Opening | Project name + install | One-line pitch that names the pain |
| Visual | None or blurry screenshot | Animated GIF showing core value in <10s |
| Quick start | 5+ steps | Max 3 commands, copy-pasteable |
| Problem statement | Buried in section 3 | Sentence 2, right after the GIF |
| Badges | 10+ irrelevant badges | Build + license + version only |
| API / usage | Full reference dump | 1-2 common examples, link to full docs |
| Contribution ask | End of page or absent | After quick start, before full docs |

## Required sections, in order
1. Badges row (build status, license, version).
2. One-line pitch: what it does + who it is for. No jargon.
3. Demo GIF or screenshot (use `<!-- demo-placeholder -->` if not ready yet).
4. Problem statement (2-3 sentences max).
5. Quick Start (install, configure, run in 3 steps).
6. Features (5-8 outcome-oriented bullets).
7. Full usage / API reference (or a link).
8. Configuration reference.
9. Contributing (1 sentence + link to CONTRIBUTING.md).
10. License + author.

**Rule:** if the value is not clear within 8 seconds of scrolling, visitors bounce. A GIF
above the fold is the single highest-leverage README change.

## Anti-patterns that kill repos before launch
- README that opens with "Installation" (no pitch, no stars).
- No demo GIF or screenshot above the fold.
- "Coming soon" badges (reads as abandoned).
- Missing LICENSE (enterprise contributors are legally blocked).
- No CONTRIBUTING (confused contributors give up).
