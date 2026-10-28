# Self-generated synthetic fixtures

All included TSV/CSV inputs were created by `scripts/generate_synthetic_data.R` with seed 20261029 and R's Mersenne-Twister/Inversion/Rejection settings. No original course dataset was loaded.

- `metadata.tsv`: 82 rows including two exact duplicates; 80 unique SYN IDs. Age fields include two out-of-range values and three missing markers. One sex label is unknown.
- `survival.tsv`: 76 independently simulated follow-up records. Times are in months; event=1 and censored=0. Three rows deliberately have missing/zero time or invalid event coding. SYN0083 has no metadata.
- `expression.csv`: 12 generic feature rows × 78 sample columns; SYN0081/SYN0082 have no metadata. FEATURE11 contains a missing value; FEATURE12 is constant. Other features are generated from random latent factors plus noise, without using the group labels.
- `fixture_manifest.csv`: seed, synthetic provenance and MD5 file fingerprints used for reproducibility checks. MD5 is an input identity check here, not a security guarantee.

Groups A/B are arbitrary synthetic labels. They are not disease, treatment or outcome claims. Values and plots must not be interpreted as patient observations or biological findings.

The analysis entry point requires this manifest and rejects altered inputs. It is a bounded synthetic demo, not a general clinical analysis/import service.

Teaching choices: IDs are trimmed and uppercased before duplicate checks; valid ages are 0–120 inclusive, with invalid/missing ages retained as NA and audited. These are synthetic-example rules, not established clinical policies. Positive follow-up time is required and no time-unit conversion or rounding occurs during fitting.
