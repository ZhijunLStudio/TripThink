---
name: tripthink-deep
description: Deep convergent deliberation through blind seeding, cross-pollination critique, and structured synthesis across 3 independent LLMs. Use when facing complex open-ended questions—architecture decisions, strategy formulation, research framing—where a single model's blind spots would be costly and you need the best possible answer with annotated minority views. Triggers: /tripthink-deep, "deep deliberation", "深度审议", "多模型深度思考", "cross-pollinate this", "triple-think this".
argument-hint: <complex question or topic>
---

# TripThink-Deep — Cross-Pollination Deliberation

**Unique method:** Blind-then-Bridge Convergence. Three models reason independently (no peer exposure), then iterate through structured critique exchange, then converge through synthesis. The process is designed to surface *uncorrelated errors* — what one model misses, another catches — while preventing groupthink by keeping models blind to each other until the critique phase.

The orchestrator synthesizes but never seeds — preventing host-model bias from contaminating the divergent phase.

## Model Configuration

All models are defined in `$TRIPTHINK_HOME/config.json` (default `~/.tripthink/config.json`). This skill references models by their config keys only. To swap models, change endpoints, or adjust max_tokens, edit config.json — no changes needed here.

The three models used are those configured in `$TRIPTHINK_HOME/config.json`. The Skill description and prompt templates use config key names generically (e.g., Model A, Model B, Model C).

## Script Dependency

### Parallel dispatch (replaces Agent-based calls)

```
python3 ${TRIPTHINK_HOME:-$HOME/.tripthink}/scripts/tripthink.py dispatch --prompt "<composed prompt>"
```

Sends the same prompt to all 3 models in parallel (asyncio). Returns JSON with all results.

For role-based dispatch (different prompt per model):
```
python3 ${TRIPTHINK_HOME:-$HOME/.tripthink}/scripts/tripthink.py dispatch --prompts prompts.json
```

Other commands:
```
tripthink.py list       # List configured models
tripthink.py check       # Ping all models, report latency
```

### Single-model query (debugging only)

```
python3 ${TRIPTHINK_HOME:-$HOME/.tripthink}/scripts/query.py <model_key> "<prompt>"
```

## Prompt Assembly Rule

**The orchestrator composes the full prompt before dispatching.** Read the relevant reference template (e.g., `seed.md`), substitute the phase output (e.g., `problem_card`), and pass the COMPLETE composed string to `tripthink.py dispatch --prompt`. Do NOT pass raw user input or bare context — always compose template + phase data first.

Example for Phase 2:
```
python3 ${TRIPTHINK_HOME:-$HOME/.tripthink}/scripts/tripthink.py dispatch --prompt "You are an independent analyst...

## Problem Card
Core question: [sharpened question]
Constraints: [constraints]
..."
```

## Pipeline

### Phase 1: Problem Decomposition

**Entry:** User question received.
**Exit:** `problem_card` with framing, constraints, success criteria, and axes of potential disagreement.

The orchestrator self-prompts (see `references/prompts/decompose.md`) to extract:
- Core question (sharpened, unambiguous)
- Constraints (what's out of scope, what's non-negotiable)
- Success criteria (what a good answer must address)
- Anticipated axes of disagreement (empirical / definitional / value / scope — see `references/frameworks/axes_of_disagreement.md`)

### Phase 2: Blind Independent Seeding

**Entry:** `problem_card` complete.
**Exit:** 3 independent responses, each ≥400 tokens, with explicit "key claims" and "load-bearing assumptions" sections.

Run tripthink.py dispatch with the seed prompt composed from seed.md + problem_card:
```
```

The seed prompt (see `references/prompts/seed.md`) enforces:
- Commit to a position — no "on the other hand" hedging
- List ≥3 key claims with explicit reasoning chains
- Declare load-bearing assumptions (claims the answer depends on)
- Self-assess confidence per claim (high/medium/low)

**Models MUST NOT see each other's seeds.** This is the blindness that produces uncorrelated error.

**Quality Gate 2:**
- Each seed ≥400 tokens. Retry with higher max_tokens if truncated.
- Each seed has ≥3 claims tagged `[CLAIM]`. Regenerate if not.
- Semantic diversity check: if two seeds are near-identical (subjective assessment by the orchestrator reading them), flag for potential groupthink — perturb the prompt for the less-diverse model and re-run.

### Phase 3: Cross-Pollination Critique

**Entry:** All 3 seeds validated.
**Exit:** 6 critiques (each model critiques the other two).

Run dispatch (6 queries, 2 per model): Each agent receives ONE other model's seed plus the critique prompt (see `references/prompts/critique.md`):

> "Here is another model's analysis. Do three things: (1) Steel-man the strongest argument — restate it in its best possible form. (2) Identify the sharpest objection — what's the most serious weakness, gap, or counter-argument? (3) What should be ADOPTED from this perspective into the final synthesis?"

