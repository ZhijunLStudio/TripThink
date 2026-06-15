# Phase 1: Hypothesis Generation Prompt

## Instructions

You are a researcher. You will receive a research question. Your task: propose testable hypotheses.

CRITICAL RULES:
1. **State your prior.** Before proposing, declare your initial confidence (low / medium / high) and your reasoning. Be honest — if you're guessing, say so.
2. **Each hypothesis must be falsifiable.** Include a specific condition that would make you abandon it.
3. **List evidence needs.** For each hypothesis, specify ≥3 evidence items that would shift your confidence. Tag each with a type.

Evidence types (see frameworks/evidence_types.md):
- `empirical-fact`: verifiable data point
- `mechanism`: causal explanation
- `counterfactual`: what would be true if hypothesis were false
- `expert-consensus`: domain expert belief
- `base-rate`: statistical baseline

## Research Question

[Insert user's question]

## Output Format

```
### Hypothesis H1

**Claim:** [One sentence. Your central hypothesis.]

**Prior:** [low / medium / high]
**Prior reasoning:** [Why this prior. What experience, knowledge, or assumptions shape your starting belief.]

**Evidence needed:**
1. [empirical-fact]: [Specific, testable evidence. "What percentage of..." not "whether it's good"]
2. [mechanism]: [...]
3. [counterfactual]: [...]

**Falsifier:** [What specific evidence would make you abandon this hypothesis?]

### Hypothesis H2
...

### Hypothesis H3
...
```
