# Phase 6: Final Report Assembly

## Orchestrator Self-Prompt)

You have a complete investigation record:
- 3 initial hypothesis cards
- Evidence gathered for prioritized gaps
- Revised/retired hypotheses with deltas
- Convergence state (CONVERGED or EXHAUSTED)

Assemble the final report. No LLM query needed — this is deterministic assembly.

## Report Structure

```
## 🔬 TripThink-Research: [Question]

### Executive Summary
[3-5 sentences. What we know now, what changed, what's still uncertain.]

### Investigation Summary
- Mode: [subordinate / lightweight / post-hoc]
- Iterations: [N]
- Hypotheses proposed: [N], Surviving: [N], Retired: [N]
- Evidence gaps filled: [N], Unresolved: [N]

### Hypothesis History
| Iter | Model | Hypothesis | Prior | Posterior | Status |
|------|-------|------------|-------|-----------|--------|
| 1 | [A] | [claim] | medium | — | — |
| 2 | [A] | [revised claim] | — | low | RETIRED |
| 1 | [B] | [claim] | high | — | — |
| 2 | [B] | [claim] | — | high | SURVIVED |
| 1 | [C] | [claim] | low | — | — |
| 2 | [C] | [revised claim] | — | medium | SURVIVED |

### Evidence Ledger
| Gap ID | Source | Quality | Claim | Supports | Contradicts |
|--------|--------|---------|-------|----------|-------------|
| G1 | [url] | primary | [claim] | H1, H2 | H3 |
| G2 | [url] | secondary | [claim] | H2 | — |
| ... | ... | ... | ... | ... | ... |

### Surviving Hypotheses
**H2 (Model B):** [claim] — Confidence: high
- Evidence basis: [G1, G2, G4]
- Key uncertainties: [...]

**H3 (Model C):** [revised claim] — Confidence: medium
- Evidence basis: [G1, G5]
- Key uncertainties: [...]

### Retired Hypotheses
**H1 (Model A):** [original claim] — RETIRED
- Falsified by: [G3] — "[quote from evidence]"
- Retirement reason: [Why the evidence was decisive]

### Contradictions Detected
| Evidence A | Evidence B | Conflict | Resolution |
|-----------|-----------|----------|------------|
| G2: "[claim]" | G5: "[claim]" | [nature of conflict] | [how handled] |

### Unresolved Gaps (if EXHAUSTED)
- [Gap]: Why it couldn't be filled. Impact on confidence.
- ...

### Confidence Calibration
- Overall confidence: [high / medium / low]
- Strongest finding: [most robust conclusion]
- Weakest link: [conclusion most likely to change with new evidence]
- Recommended follow-up: [what to investigate next]
```
