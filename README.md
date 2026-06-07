# agent-toolkit

Agent skills library for Cursor, Claude Code, VS Code, and other agent harnesses — organized by domain.

Curated skills for product, growth, launch, content, engineering, sales, and communication — plus custom additions.

See [AGENTS.md](AGENTS.md) for when to suggest which skill.

**Creating or publishing skills?** See [docs/authoring-skills.md](docs/authoring-skills.md) for the full workflow (sync scripts, manifest, and the “new skill from chat” checklist).

## Repository structure

```
agent-toolkit/
├── .claude-plugin/
│   └── marketplace.json      # Claude Code plugin catalog
├── AGENTS.md                 # When to suggest which skill
├── README.md
├── docs/
│   └── authoring-skills.md   # How to create, sync, and publish skills
├── rules/                    # Always-on Cursor rules (.mdc)
├── scripts/
│   ├── install.sh            # Install for Cursor (+ Claude if available)
│   ├── install-cursor.sh     # Symlink plugins + skills + rules into ~/.cursor/
│   ├── install-claude.sh     # Register marketplace + install plugins
│   ├── sync-from-cursor.sh   # Copy ~/.cursor/skills/ → repo (reverse sync)
│   ├── publish-skills.sh     # sync + install + git commit + push
│   ├── check-pii.sh          # Scan staged files for PII and secrets
│   ├── install-git-hooks.sh  # Install pre-push PII blocker for this repo
│   ├── hooks/pre-push        # Git hook template (installed by install-git-hooks.sh)
│   ├── skills-manifest.conf  # Maps top-level skill names → repo paths
│   └── update.sh             # git pull + refresh installs
├── product-skills/           # Skill plugins (one folder per domain)
├── execution-skills/
├── financial-skills/         # Portfolio analysis and refresh workflows
└── ...
```

| Folder | Purpose | Install target |
|--------|---------|----------------|
| `*-skills/` | Task playbooks (skills + commands) | Cursor: `~/.cursor/skills/` · Claude: plugin install |
| `rules/` | Always-on behavioral rules | Cursor: `~/.cursor/rules/` |
| `AGENTS.md` | Skill routing guide | Read from repo (or copy to project) |

### Always-on rules

| Rule | What it does |
|------|-------------|
| [karpathy-guidelines](rules/karpathy-guidelines.mdc) | Simplicity, surgical changes, goal-driven execution |
| [no-pii-push](rules/no-pii-push.mdc) | Block commits/pushes with PII, secrets, or financial data |
| [project-folder-structure](rules/project-folder-structure.mdc) | Purpose-based folder layout for new projects |
| [skills-repo-first](rules/skills-repo-first.mdc) | Repo is source of truth for skill authoring |

PII protection is also available as a skill: [no-pii-push](engineering-skills/no-pii-push/SKILL.md).

---

## Quick start

```bash
git clone https://github.com/viveksinha/agent-toolkit.git
cd agent-toolkit
chmod +x scripts/*.sh
./scripts/install.sh
```

To update later:

```bash
./scripts/update.sh
```

---

## Install

### Cursor (recommended)

Symlinks plugin folders into `~/.cursor/skills/` and rules into `~/.cursor/rules/`:

```bash
./scripts/install-cursor.sh
./scripts/install-git-hooks.sh   # optional: block git push when PII is detected
```

Custom paths:

```bash
CURSOR_SKILLS=~/.cursor/skills CURSOR_RULES=~/.cursor/rules ./scripts/install-cursor.sh
```

Cursor-only install (skip Claude):

```bash
INSTALL_CLAUDE=0 ./scripts/install.sh
```

### Day-to-day workflow (authoring skills)

**Repo is the source of truth.** Full guide: **[docs/authoring-skills.md](docs/authoring-skills.md)**.

Quick version:

```bash
./scripts/install-cursor.sh                              # after editing in repo
./scripts/sync-from-cursor.sh --apply                    # if you edited ~/.cursor/skills/ instead
./scripts/publish-skills.sh "Add or update my-skill"     # sync + commit + push
```

### Claude Code

**From GitHub** (after clone):

```bash
claude plugin marketplace add viveksinha/agent-toolkit
claude plugin install product-skills@agent-toolkit
# repeat for other plugins, or use the install script:
./scripts/install-claude.sh
```

**From a local clone**:

```bash
claude plugin marketplace add ./path/to/agent-toolkit
./scripts/install-claude.sh
```

Install a subset of plugins:

