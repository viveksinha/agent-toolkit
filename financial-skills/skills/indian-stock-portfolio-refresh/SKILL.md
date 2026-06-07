---
name: indian-stock-portfolio-refresh
description: Refreshes equity portfolio canvases from the latest Excel export. Launches parallel agents to update valuation, risk, macro, and daily-actions canvases. Use when the user updates their portfolio Excel file, adds holdings, wants to refresh buy/sell signals, or says "refresh my portfolio canvases", "update the stock canvases", or "re-run the portfolio analysis". Canvas basenames are configured in the user's project (e.g. portfolio-valuation-analysis, portfolio-risk-analysis, portfolio-macro-outlook, daily-stock-actions).
---

# Indian Stock Portfolio Canvas Refresh

## Critical constraint

**All canvas data is point-in-time.** Canvases must be regenerated from a freshly updated Excel before any trade decision. Never use a canvas that is more than a day old for action decisions.

## Paths (configure per machine)

Set these before running (or export as env vars in your shell profile):

- **Canvas dir**: `<<CANVAS_DIR>>` — Cursor project `canvases/` folder for this portfolio workspace
- **Excel folder**: `<<EXCEL_DIR>>` — folder containing Trendlyne `*multigroup*.xlsx` exports
- **SDK**: `~/.cursor/skills-cursor/canvas/sdk/`
- **Extract script**: `~/.cursor/skills/indian-stock-portfolio-refresh/scripts/extract_portfolio.py`

## Step 1: Find latest Excel and extract data

```bash
# Find the most recent multigroup Excel (set EXCEL_DIR first)
XLSX=$(ls -t "$EXCEL_DIR/"*multigroup*.xlsx | head -1)

# Extract to a temp file
python3 ~/.cursor/skills/indian-stock-portfolio-refresh/scripts/extract_portfolio.py "$XLSX" > /tmp/portfolio_data.txt
```

Verify the output shows `EQUITY_COUNT` and `TOTAL_COUNT` matching your workbook. If `openpyxl` is missing: `pip3 install openpyxl`.

## Step 2: Launch 4 parallel agents

Launch all four agents simultaneously in a single message (use Task tool, `run_in_background: true` for all). Pass each agent:
- The data file path: `/tmp/portfolio_data.txt`
- The canvas file path to write
- The specific task from the sections below

### Agent 1 — Valuation canvas (`portfolio-valuation-analysis.canvas.tsx`)

**Task**: Add/update `Dur Score` and `Mom Score` columns in the full reference table. The table headers should be: `Stock | Sector | Mcap | PE TTM | Sector PE | vs Sector | NP Growth | PEG | Val Score | Dur Score | Mom Score | Assessment`. Data comes from `Trendlyne Durability Score` and `Trendlyne Momentum Score` columns in the data file.

If `portfolio-evaluation.canvas.tsx` exists, delete it (it is superseded by the valuation-analysis canvas).

### Agent 2 — Risk canvas (`portfolio-risk-analysis.canvas.tsx`)

**Task**: Full rewrite with all holdings. Key sections:

**Sector allocation** — group all equity holdings by `Sector Name`, sum `Portfolio contribution %`. Use sector groups present in the export (e.g. banking, consumer, healthcare, software, industrials).

**Cap-size mix** — Large/Mid/Small/Others (ETFs+MFs+Gold) from `Mcap Classification`.

**Dead-weight table** — cap-aware benchmarks:
- Large Cap: flag if `Relative returns vs Nifty50 year%` < −10
- Mid Cap: flag if `Relative returns vs Sector year%` < −10 (sector peers are the benchmark — Nifty Midcap 150 is the correct index but is absent from the Trendlyne export; using Nifty50 for mid-caps creates systematic distortion via large-cap style bias)
- Small Cap: flag if `Relative returns vs Sector year%` < −15

Show columns: `Ticker | Sector | Cap | vs Nifty50 1Y% | vs Sector 1Y% | Unreal P&L% | Piotroski | Flag`.
Flag labels: Large Cap → "Nifty50 lag > 10%", Mid Cap → "Sector lag > 10%", Small Cap → "Sector lag > 15%".

**Benchmark note callout** (tone "info"): Explain that Large Cap uses Nifty50, Mid/Small use sector-relative return because Nifty50 is a large-cap index that creates style bias — and that Nifty Midcap 150 would be preferred for mid-caps but is not in the data export.

**High-beta section** — list stocks with `Beta 1Year` > 1.2: `Ticker | Sector | Cap | Beta 1Y`.

**Concentration callout** (tone "warning") if Banking & Finance combined > 35% of portfolio.

---

