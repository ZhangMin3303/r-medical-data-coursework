# Reviewed publication workflow, 2026-10; substantially AI-assisted.
file_arg <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L])
root <- normalizePath(file.path(dirname(file_arg), ".."), winslash = "/", mustWork = TRUE)
source(file.path(root, "R", "io_utils.R"), encoding = "UTF-8")
load_modules(root)
options <- parse_options(commandArgs(TRUE), list("input-dir" = "examples/input", "output-dir" = "work/latest"))
input <- repo_path(root, options[["input-dir"]])
output <- repo_path(root, options[["output-dir"]])
fixture <- verify_fixture(input)
if (dir.exists(output) && length(list.files(output, all.files = TRUE, no.. = TRUE))) {
  stop("Output directory is not empty; choose a fresh --output-dir to preserve earlier results.")
}
dir.create(output, recursive = TRUE, showWarnings = FALSE)
metadata_raw <- read.delim(file.path(input, "metadata.tsv"), colClasses = "character",
                           check.names = FALSE, na.strings = character(), stringsAsFactors = FALSE)
survival_raw <- read.delim(file.path(input, "survival.tsv"), colClasses = "character",
                           check.names = FALSE, na.strings = character(), stringsAsFactors = FALSE)
metadata <- clean_metadata(metadata_raw)
followup <- clean_survival(survival_raw)
integration <- integrate_metadata_survival(metadata$data, followup$data)
expression <- read_expression(file.path(input, "expression.csv"))
pca <- run_pca(expression, metadata$data)
km <- fit_survival(integration$data)
write_csv(metadata$data, file.path(output, "cleaned_metadata.csv"))
write_csv(metadata$audit, file.path(output, "metadata_cleaning_audit.csv"))
write_csv(metadata$dropped, file.path(output, "metadata_duplicate_rows.csv"))
write_csv(followup$dropped, file.path(output, "survival_invalid_rows.csv"))
write_csv(integration$data, file.path(output, "integrated_data.csv"))
write_csv(integration$audit, file.path(output, "integration_audit.csv"))
unmatched <- rbind(
  data.frame(sample_id = integration$missing_survival$sample_id, issue = "metadata_without_valid_survival"),
  data.frame(sample_id = integration$orphan_survival$sample_id, issue = "survival_without_metadata"))
write_csv(unmatched, file.path(output, "integration_unmatched.csv"))
write_csv(pca$scores, file.path(output, "pca_scores.csv"))
write_csv(pca$variance, file.path(output, "pca_variance.csv"))
write_csv(pca$dropped, file.path(output, "pca_feature_exclusions.csv"))
write_csv(pca$audit, file.path(output, "pca_audit.csv"))
write_csv(km$group_summary, file.path(output, "km_groups.csv"))
write_csv(km$risk_table, file.path(output, "km_at_risk.csv"))
write_csv(km$test, file.path(output, "logrank.csv"))
write_csv(fixture, file.path(output, "input_fingerprints.csv"))
reconstruction <- pca$model$x %*% t(pca$model$rotation)
target <- scale(pca$sample_matrix, center = pca$model$center, scale = pca$model$scale)
checks <- c(metadata_ids_unique = !anyDuplicated(metadata$data$sample_id),
  left_join_preserves_rows = nrow(integration$data) == nrow(metadata$data),
  survival_events_binary = all(km$data$event %in% c(0L, 1L)),
  pca_variance_sums_to_one = abs(sum(pca$variance$variance_fraction) - 1) < 1e-10,
  pca_reconstruction_error_small = max(abs(reconstruction - target)) < 1e-8,
  synthetic_ids_only = all(grepl("^SYN[0-9]{4}$", metadata$data$sample_id)))
write_csv(data.frame(check = names(checks), passed = as.logical(checks)), file.path(output, "pipeline_checks.csv"))
if (!all(checks)) stop("Pipeline integrity check failed.")
environment <- data.frame(component = c("R", "survival", "fixture_seed", "data_scope"),
  value = c(as.character(getRversion()), as.character(utils::packageVersion("survival")),
    as.character(fixture$seed[1]), "self_generated_synthetic"))
write_csv(environment, file.path(output, "environment.csv"))
plot_pca(pca, output)
plot_scree(pca, output)
plot_survival(km, output)
cat(sprintf("Completed: %d unique metadata rows; %d eligible matched follow-up rows; PCA %d samples x %d features.\n",
            nrow(metadata$data), nrow(km$data), nrow(pca$sample_matrix), ncol(pca$sample_matrix)))
cat("All outputs use synthetic inputs; no clinical finding or predictive validation is implied.\n")
