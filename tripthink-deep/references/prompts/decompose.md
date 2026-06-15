# Phase 1: Problem Decomposition Prompt

## Orchestrator Self-Prompt)

Read the user's question and produce a `problem_card`:

```
## Problem Card

### Core Question
[Sharpened, unambiguous. Remove vagueness. If the user said "should we adopt microservices?", sharpen to "Given our 5-person team, 2-year-old Django monolith, and 3-month delivery cycles, should we incrementally extract services or rebuild as microservices?"]

### Constraints
- [What's out of scope]
- [What's non-negotiable]
- [Budget / time / team constraints]

### Success Criteria
A good answer must:
1. [Criterion 1]
2. [Criterion 2]
3. ...

### Anticipated Axes of Disagreement
Classify each potential disagreement using the taxonomy in frameworks/axes_of_disagreement.md:

| Axis | Type | Why Models Might Disagree |
|------|------|--------------------------|
| ... | empirical / definitional / value / scope | ... |
```

Rules:
- If the user's question is too vague, ASK for clarification before proceeding. Don't guess.
- If the question contains hidden assumptions, surface them in the problem card.
- Keep the problem card concise — it's a framing document, not an essay.
