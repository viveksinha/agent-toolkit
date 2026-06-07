---
name: human-writing-style
description: Ensures written content — documents, blogs, articles, documentation, presentations — reads like a human wrote it, not an AI. Primary rule: avoid overusing hyphens and em-dashes; use flowing, readable sentences instead. Use whenever producing or editing long-form written content.
---

# Human Writing Style

When writing a document, blog, article, documentation, or presentation, avoid using too many hyphens and em-dashes. They give an impression that it is AI-written. It should feel more like human written.

## The Hyphen Problem

AI-generated text over-relies on:
- Em-dashes to stitch clauses: *"The query ran slowly — the plan was wrong — and nobody noticed."*
- Hyphenated compound modifiers stacked together: *"a production-ready, latency-sensitive, multi-tenant system"*
- Parenthetical em-dash asides that interrupt every other sentence

These patterns are readable in isolation but become a fingerprint at volume. A human writer uses them occasionally, not as a default connector.

## What to Do Instead

**Break it into two sentences.**
Before: *"The filter applied to orders — but not to order_items — which meant the larger table scanned every partition."*
After: *"The filter applied to orders but not to order_items. The larger table scanned every partition."*

**Use a conjunction.**
Before: *"Static analysis catches plan errors — runtime stats catch operator bottlenecks."*
After: *"Static analysis catches plan errors, while runtime stats catch operator bottlenecks."*

**Rewrite the compound modifier as a clause.**
Before: *"a query-shape-aware, fingerprint-tracking background job"*
After: *"a background job that tracks query shapes and monitors fingerprints"*

## Rules

1. No more than one em-dash per paragraph. If you have two, rewrite one.
2. Hyphenate only when the compound is a standard term (e.g., `on-call`, `real-time`) or when omitting the hyphen causes ambiguity.
3. Never stack more than two hyphenated modifiers before a noun.
4. Prefer short sentences over long ones held together by em-dashes.
5. Read the paragraph aloud. If you pause awkwardly at a dash, rewrite the sentence.