**Hidden risk audit** — add a dedicated section titled "Portfolio-Level Hidden Risks". These go beyond sector concentration and catch risks invisible on a sector pie chart.

**1. Valuation concentration**
Count equity holdings with `PE TTM` > 40. Compute their combined `Portfolio contribution %`.
- Callout (tone "warning") if >40% of equity NAV is in PE>40 stocks: "Valuation concentration — X% of equity NAV in stocks trading >40x earnings. A macro re-rating event compresses the whole book simultaneously."
- Show table: `Ticker | Sector | PE TTM | Weight%` sorted by PE TTM descending.

**2. Factor tilt**
Compute: `avg_mom = mean(Trendlyne Momentum Score)` and `avg_val = mean(Trendlyne Valuation Score)` across all equity holdings.
- If avg_mom > 65 → Callout (tone "warning"): "Momentum-tilted portfolio — average momentum score {avg_mom}. Holdings move together when momentum unwinds."
- If avg_val < 35 → Callout (tone "warning"): "Growth/expensive tilt — average valuation score {avg_val}. Portfolio is skewed toward expensive stocks."
- Show a two-stat row: `Avg Momentum Score | Avg Valuation Score | Avg Durability Score`.

**3. Position drift (concentration by drift)**
List any stock where `Portfolio contribution %` > 12%.
- Callout (tone "danger") if any single stock exceeds 15%: "Single-stock concentration — {ticker} is {weight}% of NAV. Consider rebalancing."
- Table: `Ticker | Sector | Weight% | Flag`.

**4. Cyclicality / defensive imbalance**
Sum `Portfolio contribution %` for defensive sectors: FMCG, Healthcare, Pharmaceuticals, Utilities, Consumer Staples.
- If defensive weight < 10% of total equity portfolio → Callout (tone "info"): "Minimal defensive buffer — only {X}% in defensive sectors (FMCG/Healthcare/Utilities). Portfolio has no damper in a risk-off environment."

**5. Macro sensitivity distribution**
Tag each equity holding with one primary macro driver using this mapping (apply best-fit; one tag per stock):
- `Rate-sensitive`: Banking, NBFC, Real Estate, Capital Goods (debt-heavy)
- `Capex-cycle`: Infrastructure, Defence, Railways, Cement, EPC
- `Export-FX (USD)`: IT/Software, Pharma API, Specialty Chemicals (export)
- `Import-FX`: Oil & Gas (downstream), Tyres, Paints, Aviation
- `Domestic-demand`: FMCG, Retail, Consumer Durables, Auto (domestic)
- `Global-commodity`: Metals, Mining, Agri-inputs

Compute the portfolio weight per tag. Show a bar chart (`BarChart`) of macro tag weights.
- Callout (tone "warning") if any single macro tag represents >35% of equity NAV: "Macro sensitivity concentration — {X}% of equity NAV shares the same primary macro driver ({tag})."

**6. Balance sheet risk cluster**
List equity holdings with `Trendlyne Durability Score` < 40.
- Callout (tone "warning") if >3 such stocks exist: "Balance sheet risk cluster — {N} holdings have durability score <40, indicating elevated leverage or earnings quality risk."
- Table: `Ticker | Sector | Durability Score | PE TTM | Weight%`.

**7. Qualitative risk checklist (manual lookup required)**
Add a final callout (tone "info") titled "Risks requiring manual lookup — not in Trendlyne export":
```
- Promoter pledge: Check BSE shareholding for any holding with pledge >25%
- FII ownership concentration: If top FII-held stocks overlap heavily, FII exit risk clusters
- Liquidity/exit: For stocks with ADTV <₹10 Cr, check if combined weight >15% of NAV
- Timing concentration: Were >50% of positions entered in the same quarter?
- Key-man risk: Any founder-dependent company with no succession plan?
- Regulatory cluster: Multiple holdings in same regulatory jurisdiction (US FDA, RBI, SEBI)?
```

### Agent 3 — Macro canvas (`portfolio-macro-outlook.canvas.tsx`)

**Task**: Score all equity holdings on configurable macro factors (−1 to +2 each). Use current macro context from the user or public sources — do not hardcode rates, budgets, or dates in the skill file.

Sort bar chart by composite macro score descending.

### Agent 4 — Actions canvas (`daily-stock-actions.canvas.tsx`)

**Task**: Add scoring and position-sizing columns. **Do NOT change existing action labels (BUY/HOLD/WATCH/REDUCE) or thesis text** — only prepend sizing rationale and add new columns.

