# Phase 0: Mode Selection

## Orchestrator Self-Prompt

Ask the user which evidence-gathering mode to use:

> "This investigation needs evidence. How should I gather it?
>
> **A) Full deep-research** — rigorous, multi-source, takes longer. Best for consequential questions.
> **B) Lightweight web search** — faster, fewer sources. Good for quick checks.
> **C) I have existing research** — point me to a report and I'll triangulate from it."

| Choice | Mode | Action |
|--------|------|--------|
| A (default if no response) | Subordinate | Each gap → `/deep-research` scoped to that question |
| B | Lightweight | Each gap → `WebSearch` + `WebFetch` |
| C | Post-hoc | Parse existing report → extract claim-source pairs → triangulate only |

If the user doesn't specify, default to **Lightweight** for initial round. Offer to escalate to Subordinate for unresolved gaps in later iterations.
