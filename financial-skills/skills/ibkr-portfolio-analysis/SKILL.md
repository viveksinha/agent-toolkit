---
name: ibkr-portfolio-analysis
description: Parse an IBKR Activity Statement CSV and render a rich portfolio analysis canvas. Use when the user shares an IBKR export file, asks to analyze their IBKR portfolio, or mentions an IBKR activity statement. Always produces a canvas.
---

# IBKR Portfolio Analysis

## Step 1 — Read and parse the CSV

Read the file. IBKR CSVs are section-based: every row starts with a section name and `Header` or `Data`.

**Open Positions** (`Summary` rows only):
```
col 5: Symbol | col 7: Qty | col 9: Cost Price | col 10: Cost Basis
col 11: Close Price | col 12: Value | col 13: Unrealized P/L
```

**Net Asset Value** (`Data` rows):
```
col 2: "Cash" | "Stock" | "Total" → col 3: Prior, col 4: Current Long, col 6: Current Total
```

**Trades** (`Order` rows):
```
col 5: Symbol | col 6: Date/Time | col 7: Qty | col 8: T.Price | col 10: Proceeds | col 11: Comm/Fee
```

**Grant Activity** (`Data` rows, if present):
```
col 1: Symbol | col 4: Award Date | col 5: Vesting Date | col 6: Qty | col 7: Price | col 8: Value
```

**Statement** section: Period date (`col 3` where `col 2 == "Period"`), Account (`col 2 == "Account"`).

Skip `SubTotal`, `Total`, `Total (All Assets)`, `Lot` rows.

Strip commas from quoted numbers like `"1,234.56"` before parsing as float.

## Step 2 — Write the canvas

