# Validation scope — 29 October 2026

## Distinct evidence

1. **Historical sources:** twelve unchanged archived R scripts syntax-parse. Their original real-data analyses, dependency sets and numerical outputs were not rerun.
2. **Publication reconstruction:** new AI-assisted functions and test fixtures executed using only synthetic inputs. This is later reproducibility work, not a recovery of historical numerical findings.

The user confirmed teacher-provided early frameworks, collaboration on implementation details, and primary responsibility for later real-data/group work. Per-file contribution fractions remain unrecorded.

## Actual selected run

R 4.4.1, survival 3.6.4, Windows x86-64 (ucrt), seed 20261029. A project-local library path and --vanilla startup were used; the already installed R/recommended package was used. No package download, fresh R installation or full environment lock was performed.

The run cleaned 82 metadata rows to 80 unique IDs. After explicitly excluding three invalid follow-up rows, 72 valid records matched metadata; one additional valid follow-up ID lacked metadata. PCA aligned 76 samples and retained 10 of 12 features after recording one incomplete and one constant feature.

The run wrote actual CSV audit tables and three PNG figures. All six pipeline checks passed. Plots were visually inspected for labels, units, synthetic scope and readability.

## Regression scope

Fourteen checks passed, covering normalization/missingness, exact versus conflicting duplicates, blank IDs, row-preserving joins, duplicate-key rejection, invalid time/event values, hand-computed Kaplan–Meier ties/censoring, unclean/empty comparisons, PCA sample/feature alignment, full-component reconstruction and orthogonality, label independence, degenerate inputs, input fingerprint tampering and path escape rejection.

For the hand-computable KM group, risk/event calculations give survival 0.75, 0.5 and 0 at times 1, 2 and 3. A wholly censored comparison group remains at 1. This checks right-censor and tie handling; it is not clinical validation.

## Reproducibility boundary

The run commands use relative paths from the checkout root and protect existing output directories. A separate fresh source-only copy in a Unicode path containing spaces regenerated all four input files and all seventeen CSV result tables byte-identically. All three PNGs were generated and checked for valid dimensions; the fourteen regression checks passed again. Two negative CLI checks correctly rejected overwriting existing input and output directories. The existing R/survival installation was reused; this was not a clean dependency installation.

Version/backend differences can change PCA signs, plot rendering or numeric formatting. A different sign is not a biological finding. Other R/package versions, platforms, raw clinical schemas and full historical analyses remain unverified.

No accuracy, AUC, predictive benefit, biological discovery, causal conclusion or clinical usefulness is claimed.
