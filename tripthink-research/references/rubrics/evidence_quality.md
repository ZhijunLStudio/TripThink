# Evidence Quality Rubric

| Grade | Definition | Examples | Default Weight |
|-------|-----------|----------|---------------|
| **primary** | Direct observation, official data, peer-reviewed research | Government statistics, published papers, company 10-K filings, API documentation from the source | 1.0 |
| **secondary** | Reputable analysis citing primary sources | Industry reports (Gartner, McKinsey), technical blog posts with benchmarks, news articles citing named sources | 0.7 |
| **tertiary** | Aggregation, summarization, or reporting without clear source chain | Wikipedia (as starting point, not final source), tech news without named sources, forum summaries | 0.4 |
| **llm-recall** | Model's own memory — no retrievable source | "I recall that..." "As far as I know..." — ANY unsourced statement | 0.1 |

## Rules

1. **Every evidence entry MUST have a grade.** No grade → treated as llm-recall.
2. **llm-recall is flagged, not forbidden.** Sometimes model memory is all we have. But it's explicitly low-confidence.
3. **Two llm-recall entries agreeing ≠ evidence.** That's just two models sharing the same training data bias.
4. **Contradictory evidence is preserved, not resolved.** If a primary source and a secondary source disagree, both go in the evidence ledger with a contradiction flag.
5. **Source freshness matters.** A primary source from 2019 on a fast-moving topic (AI, crypto, startup ecosystem) may be less reliable than a secondary 2026 analysis.
