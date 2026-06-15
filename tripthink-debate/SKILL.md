---
name: tripthink-debate
description: Adversarial stress-test through role-locked dialectic across 3 LLMs. One model steelmans the proposition, another attacks every load-bearing claim, a third analyzes neutrally—then rebuttals fly and a judge rules. Use when evaluating a specific proposal, decision, or claim where you need to find what breaks before committing. Triggers: /tripthink-debate, "stress test this", "adversarial review", "对抗审议", "压力测试", "debate this proposition", "steelman this and attack it".
argument-hint: <proposition or claim to stress-test>
---

# TripThink-Debate — Adversarial Stress-Test

**Unique method:** Role-Locked Dialectic with Adjudication. Three models are assigned immutable adversarial roles. They do not converge, do not synthesize, do not seek consensus. The output is not an "answer" — it's a battle-tested proposition with a damage report showing which claims survived, which were wounded, and which were falsified.

The orchestrator serves as judge — it never debates, never seeds arguments. It reads the full transcript and rules per-crux.

## Model Configuration

All models are defined in `$TRIPTHINK_HOME/config.json` (default `~/.tripthink/config.json`). This skill references models by config key only. Role assignment uses seeded randomization (logged for reproducibility) to prevent capability bias.

## Script Dependency

### Parallel dispatch (replaces Agent-based calls)

```
python3 ${TRIPTHINK_HOME:-$HOME/.tripthink}/scripts/tripthink.py dispatch --prompt "<composed prompt>"
```

Sends the same prompt to all models in parallel. Use for phases where all models get identical instructions (Phase 1 self-prompts, Phase 3 openings with shared proposition_card).

For role-based dispatch (different prompt per model), write prompts to a JSON file and call:
```
python3 ${TRIPTHINK_HOME:-$HOME/.tripthink}/scripts/tripthink.py dispatch --prompts /tmp/role_prompts.json
```

Other commands:
```
tripthink.py list       # List configured models
tripthink.py check       # Ping all models, report latency
```

## Prompt Assembly Rule

**The orchestrator composes the full prompt before dispatching.** Read the relevant reference template, substitute phase outputs, and pass the COMPLETE composed string to `tripthink.py dispatch`. Never pass raw user input directly — always compose template + phase context first.

## Pipeline

### Phase 1: Proposition Crystallization

**Entry:** User's proposition received.
**Exit:** `proposition_card` — sharpened, scoped, falsifiable.

The orchestrator (self-prompt, see `references/prompts/frame.md`) extracts:
- **Canonical proposition**: sharpened, unambiguous, one sentence
- **Scope**: what's in bounds, what's out
- **Falsification condition**: what would prove it wrong (Popper-style)
- **Success criteria**: what "winning" the debate means for each side

### Phase 2: Role Assignment

**Entry:** Proposition crystallized.
**Exit:** Model→Role mapping, logged with RNG seed.

Random 1:1:1 assignment of the three models to:
- **Steelman (FOR):** Builds the strongest possible case. Forbidden from hedging, conceding, or saying "it depends."
- **Critic (AGAINST):** Attacks every load-bearing claim. Forbidden from proposing alternatives — destroy only.
- **Analyst (NEUTRAL):** Tracks which attacks land, which are deflected. Not a "moderator" — a third perspective that prevents false dichotomy.

Assignment is done by the orchestrator using deterministic round-robin or random rotation — the assignment mapping is logged in the output for reproducibility.

### Phase 3: Opening Statements

**Entry:** Roles assigned.
**Exit:** 3 opening statements, each with ≥3 tagged crux claims.

Run tripthink.py dispatch with --prompts, using role-specific prompts: `references/prompts/opening_for.md`, `opening_against.md`, `opening_neutral.md`.

**Steelman requirements:**
- ≥3 load-bearing claims tagged `[CRUX-C1]` through `[CRUX-Cn]`
- Each crux: the proposition fails without it
- No hedging, no "on the other hand"

**Critic requirements:**
- ≥3 attacks, each targeting a specific steeler claim (or a hidden assumption)
- Each attack tagged `[ATTACK-A1]` through `[ATTACK-An]`

**Analyst requirements:**
- Identify ≥3 hidden assumptions the proposition depends on
- Flag what's testable vs. unfalsifiable
- Note what evidence would resolve each uncertainty

