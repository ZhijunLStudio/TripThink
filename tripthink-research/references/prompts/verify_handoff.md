# Phase 3: Evidence Acquisition Handoff

## For the Orchestrator

For each gap in the prioritized register, dispatch evidence gathering:

### Subordinate Mode (deep-research)

Invoke `/deep-research` scoped to the single gap question:

```
/deep-research [gap question, scoped to one specific evidence need]
```

Wait for the research report. Extract the evidence items and grade them.

### Lightweight Mode (WebSearch + WebFetch)

```
1. WebSearch: [gap question as search query]
2. WebFetch top 2-3 results for full text
3. Extract claims, grade sources
```

### Evidence Entry Format

For each gap, produce:

```
## Gap [GID]: [Gap Question]

### Source 1
- URL: [url]
- Quality: primary / secondary / tertiary / llm-recall
- Claim: [specific factual claim from source]
- Polarity: supports / contradicts / neutral
  - Affected hypotheses: [H1, H2, ...]
  - Direction: strengthens / weakens / no shift

### Source 2
...
```

### Quality Gate

- Each gap must have ≥1 source with quality grade
- LLM-recall sources MUST be flagged
- If zero retrievable sources found → mark gap as `UNFILLABLE`, move to next
