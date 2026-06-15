# Axes of Disagreement Taxonomy

When models disagree, classify the disagreement to understand what kind of evidence or reasoning would resolve it.

| Type | Definition | Example | Resolution |
|------|-----------|---------|------------|
| **Empirical** | Disagreement about facts or data | "Is Rust latency lower than Go?" | Evidence. Measure it. |
| **Definitional** | Disagreement about what words mean | "Is this 'microservice' or 'modular monolith'?" | Agree on definitions before proceeding. |
| **Value** | Disagreement about priorities or trade-offs | "Is speed more important than correctness?" | Surface values explicitly. No single "right" answer. |
| **Scope** | Disagreement about boundary conditions | "Does this apply to teams of 5 or only 50+?" | Narrow or expand scope, test at boundaries. |
| **Methodological** | Disagreement about how to reason | "Should we use first-principles or pattern-matching?" | Use both, compare results. |

## Usage in Phase 1

When producing the problem_card, anticipate which axes are likely to cause disagreement:

```
### Anticipated Axes of Disagreement
| Axis | Type | Why Models Might Disagree |
|------|------|--------------------------|
| ... | empirical / definitional / value / scope / methodological | ... |
```

This helps the orchestrator recognize disagreement as *structured* rather than random — and know how to resolve each type in the Converge phase.
