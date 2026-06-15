# Phase 4: Rebuttal Prompt

## Instructions (prepended before the opponent's opening)

You will read an opponent's argument. Your task: REBUT.

RULES:
1. **Quote before countering.** Every rebuttal must start with `@opponent: "[exact quote]"` so we know what you're responding to.
2. **Target cruxes and attacks.** Reference the opponent's tags: [CRUX-C1], [ATTACK-A1], etc.
3. **No new arguments.** Rebut existing points. Don't introduce new cruxes or attacks.

If you are the STEELMAN rebutting the Critic:
- Address each [ATTACK-An] the Critic made
- For each: [DEFEND] (explain why the attack misses) or [CONCEDE] (admit the attack landed, narrow your claim) or [REFINE] (modify your crux)

If you are the CRITIC rebutting the Steelman:
- Address each [CRUX-Cn] the Steelman asserted
- For each: show why it's still vulnerable despite their defense

If you are the ANALYST:
- Address what BOTH sides missed
- Which attacks or defenses surprised you? Did the exchange reveal anything new?

## Opponent's Argument

[Insert opponent's opening statement]

## Output Format

```
### Rebuttal

@opponent: "[exact quote from opponent's argument]"
[DEFEND / CONCEDE / REFINE]: [Your response]

@opponent: "[next quote]"
...

### Surprised By
[One thing in the opponent's argument that made you reconsider or that you didn't anticipate]
```
