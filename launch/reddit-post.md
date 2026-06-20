# Reddit Launch — Subreddit Targeting + Post Templates

## Subreddit Selection Matrix

| Subreddit | Subscribers | Best for | Post format |
|-----------|-------------|----------|-------------|
| r/SideProject | 350K | Any project, most welcoming | Personal story, any demo |
| r/programming | 6M | Dev tools, libraries | Problem + architecture |
| r/webdev | 1.5M | Web apps, full-stack | Show UI, focus on UX |
| r/opensource | 180K | Any OSS project | "free", "self-hosted", "no vendor lock-in" |
| r/javascript | 2M | JS tools | Install snippet in post body |
| r/typescript | 130K | TS tools | Type safety angle |
| r/chess | 380K | Chess tools | Chess player pain, not tech |
| r/selfhosted | 380K | Self-hosted apps | Docker compose snippet |

**Sequencing:** niche first → wait 48h → broader dev → wait 48h → general. Never cross-post simultaneously.

## Post Title Formulas

```
# Problem/Solution (highest upvotes on r/programming)
I got frustrated that [PROBLEM], so I built [PROJECT] — open source [WHAT_IT_IS]

# Direct announcement (r/SideProject)
I built [PROJECT] — [ONE_LINE_PITCH]

# Question hook (niche subreddits)
Does anyone else find [PROBLEM]? I built [PROJECT] to solve it
```

## Full Post Template

```
**Title:** I got frustrated that {{PROBLEM}}, so I built {{PROJECT_NAME}} — open source and free

{{PROJECT_NAME}} is {{WHAT_IT_IS}}.

**The problem:** {{2-3 sentences describing the pain.}}

**What it does:**
- {{KEY_FEATURE_1}}
- {{KEY_FEATURE_2}}
- {{KEY_FEATURE_3}}

{{INSTALL_OR_TRY_SNIPPET}}

**Stack:** {{TECH_STACK}}

Live: {{LIVE_URL}}
GitHub: {{REPO_URL}}

Feedback very welcome — this is {{VERSION_STATUS}}.
```

## TourneyRadar Example (r/chess)

**Title:** I built a tool that finds chess tournaments near you — worldwide, filterable, free

```
TourneyRadar is an open source chess tournament finder that scrapes Chess-Results.com weekly and puts everything on an interactive map.

**The problem:** Finding chess tournaments is painful. Chess-Results lists thousands of tournaments but you can only search one federation at a time, there's no map, and you can't filter by time control or rating requirements.

**What it does:**
- Interactive world map with tournament pins and cluster zoom
- Filter by country, time control (Classical/Rapid/Blitz), FIDE rating status, date range
- Public REST API — no auth, no key: `GET /v1/tournaments?country=IN&upcoming=true`
- Data updates weekly covering 140+ federations

Try it: https://tourneyradar.com
GitHub: https://github.com/AnayDhawan/tourneyradar
```

## Engagement Rules
- Reply to every comment within 24 hours
- If someone reports a bug: thank them, open GitHub issue, reply with link
- Do not delete posts that get negative feedback
