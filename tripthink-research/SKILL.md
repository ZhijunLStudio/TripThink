---
name: tripthink-research
description: Evidence-interleaved investigation with claim-level source binding and multi-model triangulation. Three LLMs propose hypotheses, evidence gaps are identified and filled (via deep-research or web search), hypotheses are revised or retired based on evidence, and the cycle repeats until convergence. Use when you need calibrated beliefs grounded in verifiable sources—not just model reasoning, but what's actually known. Triggers: /tripthink-research, "evidence-grounded analysis", "带证据的分析", "查证后审议", "triangulate this", "what does the evidence say about".
argument-hint: <research question>
---

# TripThink-Research — Evidence-Interleaved Investigation

**Unique method:** Claim-Level Source Binding with Multi-Model Triangulation. Three models independently propose hypotheses with explicit evidence requirements. Gaps are collected, prioritized, and filled — each gap triggers a targeted deep-research or web search. Models revise their hypotheses based on what was found (or retire them). The output is a calibrated belief report showing what survived evidence review, what was retired, and what remains unresolved.

**The core epistemic value over deep-research alone:** deep-research tells you what the sources say. TripThink-research tells you whether three independent reasoners reach the same conclusions from those sources — which is a different question (interpretation robustness ≠ source quality).

## Model Configuration

All models are defined in `$TRIPTHINK_HOME/config.json` (default `~/.tripthink/config.json`). This skill references models by config key only.

## Script Dependency

### Parallel dispatch (replaces Agent-based calls)

```
python3 ${TRIPTHINK_HOME:-$HOME/.tripthink}/scripts/tripthink.py dispatch --prompt "<composed prompt>"
```

Sends the same prompt to all models in parallel. Use for phases where all models get identical instructions.

For role-based dispatch (different prompt per model):
```
python3 ${TRIPTHINK_HOME:-$HOME/.tripthink}/scripts/tripthink.py dispatch --prompts prompts.json
```

## Prompt Assembly Rule

**The orchestrator composes the full prompt before dispatching.** Read the reference template, substitute phase outputs (hypothesis cards, evidence, gap register), and pass the COMPLETE composed string to `tripthink.py dispatch`. Never pass raw user input or bare context — always compose template + data first.

## Relationship to deep-research

TripThink-research is the **outer loop**; deep-research is the **inner gap-filler**. Each prioritized evidence gap in Phase 3 spawns one focused deep-research invocation.

Three integration modes (The orchestrator asks user which to use in Phase 0):

| Mode | When | How |
|------|------|-----|
| **Subordinate** (default) | Consequential research | Each gap → full `/deep-research` invocation. Slow, rigorous. |
| **Lightweight** | Quick checks | Each gap → `WebSearch` + `WebFetch`. Fast, lower rigor. |
| **Post-hoc** | Review existing research | Takes a completed deep-research report, runs only the triangulation phase to surface interpretation disagreements. |

## Pipeline

### Phase 0: Mode Selection

**Entry:** User question received.
**Exit:** Mode selected (subordinate / lightweight / post-hoc).

The orchestrator asks:
> "This investigation needs evidence. Should I use full deep-research (rigorous, slower), lightweight web search (faster, less thorough), or do you have an existing research report I should triangulate?"

### Phase 1: Hypothesis Generation

**Entry:** Mode selected, question framed.
**Exit:** 3 hypothesis cards, each with prior, evidence requirements, and falsifier.

Run tripthink.py dispatch. The orchestrator first composes the full prompt from the reference template + phase data, then: Prompt: `references/prompts/hypothesize.md`.

Each model produces a hypothesis card:
- **Claim**: the central hypothesis (one sentence)
- **Prior**: initial confidence (low / medium / high) with reasoning
- **Evidence needed**: ≥3 specific, testable evidence items with type tags (see `references/frameworks/evidence_types.md`):
 - `empirical-fact`: a verifiable data point
 - `mechanism`: causal explanation
 - `counterfactual`: what would be true if hypothesis were false
 - `expert-consensus`: what domain experts believe
 - `base-rate`: relevant statistical baseline
- **Falsifier**: what evidence would make the model abandon this hypothesis

**Quality Gate 1:**
- Each card has ≥3 evidence items with type tags
- Each card has a stated falsifier
- Hypotheses are distinct (not minor rephrasings of each other)

### Phase 2: Gap Identification & Prioritization

**Entry:** 3 hypothesis cards.
**Exit:** `gap_register` — deduplicated, prioritized list of evidence needs.

The orchestrator (deterministic processing):
1. Collect all evidence-needs from all hypothesis cards
2. Semantic deduplication (same need expressed differently → merge)
3. Prioritize by **leverage**: which gap, if filled, would change the most beliefs?
  - Leverage score = (number of hypotheses affected) × (average prior uncertainty of those hypotheses)
  - See `references/frameworks/leverage_scoring.md`

**Quality Gate 2:**
- No duplicate gaps in register
- Top-N gaps selected (N = user-configurable, default 5)

### Phase 3: Evidence Acquisition

**Entry:** Prioritized gap register.
**Exit:** `evidence/` entries for each gap, with source, claim, quality grade, polarity.

For each top-N gap, The orchestrator dispatches evidence gathering:

**Subordinate mode:** Invoke `/deep-research` scoped to that single gap question.
**Lightweight mode:** Run `WebSearch` + `WebFetch` for that gap.
**Post-hoc mode:** Extract relevant sections from the existing research report.

