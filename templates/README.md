<!-- Replace all {{PLACEHOLDERS}} before publishing. Sections marked OPTIONAL: delete the whole section if it does not apply. Never leave a marker or an empty slot behind. -->

<div align="center">

<!-- OPTIONAL: delete the logo line if the project has no logo -->
<img src="{{LOGO_PATH}}" width="64" height="64" alt="{{PROJECT_NAME}} logo" />

# {{PROJECT_NAME}}

**{{TAGLINE}}**

{{ONE_LINE_PITCH}}: {{WHO_ITS_FOR}}.

[Features](#features) · [Screenshots](#screenshots) · [Quick start](#quick-start) · [Docs]({{DOCS_URL}}) · [Live demo]({{LIVE_URL}}) · [Contributing](CONTRIBUTING.md)

[![CI](https://github.com/{{OWNER}}/{{REPO}}/actions/workflows/ci.yml/badge.svg)](https://github.com/{{OWNER}}/{{REPO}}/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/{{OWNER}}/{{REPO}})](LICENSE)
[![npm version](https://img.shields.io/npm/v/{{PACKAGE_NAME}}?color=cb3837)](https://www.npmjs.com/package/{{PACKAGE_NAME}})
![Stack](https://img.shields.io/badge/stack-{{STACK}}-38bdf8)
[![Stars](https://img.shields.io/github/stars/{{OWNER}}/{{REPO}}?style=social)](https://github.com/{{OWNER}}/{{REPO}})

</div>

---

<!-- demo-placeholder: replace with actual GIF showing core value in <10 seconds -->
<p align="center">
  <img src="docs/demo.gif" alt="{{PROJECT_NAME}} demo" width="720">
</p>

## Why {{PROJECT_NAME}}?

{{PROBLEM_SENTENCE_1}} {{PROBLEM_SENTENCE_2}}. {{CONSEQUENCE_IF_UNSOLVED}}. {{PROJECT_NAME}} solves this by {{HOW_IT_SOLVES}}.

- **{{WHY_1_TITLE}}** - {{WHY_1_BODY}}
- **{{WHY_2_TITLE}}** - {{WHY_2_BODY}}
- **{{WHY_3_TITLE}}** - {{WHY_3_BODY}}
- **{{WHY_4_TITLE}}** - {{WHY_4_BODY}}

## Features

| Feature | What it does |
| --- | --- |
| **{{FEATURE_1}}** | {{OUTCOME_1}} |
| **{{FEATURE_2}}** | {{OUTCOME_2}} |
| **{{FEATURE_3}}** | {{OUTCOME_3}} |
| **{{FEATURE_4}}** | {{OUTCOME_4}} |
| **{{FEATURE_5}}** | {{OUTCOME_5}} |

### {{FEATURE_1}}

{{FEATURE_1_BULLETS}}

### {{FEATURE_2}}

{{FEATURE_2_BULLETS}}

### {{FEATURE_3}}

{{FEATURE_3_BULLETS}}

<!-- OPTIONAL: delete Screenshots for projects with no visual output (libraries, most CLIs) -->
## Screenshots

| {{SCREENSHOT_1_TITLE}} | {{SCREENSHOT_2_TITLE}} |
| --- | --- |
| ![{{SCREENSHOT_1_TITLE}}]({{SCREENSHOT_1_PATH}}) | ![{{SCREENSHOT_2_TITLE}}]({{SCREENSHOT_2_PATH}}) |

## Quick start

Requirements: {{REQUIREMENTS}}.

```bash
git clone https://github.com/{{OWNER}}/{{REPO}}.git
cd {{REPO}}
{{INSTALL_COMMAND}}
{{RUN_COMMAND}}
```

{{WHAT_HAPPENS_AFTER}}.

<!-- OPTIONAL: delete Environment variables if the project reads no configuration -->
### Environment variables

| Variable | Required | Default | Purpose |
| --- | --- | --- | --- |
| `{{OPTION_1}}` | {{REQUIRED}} | `{{DEFAULT}}` | {{DESCRIPTION}} |
| `{{OPTION_2}}` | {{REQUIRED}} | `{{DEFAULT}}` | {{DESCRIPTION}} |

### Scripts

| Command | Description |
| --- | --- |
| `{{RUN_COMMAND}}` | Start the project |
| `{{BUILD_COMMAND}}` | Create a production build |
| `{{TEST_COMMAND}}` | Run the tests |

### Continuous integration

GitHub Actions runs `ci.yml` on every push and pull request.

<!-- OPTIONAL: delete Keyboard shortcuts unless the product has real shortcuts -->
## Keyboard shortcuts

| Keys | Action |
| --- | --- |
| `{{SHORTCUT_1_KEYS}}` | {{SHORTCUT_1_ACTION}} |
| `{{SHORTCUT_2_KEYS}}` | {{SHORTCUT_2_ACTION}} |

## Tech stack

| Area | Choice |
| --- | --- |
{{TECH_STACK_ROWS}}

## Folder structure

```
{{FOLDER_TREE}}
```

<!-- OPTIONAL: delete Privacy unless the project handles user data or makes network requests -->
## Privacy

{{PRIVACY_SUMMARY}}

{{NETWORK_CALLS}}

## Roadmap

- **Shipped** - {{ROADMAP_SHIPPED}}
- **Next** - {{ROADMAP_NEXT}}

## Contributing

Contributions of all sizes are welcome - {{CONTRIBUTION_KINDS}}. Start with [CONTRIBUTING.md](CONTRIBUTING.md), and please follow our [Code of Conduct](CODE_OF_CONDUCT.md). Security issues: see [SECURITY.md](SECURITY.md).

## License

[{{LICENSE}}](LICENSE) © {{YEAR}} [{{AUTHOR_NAME}}]({{AUTHOR_URL}})
