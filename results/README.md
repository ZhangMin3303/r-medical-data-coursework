# Regenerated synthetic results

These files were actually generated from the included synthetic fixtures on the documented reference environment. None comes from the original clinical/TCGA inputs.

- Cleaning reports show retained rows, exact duplicates and invalid/missing values.
- Integration reports preserve metadata order and identify missing/unmatched follow-up.
- PCA reports contain all component scores, variance fractions, feature exclusions and sample alignment counts.
- Survival reports contain synthetic group/event counts, at-risk counts and a teaching log-rank statistic/p-value.
- `pipeline_checks.csv` records six data-flow/numerical integrity checks.
- `environment.csv` records R, survival, seed and synthetic scope; `input_fingerprints.csv` identifies the inputs.
- The three PNGs are PCA scores, a scree plot and Kaplan–Meier curves. Curves omit confidence bands in this basic teaching view; censor marks and an at-risk CSV are provided.

Explained variance is not classification accuracy. The log-rank p-value is a calculation on a deliberately simulated teaching example, not a medical result, causal effect or validation metric.

To rerun, write to an empty ignored directory such as `work/recomputed`; keep these reference files unchanged for comparison. Numerical reconstruction and repeat-run checks are described in the validation document.
