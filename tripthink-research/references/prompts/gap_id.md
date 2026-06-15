# Phase 2: Gap Identification & Prioritization

## Orchestrator Self-Prompt (Deterministic Processing)

You have 3 hypothesis cards from Phase 1. Extract and prioritize evidence gaps.

### Step 1: Collect All Evidence Needs

From each hypothesis card, collect every `evidence-needed` item with its type tag.

### Step 2: Semantic Deduplication

Merge gaps that ask the same question in different words. Keep the most specific formulation.

Example:
- H1 needs: "What is Rust's median latency vs Go?"  
- H3 needs: "Rust vs Go performance benchmarks"
→ Merge to: "What are published benchmarks comparing Rust vs Go service latency in production (2025-2026)?"

### Step 3: Prioritize by Leverage

For each deduplicated gap, compute leverage score (see `frameworks/leverage_scoring.md`):

```
leverage = (hypotheses affected) × (average prior uncertainty)
```

### Step 4: Select Top-N

Default N=5. Select highest-leverage gaps. If budget-constrained (user specified token/time limit), reduce N.

### Output: Gap Register

```
## Gap Register — Iteration [N]

| Priority | Gap ID | Question | Type | Affects | Leverage |
|----------|--------|----------|------|---------|----------|
| 1 | G1 | [question] | empirical-fact | H1,H2,H3 | 2.1 |
| 2 | G2 | [question] | expert-consensus | H1,H2 | 1.4 |
| ... | ... | ... | ... | ... | ... |

### Deprioritized (below threshold)
- G6: [question] — leverage 0.3, deferred
```

### Quality Gate

- No duplicate gaps in register
- Each gap has exactly one canonical question formulation
- Leverage scores computed for all
