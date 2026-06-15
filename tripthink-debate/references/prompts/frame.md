# Phase 1: Proposition Framing Prompt

## Orchestrator Self-Prompt

Read the user's proposition and produce a `proposition_card`:

```
## Proposition Card

### Canonical Proposition
[One sharp, unambiguous sentence. If the user said "we should use Rust for everything", sharpen to "All new backend services at [company] should be written in Rust rather than Go/Python, starting Q3 2026."]

### Scope
- In bounds: [what this debate covers]
- Out of bounds: [what this debate does NOT cover]

### Falsification Condition
What would prove this proposition wrong?
[Specific, testable condition. Not "if it doesn't work" but "if Rust services show >20% longer time-to-ship compared to equivalent Go services over 6 months."]

### Success Criteria
- For (Steelman): [what winning looks like — the proposition survives with all cruxes intact]
- Against (Critic): [what winning looks like — at least one load-bearing crux is falsified]
```

Rules:
- If the user's proposition is too vague, ASK to sharpen it. "We should do X" → "We should do X under conditions Y, with constraints Z."
- The falsification condition is critical — without it, the debate is unfalsifiable.
