---
name: create-speaker-notes
description: >-
  Creates detailed, flowing speaker notes for presentation decks (PPTX, Google
  Slides, Keynote). Extracts slide content, writes narration with transitions,
  flags unclear slides, and optionally embeds notes in the deck. Use when the user
  asks for speaker notes, presenter script, talk track, narration for slides,
  or notes for a webinar, lecture, or pitch deck.
---

# Create Speaker Notes

Generate **spoken narration** for slide decks — not bullet prompts. Notes should read like a coherent talk with explicit transitions, audience-appropriate depth, and honest flags where slide content is ambiguous.

## When to apply

- User references a `.pptx`, Google Slides URL, or slide export
- User asks for speaker notes, presenter script, talk track, or narration
- User wants notes embedded in PowerPoint/Google Slides speaker-notes pane

## Before writing — gather context

Ask or infer from the request (do not block on missing items; use sensible defaults and note assumptions):

| Input | Default if unknown |
|-------|-------------------|
| Audience (technical level, role) | Mixed professional audience |
| Session duration | ~1 min per slide, adjusted for dense sections |
| Tone | Conversational expert — precise, human, not salesy |
| Business vs technical mix | Match audience; go deeper on architecture/numbers when slides show them |
| Sections to emphasize | User-named topics or longest slide groups |
| Output location | `planning/speaker-notes.md` in project, or path user gives |
| Embed in deck? | Yes if source is `.pptx` unless user says markdown-only |

Record assumptions in a short header at the top of the output file.

## Workflow

Copy and track progress:

```
Speaker notes progress:
- [ ] Step 1: Extract slide content
- [ ] Step 2: Map deck structure and narrative arc
- [ ] Step 3: Draft notes slide-by-slide
- [ ] Step 4: Add transitions, timing, flags appendix
- [ ] Step 5: Write markdown deliverable
- [ ] Step 6: Embed in PPTX (if applicable)
```

### Step 1: Extract slide content

**PPTX (preferred):** Run the extraction script:

```bash
python ~/.cursor/skills/create-speaker-notes/scripts/extract_slides.py \
  "path/to/deck.pptx" \
  --output /tmp/slide-extract.txt \
  --images-dir /tmp/slide-images
```

Read `/tmp/slide-extract.txt`. For slides with little or no text, read exported images from `--images-dir` (the script saves pictures per slide).

**Google Slides:** Try public export without auth:

```bash
# Plain text (slide order)
curl -sL "https://docs.google.com/presentation/d/{FILE_ID}/export?format=txt" -o /tmp/slides.txt

# PPTX for full extraction
curl -sL "https://docs.google.com/presentation/d/{FILE_ID}/export?format=pptx" -o /tmp/slides.pptx
python ~/.cursor/skills/create-speaker-notes/scripts/extract_slides.py /tmp/slides.pptx
```

If export fails (private doc), ask user to share the file locally or grant access.

**Other inputs:** PDF/images — extract text with available tools; read images for diagram-heavy slides.

Also collect: existing speaker notes on slides, nearby `planning/` or `context/` docs, and user-stated constraints.

### Step 2: Map deck structure

Before writing prose, identify:

1. **Opening** — title, agenda, speaker intro
2. **Core argument** — one sentence the talk proves
3. **Sections** — group slides; note which are case studies, demos, or deep dives
4. **Visual-only slides** — diagrams, screenshots, duplicate titles
5. **Numbers worth anchoring** — latency, QPS, scale, business outcomes
6. **Close** — summary, Q&A, CTA

Plan **transitions** between sections so the talk feels like one story (e.g. link case study N to case study N+1 via a shared pattern or escalating stakes).

### Step 3: Write notes per slide

Follow the per-slide template in [reference.md](reference.md).

**Style rules:**

- Write **first person** as the presenter ("I'll show…", "Let me walk left to right…")
- **Flowing paragraphs** — 150–400 words per typical content slide; longer for deep-dive sections user cares about
- **Transitions** — end slides with a bridge sentence to the next topic when the section changes
- **Technical depth** — when slides show architecture or metrics, explain *why* the number matters, not just repeat it
- **Business depth** — tie features to user/workflow outcomes ("who acts on this data, how fast, what if we're wrong?")
- **Do not** read bullet lists verbatim; interpret and narrate
- **Do not** invent facts, quotes, or metrics not on the slide or in provided sources; search or flag instead

**Flag unclear slides** with:

```markdown
⚠️ NEEDS YOUR INPUT — [one-line reason]
```

Use when: slide is image-only, duplicate of adjacent slide, contradictory numbering, inferred diagram labels, or missing context only the presenter knows.

### Step 4: Timing and appendix

- Add `**~X min**` per slide or section; total should ≈ user's duration
- Append **Slide flags summary** table and **suggested timing** table
- List **sources** if external blogs/docs were used

### Step 5: Write markdown deliverable

Default path: `planning/speaker-notes.md` (or user path). Use structure from [reference.md](reference.md).

### Step 6: Embed in PPTX (optional)

If user wants notes in the deck or source is local `.pptx`:

```bash
python ~/.cursor/skills/create-speaker-notes/scripts/inject_notes.py \
  "path/to/deck.pptx" \
  "path/to/speaker-notes.md" \
  --output "path/to/deck-with-notes.pptx"
```

Omit `--output` to update in place. Markdown must use `## Slide N` headers (see reference).

For **Google Slides**, deliver markdown; tell user to paste into Notes pane or re-import via PPTX round-trip.

## Quality checklist

Before finishing:

- [ ] Every slide has a `## Slide N` section (including title and thank-you)
- [ ] Narration connects across sections — no abrupt topic jumps
- [ ] Unclear slides are flagged, not silently guessed
- [ ] Timing sums to requested duration (±10%)
- [ ] Assumptions documented in file header
- [ ] PPTX injection ran without errors (if requested)

## Additional resources

- Per-slide template, markdown structure, flag rules: [reference.md](reference.md)
- Short before/after example: [examples.md](examples.md)
