# Phase 3: Evidence Acquisition

## Orchestrator Instructions

For each gap in the priority register, dispatch evidence gathering.

See `verify_handoff.md` for the handoff template to use with deep-research or web search.

### Subordinate Mode

For each gap:
1. Invoke `/deep-research` scoped to that single question
2. From the research report, extract evidence items
3. Grade each source (primary/secondary/tertiary/llm-recall)
4. Record polarity (supports/contradicts/neutral) per hypothesis

### Lightweight Mode

For each gap:
1. `WebSearch` with the gap question as query
2. `WebFetch` top 2-3 results
3. Extract specific claims, not general summaries
4. Grade and record polarity

### Post-hoc Mode

For each gap:
1. Search the existing research report for relevant sections
2. Extract claim-source pairs
3. Flag gaps that the existing report doesn't cover → these become UNFILLABLE

### Evidence Entry Format

```
## Gap G1: [Question]

### Source 1
- URL: [url]
- Quality: primary
- Claim: [exact quote or specific paraphrase]
- Polarity: supports H1, contradicts H3

### Source 2
...
```

### Quality Gate

- Each gap has ≥1 source with grade
- LLM-recall sources MUST be flagged explicitly: `[QUALITY: llm-recall — LOW CONFIDENCE]`
- If zero sources found for a gap → mark `UNFILLABLE`, document why, move to next
- Contradictory evidence pairs (two sources disagreeing) → both preserved, flag as `[CONFLICT]`