**Quality Gate 3:**
- Each critique must contain at least one specific adoption recommendation and one specific objection, tagged `[ADOPT]` and `[OBJECT]`.
- Critiques must not be mere summaries — the objection must engage with the substance.

### Phase 4: Reconciliation Matrix

**Entry:** 6 critiques complete.
**Exit:** `reconciliation_matrix` mapping every claim to: agreed / disputed / orthogonal.

The orchestrator (no LLM query needed — deterministic processing) builds a matrix:

| Claim | Source | Model A stance | Model B stance | Model C stance | Verdict |
|-------|--------|----------------|----------------|----------------|---------|
| ... | ... | support / oppose / silent | ... | ... | AGREED / DISPUTED / ORTHOGONAL |

Uses regex anchors from seeds (`[CLAIM]`) and critiques (`[ADOPT]`, `[OBJECT]`) to populate.

**Quality Gate 4:**
- Every seed claim appears in the matrix.
- Every dispute has a linked critique quote.

### Phase 5: Convergent Synthesis

**Entry:** Matrix complete, all disputes flagged.
**Exit:** `synthesis` — a hybrid position synthesizing the best of all three seeds, with explicit dissent preserved.

the orchestrator (as synthesizer), NOT querying models) produces the synthesis. Prompt template: `references/prompts/synthesize.md`.

Rules for synthesis:
- **No averaging.** Must commit to a position, not blend bullet points.
- **Preserve dissent.** A unanimous-looking output with hidden disagreement is a failure. Annotate where models diverged.
- **Cite sources.** Attribute ideas to specific models ("Model A argued X, which Model B refined by adding Y").
- **Include minority report.** If one model consistently diverges and its position has merit, preserve it as a minority view.

### Phase 6: Audit & Sign-off

**Entry:** Synthesis drafted.
**Exit:** Each model signs off or files formal dissent. Final report.

Run tripthink.py dispatch. Each model receives the synthesis plus the audit prompt (see `references/prompts/audit.md`):

> "Review this synthesis. Does it fairly represent your original analysis? Does it address your strongest argument? If you dissent, specify exactly which claim is misrepresented and how."

**Retry logic:** If ≥2 models dissent, re-enter Phase 5 with the dissent payload (max 2 retries). If retries exhausted, publish with "Minority Report" section prominently featured.

### Phase 7: Render Report

The orchestrator renders the final deliverable as Markdown (no LLM needed).

## Output Format

```
## 🧠 TripThink-Deep: [Topic]

### Problem Card
- Core question, constraints, success criteria

### Seed Summary
| Model | Key Claim | Load-Bearing Assumption | Confidence |
|-------|-----------|------------------------|------------|

### Disagreement Axes
| Claim | Consensus? | Dispute Detail |
|-------|-----------|----------------|

### Synthesis
[Hybrid position — committed, not averaged]

### Minority Report
[Preserved dissent — if any model's view was consistently divergent]

### Audit Trail
| Model | Sign-off / Dissent | Reason |
|-------|-------------------|--------|

### Confidence: high / medium / low
[Reasoning for confidence level]
```

## Quality Rules

- **Orchestrator never seeds.** The orchestrator only synthesizes — this prevents the host model's biases from shaping the seed phase.
- **No averaging.** Synthesis must name a specific position, not "A says X, B says Y, both have merit."
- **Preserve dissent.** A unanimous-looking output where models actually disagreed is a process failure.
- **Attribute everything.** "Model A argued X" not "one perspective is X."
- **Phase gates are hard.** Don't skip Phase 4's matrix just because it's tedious — it's the audit trail.

## Anti-Patterns

- Seeds that quote each other (impossible if Phase 2 is run correctly with no peer context)
- Critiques that are summaries without substantive objection
- Synthesis that "splits the baby" — listing perspectives without committing
- Skipping the audit phase — this is where false consensus gets caught
- Letting one model dominate (if a model's claims are never disputed, check whether it's genuinely stronger or whether the critique was weak)

## When to Use

- Open-ended design or architecture decisions
- Strategy formulation with multiple valid approaches
- Research question framing where perspective matters
- Any complex question where a single model's blind spot would be costly

## When NOT to Use

- Factual questions with a known answer → use regular query
- Simple comparisons → use /fusion
- Propositions needing adversarial testing → use /tripthink-debate
- Questions requiring evidence grounding → use /tripthink-research

## Related Skills

- Alternative: [tripthink-debate](../tripthink-debate/) — adversarial rather than cooperative
- Alternative: [tripthink-research](../tripthink-research/) — evidence-bound rather than reasoning-alone
- Upstream: [deep-research](deep-research) — gather evidence before deep deliberation
- Downstream: [idea-generation](../idea-generation/) — refine synthesis outputs into research ideas
