# Publication reconstruction, 2026-10: AI-assisted; not the historical course script.
require_columns <- function(data, columns, label = "table") {
  missing <- setdiff(columns, names(data))
  if (length(missing)) stop(label, " is missing columns: ", paste(missing, collapse = ", "))
}
normalize_id <- function(values) {
  id <- toupper(trimws(as.character(values)))
  if (anyNA(id) || any(!nzchar(id))) stop("Sample identifiers must be non-empty.")
  id
}
assert_unique_ids <- function(data, key = "sample_id", label = "table") {
  require_columns(data, key, label)
  if (anyDuplicated(data[[key]])) stop(label, " has conflicting or repeated sample IDs.")
  invisible(TRUE)
}
as_number <- function(values) {
  suppressWarnings(as.numeric(trimws(as.character(values))))
}
missing_marker <- function(values) {
  is.na(values) | toupper(trimws(as.character(values))) %in% c("", "NA", "N/A", "NOT_REPORTED", "UNKNOWN")
}
write_csv <- function(data, file) {
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  write.table(data, file, sep = ",", row.names = FALSE, col.names = TRUE,
              quote = TRUE, na = "", eol = "\n", fileEncoding = "UTF-8")
}
repo_root <- function() {
  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg) != 1L) stop("Run this entry point with Rscript.")
  script <- sub("^--file=", "", file_arg)
  normalizePath(file.path(dirname(script), ".."), winslash = "/", mustWork = TRUE)
}
repo_path <- function(root, relative) {
  if (length(relative) != 1L || grepl("^[/\\\\]|^[A-Za-z]:", relative)) {
    stop("Use a path relative to the checkout.")
  }
  parts <- strsplit(gsub("\\\\", "/", relative), "/", fixed = TRUE)[[1L]]
  if (".." %in% parts) stop("Parent-directory traversal is not supported.")
  file.path(root, relative)
}
parse_options <- function(args, defaults) {
  if (length(args) %% 2L != 0L) stop("Options must be --name value pairs.")
  if (!length(args)) return(defaults)
  for (i in seq(1L, length(args), by = 2L)) {
    name <- sub("^--", "", args[i])
    if (!startsWith(args[i], "--") || !name %in% names(defaults)) stop("Unknown option: ", args[i])
    defaults[[name]] <- args[i + 1L]
  }
  defaults
}
load_modules <- function(root) {
  for (name in c("cleaning.R", "integration.R", "pca.R", "survival.R")) {
    sys.source(file.path(root, "R", name), envir = .GlobalEnv)
  }
}
verify_fixture <- function(input_dir) {
  manifest_file <- file.path(input_dir, "fixture_manifest.csv")
  if (!file.exists(manifest_file)) stop("Missing synthetic fixture manifest.")
  manifest <- read.csv(manifest_file, stringsAsFactors = FALSE)
  require_columns(manifest, c("file", "md5", "provenance", "seed"), "fixture manifest")
  expected <- c("metadata.tsv", "survival.tsv", "expression.csv")
  if (!setequal(manifest$file, expected) || nrow(manifest) != length(expected) ||
      any(manifest$provenance != "self_generated_synthetic")) stop("Invalid fixture manifest.")
  paths <- file.path(input_dir, manifest$file)
  if (!all(file.exists(paths))) stop("Missing synthetic input file.")
  actual <- unname(tools::md5sum(paths))
  if (!identical(actual, as.character(manifest$md5))) stop("Input fingerprint mismatch; do not label changed inputs as the published synthetic fixture.")
  invisible(manifest)
}
open_plot <- function(file, width = 1300L, height = 850L) {
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  grDevices::png(file, width = width, height = height, res = 130)
  par(mar = c(5, 5, 4, 2) + 0.1, family = "sans", las = 1)
}