```bash
PLUGINS_TO_INSTALL="product-skills execution-skills" ./scripts/install-claude.sh
```

Project-scoped install (shared via `.claude/settings.json`):

```bash
CLAUDE_SCOPE=project ./scripts/install-claude.sh
```

### Update

Pulls latest changes, refreshes Cursor symlinks, and updates the Claude marketplace:

```bash
./scripts/update.sh
```

After updating, refresh installed Claude plugins:

```bash
claude plugin update --all
```

### No install needed

Open any `SKILL.md`, copy the prompt template, replace `[$ARGUMENTS](https://code.claude.com/docs/en/skills.md#available-string-substitutions)` with your context, and paste into any LLM.

---

## Plugins

Each top-level folder is an independently installable plugin, organized by discipline.

### [product-skills](product-skills/) — Craft & ship products

Discovery, specs, experiments, readouts, and competitive strategy.

| Type | Name | What it does |
|------|------|-------------|
| Skill | [7-powers](product-skills/skills/7-powers/SKILL.md) | Analyze competitive advantage using Hamilton Helmer's 7 Powers framework |
| Skill | [amazon-working-backwards](product-skills/skills/amazon-working-backwards/SKILL.md) | Write a PR/FAQ to pressure-test a product idea before committing to build |
| Skill | [craft-spec](product-skills/skills/craft-spec/SKILL.md) | Turn messy ideas into a clear, structured PRD |
| Skill | [craft-experiment-design](product-skills/skills/craft-experiment-design/SKILL.md) | Write a hypothesis, define success metrics, and plan a holdout strategy |
| Skill | [craft-experiment-readout](product-skills/skills/craft-experiment-readout/SKILL.md) | Summarize results, call a winner, and draft a stakeholder-ready recommendation |
| Skill | [craft-discovery-synthesis](product-skills/skills/craft-discovery-synthesis/SKILL.md) | Extract themes and insights from raw user interviews and feedback |
| Skill | [create-user-stories](product-skills/skills/create-user-stories/SKILL.md) | Break a PRD into implementable user stories with acceptance criteria |
| Skill | [draft-spec](product-skills/skills/draft-spec/SKILL.md) | Draft a detailed spec with problem context, solution design, and strategic framing |
| Skill | [good-strategy-bad-strategy](product-skills/skills/good-strategy-bad-strategy/SKILL.md) | Evaluate or develop strategy using Rumelt's kernel — Diagnosis, Guiding Policy, Coherent Actions |
| Skill | [high-output-management](product-skills/skills/high-output-management/SKILL.md) | Diagnose team leverage, design processes, and make management decisions using Grove's framework |
| Skill | [jobs-to-be-done](product-skills/skills/jobs-to-be-done/SKILL.md) | Uncover functional, social, and emotional jobs driving customer behavior |
| Skill | [mom-test](product-skills/skills/mom-test/SKILL.md) | Design customer conversations that extract real signal, not polite lies |
| Skill | [playing-to-win](product-skills/skills/playing-to-win/SKILL.md) | Develop strategy using the Lafley/Martin cascade — Where to Play, How to Win |
| Skill | [pre-mortem](product-skills/skills/pre-mortem/SKILL.md) | Imagine launch failure and work backward to identify risks before you ship |
| Skill | [prioritize](product-skills/skills/prioritize/SKILL.md) | Take a list of ideas or initiatives and quickly rank them using RICE |
| Skill | [competitor-monitoring](product-skills/skills/competitor-monitoring/SKILL.md) | Visit competitor sites weekly and write a structured competitive intelligence report |
| Skill | [market-research-digest](product-skills/skills/market-research-digest/SKILL.md) | Synthesize Drive files, meeting notes, and web signals into a weekly research summary |
| Skill | [what-would-lenny-do](product-skills/skills/what-would-lenny-do/SKILL.md) | Answer product strategy and growth questions using Lenny Rachitsky's archive |
| Command | [write-prd](product-skills/commands/write-prd.md) | Guided PRD writing with conversational context gathering |
| Command | [run-discovery](product-skills/commands/run-discovery.md) | Full discovery workflow from research through experiment design |

### [execution-skills](execution-skills/) — Stay on top of your product

Meeting processing, stakeholder comms, support triage, and idea stress-testing.

