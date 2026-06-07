# Speaker Notes — Examples

## Example: weak vs strong (same slide)

**Slide content:** Architecture — Sources → Kafka → Flink → Pinot → Dashboard

### Weak (avoid)

```
- Walk through architecture
- Kafka decouples
- Flink processes
- Pinot queries
- Mention scale
```

### Strong (target)

```
## Slide 6 — The Canonical Pipeline

**~4 min**

We've talked about *why* freshness matters. This is the *how* — and you'll see this
exact spine five more times tonight with different numbers attached.

Walk left to right. Sources — apps, IoT, web — emit events, not nightly CSVs.
Kafka is the shock absorber: producers don't wait on your Flink job, and you can
replay after a bug. Stream processing is where joins and windows live — stateless
steps scale easily; stateful joins are where design gets hard.

The box textbooks skip is real-time OLAP — Pinot, Druid, ClickHouse — because
stream output still isn't a dashboard. Notice the branch down to the lake and
Snowflake: same Kafka topic, seconds for ops, hours for ML. One log, two speeds.

When we get to [next case study], watch for which path each metric uses.
```

---

## Example: flag on visual slide

```markdown
## Slide 8 — Data Complexity Diagram

**~2 min**

⚠️ NEEDS YOUR INPUT — full-bleed diagram; labels read from image, not slide text.

On the left is the operational estate — dozens of microservices and databases with
spaghetti integrations. On the right, analytical copies in marts and warehouses.
The point: every new pipe adds latency and truth drift. Kafka is the industry's
answer to "emit once, consume many."

Bridge: "Let me make this concrete with three deployments at different scale."
```

---

## Example: deep-dive case study transition

```markdown
[End of slide 14]

Charter is internal ops at modem-fleet scale. Our last case flips the audience —
external customers, financial accuracy, sub-second dashboards. Same company as
the crash story, different freshness budget and blast radius if we're wrong.
```
