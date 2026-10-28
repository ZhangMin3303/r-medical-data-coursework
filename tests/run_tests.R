# Invariants and hand-computable fixtures; these are not clinical validations.
file_arg <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L])
root <- normalizePath(file.path(dirname(file_arg), ".."), winslash = "/", mustWork = TRUE)
source(file.path(root, "R", "io_utils.R"), encoding = "UTF-8")
load_modules(root)
results <- data.frame(test = character(), passed = logical(), detail = character())
check <- function(name, expression) {
  error <- tryCatch({ force(expression); NULL }, error = function(e) conditionMessage(e))
  results <<- rbind(results, data.frame(test = name, passed = is.null(error),
      detail = if (is.null(error)) "" else error, stringsAsFactors = FALSE))
  cat(if (is.null(error)) "PASS " else "FAIL ", name, "\n", sep = "")
}
must_error <- function(expression, pattern) {
  message <- tryCatch({ force(expression); NA_character_ }, error = function(e) conditionMessage(e))
  stopifnot(!is.na(message), grepl(pattern, message, ignore.case = TRUE))
}
input <- file.path(root, "examples", "input")
raw_metadata <- read.delim(file.path(input, "metadata.tsv"), colClasses = "character",
                           na.strings = character(), stringsAsFactors = FALSE)
raw_survival <- read.delim(file.path(input, "survival.tsv"), colClasses = "character",
                           na.strings = character(), stringsAsFactors = FALSE)
metadata <- clean_metadata(raw_metadata)
followup <- clean_survival(raw_survival)
joined <- integrate_metadata_survival(metadata$data, followup$data)
expression <- read_expression(file.path(input, "expression.csv"))
pca <- run_pca(expression, metadata$data)
check("metadata normalization, exact duplicate removal and missingness", {
  stopifnot(nrow(raw_metadata) == 82L, nrow(metadata$data) == 80L,
            nrow(metadata$dropped) == 2L, all(grepl("^SYN[0-9]{4}$", metadata$data$sample_id)),
            sum(metadata$data$age_issue == "missing") == 3L,
            sum(metadata$data$age_issue == "invalid_or_out_of_range") == 2L,
            sum(metadata$data$sex == "Unknown") == 1L)
})
check("conflicting duplicate IDs are rejected", {
  conflict <- raw_metadata[1L, , drop = FALSE]
  conflict$age_years <- "99"
  must_error(clean_metadata(rbind(raw_metadata, conflict)), "conflicting|repeated")
})
check("blank identifiers are rejected", {
  invalid <- raw_metadata; invalid$sample_id[1L] <- ""
  must_error(clean_metadata(invalid), "non-empty")
})
check("left join preserves metadata row count and order", {
  stopifnot(nrow(joined$data) == 80L, identical(joined$data$sample_id, metadata$data$sample_id),
            sum(joined$data$has_survival) == 72L, nrow(joined$missing_survival) == 8L,
            identical(joined$orphan_survival$sample_id, "SYN0083"))
})
check("duplicate join keys cannot multiply rows", {
  repeated <- rbind(followup$data, followup$data[1L, ])
  must_error(integrate_metadata_survival(metadata$data, repeated), "conflicting|repeated")
})
check("survival invalid time and event values are audited", {
  stopifnot(nrow(followup$dropped) == 3L,
    setequal(followup$dropped$sample_id, c("SYN0003", "SYN0007", "SYN0012")),
    all(followup$data$event %in% c(0L, 1L)), all(followup$data$time_months > 0))
})
check("Kaplan-Meier agrees with hand-calculated ties and censoring", {
  known <- data.frame(sample_id = sprintf("SYN%04d", 1:7),
    time_months = c(1, 2, 2, 3, 1, 2, 3), event = c(1L, 0L, 1L, 1L, 0L, 0L, 0L),
    group = c(rep("A", 4), rep("B", 3)), has_survival = TRUE)
  fit <- fit_survival(known)
  times <- summary(fit$fit, times = c(1, 2, 3))
  a <- times$surv[as.character(times$strata) == "group=A"]
  b <- times$surv[as.character(times$strata) == "group=B"]
  stopifnot(isTRUE(all.equal(unname(a), c(0.75, 0.5, 0), tolerance = 1e-12)),
            all(b == 1), sum(fit$group_summary$events) == 3L)
})
check("survival fit refuses unclean event values and empty comparisons", {
  invalid <- joined$data; invalid$event[which(invalid$has_survival)[1L]] <- 2L
  must_error(fit_survival(invalid), "Invalid time/event")
  censored <- joined$data; censored$event[censored$has_survival] <- 0L
  must_error(fit_survival(censored), "At least one event")
})
check("PCA uses matched samples and removes only documented bad features", {
  stopifnot(nrow(pca$sample_matrix) == 76L, ncol(pca$sample_matrix) == 10L,
    identical(rownames(pca$sample_matrix), metadata$data$sample_id[1:76]),
    setequal(pca$dropped$feature_id, c("FEATURE11", "FEATURE12")))
})
check("PCA full-component reconstruction and orthogonality", {
  reconstructed <- pca$model$x %*% t(pca$model$rotation)
  expected <- scale(pca$sample_matrix, center = pca$model$center, scale = pca$model$scale)
  stopifnot(max(abs(reconstructed - expected)) < 1e-8,
    max(abs(crossprod(pca$model$rotation) - diag(ncol(pca$model$rotation)))) < 1e-10,
    max(abs(colMeans(pca$model$x))) < 1e-10,
    abs(sum(pca$variance$variance_fraction) - 1) < 1e-10)
})
check("PCA is independent of group labels", {
  changed <- metadata$data; changed$group <- rev(changed$group)
  other <- run_pca(expression, changed)
  stopifnot(isTRUE(all.equal(pca$model$x, other$model$x, tolerance = 1e-12)))
})
check("PCA refuses degenerate constant inputs", {
  constant <- expression; constant[] <- 1
  must_error(run_pca(constant, metadata$data), "two complete, variable")
})
check("input manifest verifies and rejects changed fixtures", {
  verify_fixture(input)
  work <- file.path(root, "work"); dir.create(work, showWarnings = FALSE)
  sandbox <- tempfile("fixture_test_", tmpdir = work)
  dir.create(sandbox)
  copied <- file.copy(list.files(input, full.names = TRUE), sandbox)
  stopifnot(all(copied))
  cat("\nchanged", file = file.path(sandbox, "metadata.tsv"), append = TRUE)
  must_error(verify_fixture(sandbox), "fingerprint mismatch")
  resolved <- normalizePath(sandbox, winslash = "/", mustWork = TRUE)
  allowed <- paste0(normalizePath(work, winslash = "/", mustWork = TRUE), "/")
  stopifnot(startsWith(resolved, allowed))
  unlink(resolved, recursive = TRUE)
})
check("CLI paths reject checkout escape", {
  must_error(repo_path(root, "../outside"), "traversal")
  must_error(repo_path(root, normalizePath(root, winslash = "/", mustWork = TRUE)), "relative")
})
output <- file.path(root, "work", "test_results.csv")
write_csv(results, output)
cat(sprintf("%d/%d checks passed.\n", sum(results$passed), nrow(results)))
if (!all(results$passed)) {
  print(results[!results$passed, , drop = FALSE])
  quit(save = "no", status = 1L)
}
