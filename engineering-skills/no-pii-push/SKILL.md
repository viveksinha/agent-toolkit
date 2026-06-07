---
name: no-pii-push
description: >-
  Global git safety gate before commit or push in any repository. Scan for PII,
  secrets, financial exports, stock tickers, and portfolio metadata. Refuse and
  alert on any match. Use when committing, pushing, publishing, or checking if
  content is safe to publish.
---

# No PII, secrets, or portfolio metadata in git

**Applies globally** — every repository. Before any commit or push, scan for personally identifiable information, secrets, financial data, **stock tickers**, and **portfolio metadata**. Low-risk PII still counts.

## When to activate

- User asks to commit, push, or publish (any repo)
- User says "check for PII", "scan for secrets", "is this safe to push"
- Another rule or workflow requests a git push
- You are about to stage files that may contain exports, env files, credentials, or skill docs with real holdings

## Required scan

**agent-toolkit** (this repo):

```bash
scripts/check-pii.sh                    # staged files
scripts/check-pii.sh path/to/file ...   # specific files
```

**Any other repository:** run that repo's scanner if it exists, or manually verify every category in **Block list** below on all files being committed or pushed.

**Do not commit or push** until the scan exits 0.

## Block list

| Category | Examples |
|----------|----------|
| Secrets | API keys (`ghp_`, `sk-`, `AKIA`, `AIza`, `xoxb-`), bearer tokens, passwords, `.pem` / `.key` files |
| Credential files | `.env`, `.env.*`, `credentials.json`, `secrets.yaml`, `*.cookie` |
| Contact PII | Email addresses, phone numbers, physical addresses |
| Identity | SSN, tax IDs, government IDs, names tied to account data |
| Financial accounts | Account/routing numbers, credit cards, brokerage IDs (e.g. IBKR `U########`) |
| Financial exports | IBKR statements, portfolio CSVs/XLSX, Trendlyne `*multigroup*.xlsx` |
| **Stock tickers** | Real symbols in `THEME_CLUSTERS`, ticker arrays, `TICKER + TICKER` lists — use `TICKER_A` / `FOO` in git |
| **Portfolio metadata** | Holding counts (`NN holdings`), position weights for named symbols, demat qty, P&L tied to your book |
| **Stock clusters** | Thematic groups with your real tickers — use `Theme A` + placeholders in committed files |
| Path leakage | Absolute paths with personal email or account name; paths to personal export folders |

**Allowed:** `TICKER_A`, `FOO`, `BAR`, `XYZ`, `EXAMPLE`, `REDACTED`, `<<placeholder>>`, `@example.com`, generic sizing rules without real symbols/counts, public sector category names without your weights.

## On failure — alert and stop

1. **Refuse** the commit or push
2. Print **PII/SECRET ALERT** for each file and match type
3. Suggest remediation: redact to placeholders, remove counts/weights, `.gitignore` exports, env vars for paths, local-only overlay for `THEME_CLUSTERS`
4. Re-scan after fixes; only proceed when clean
5. Do not use `--no-verify` unless the user explicitly overrides after reading the alert

## Git hook (optional enforcement)

```bash
./scripts/install-git-hooks.sh
```

## Never commit

`.env`, `*.pem`, `*.key`, `*.cookie`, `credentials*.json`, brokerage exports, portfolio spreadsheets, `*multigroup*.xlsx`, tax documents.
