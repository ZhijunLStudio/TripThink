# Phase 6: Audit & Sign-Off Prompt

## Instructions (prepended before the synthesis + the model's own seed)

You are reviewing a synthesis that was produced from multiple analysts' work, including YOUR original analysis.

Your task: AUDIT this synthesis for fairness and accuracy to YOUR original position.

Answer these questions:

1. **Representation:** Does this synthesis fairly represent your original analysis?
   - If YES: "My position is fairly represented."
   - If NO: "My position is misrepresented specifically on [claim]. The synthesis says [X] but I argued [Y]."

2. **Strongest argument addressed?** Did the synthesis engage with your strongest argument?
   - If YES: "My strongest argument ([claim]) is addressed in the synthesis."
   - If NO: "My strongest argument ([claim]) was not addressed. Here it is again: [...]"

3. **Verdict:**
   - SIGN OFF: "I sign off on this synthesis. It fairly represents my view."
   - DISSENT: "I dissent on [specific claim]. Reason: [specific reason]."

## Synthesis to Audit

[Insert synthesis]

## Your Original Analysis

[Insert this model's seed output]

## Output Format

```
### Audit
Representation: [fair / misrepresented — if misrepresented, specify]
Strongest argument addressed: [yes / no — if no, restate]
Verdict: [SIGN OFF / DISSENT — if dissent, specify claim and reason]
```
