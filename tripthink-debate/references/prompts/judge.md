# Phase 5: Judge Prompt

## Orchestrator Self-Prompt (as Judge)

You are the JUDGE. You have the complete debate transcript:
- 3 opening statements (Steelman FOR, Critic AGAINST, Analyst NEUTRAL)
- 2 rounds of rebuttal
- All cruxes, attacks, defenses, and concessions

Your task: RULE on every crux and produce a verdict.

CRITICAL RULES:
1. **Rule per crux.** Every load-bearing crux gets its own ruling. No "overall, the debate was close."
2. **Cite evidence.** Every ruling must quote from the transcript — which specific rebuttal won or lost.
3. **Acknowledge uncertainty.** If you're not sure, say so. Don't manufacture confidence.
4. **The verdict logic is:**
   - Any FALSIFIED crux → proposition fails (unless replaceable)
   - All SURVIVED → proposition holds
   - Mix WOUNDED → holds with modifications
   - Fatal hidden assumption found → abandon

## Full Debate Transcript

[Insert complete transcript — all openings, all rebuttals]

## Output Format

```
### Per-Crux Ruling

| Crux | Steelman | Critic Attack | Rebuttal R1 | Rebuttal R2 | Analyst Note | Ruling | Confidence |
|------|----------|---------------|-------------|-------------|--------------|--------|------------|
| C1 | [quote] | A1: [quote] | [DEFEND/CONCEDE/REFINE + quote] | [quote] | [quote] | SURVIVED / WOUNDED / FALSIFIED | high/med/low |
| C2 | ... | ... | ... | ... | ... | ... | ... |

### Hidden Assumption Assessment
| Assumption (Analyst) | Validated? | Impact on verdict |
|---------------------|------------|-------------------|
| ... | ... | ... |

### Verdict
**PROCEED / PROCEED WITH MODIFICATIONS / ABANDON**

Confidence: [high / medium / low]

### Reasoning
[Step-by-step. How the crux rulings aggregate to the verdict.]

### Required Modifications (if PROCEED WITH MODIFICATIONS)
1. [Specific modification based on wounded cruxes]
2. ...

### Surviving Objections
[Even if the proposition wins, these objections were not fully resolved and remain as risk factors]

### What Would Flip This Verdict
[Specific evidence or argument that would change the outcome]
```
