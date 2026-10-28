# Dependency scope

The selected reconstruction uses base/recommended R plus **survival**. No network access or package installation occurs inside analysis scripts.

Validated reference: R 4.4.1, survival 3.6.4, Windows x86-64 (ucrt). Base tools used include stats::prcomp, utils CSV/TSV I/O and grDevices PNG rendering.

Use an isolated project library where possible. If survival is missing, install it separately from your chosen CRAN mirror, subject to its own license, before running the workflow. The installed version may differ; run the checks and tests and record it.

This is a tested version record, not a complete dependency lock or cross-platform compatibility guarantee. No R installation, package binaries, user libraries or renv cache is bundled.

Validation used a project-local library path and the already installed R/recommended survival package; no clean R/package installation was performed.