| Type | Name | What it does |
|------|------|-------------|
| Skill | [meeting-synthesis](execution-skills/skills/meeting-synthesis/SKILL.md) | Turn meeting transcripts or notes into concise takeaways and action items with DRIs |
| Skill | [stakeholder-update](execution-skills/skills/stakeholder-update/SKILL.md) | Write a weekly stakeholder update — metrics, bets, customer signal, highlights |
| Skill | [yes-and](execution-skills/skills/yes-and/SKILL.md) | Build on an idea constructively — extend what's working, surface risks with mitigations |
| Skill | [pm-weekly-brief](execution-skills/skills/pm-weekly-brief/SKILL.md) | Read Slack, calendar, and Drive activity from the past 7 days and write a personal PM summary |
| Skill | [release-notes-generator](execution-skills/skills/release-notes-generator/SKILL.md) | Read completed tickets and write polished, user-facing release notes grouped by product area |
| Skill | [update-knowledge-base](execution-skills/skills/update-knowledge-base/SKILL.md) | Cross-reference shipped tickets with your help center to detect outdated or missing docs |
| Skill | [kinder-messages](execution-skills/skills/kinder-messages/SKILL.md) | Rephrase Slack/email/DMs to be warmer and collaborative without losing clarity |
| Skill | [create-speaker-notes](execution-skills/skills/create-speaker-notes/SKILL.md) | Write flowing speaker notes and talk tracks for presentation decks |
| Skill | [support-feedback-prioritization](execution-skills/skills/support-feedback-prioritization/SKILL.md) | Pull Intercom + Slack signals, enrich with CRM data, and rank by customer value into a tiered report |
| Command | [yc-office-hours](execution-skills/commands/yc-office-hours.md) | Interactive stress-test of a product idea with branching modes and forcing questions before committing to build |

### [design-skills](design-skills/) — Design & research

User research, journey mapping, usability analysis, and design critique. *Coming soon.*

### [engineering-skills](engineering-skills/) — Build & ship

Automation and engineering workflows.

| Type | Name | What it does |
|------|------|-------------|
| Skill | [data-scraper-agent](engineering-skills/data-scraper-agent/SKILL.md) | Build automated public-data collection agents with Python, Gemini Flash, and GitHub Actions |
| Skill | [no-pii-push](engineering-skills/no-pii-push/SKILL.md) | Scan for PII and secrets before commit/push; refuse and alert on any match |

### [financial-skills](financial-skills/) — Portfolio analysis

Brokerage statement parsing and equity portfolio canvas refresh. Skill templates use placeholders only — configure tickers and paths locally; never commit export files or real holdings data.

| Type | Name | What it does |
|------|------|-------------|
| Skill | [ibkr-portfolio-analysis](financial-skills/skills/ibkr-portfolio-analysis/SKILL.md) | Parse an IBKR Activity Statement CSV and render a portfolio analysis canvas |
| Skill | [indian-stock-portfolio-refresh](financial-skills/skills/indian-stock-portfolio-refresh/SKILL.md) | Refresh valuation, risk, macro, and daily-actions canvases from a Trendlyne Excel export |

### [launch-skills](launch-skills/) — Launch & announce

Plan, message, and execute product launches at any scale — from major products to incremental improvements.

| Type | Name | What it does |
|------|------|-------------|
| Skill | [launch-strategy](launch-skills/skills/launch-strategy/SKILL.md) | Plan a launch with tiered framework, messaging brief, checklist, timeline, and retro |
| Skill | [launch-tweet](launch-skills/skills/launch-tweet/SKILL.md) | Craft launch tweets, threads, and social posts adapted for X, LinkedIn, BlueSky, and HN |
| Skill | [launch-email](launch-skills/skills/launch-email/SKILL.md) | Write launch emails — subject lines, announcement structure, segmentation, changelog digests |
| Skill | [launch-blog-post](launch-skills/skills/launch-blog-post/SKILL.md) | Write launch blog posts optimized for SEO and AI engine citation (AEO) |
| Skill | [launch-video](launch-skills/skills/launch-video/SKILL.md) | Plan and produce demo videos, GIFs, screenshots, and programmatic video with Remotion |
| Skill | [launch-landing-page](launch-skills/skills/launch-landing-page/SKILL.md) | Design launch landing pages with urgency mechanics, waitlists, and conversion optimization |
| Skill | [launch-distribution](launch-skills/skills/launch-distribution/SKILL.md) | Execute multi-channel distribution — Twitter, Reddit, LinkedIn, HN, Product Hunt, press |
| Skill | [launch-metrics](launch-skills/skills/launch-metrics/SKILL.md) | Set up UTMs, define KPIs by tier, run data-driven retros, and build a launch history |

### [content-marketing-skills](content-marketing-skills/) — Write and distribute content

