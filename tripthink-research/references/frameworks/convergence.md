# Convergence State Machine

```
INPUTS:
  - hypotheses(t): current iteration's hypothesis set
  - hypotheses(t-1): previous iteration's hypothesis set (null for iteration 0)
  - gap_register: all identified evidence gaps
  - iteration: current iteration number (0-indexed)
  - budget: max iterations (default 3)

STATE TRANSITIONS:

if iteration == 0:
    → LOOP (always do at least one revision cycle)

if all hypotheses unchanged AND no critical gaps remain:
    → CONVERGED
    // No model changed its mind, no important evidence unfound

if hypotheses changed (any revision or retirement) AND budget > 0:
    → LOOP
    // New beliefs → potential new gaps → gather more evidence

if budget exhausted (iteration >= max_iterations):
    → EXHAUSTED
    // Produce report with explicit "unresolved gaps" section

if hypotheses(t) ≈ hypotheses(t-2) AND hypotheses(t) ≠ hypotheses(t-1):
    → EXHAUSTED + OSCILLATION FLAG
    // Models are flip-flopping without converging. Surface to user.
    // This is a failure mode — don't hide it.

CONVERGENCE CHECK DETAIL:
"hypotheses unchanged" means:
  - No claim text changed beyond minor wording
  - No confidence changed by more than one level (low↔high is a change)
  - No retirement/new hypothesis

"critical gaps" are:
  - Gaps tagged [mechanism] or [empirical-fact] that affect >1 hypothesis
  - Gaps where the expected belief change (leverage score) exceeds threshold

OSCILLATION DETECTION:
  Compare hypotheses(t) with hypotheses(t-2).
  If the SAME models are flip-flopping on the SAME claims:
  → oscillation detected. Flag and report. Don't loop indefinitely.
```
