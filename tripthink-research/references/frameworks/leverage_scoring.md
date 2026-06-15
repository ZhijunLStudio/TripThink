# Leverage Scoring for Gap Prioritization

## Definition

Leverage = how much would filling this gap change our beliefs?

## Formula

```
leverage(gap) = (number_of_hypotheses_affected) × (average_prior_uncertainty_of_affected)
```

Where:
- `number_of_hypotheses_affected`: count of hypotheses (across all models) that list this gap as evidence-needed
- `average_prior_uncertainty`: mean of (1 - |prior - 0.5| × 2) for affected hypotheses. Range 0–1.
  - prior=0.5 (maximum uncertainty) → uncertainty=1.0
  - prior=0.0 or 1.0 (certainty) → uncertainty=0.0

## Priority Tiers

| Score | Tier | Action |
|-------|------|--------|
| ≥2.0 | **Critical** | Fill first. Expected to substantially shift beliefs. |
| 1.0–1.9 | **High** | Fill after critical gaps. |
| 0.5–0.9 | **Medium** | Fill if budget allows. |
| <0.5 | **Low** | Document as unfilled. Don't spend budget. |

## Example

Gap G1: "What is the median latency of Rust vs Go services in production?"
- Affects H1 (prior=0.6, uncertainty=0.8), H2 (prior=0.3, uncertainty=0.4), H3 (prior=0.7, uncertainty=0.6)
- leverage = 3 × (0.8+0.4+0.6)/3 = 3 × 0.6 = 1.8 → **High priority**
