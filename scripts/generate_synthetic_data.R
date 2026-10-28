# Newly authored, AI-assisted fixtures. No original course/clinical inputs are read.
file_arg <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L])
root <- normalizePath(file.path(dirname(file_arg), ".."), winslash = "/", mustWork = TRUE)
source(file.path(root, "R", "io_utils.R"), encoding = "UTF-8")
options <- parse_options(commandArgs(TRUE), list("output-dir" = "examples/input", seed = "20261029"))
output <- repo_path(root, options[["output-dir"]])
seed <- suppressWarnings(as.integer(options[["seed"]]))
if (is.na(seed) || seed < 0L) stop("Supply a non-negative integer seed.")
files <- c("metadata.tsv", "survival.tsv", "expression.csv", "fixture_manifest.csv")
if (any(file.exists(file.path(output, files)))) stop("Synthetic inputs already exist; choose a fresh output directory.")
dir.create(output, recursive = TRUE, showWarnings = FALSE)
RNGkind("Mersenne-Twister", "Inversion", "Rejection")
set.seed(seed)
n <- 80L
metadata <- data.frame(sample_id = sprintf(" syn%04d ", seq_len(n)),
  age_years = as.character(30L + (seq_len(n) * 7L) %% 50L),
  sex = ifelse(seq_len(n) %% 2L == 0L, " male ", " female "),
  group = ifelse(seq_len(n) %% 2L == 0L, " group_b ", " group_a "), stringsAsFactors = FALSE)
metadata$age_years[c(3, 4)] <- c("-5", "250")
metadata$age_years[c(5, 6, 7)] <- c("NA", "", "not_reported")
metadata$sex[8] <- "not_reported"
metadata <- rbind(metadata, metadata[1, ], metadata[2, ])
write.table(metadata, file.path(output, "metadata.tsv"), sep = "\t", quote = FALSE,
            row.names = FALSE, na = "NA", eol = "\n", fileEncoding = "UTF-8")
survival_ids <- c(seq_len(75L), 83L)
event_time <- rexp(length(survival_ids), rate = 1 / 18)
censor_time <- runif(length(survival_ids), min = 6, max = 36)
survival <- data.frame(sample_id = sprintf("SYN%04d", survival_ids),
  time_months = pmin(event_time, censor_time), event = as.character(as.integer(event_time <= censor_time)))
survival$time_months[3] <- NA_real_
survival$event[7] <- "2"
survival$time_months[12] <- 0
write.table(survival, file.path(output, "survival.tsv"), sep = "\t", quote = FALSE,
            row.names = FALSE, na = "NA", eol = "\n", fileEncoding = "UTF-8")
expression_ids <- c(seq_len(76L), 81L, 82L)
latent <- matrix(rnorm(length(expression_ids) * 3L), ncol = 3L)
weights <- matrix(rnorm(3L * 10L), nrow = 3L)
values <- latent %*% weights + matrix(rnorm(length(expression_ids) * 10L, sd = 0.35), ncol = 10L)
values <- cbind(values, FEATURE11 = rnorm(length(expression_ids)), FEATURE12 = rep(3.14, length(expression_ids)))
values[1L, 11L] <- NA_real_
expression <- data.frame(feature_id = sprintf("FEATURE%02d", seq_len(ncol(values))),
                         t(values), check.names = FALSE)
names(expression)[-1L] <- sprintf("SYN%04d", expression_ids)
write_csv(expression, file.path(output, "expression.csv"))
input_files <- files[1:3]
manifest <- data.frame(file = input_files, md5 = unname(tools::md5sum(file.path(output, input_files))),
  seed = seed, provenance = "self_generated_synthetic", stringsAsFactors = FALSE)
write_csv(manifest, file.path(output, "fixture_manifest.csv"))
cat("Generated synthetic fixtures: 82 metadata rows (80 unique), 76 follow-up rows, 12 features x 78 samples.\n")
cat("Deliberate invalid values and unmatched IDs are teaching cases, not real medical observations.\n")
