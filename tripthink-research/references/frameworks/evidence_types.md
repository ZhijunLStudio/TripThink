# Evidence Type Taxonomy

| Type | Definition | Example | Quality Implication |
|------|-----------|---------|-------------------|
| `empirical-fact` | A verifiable measurement, statistic, or data point | "In Q1 2026, Rust services had median P99 latency of 12ms vs Go's 18ms" | Highest weight if sourced. Check for replication. |
| `mechanism` | A causal explanation of HOW something works | "Rust's zero-cost abstractions eliminate GC pauses, reducing tail latency" | Important for understanding WHY. Needs empirical-fact to confirm. |
| `counterfactual` | What would be true if the hypothesis were false | "If Rust weren't faster, we'd expect to see comparable latency distributions" | Essential for falsification. Often overlooked. |
| `expert-consensus` | What domain experts or the literature generally believes | "The 2025 StackOverflow survey shows Rust as the most-admired language for 4th consecutive year" | Useful for calibration. Can be wrong. Check for contrary voices. |
| `base-rate` | Statistical baseline, prior probability, or reference class | "Among companies with >50 engineers that adopted Rust for new services in 2024-25, X% reported..." | Critical for avoiding base-rate neglect. Often unavailable — flag explicitly. |

## Quality Weights

When computing confidence:
- `empirical-fact` from primary sources: weight 1.0
- `empirical-fact` from secondary sources: weight 0.7
- `mechanism`: weight 0.5 (needs empirical confirmation)
- `expert-consensus`: weight 0.4 (can be wrong)
- `base-rate`: weight 0.8 if well-sourced, 0.2 if estimated
- `llm-recall` (model memory): weight 0.1 — flagged, never relied on alone