Each evidence entry records (see `references/prompts/verify_handoff.md`):
- Gap ID
- Source URL(s)
- Claim extracted from source
- **Quality grade** (see `references/rubrics/evidence_quality.md`):
 - `primary`: official source, peer-reviewed, direct observation
 - `secondary`: reputable analysis, industry report
 - `tertiary`: news report, aggregation
 - `llm-recall`: model memory (lowest grade, flagged)
- **Polarity**: `supports` / `contradicts` / `neutral` relative to each hypothesis

**Quality Gate 3:**
- Each gap has ≥1 source with quality grade
- LLM-recall sources are explicitly flagged as low-confidence
- Contradictory evidence pairs are surfaced, not silenced

### Phase 4: Hypothesis Revision

**Entry:** Evidence acquired for top-N gaps.
**Exit:** Each model submits revised hypothesis card OR retirement notice.

Run dispatch. Each model receives ALL evidence (regardless of whose hypothesis generated the gap) plus their own original hypothesis. Prompt: `references/prompts/revise.md`.

Each model must:
- **Revise**: update claim, confidence, evidence basis in response to findings
- **Retire**: abandon hypothesis if falsifier was triggered, with explicit reason
- **No change**: if evidence doesn't shift belief, explain why

**Quality Gate 4:**
- Every revision has a delta log (what changed, why, which evidence item caused the shift)
- Retired hypotheses have a retirement reason linked to specific evidence
- Confidence changes match evidence polarity (conflicting evidence MUST reduce confidence)

### Phase 5: Convergence Check

**Entry:** Revised hypotheses.
**Exit:** Decision — CONVERGED / LOOP / EXHAUSTED.

The orchestrator runs the convergence state machine (see `references/frameworks/convergence.md`):

```
INPUTS: hypotheses(t), hypotheses(t-1), gap_register, iteration, budget

if iteration == 0:
  → LOOP (always do at least one revision)
if all hypotheses unchanged AND no critical gaps remain:
  → CONVERGED
if hypotheses changed but new gaps surfaced AND budget > 0:
  → LOOP (back to Phase 2 with new gaps)
if budget exhausted:
  → EXHAUSTED (report with explicit "unresolved" section)
if hypotheses oscillating (t and t-2 identical):
  → EXHAUSTED + flag "oscillation" — escalate to user
```

Max iterations: 3 by default. Budget: user-configurable (time or token limit).

**Quality Gate 5:**
- Oscillation detection mandatory — don't loop forever
- EXHAUSTED state must produce unresolved-gaps section

### Phase 6: Final Report

**Entry:** CONVERGED or EXHAUSTED.
**Exit:** Calibrated research report.

The orchestrator assembles the final deliverable. No LLM query needed. Prompt template: `references/prompts/final_report.md`.

## Output Format

```
## 🔬 TripThink-Research: [Question]

### Mode: [subordinate / lightweight / post-hoc] | Iterations: [N]

### Hypothesis History
| Iter | Model | Hypothesis | Prior | Posterior | Status |
|------|-------|------------|-------|-----------|--------|

### Evidence Ledger
| Gap ID | Source | Quality | Claim | Supports | Contradicts |
|--------|--------|---------|-------|----------|-------------|

### Surviving Hypotheses
[With calibrated confidence and evidence basis]

### Retired Hypotheses
[With retirement reason and triggering evidence]

### Unresolved Gaps (if EXHAUSTED)
[What we still don't know]

### Contradictions Detected
[Where evidence items conflict — both preserved with conflict flag]

### Confidence Calibration
- Overall confidence: [high / medium / low]
- Key uncertainty sources
- Recommended next investigation (if not CONVERGED)
```

## Quality Rules

- **Priors required.** Every hypothesis enters with a stated prior confidence. No "the model said so."
- **Evidence-grading mandatory.** LLM-recall is explicitly tagged and weighted lower than retrieved sources.
- **Retirement is a feature.** A run that retires 2 of 3 hypotheses is successful, not failed.
- **Oscillation is failure.** Surface it explicitly — don't pretend convergence.
- **Contradictions surface, not silenced.** If two evidence items conflict, both go in the report.
- **Unfilled gaps are explicit.** EXHAUSTED state forces an "unresolved" section.

## Anti-Patterns

- Treating LLM consensus as evidence (it isn't — see `references/rubrics/evidence_quality.md`)
- Letting models revise hypotheses before seeing evidence
- Hiding gaps that couldn't be filled
- Pretending convergence when models capitulated to majority rather than evidence
- Skipping the convergence check and looping indefinitely

## When to Use

- Research questions where factual grounding matters
- Claims that need evidence verification before being acted on
- Analyzing a topic where different interpreters might reach different conclusions from the same data
- Pre-decision due diligence: "what do we actually know vs. what are we assuming?"

## When NOT to Use

- Pure reasoning questions without factual component → use /tripthink-deep
- Specific proposition stress-testing → use /tripthink-debate
- Quick fact checks → just use WebSearch directly
- Trivial questions where the research cost exceeds the information value

## Related Skills

- Upstream: [deep-research](deep-research) — the inner-loop evidence gatherer
- Alternative: [tripthink-deep](../tripthink-deep/) — reasoning without evidence requirement
- Alternative: [tripthink-debate](../tripthink-debate/) — adversarial without evidence loop
- Downstream: [idea-generation](../idea-generation/) — refine surviving hypotheses into research ideas