Long-form writing and platform-native social content.

| Type | Name | What it does |
|------|------|-------------|
| Skill | [article-blog-writing](content-marketing-skills/skills/article-blog-writing/SKILL.md) | Write long-form articles, guides, and newsletters in a distinctive voice |
| Skill | [human-writing-style](content-marketing-skills/skills/human-writing-style/SKILL.md) | Edit long-form content to read naturally and avoid AI tells like overused em-dashes |
| Skill | [social-content-engine](content-marketing-skills/skills/social-content-engine/SKILL.md) | Create platform-native content for X, LinkedIn, TikTok, YouTube, and newsletters |

### [growth-skills](growth-skills/) — Grow & optimize

Activation analysis, retention strategies, funnel optimization, and go-to-market planning.

| Type | Name | What it does |
|------|------|-------------|
| Skill | [build-metric-tree](growth-skills/skills/build-metric-tree/SKILL.md) | Decompose a top-line metric into a sized tree, identify where the real leverage is and where it isn't |
| Skill | [build-plg-strategy](growth-skills/skills/build-plg-strategy/SKILL.md) | Design a product-led growth strategy — activation, monetization, distribution, and PLG-to-sales bridge |
| Skill | [diagnose-activation](growth-skills/skills/diagnose-activation/SKILL.md) | Diagnose where new users fail to activate, identify the aha moment, and build a sized plan to move activation rate |
| Skill | [diagnose-retention](growth-skills/skills/diagnose-retention/SKILL.md) | Decompose your retention curve into cohorts, identify retention-predictive behaviors, and build a plan to bend the curve |
| Skill | [diagnose-monetization](growth-skills/skills/diagnose-monetization/SKILL.md) | Find revenue leaks, evaluate packaging and pricing, and size expansion revenue opportunities |
| Skill | [diagnose-acquisition](growth-skills/skills/diagnose-acquisition/SKILL.md) | Map where users come from, measure channel quality and CAC, and find the highest-leverage acquisition channels |
| Skill | [map-growth-loops](growth-skills/skills/map-growth-loops/SKILL.md) | Identify and measure self-reinforcing growth loops, find where loops break, and invest in compounding growth |
| Skill | [north-star-metric](growth-skills/skills/north-star-metric/SKILL.md) | Define a North Star Metric and its input metrics; classify the game your product plays |

### [sales-skills](sales-skills/) — Close deals

| Type | Name | What it does |
|------|------|-------------|
| Skill | [know-before-you-go-perla-lobera](sales-skills/skills/know-before-you-go-perla-lobera/SKILL.md) | Pre-call intelligence brief from CRM, meeting notes, and web research |
| Skill | [churn-lost-deal-analysis](sales-skills/skills/churn-lost-deal-analysis/SKILL.md) | Read CRM loss data, cluster by theme, and surface product gaps with ARR-weighted recommendations |

## Skills vs Commands

- **Skills** are standalone prompt templates for a single task. They need your context (notes, data, ideas) and produce creative/analytical output.
- **Commands** chain multiple skills into guided workflows. They orchestrate the conversation, gather context step by step, and produce a comprehensive deliverable.

## MCP requirements

Most skills work with pasted context alone. The skills below need the listed MCP server connected in Cursor or Claude Code.

| MCP | Skills |
|-----|--------|
| **lennysdata** | `what-would-lenny-do` |
| **Slack + Calendar + Drive** | `pm-weekly-brief` |
| **Linear / Jira / GitHub Issues + Drive** | `release-notes-generator`, `update-knowledge-base` |
| **Intercom + Slack + CRM + Drive** | `support-feedback-prioritization` |
| **CRM + Drive** | `churn-lost-deal-analysis` |
| **Google Drive + Browser** | `competitor-monitoring`, `market-research-digest` |
| **Salesforce / Granola / Outreach** (optional) | `know-before-you-go-perla-lobera` |

All other skills are prompt-only — no server connection required.

## Contributing

- **Improve a skill** — open a PR with changes to any `SKILL.md` file
- **Add a new skill** — create a folder under the appropriate plugin's `skills/` directory
- **Add a command** — create a `.md` file in the appropriate plugin's `commands/` directory
- **Share feedback** — open an issue describing what worked, what didn't, or what's missing

---

> **Note:** Many skills in this repo were adapted from [Amplitude's open-source builder-skills](https://github.com/amplitude/builder-skills). Original work © Amplitude. Custom skills and modifications © Vivek Sinha.