Canvas path: `<<workspace>>/canvases/ibkr-portfolio.canvas.tsx` (use the current Cursor project's `canvases/` folder).

Use the template below. Replace the inline data arrays and summary constants with values parsed from the file. Example values in the template are fictional placeholders only.

```tsx
import {
  Stack, Row, Grid, H1, H2, Text, Stat, Table, Card, CardHeader, CardBody,
  Pill, Divider, BarChart, Callout, useHostTheme,
} from "cursor/canvas";

const PERIOD  = "<<period from Statement section>>";
const ACCOUNT = "<<account number>>";

// One entry per Open Position Summary row, sorted by value descending
const positions = [
  { symbol: "FOO", name: "Example Corp", qty: 10, costBasis: 1000.00, value: 1100.00, pl: 100.00 },
  // ... all positions
];

// Trades (Order rows only)
const trades = [
  { symbol: "BAR", qty: 5, price: 50.00, total: 250.00 },
  // ...
];

// Grant Activity rows (omit section if none)
const grants = [
  { symbol: "XYZ", qty: 20, price: 25.00, value: 500.00, vestingDate: "2030-01-01" },
];

const TOTAL_NAV    = <<Net Asset Value Total current>>;
const TOTAL_STOCKS = <<Net Asset Value Stock current>>;
const TOTAL_CASH   = <<Net Asset Value Cash current>>;
const TOTAL_COST   = <<sum of all position costBasis>>;
const TOTAL_PL     = <<sum of all position pl>>;
const TOTAL_RETURN = ((TOTAL_PL / TOTAL_COST) * 100).toFixed(2);

const fmt = (n: number) =>
  "$" + Math.abs(n).toLocaleString("en-US", { minimumFractionDigits: 0, maximumFractionDigits: 0 });

const fmtPct = (n: number) => (n >= 0 ? "+" : "\u2212") + Math.abs(n).toFixed(1) + "%";

const top10Value   = [...positions].sort((a, b) => b.value - a.value).slice(0, 10);
const top12AbsPL   = [...positions].sort((a, b) => Math.abs(b.pl) - Math.abs(a.pl)).slice(0, 12);

export default function IBKRPortfolio() {
  useHostTheme();
  return (
    <Stack gap={24} style={{ padding: 24 }}>

      <Row align="center" justify="space-between">
        <Stack gap={4}>
          <H1>IBKR Portfolio</H1>
          <Text tone="secondary">{PERIOD} · Account {ACCOUNT} · {positions.length} positions</Text>
        </Stack>
        <Pill tone={TOTAL_PL >= 0 ? "success" : "deleted"} active>
          {(TOTAL_PL >= 0 ? "+" : "\u2212") + TOTAL_RETURN + "% total return"}
        </Pill>
      </Row>

      <Grid columns={5} gap={16}>
        <Stat value={fmt(TOTAL_NAV)}    label="Total NAV" />
        <Stat value={fmt(TOTAL_STOCKS)} label="Stock Value" />
        <Stat value={fmt(TOTAL_CASH)}   label="Cash" />
        <Stat value={(TOTAL_PL >= 0 ? "+" : "\u2212") + fmt(TOTAL_PL)} label="Unrealized P/L"   tone={TOTAL_PL >= 0 ? "success" : "danger"} />
        <Stat value={(TOTAL_PL >= 0 ? "+" : "") + TOTAL_RETURN + "%"}  label="Portfolio Return" tone={TOTAL_PL >= 0 ? "success" : "danger"} />
      </Grid>

      <Divider />

      <Grid columns={2} gap={16}>
        <Card>
          <CardHeader>Top 10 Holdings by Value (USD)</CardHeader>
          <CardBody>
            <BarChart
              categories={top10Value.map(p => p.symbol)}
              series={[{ name: "Market Value", data: top10Value.map(p => Math.round(p.value)) }]}
              height={240}
              horizontal
            />
          </CardBody>
        </Card>

        <Card>
          <CardHeader>Unrealized P/L — Top 12 by Magnitude (USD)</CardHeader>
          <CardBody>
            <BarChart
              categories={top12AbsPL.map(p => p.symbol)}
              series={[
                { name: "Gain", data: top12AbsPL.map(p => Math.round(Math.max(0,  p.pl))), tone: "success" },
                { name: "Loss", data: top12AbsPL.map(p => Math.round(Math.max(0, -p.pl))), tone: "danger"  },
              ]}
              height={240}
              horizontal
              stacked
            />
          </CardBody>
        </Card>
      </Grid>

      <Divider />

      <H2>All Holdings</H2>
      <Table
        headers={["Symbol", "Name", "Qty", "Cost Basis", "Market Value", "P/L $", "P/L %"]}
        rows={[...positions].sort((a, b) => b.value - a.value).map(p => {
          const pct = (p.pl / p.costBasis) * 100;
          return [
            <Text weight="semibold">{p.symbol}</Text>,
            <Text tone="secondary" size="small">{p.name}</Text>,
            <Text size="small">{p.qty}</Text>,
            <Text size="small">{fmt(p.costBasis)}</Text>,
            <Text size="small">{fmt(p.value)}</Text>,
            <Pill size="sm" tone={p.pl >= 0 ? "success" : "deleted"}>
              {(p.pl >= 0 ? "+" : "\u2212") + fmt(p.pl)}
            </Pill>,
            <Pill size="sm" tone={p.pl >= 0 ? "success" : "deleted"}>{fmtPct(pct)}</Pill>,
          ];
        })}
        columnAlign={["left", "left", "right", "right", "right", "right", "right"]}
        rowTone={[...positions].sort((a, b) => b.value - a.value).map(p =>
          p.pl >= 1000 ? "success" as const : p.pl <= -300 ? "danger" as const : undefined
        )}
        striped
        stickyHeader
      />

      <Divider />

      <H2>Trades — {PERIOD}</H2>
      {/* Update the Callout text to match actual trade count, total deployed, and commissions */}
      <Callout tone="info" title="<<N>> positions opened">
        Deployed <<$X>> across <<N>> stocks. Commission: <<$Y>>.
        {grants.length > 0 && ` Stock grant: ${grants[0].qty} ${grants[0].symbol} shares vested at $${grants[0].price} = $${grants[0].value} (vesting ${grants[0].vestingDate}).`}
      </Callout>

      <Table
        headers={["Symbol", "Action", "Qty", "Trade Price", "Deployed"]}
        rows={trades.map(t => [
          <Text weight="semibold">{t.symbol}</Text>,
          <Pill size="sm" tone="info">BUY</Pill>,
          t.qty,
          "$" + t.price.toFixed(3),
          fmt(t.total),
        ])}
        columnAlign={["left", "left", "right", "right", "right"]}
      />

    </Stack>
  );
}
```

## Notes

- Sort `positions` by `value` descending before writing (matches table order).
- `name` is not in the CSV — use the `Description` from the `Financial Instrument Information` section, or leave as the symbol if absent.
- Negative `qty` in Trades means sell; use `<Pill tone="warning">SELL</Pill>` for those rows.
- If no trades occurred that day, omit the Trades section entirely.
- After writing the canvas, link it to the user as `[ibkr-portfolio](<<canvas path>>)`.
