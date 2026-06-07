# Speaker Notes — Reference

## Output file header

```markdown
# Speaker Notes — [Deck Title]

**Deck:** `path/to/deck.pptx`  
**Session:** [date, duration, format]  
**Audience:** [role, technical level]  

**Assumptions:** [anything inferred — duration, audience, emphasis]  

**How to use:** Spoken narration, not bullets. Slides marked ⚠️ need presenter verification.
```

---

## Per-slide section template

```markdown
## Slide N — [Short title from slide]

**~X min**

[Opening hook or transition from previous slide — 1–2 sentences if section changed]

[Main narration — flowing paragraphs. Cover:
- What the audience sees and why it matters
- Business context (who cares, what decision, cost of delay/error)
- Technical context when relevant (architecture, data flow, scale numbers)
- Tie-back to earlier mental models if the deck builds a thread]

[Optional: "Say this line" for key phrases on the slide]

[Closing bridge to next slide — when section or case study changes]
```

### Slide-type guidance

| Slide type | Emphasis |
|------------|----------|
| Title | Energy, promise, scope, logistics |
| Agenda / landscape | Map the journey; name what you'll skip |
| Concept / framework | One mental model; example from audience domain |
| Architecture diagram | Walk left-to-right; "why this box exists" |
| Case study intro | Problem → outcome → architecture preview |
| Metrics / scale | Say numbers slowly; compare to familiar scale |
| Screenshot / product UI | What user sees; what pipeline powers it |
| Visual-only diagram | Describe paths on screen; flag if labels unclear |
| Duplicate title | Note delivery strategy (merge with next/prior) |
| Thank you / Q&A | Seed 2–3 questions if room is quiet |

---

## Transition patterns

Use explicit bridges — pick one that fits:

- **Pattern escalation:** "Same spine as [previous], but now the freshness budget is tighter."
- **Audience shift:** "Last case was internal engineers; this one is external customers."
- **Scale jump:** "If that felt big, the next number is two orders of magnitude larger."
- **Concept callback:** "Remember the decay curve — this slide is that curve as an architecture."
- **Product vs plumbing:** "You know what the partner sees; now let's open the hood."

---

## Flag rules (⚠️ NEEDS YOUR INPUT)

| Situation | Flag text pattern |
|-----------|-------------------|
| Image-only, no extractable text | "Full-bleed visual — narration inferred from image" |
| Duplicate slide title/content | "Duplicate of slide N — recommend merging delivery" |
| Wrong note on slide (copy-paste error) | "Existing note mismatches slide — replaced/flagged" |
| Metric not on slide | "Metric from external source [link] — verify before citing" |
| Inferred diagram label | "Label inferred — confirm against slide" |
| Footer/slide number mismatch | "Cosmetic numbering only" |

Always include an appendix table listing all flagged slides.

---

## Timing table (appendix)

```markdown
## Suggested timing ([total] min)

| Block | Slides | Minutes |
|-------|--------|---------|
| [Section name] | 1–5 | 10 |
| ... | ... | ... |
```

Rule of thumb: title/section headers ~1–2 min; dense case studies ~4–6 min; Q&A remainder.

---

## Markdown → PPTX injection format

The inject script parses:

```markdown
## Slide 1 — Optional title

**~2 min**

Narration paragraphs...
```

- Header regex: `^## Slide (\d+)`
- Timing lines (`**~X min**`) are stripped before injection
- Section stops at next `---` or `## Appendix`

---

## Audience calibration

| Audience | Business : technical | Language |
|----------|---------------------|----------|
| Executive | 70 : 30 | Outcomes, risk, cost; minimal jargon |
| Mixed professional | 50 : 50 | Define terms once; analogies from work |
| Technical (eng/data) | 30 : 70 | Architecture, tradeoffs, numbers; still tie to "why" |
| Academic (course) | 40 : 60 | Link to curriculum; invite questions; no code unless asked |

When user says "technical audience," still add business stakes — decisions and failure modes.

---

## Anti-patterns

- Bullet dumps mirroring slide text
- Abrupt section changes without bridges
- Inventing customer names, metrics, or quotes
- Same length for every slide regardless of content
- Ignoring existing speaker notes (merge or explicitly override)
- Skipping title, appendix, or Q&A slides
