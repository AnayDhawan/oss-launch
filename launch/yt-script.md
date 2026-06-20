# YouTube Demo Script — Structure + Template

## Video Architecture

| Segment | Duration | Purpose | What to show |
|---------|----------|---------|--------------|
| Hook | 0–8s | Stop the scroll | End result / output |
| Problem | 8–30s | Create desire | Screen recording of the pain |
| Demo | 30s–3min | Deliver value | Core use case, start-to-finish |
| How it works (optional) | 1–2min | Technical credibility | Code tour or architecture diagram |
| CTA | Last 15s | Drive action | "Link in description, star if useful" |

**Rules:**
- Never open with "Hey guys welcome back to my channel"
- Show the thing working in the first 8 seconds
- No slides, no talking heads — screen recording only
- Captions on (40% of views are silent)
- Under 4 min for tool demos. Under 8 min for full walkthrough.

## Script Template

```
[HOOK — 0:00-0:08]
Visual: [SHOW THE END RESULT]
Voiceover: "Here's {{PROJECT_NAME}}. {{ONE_LINE_WHAT_IT_DOES}}."

[PROBLEM — 0:08-0:30]
Visual: [SCREEN RECORDING OF THE PAIN — the bad alternative]
Voiceover: "{{PROBLEM_SENTENCE_1}}. {{PROJECT_NAME}} fixes that."

[DEMO — 0:30-3:00]
Visual: [SCREEN RECORDING of actual product]

Step 1: [SHOW INSTALL/OPEN]
Voiceover: "{{INSTALL_OR_OPEN_NARRATION}}"

Step 2: [SHOW CORE FEATURE 1]
Voiceover: "{{FEATURE_1_NARRATION}}"

Step 3: [SHOW CORE FEATURE 2]
Voiceover: "{{FEATURE_2_NARRATION}}"

Step 4: [SHOW KEY DIFFERENTIATOR]
Voiceover: "{{DIFFERENTIATOR_NARRATION}}"

[HOW IT WORKS — 3:00-4:30, optional]
Visual: [CODE SNIPPET or architecture diagram]
Voiceover: "Under the hood, {{BRIEF_TECHNICAL_EXPLANATION}}. The interesting part is {{INTERESTING_DETAIL}}."

[CTA — last 15s]
Visual: [GitHub repo page]
Voiceover: "It's open source — link in the description. Star it on GitHub if you find it useful."
```

## TourneyRadar Demo Script

```
[HOOK — 0:00-0:08]
Visual: TourneyRadar.com with world map loaded, zoomed into Europe, clusters expanding
Voiceover: "This is TourneyRadar. It shows every upcoming chess tournament in the world on one map."

[PROBLEM — 0:08-0:30]
Visual: Chess-Results.com open, searching one federation at a time, no map, no filter
Voiceover: "Chess-Results is the main source for tournament data — but you can only search one country at a time, there's no map, and you can't filter by time control. TourneyRadar fixes that."

[DEMO — 0:30-2:30]
0:30 — Click a country cluster, see tournament pins
Voiceover: "Every pin is a tournament. Click to see details."

0:50 — Open tournament detail: name, dates, city, time control, FIDE status
Voiceover: "Date, city, time control, whether it's FIDE rated."

1:10 — Use country filter: select "India", map recenters
Voiceover: "Filter by country."

1:25 — Toggle time control filter to Rapid only
Voiceover: "Filter by time control."

1:40 — Show /tournaments list view
Voiceover: "Or browse as a list."

1:55 — Show public API: curl in terminal, no key needed
Voiceover: "There's a public REST API. No auth, no key. Pull the data into your own projects."

[HOW IT WORKS — 2:30-3:30]
Visual: GitHub Actions scrape.yml, then Supabase dashboard
Voiceover: "A Puppeteer scraper runs every week on GitHub Actions, hitting Chess-Results across 140 federation codes in 4 regional workers — each completes under 30 minutes. Results geocode through Google Maps and land in Supabase."

[CTA — 3:30-3:45]
Visual: GitHub repo page
Voiceover: "It's open source — link in the description. If you find it useful, star it on GitHub."
```

## YouTube Description Template

```
{{PROJECT_NAME}} — {{ONE_LINE_PITCH}}

🔗 Live: {{LIVE_URL}}
⭐ GitHub: {{REPO_URL}}

## What it does
- {{BULLET_1}}
- {{BULLET_2}}
- {{BULLET_3}}

## Stack
{{TECH_STACK}}

## Timestamps
0:00 Demo
0:30 {{FEATURE_1}}
1:30 {{FEATURE_2}}
2:30 How it works
3:30 Contributing / open source

#{{TAG1}} #{{TAG2}} #opensource
```