**Quality Gate 3:**
- Each opening has ≥3 tagged elements
- Cruxes are genuinely load-bearing (if removing it doesn't kill the proposition, reject and regenerate)

### Phase 4: Rebuttal Exchange

**Entry:** Openings complete.
**Exit:** 2 rounds of rebuttal. Each model responds to the other two.

**Round 1:** Each model receives the other two's openings (anonymized) and must:
- Directly quote the opponent's tagged claim → `@opponent: "[CRUX-C1]..."`
- Provide counter-argument or evidence
- Tag: `[REBUTTAL-R1]`

Run tripthink.py dispatch with --prompts. Prompt: `references/prompts/rebuttal.md`.

**Round 2:** Each model receives Round 1 rebuttals targeting them and must defend or concede:
- `[DEFEND]:` explains why the rebuttal misses
- `[CONCEDE]:` admits the rebuttal landed, narrows scope
- `[REFINE]:` modifies the original crux in response

**Rebuttal state machine:**

```
state: AWAITING_REBUTTAL
 → REBUTTAL_RECEIVED
   ├─ has crux tags? no → RETRY (max 2) → fail = forfeit that exchange
   ├─ targets opponent only? no → REJECT, retry
   ├─ new claim snuck in? yes → FLAG "scope drift", allow but log
   └─ valid → ACCEPT
```

**Quality Gate 4:**
- Every crux has been attacked at least once
- Every rebuttal has source-quote from opponent
- Scope drift incidents logged

### Phase 5: Draft Adjudication

**Entry:** Full debate transcript.
**Exit:** `draft_verdict` — per-crux ruling, overall confidence, surviving objections. **This is a draft.** It goes to the losing side for review in Phase 6 before being finalized.

The orchestrator (as judge) reads the complete transcript and produces a draft ruling. Prompt: `references/prompts/judge.md`.

The judge must produce:

**Per-crux grid:**

| Crux | Steelman | Critic Attack | Rebuttal | Analyst Note | Ruling | Confidence |
|------|----------|---------------|----------|--------------|--------|------------|
| C1 | ... | A1: ... | DEFEND/CONCEDE/REFINE | ... | SURVIVED / WOUNDED / FALSIFIED | high/med/low |

**Verdict logic** (see `references/rubrics/verdict_calibration.md`):
- Any FALSIFIED load-bearing crux → proposition **fails** (unless replaceable)
- All cruxes SURVIVED → proposition **holds**
- Mix of SURVIVED + WOUNDED → proposition **holds with modifications**
- Critic identifies fatal assumption Analyst confirms → proposition **abandoned**

**Quality Gate 5:**
- Every crux has an explicit ruling with quote evidence
- Judge must acknowledge uncertainty — if confidence is >0.95 and there was substantial disagreement, re-evaluate

### Phase 6: Last-Word Review

**Entry:** Draft verdict from Phase 5.
**Exit:** Final verdict, potentially revised.

The losing side reviews the DRAFT verdict before it's final. Run tripthink.py dispatch --models <losing_model> with the lastword prompt. Prompt: `references/prompts/lastword.md`.

> "This is a DRAFT ruling. It went against your position on [specific cruxes]. If you believe the judge made a logical error, specify exactly which ruling and why."

If the last-word identifies a genuine logic flaw (the orchestrator evaluates), the judge revises the draft (max 1 revision). Then the verdict becomes final.

### Phase 7: Render Final Verdict

The orchestrator renders the final deliverable, incorporating any revision from Phase 6.

## Output Format

```
## ⚖️ TripThink-Debate: [Proposition]

### Proposition Card
- Canonical form, scope, falsification condition, success criteria

### Role Assignment
| Model | Role | RNG Seed |
|-------|------|----------|

### Crux Grid
| Crux | Steelman | Critic | Analyst | Rebuttal | Ruling | Confidence |
|------|----------|--------|---------|----------|--------|------------|

### Verdict
**PROCEED / PROCEED WITH MODIFICATIONS / ABANDON**

### Required Modifications (if PROCEED WITH MODIFICATIONS)
1. ...
2. ...

### Surviving Objections
Even though the proposition [holds], these objections were not fully resolved:
- ...

### Last-Word Review
[Outcome, whether verdict was revised]

### Full Transcript (appendix)
```

## Quality Rules

- **Role lock is absolute.** If the Steelman hedges, regenerate. If the Critic proposes alternatives, regenerate.
- **Symmetry of information.** All sides see the same proposition framing. No side gets extra context.
- **Crux discipline.** Untagged arguments don't count in judging. Forces specificity.
- **Judge transparency.** Every ruling must cite which rebuttal won which crux, with direct quotes.
- **Surviving objections preserved.** Even when proposition "wins," winning ≠ unobjected.

## Anti-Patterns

- Judge writing verdict before reading Round 2 rebuttals (enforced by phase gate)
- "Both sides made good points" — rubric requires per-crux ruling
- Role bias by capability (always assigning strongest model to Steelman) — fixed by seeded RNG
- Strawmanning — detected by comparing proposition with steeler's paraphrase; if they differ materially, regenerate

## When to Use

- Evaluating a specific architectural or technical proposal
- Stress-testing a product decision before committing resources
- Checking whether a research hypothesis can survive adversarial scrutiny
- Any high-stakes decision where you need to know what would have to be true for the choice to be wrong

## When NOT to Use

- Open-ended questions without a specific proposition → use /tripthink-deep
- Questions requiring factual evidence → use /tripthink-research
- Simple yes/no decisions where the stakes are low
- Trivial propositions where the debate cost exceeds the decision value

## Related Skills

- Alternative: [tripthink-deep](../tripthink-deep/) — cooperative synthesis rather than adversarial
- Alternative: [tripthink-research](../tripthink-research/) — evidence-grounded rather than role-bound
- Embedded: [deep-research](deep-research) — when judge encounters an empirical crux it cannot rule on
