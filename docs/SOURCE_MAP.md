# Historical sources and selected reconstruction

The private audit located twelve historical R files; all passed syntax parsing. Raw course-time files remain private because teacher/peer provenance and redistribution rights are not fully recorded at file level. The confirmed contribution pattern is described in ATTRIBUTION.md.

| Private audit ID | Historical theme | Treatment in this candidate |
| --- | --- | --- |
| R01 / R04 | Two substantially overlapping comprehensive workflows, including differential tests, enrichment, survival and model-related calls | Counted as one workflow; not republished or rerun |
| R02 | Survival/boxplot helper | Body excluded; helper-specific authorship/permission not established |
| R03 | Wilcoxon/differential-expression helper | Body excluded; not part of the selected first release |
| R05 / R06 | Data reading and elementary data cleaning | Concepts reconstructed with new synthetic schemas; course frameworks not republished |
| R07 | Clinical-column selection/cleaning | New bounded cleaning function; no raw clinical fields or course data included |
| R08 | Clinical/follow-up table joins | Explicit key and one-to-one checks in the new integration function |
| R09 | Volcano visualization with fixed text counts | Excluded; fixed annotations are not accepted as computed evidence |
| R10 | Heatmap/other gene-expression visualization | Outside first-release scope |
| R11 | Survival workflow | New event/censor checks, valid-row audit and fit-before-plot order |
| R12 | PCA workflow | New explicit sample alignment, transpose/scale rules and feature-exclusion audit |

This is one coursework portfolio, not twelve independent projects. Original full-source paths, personal filenames, teaching documents and clinical inputs are deliberately absent from the public source map.

## Changes motivated by the audit

The historical code includes machine paths, inline package installation, implicit join keys, a tab separator typo, a plot object used before assignment, fixed-size feature selection and fixed volcano annotations. The reconstruction avoids these issues in its selected workflows.

It does not establish that the original full analyses reproduce, nor does it replace historical outputs with newly simulated values. The synthetic demo and historical course evidence must stay separate.
