# readme-anatomy.md: what separates a 50-star README from a 1000-star one

| Element | 50-star README | 1000-star README |
|---------|---------------|-----------------|
| Opening | Project name + install | One-line pitch that names the pain |
| Visual | None or blurry screenshot | Animated GIF showing core value in <10s |
| Quick start | 5+ steps | Max 3 commands, copy-pasteable |
| Problem statement | Buried in section 3 | Sentence 2, right after the GIF |
| Badges | 10+ irrelevant badges | Build + license + version, plus at most a stack badge |
| API / usage | Full reference dump | 1-2 common examples inside the feature sections, link to full docs |
| Contribution ask | End of page or absent | Own section near the end, linking CONTRIBUTING.md |

## Default layout

Every README generated from `templates/README.md` follows this layout, in this order. It is
the default; deviate only when a section genuinely does not apply.

1. **Centered header**: logo (optional), name, bold tagline, one-line pitch, a nav row of
   anchor links (Features, Screenshots, Quick start, Docs, Live demo, Contributing), then the
   badges row (build status, license, version, stack, stars).
2. **Demo GIF or screenshot**, centered, directly under the header. Use
   `<!-- demo-placeholder -->` if not ready yet.
3. **Why {{PROJECT_NAME}}?**: the problem in 2-3 sentences, then 4 bullets on properties of
   the whole project (license, local-first, no login, offline). These are not the features.
4. **Features**: a two-column table (feature, what it does), then one `###` section per
   major feature with 2-5 concrete bullets. Usage examples live here, not in a separate
   Usage section.
5. **Screenshots** (optional): a two-column table of captioned images. Skip for libraries
   and most CLIs.
6. **Quick start**: requirements line, then clone, install, run in a fenced block (max 3
   commands after the clone), then one sentence on what happens next. Followed by
   `### Environment variables` (optional, skip if nothing is configurable), `### Scripts`,
   and `### Continuous integration`.
7. **Keyboard shortcuts** (optional): only if the product has real shortcuts.
8. **Tech stack**: an `Area | Choice` table, each tool linked.
9. **Folder structure**: a real tree in a fenced block, with one comment per entry.
10. **Privacy** (optional): only if the project handles user data or calls external hosts.
    List every host and why.
11. **Roadmap**: what shipped, what is next. Honest, no dates you will not keep.
12. **Contributing**: one short paragraph, links to CONTRIBUTING, Code of Conduct, SECURITY.
13. **License**: license, year, author.

Headings use sentence case ("Quick start", not "Quick Start"). Separators inside bullets are
a spaced hyphen, never an em dash.

**Rule:** if the value is not clear within 8 seconds of scrolling, visitors bounce. A GIF
above the fold is the single highest-leverage README change. The nav row puts Quick start one
click away for readers who came to install, not to browse.

## Existing READMEs

This layout is for READMEs that do not exist yet. An existing README with real prose is
augmented (missing sections, a badges row), never reflowed into this layout.

## Anti-patterns that kill repos before launch
- README that opens with "Installation" (no pitch, no stars).
- No demo GIF or screenshot above the fold.
- "Coming soon" badges (reads as abandoned).
- Missing LICENSE (enterprise contributors are legally blocked).
- No CONTRIBUTING (confused contributors give up).
- An OPTIONAL section left in with empty slots, or a section for a feature the project does
  not have. Delete it.
