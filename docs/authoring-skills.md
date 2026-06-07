# Authoring and publishing skills

How to create, edit, and publish skills in agent-toolkit. The repo is the **source of truth**; Cursor loads skills from `~/.cursor/skills/` via symlinks.

---

## Scripts — what each one does

| Script | When to use |
|--------|-------------|
| [`install-cursor.sh`](../scripts/install-cursor.sh) | After editing skills **in the repo** — refreshes symlinks so Cursor sees changes |
| [`sync-from-cursor.sh`](../scripts/sync-from-cursor.sh) | When the skill landed in **`~/.cursor/skills/`** by mistake (common after chat) |
| [`publish-skills.sh`](../scripts/publish-skills.sh) | End of session — sync + install + **commit + push** to GitHub |
| [`update.sh`](../scripts/update.sh) | On another machine — `git pull` + reinstall symlinks |
| [`install-git-hooks.sh`](../scripts/install-git-hooks.sh) | Once per clone — blocks pushes that contain PII/secrets |

---

## Scenario: new skill from a chat conversation

The agent often writes to `~/.cursor/skills/my-new-skill/`. That is fine as a starting point — use the steps below to bring it into the repo.

### Step 1 — Pick a home in the repo

| If the skill is about… | Put it here |
|------------------------|-------------|
| PM, specs, discovery | `product-skills/skills/{name}/` |
| Meetings, comms, updates | `execution-skills/skills/{name}/` |
| Writing, social, content | `content-marketing-skills/skills/{name}/` |
| Engineering, automation, data | `engineering-skills/{name}/` (no `skills/` subfolder) |
| Portfolio / brokerage analysis | `financial-skills/skills/{name}/` |
| Launches | `launch-skills/skills/{name}/` |
| Growth metrics | `growth-skills/skills/{name}/` |
| Sales | `sales-skills/skills/{name}/` |

Example: a “summarize Slack threads” skill → `execution-skills/skills/slack-thread-summary/SKILL.md`

### Step 2 — Register it in the manifest

Open [`scripts/skills-manifest.conf`](../scripts/skills-manifest.conf) and add one tab-separated line:

```
slack-thread-summary	execution-skills/skills/slack-thread-summary
```

- **Left** — name Cursor sees at `~/.cursor/skills/slack-thread-summary`
- **Right** — folder path inside this repo

Plugin folders (`*-skills`) are linked automatically by `install-cursor.sh` — do **not** list them in the manifest.

### Step 3 — Pull the skill from `~/.cursor/` into the repo

From the repo root:

```bash
./scripts/sync-from-cursor.sh --dry-run   # preview what will copy
./scripts/sync-from-cursor.sh --apply     # copy files into repo
```

Skip this if the skill was already created in the repo during chat.

### Step 4 — Wire up Cursor

```bash
./scripts/install-cursor.sh
```

This symlinks the plugin folder and your new skill so `~/.cursor/skills/slack-thread-summary` points at the repo.

Restart Cursor or start a new agent chat to pick up the skill.

### Step 5 — Publish to GitHub

```bash
./scripts/publish-skills.sh "Add slack-thread-summary skill"
```

That runs sync → install → commit → push. The pre-push hook scans for PII/secrets before pushing.

Commit only, no push:

```bash
PUSH=0 ./scripts/publish-skills.sh "WIP: draft skill"
```

---

## Two paths — quick reference

### Path A — Ideal (repo-first)

Open **this repo** as your Cursor workspace. Create the skill in the right plugin folder, then:

```bash
./scripts/install-cursor.sh
./scripts/publish-skills.sh "Add my-new-skill"
```

No sync step needed.

### Path B — Reality (chat created it in `~/.cursor/`)

```bash
# 1. Add row to scripts/skills-manifest.conf
# 2. Then:
./scripts/sync-from-cursor.sh --apply
./scripts/install-cursor.sh
./scripts/publish-skills.sh "Add my-new-skill"
```

---

## Editing an existing skill

| Where you edited | What to run |
|------------------|-------------|
| In the repo | `./scripts/install-cursor.sh` |
| In `~/.cursor/skills/` by accident | `sync-from-cursor.sh --apply` then `install-cursor.sh` |
| Ready to save to GitHub | `./scripts/publish-skills.sh "Describe what changed"` |

---

## What belongs in the repo vs what does not

**Skill templates are fine** — including workflows for brokerage analysis, portfolio refresh, etc. Those live here as generic `SKILL.md` files (no real holdings, account numbers, or personal paths). Redact examples before publishing.

**Do not commit:**

| Type | Why |
|------|-----|
| **Data files** | Activity statements, portfolio CSVs/XLSX, exports — blocked by `.gitignore` and the pre-push PII scan |
| **Secrets** | `.env`, API keys, cookies, credentials |
| **Personal paths** | Absolute paths with your email or username in the folder name |
| **Personal holdings data** | Export files, real tickers in `THEME_CLUSTERS`, account numbers — keep out of git; use placeholders in committed skill files |
| **Project-local skill symlinks** | Skills that symlink into another repo — keep them in that project |
| **Machine-only skills** | Anything you do not want on GitHub — leave in `~/.cursor/skills/` and omit from the manifest |

The PII hook scans for **actual** secrets and identifiers (emails, tokens, account numbers, personal paths). It does not block generic words like “portfolio” or “brokerage” in documentation.

See also: [no-pii-push rule](../rules/no-pii-push.mdc) and [no-pii-push skill](../engineering-skills/no-pii-push/SKILL.md).

---

## Cheat sheet

```
New skill from chat:
  1. skills-manifest.conf  →  add one line
  2. sync-from-cursor --apply  →  copy home → repo
  3. install-cursor  →  symlink repo → home
  4. publish-skills  →  commit + push

Edit existing skill in repo:
  install-cursor → publish-skills
```
