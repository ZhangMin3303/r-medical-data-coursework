# Reviewed reconstruction from coursework themes; substantially AI-assisted.
clean_metadata <- function(raw) {
  require_columns(raw, c("sample_id", "age_years", "sex", "group"), "metadata")
  data <- raw[c("sample_id", "age_years", "sex", "group")]
  data$sample_id <- normalize_id(data$sample_id)
  data$age_years <- trimws(as.character(data$age_years))
  data$sex <- toupper(trimws(as.character(data$sex)))
  data$group <- toupper(trimws(as.character(data$group)))
  # Remove exact normalized duplicates only; never choose between conflicting rows.
  duplicates <- duplicated(data)
  dropped <- data.frame(sample_id = data$sample_id[duplicates], reason = "exact_duplicate", stringsAsFactors = FALSE)
  data <- data[!duplicates, , drop = FALSE]
  assert_unique_ids(data, label = "metadata")
  age_missing <- missing_marker(data$age_years)
  age <- as_number(data$age_years)
  age_invalid <- !age_missing & (!is.finite(age) | age < 0 | age > 120)
  age[age_missing | age_invalid] <- NA_real_
  sex_missing <- missing_marker(data$sex)
  data$age_years <- age
  data$age_issue <- ifelse(age_missing, "missing", ifelse(age_invalid, "invalid_or_out_of_range", ""))
  data$sex <- ifelse(data$sex %in% c("F", "FEMALE"), "Female",
                     ifelse(data$sex %in% c("M", "MALE"), "Male", "Unknown"))
  if (any(!data$group %in% c("GROUP_A", "GROUP_B"))) stop("Unrecognized synthetic group label.")
  data$group <- factor(data$group, levels = c("GROUP_A", "GROUP_B"))
  rownames(data) <- NULL
  audit <- data.frame(metric = c("input_rows", "exact_duplicates_removed", "retained_rows",
      "age_missing", "age_invalid", "sex_unknown"),
    value = c(nrow(raw), sum(duplicates), nrow(data), sum(age_missing), sum(age_invalid), sum(data$sex == "Unknown")))
  list(data = data, dropped = dropped, audit = audit)
}
clean_survival <- function(raw) {
  require_columns(raw, c("sample_id", "time_months", "event"), "survival")
  id <- normalize_id(raw$sample_id)
  time <- as_number(raw$time_months)
  event_text <- trimws(as.character(raw$event))
  event_ok <- !is.na(event_text) & event_text %in% c("0", "1")
  time_ok <- is.finite(time) & time > 0
  reason <- ifelse(!time_ok & !event_ok, "invalid_time_and_event",
                    ifelse(!time_ok, "invalid_time", ifelse(!event_ok, "event_must_be_0_or_1", "")))
  candidate <- data.frame(sample_id = id, time_months = time, event = as_number(event_text), stringsAsFactors = FALSE)
  assert_unique_ids(candidate, label = "survival")
  data <- candidate[time_ok & event_ok, , drop = FALSE]
  data$event <- as.integer(data$event)
  dropped <- data.frame(sample_id = id[!(time_ok & event_ok)], reason = reason[!(time_ok & event_ok)], stringsAsFactors = FALSE)
  rownames(data) <- rownames(dropped) <- NULL
  list(data = data, dropped = dropped, input_rows = nrow(raw))
}