**Composite Signal Score** (0–10):
```
val  = (Trendlyne Valuation Score / 100) × 3
mom  = (Trendlyne Momentum Score / 100) × 3
dur  = (Trendlyne Durability Score / 100) × 2
peg  = PEG < 1 → 1.0; PEG 1–2 → 0.5; PEG > 2 or null → 0
n50  = vs Nifty50 > 0 → 1.0; vs Nifty50 < −15 → −0.5; else 0
composite = clamp(val + mom + dur + peg + n50, 0, 10)
```

**Position sizing** (total portfolio = sum of all `Current Value`):
- BUY target: 4% of total portfolio
- REDUCE target: 2% of total portfolio
- `sharesToAct = round(|targetValue − currentValue| / currentPrice)`
- HOLD/WATCH: no action, show "—"

**Thesis prefix** format:
- BUY add: `"Add ~N shares @ ₹P → grow W% → 4.0% (+₹XL). [existing thesis]"`
- BUY at target (already ≥ 4%): `"At target size (W%). [existing thesis]"`
- REDUCE: `"Sell ~N shares @ ₹P → trim W% → 2.0% (−₹XL). [existing thesis]"`
- HOLD: `"Position at W% — maintain. [existing thesis]"`
- WATCH: `"Position at W% — monitor. [existing thesis]"`

**New table columns**: `Val | Mom | Dur | Score | Wt% | Held | Qty Δ | ₹ Impact | Day Chg% | Unreal P&L% | Thesis`

- `Held` = current shares held in demat (the `qty` field from the data)
- `Qty Δ` = shares to add (+N, green) or exit (−N, red); `—` for HOLD/WATCH; "—" for BUY already at target size

**Callouts at top**:
- Macro Pulse (update with current repo rate, monsoon, trade deal status)
- Top Conviction Buys: tickers with composite ≥ 7.0 (tone "success")
- Reduce / Exit: tickers with composite < 3.0 (tone "warning")

**Concentration-override actions callout** (tone "danger") — MANDATORY, always include:

Individual composite scoring only captures stock-level signals. This callout surfaces portfolio-level actions that override individual HOLDs. Run these checks on every refresh and generate concrete actions:

1. **Thematic cluster (example)**: For each cluster in `THEME_CLUSTERS` (see below), sum member weights. If total exceeds your warn threshold: identify the largest-weight / weakest-composite member → generate a REDUCE action with trim-to-target sizing. Show ticker, shares, ₹ freed, and post-trim cluster weight.

2. **Sector cluster (example)**: Sum weights for a sector group (e.g. banking + NBFC). If total exceeds your threshold: flag the weakest-composite member above minimum weight for REDUCE with trim-to-target sizing.

3. **Single-sector sub-cluster** (same business model, different tickers): For any group of 2+ holdings that share an identical revenue driver, if combined weight exceeds threshold: flag the largest-weight / weakest-composite member for a trim action. Show cluster total before and after trim.

4. **Exit proceeds redeployment**: If any stocks are flagged EXIT this refresh, compute total ₹ freed. If defensive-buffer weight is below your target, state how to redeploy into defensive names or top composite BUYs.

5. **Position trip-wires**: List any stock above your watch weight with a rule like "Trim to X% if weight crosses Y%." No immediate action needed — trip-wires must be visible.

These override actions must appear as a separate, prominent callout BEFORE the stock table. They are not optional commentary — they are the primary portfolio management output for the session.

## Step 3: Verify after completion

Check each canvas status:
```bash
ls -la <canvas_dir>/*.canvas.tsx
cat <canvas_dir>/*.canvas.status.json 2>/dev/null
```

Confirm: 4 canvas files exist, `portfolio-evaluation.canvas.tsx` is gone.

## Canvas SDK rules (pass to all agents)

- Import **only** from `cursor/canvas`
- No `fetch()`, no network, no relative imports, no npm packages
- `BarChart`: `categories: string[]`, `series: { name, data: number[], tone? }[]`
- `Pill` tones: `"neutral" | "success" | "warning" | "deleted" | "info"` — no `"danger"`
- `Table rowTone`: supports `"danger"`, `"warning"`, `"success"`
- `Callout` tone: `"info" | "warning" | "danger" | "success"`
- All data inline — default export the top-level component

## Table sort order (mandatory — all canvases, all tables)

Every table or grouped list of stocks must be sorted:

1. **Primary: Verdict/action** in this fixed order — `Strong Hold` → `Hold` → `Reduce` → `Exit`
   - For actions canvases where the field is labelled differently, map: `BUY` → 0, `HOLD` → 1, `WATCH` → 2, `REDUCE` → 3, `EXIT` → 4
2. **Secondary: Stock name alphabetically (A→Z)** within each group

