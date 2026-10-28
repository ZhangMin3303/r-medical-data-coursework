# Feature rows -> sample rows before centered, unit-variance PCA.
read_expression <- function(file) {
  table <- read.csv(file, check.names = FALSE, stringsAsFactors = FALSE, na.strings = c("", "NA"))
  require_columns(table, "feature_id", "expression")
  if (anyNA(table$feature_id) || any(!nzchar(table$feature_id)) || anyDuplicated(table$feature_id)) {
    stop("Expression feature IDs must be non-empty and unique.")
  }
  values <- table[setdiff(names(table), "feature_id")]
  if (!length(values) || any(!vapply(values, is.numeric, logical(1)))) stop("Expression columns must be numeric.")
  matrix <- as.matrix(values)
  rownames(matrix) <- table$feature_id
  colnames(matrix) <- normalize_id(colnames(matrix))
  if (anyDuplicated(colnames(matrix))) stop("Expression sample IDs must be unique.")
  matrix
}
run_pca <- function(expression, metadata) {
  if (!is.matrix(expression) || !is.numeric(expression)) stop("PCA requires a numeric feature-by-sample matrix.")
  if (is.null(rownames(expression)) || is.null(colnames(expression))) stop("PCA input needs feature and sample identifiers.")
  if (anyDuplicated(rownames(expression))) stop("Duplicate PCA feature identifiers.")
  colnames(expression) <- normalize_id(colnames(expression))
  if (anyDuplicated(colnames(expression))) stop("Duplicate PCA sample identifiers.")
  assert_unique_ids(metadata, label = "PCA metadata")
  require_columns(metadata, "group", "PCA metadata")
  ids <- metadata$sample_id[metadata$sample_id %in% colnames(expression)]
  if (length(ids) < 3L) stop("PCA requires at least three matched samples.")
  used <- expression[, ids, drop = FALSE]
  complete <- apply(used, 1L, function(row) all(is.finite(row)))
  deviation <- apply(used, 1L, stats::sd)
  variable <- is.finite(deviation) & deviation > sqrt(.Machine$double.eps)
  keep <- complete & variable
  dropped <- data.frame(feature_id = rownames(used)[!keep],
      reason = ifelse(!complete[!keep], "missing_or_nonfinite", "constant_or_near_constant"))
  used <- used[keep, , drop = FALSE]
  if (nrow(used) < 2L) stop("PCA needs at least two complete, variable features.")
  sample_matrix <- t(used)
  model <- stats::prcomp(sample_matrix, center = TRUE, scale. = TRUE)
  fraction <- model$sdev^2 / sum(model$sdev^2)
  scores <- data.frame(sample_id = rownames(model$x), model$x, check.names = FALSE)
  scores$group <- metadata$group[match(scores$sample_id, metadata$sample_id)]
  variance <- data.frame(component = colnames(model$x), variance_fraction = fraction,
      cumulative_fraction = cumsum(fraction))
  audit <- data.frame(metric = c("input_features", "input_expression_samples", "matched_samples",
      "expression_without_metadata", "metadata_without_expression", "dropped_features", "used_features"),
    value = c(nrow(expression), ncol(expression), length(ids),
      sum(!colnames(expression) %in% metadata$sample_id), sum(!metadata$sample_id %in% colnames(expression)),
      nrow(dropped), nrow(used)))
  list(model = model, sample_matrix = sample_matrix, scores = scores, variance = variance,
       dropped = dropped, audit = audit)
}
plot_pca <- function(result, directory) {
  colors <- c(GROUP_A = "#196B8C", GROUP_B = "#D0743C")
  open_plot(file.path(directory, "pca_scores.png"))
  on.exit(grDevices::dev.off(), add = TRUE)
  scores <- result$scores
  labels <- sprintf("%s (%.1f%%)", c("PC1", "PC2"), result$variance$variance_fraction[1:2] * 100)
  plot(scores$PC1, scores$PC2, col = colors[as.character(scores$group)], pch = 19,
       xlab = labels[1], ylab = labels[2], main = "PCA: synthetic feature matrix",
       sub = "Exploratory coursework example; groups are plot annotations, not PCA inputs")
  abline(h = 0, v = 0, col = "#DADFE3", lty = 3)
  legend("topright", legend = names(colors), col = colors, pch = 19, bty = "n")
}
plot_scree <- function(result, directory) {
  open_plot(file.path(directory, "pca_scree.png"))
  on.exit(grDevices::dev.off(), add = TRUE)
  plot(seq_len(nrow(result$variance)), result$variance$variance_fraction * 100,
       type = "b", pch = 19, col = "#196B8C", xlab = "Principal component",
       ylab = "Explained variance (%)", main = "PCA explained variance",
       sub = "Synthetic data; variance explained does not establish diagnostic usefulness")
  grid(col = "#E8EDF0")
}
