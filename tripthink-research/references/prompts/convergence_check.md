# Phase 5: Convergence Check

## Orchestrator Self-Prompt (Deterministic)

Run the convergence state machine against current and previous iteration state.

### Inputs

- `hypotheses(t)`: current iteration's hypothesis cards
- `hypotheses(t-1)`: previous iteration's hypothesis cards (null for iteration 0)
- `gap_register(t)`: current gaps including any new ones surfaced in revision
- `iteration`: current iteration number (0-indexed)
- `max_iterations`: hard limit (default 3, configurable)

### State Machine

```
if iteration == 0:
    → LOOP (always do at least one revision cycle)

if iteration >= max_iterations:
    → EXHAUSTED
    Reason: "Hard iteration limit (N={max_iterations}) reached."

if all hypotheses unchanged AND no critical gaps remain:
    → CONVERGED
    Check: "unchanged" = no claim text changed beyond minor wording, no confidence changed by >1 level

if hypotheses changed (any revision/retirement) AND gaps_remaining AND iteration < max_iterations:
    → LOOP (back to Phase 2 with new gaps)

if hypotheses(t) ≈ hypotheses(t-2) AND hypotheses(t) ≠ hypotheses(t-1):
    → EXHAUSTED + OSCILLATION
    Reason: "Models are oscillating between states without converging. This is a failure mode."
    Action: Surface to user with the two competing states documented.

if no hypotheses changed AND critical gaps remain unfilled:
    → EXHAUSTED
    Reason: "Convergence blocked by unfillable gaps: [list]."
```

### Output

```
## Convergence Decision: [CONVERGED / LOOP / EXHAUSTED]

### State
- Iteration: [N] / [max]
- Hypotheses changed: [N]
- Gaps remaining: [N] (critical: [N])
- Oscillation detected: [yes/no]

### Decision
[CONVERGED / LOOP / EXHAUSTED]
Reason: [specific reason from state machine]

### If LOOP
Next iteration will address gaps: [Gx, Gy, Gz]

### If EXHAUSTED
Unresolved items will be documented in final report.
```

### Quality Gate

- Oscillation detection is MANDATORY — check hypotheses(t) vs hypotheses(t-2)
- Hard limit enforcement is MANDATORY — `iteration >= max_iterations` MUST trigger EXHAUSTED
- Never LOOP with zero new gaps
