# github-metadata.md — set once, drives discovery forever

GitHub's search and "Explore" use topics + description. Set them deliberately.

## Topics (`gh repo edit --add-topic`)
- Max 20. Include: language (`typescript`), domain (`chess`), type (`web-app`, `cli`),
  category (`open-source`), specific tech (`nextjs`, `supabase`).
- Anti-pattern: `awesome`, `project`, `code` — zero discovery value.

## Description + homepage
One sentence, under 350 chars, with the primary keyword.
```bash
gh repo edit --description "Find chess tournaments worldwide: interactive map, 140+ federations, public API"
gh repo edit --homepage "https://example.com"
```

## Badges (top of README)
```markdown
![Build](https://github.com/{{OWNER}}/{{REPO}}/actions/workflows/ci.yml/badge.svg)
[![License: {{LICENSE}}](https://img.shields.io/badge/license-{{LICENSE}}-blue)](LICENSE)
[![Stars](https://img.shields.io/github/stars/{{OWNER}}/{{REPO}}?style=social)](https://github.com/{{OWNER}}/{{REPO}})
```

## Star ask
Place it immediately after the demo GIF, before installation. Never at the bottom.
> If this is useful, star it. It helps others find it.

## Contributor avatars (optional, in README)
```html
<a href="https://github.com/{{OWNER}}/{{REPO}}/graphs/contributors">
  <img src="https://contrib.rocks/image?repo={{OWNER}}/{{REPO}}"/>
</a>
```
