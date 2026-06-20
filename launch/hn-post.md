# Show HN Post — Template + Strategy

## Timing
- **Best days:** Tuesday, Wednesday, Thursday
- **Best time:** 8:00–11:00 AM US Eastern (UTC-4/5)
- Avoid: Friday afternoon, weekends, major US holidays

## Title Formula
```
Show HN: {{PROJECT_NAME}} – {{WHAT_IT_DOES}} ({{KEY_DIFFERENTIATOR}})
```

**Rules:**
- Under 80 characters
- No exclamation marks — HN culture rejects hype
- Differentiator must be specific ("open source" / "self-hostable" / "no login required")
- Never: "I built X for Y months" in the title — belongs in the comment

**URL:** point to live demo, not GitHub repo.

## First Comment (Post Immediately)

```
Hi HN! I'm {{YOUR_NAME}}, I built {{PROJECT_NAME}}.

**Why I built it:** {{1-2 sentences on the frustration}}. I looked for existing tools and found {{GAP}}, so I built {{PROJECT_NAME}}.

**Technical details:** {{INTERESTING_TECHNICAL_ASPECT_1}}. {{INTERESTING_TECHNICAL_ASPECT_2}}.

**Looking for feedback on:** {{SPECIFIC_QUESTION_1}} and {{SPECIFIC_QUESTION_2}}.

GitHub: {{REPO_URL}}
```

## TourneyRadar First Comment

```
Hi HN! I'm Anay, I built TourneyRadar.

**Why I built it:** Chess tournaments are scattered across Chess-Results.com, federation websites, and club newsletters — no central place to find what's coming up near you. I built a scraper that normalizes 140+ federation data feeds into a single map.

**Technical details:** The scraper runs as a GitHub Actions matrix job, sharding 140 federation codes across 4 regional workers (europe, americas, asia-oceania, africa-me) — each completes under 30 minutes. Locations geocode via Google Maps API. Data lives in Supabase Postgres and is served via a public REST API with no auth or key required.

**Looking for feedback on:** whether the filter UX makes sense for players at different levels, and whether the public API format is useful for the chess developer community.

GitHub: https://github.com/AnayDhawan/tourneyradar
```

## HN Anti-Patterns
- Asking for stars or upvotes
- Self-promotional language ("revolutionary", "best")
- Posting and not responding to comments
- Linking to GitHub without a live demo