Bar charts (score or signal sorted) are exempt — sort those by value descending.

```ts
const verdictOrder: Record<string, number> = { 'Strong Hold': 0, 'Hold': 1, 'Reduce': 2, 'Exit': 3 };
const sortedByVerdict = [...stocks].sort((a, b) => {
  const verdictDiff = verdictOrder[a.verdict] - verdictOrder[b.verdict];
  if (verdictDiff !== 0) return verdictDiff;
  return a.name.localeCompare(b.name);
});
// Use sortedByVerdict for tableRows / tableRowTones
// Use score-sorted array only for BarChart categories/values
```

## Step 4: Backup canvases

After any refresh, run:

```bash
bash ~/.cursor/skills/indian-stock-portfolio-refresh/scripts/backup_canvases.sh
```

Set `CANVAS_DIR` and `BACKUP_DIR`, then run the script. It copies all 4 `.canvas.tsx` files with today's date prefix and keeps the last 7 days per canvas automatically. Run this even after a partial (actions-only) refresh.

---

## Daily quick refresh (actions canvas only)

For a daily price/signal refresh, run only Agent 4 — skip Agents 1–3. Steps:

1. Export a fresh `YYYY-MM-DD-multigroup.xlsx` from Trendlyne and save to the ind-stocks folder
2. Run the data extraction (Step 1 above)
3. Launch **Agent 4 only** with the task spec from the "Agent 4" section above
4. Run the backup script

Trigger phrase: "just refresh actions" or "refresh daily actions canvas"

Full refresh (all 4 agents) is needed when: new stocks added, macro context has significantly changed, or it has been more than 2 weeks since the last full refresh.

## Thematic cluster concentration guard (mandatory — Agent 4)

The composite scoring model scores each stock **independently**. It is blind to the fact that two stocks may share the same underlying macro thesis, creating hidden concentration risk. Agent 4 must compute and surface thematic cluster weights **before** emitting BUY ADD recommendations.

### Step: compute thematic cluster totals

After assembling all stock entries, group into the following **hard-coded thematic clusters** (these cut across sector labels):

```ts
// Configure locally — do not commit real tickers or weights to a public repo
const THEME_CLUSTERS: Record<string, string[]> = {
  'Theme A (example)': ['TICKER_A', 'TICKER_B', 'TICKER_C'],
  'Theme B (example)': ['TICKER_D', 'TICKER_E'],
  // Configure THEME_CLUSTERS in your local project — use placeholders in the repo; never commit real tickers
};
```

For each cluster compute:
- `currentPct` — sum of current portfolio weights for all tickers in the cluster
- `postActionPct` — same sum after applying all BUY ADD targets (replace each BUY ticker's current weight with 4%)

### Concentration thresholds

| Cluster type | Warn | Critical |
|---|---|---|
| Single thematic cluster (post-action) | > 9% | > 12% |
| Banking specifically (post-action) | > 14% | > 18% |

### What to do when a threshold is breached

1. **Do not suppress the BUY signal** — keep the action label as-is.
2. **Add a `Callout tone="warning"` block** above the main table titled `"Thematic Concentration Warning"` listing each breached cluster with current% and post-action%.
3. **In the thesis prefix for any BUY ADD that contributes to a breached cluster**, append: `" ⚠ Cluster at X% post-action — consider sizing to 2% instead of 4%."` — placed after the sizing line, before the main thesis text.

### Example callout

```tsx
<Callout tone="warning" title="Thematic Concentration Warning">
  <Stack gap={4}>
    <Text size="small">Theme A: 12.0% post-action — multiple holdings share the same macro driver. A sector drawdown hits all simultaneously.</Text>
    <Text size="small">Theme B (post-action): 15.0% — new BUY ADDs on a cluster already above warn threshold. Consider executing one at a time.</Text>
    <Text size="small">Theme C (post-action): 10.5% — two names in the same capex thesis despite different sector labels.</Text>
  </Stack>
</Callout>
```

### Why sector labels alone are insufficient

The Trendlyne export uses fine-grained sector names that can obscure shared risk factors — e.g. multiple asset-management names all tied to equity AUM / SIP flows, or cable and electrical names both tied to power-infra capex despite different sector labels. Always reason about **shared risk factors**, not sector names alone.

---

## What this suite does NOT cover

- Live prices (data is point-in-time from Excel — refresh Excel first)
- Earnings calendar or event triggers
- Technical analysis (MA crossovers, support/resistance)
- Tax impact of realized gains on REDUCE/EXIT actions
- Cross-stock correlation during market drawdowns (thematic cluster guard above is a partial proxy, not a full correlation matrix)
