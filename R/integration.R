# Explicit keys and one-to-one cardinality replace implicit classroom joins.
integrate_metadata_survival <- function(metadata, survival) {
  assert_unique_ids(metadata, label = "clean metadata")
  assert_unique_ids(survival, label = "clean survival")
  matched <- match(metadata$sample_id, survival$sample_id)
  joined <- metadata
  joined$time_months <- survival$time_months[matched]
  joined$event <- survival$event[matched]
  joined$has_survival <- !is.na(matched)
  orphan <- survival$sample_id[!survival$sample_id %in% metadata$sample_id]
  audit <- data.frame(metric = c("metadata_rows", "survival_rows", "matched_metadata_rows",
      "metadata_without_valid_survival", "survival_without_metadata", "joined_rows"),
    value = c(nrow(metadata), nrow(survival), sum(!is.na(matched)),
              sum(is.na(matched)), length(orphan), nrow(joined)))
  list(data = joined, audit = audit,
       missing_survival = data.frame(sample_id = metadata$sample_id[is.na(matched)]),
       orphan_survival = data.frame(sample_id = orphan))
}
