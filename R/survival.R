# Right-censored, synthetic-only teaching example; event 1 = event, 0 = censored.
fit_survival <- function(joined) {
  if (!requireNamespace("survival", quietly = TRUE)) stop("Install the survival package before running this example.")
  require_columns(joined, c("sample_id", "time_months", "event", "group", "has_survival"), "joined data")
  data <- joined[joined$has_survival, , drop = FALSE]
  if (!nrow(data)) stop("No eligible survival records.")
  if (any(!is.finite(data$time_months) | data$time_months <= 0) ||
      anyNA(data$event) || any(!data$event %in% c(0L, 1L))) stop("Invalid time/event values; clean and audit inputs first.")
  if (anyNA(data$group)) stop("Missing survival group.")
  data$group <- droplevels(factor(data$group))
  if (nlevels(data$group) < 2L) stop("Need at least two observed groups.")
  if (sum(data$event) == 0L) stop("At least one event is required for the comparison example.")
  # No rounding or days-to-month conversion is performed at analysis time.
  fit <- survival::survfit(survival::Surv(time_months, event) ~ group, data = data)
  logrank <- survival::survdiff(survival::Surv(time_months, event) ~ group, data = data)
  dof <- length(logrank$n) - 1L
  test <- data.frame(test = "logrank_synthetic_only", chisq = unname(logrank$chisq), df = dof,
      p_value = stats::pchisq(logrank$chisq, df = dof, lower.tail = FALSE))
  grid <- pretty(c(0, max(data$time_months)), n = 5)
  grid <- grid[grid >= 0 & grid <= max(data$time_months)]
  risk <- summary(fit, times = grid, extend = TRUE)
  risk_table <- data.frame(group = sub("^group=", "", as.character(risk$strata)),
      time_months = risk$time, at_risk = risk$n.risk, events_in_interval = risk$n.event,
      censored_in_interval = risk$n.censor)
  group_summary <- do.call(rbind, lapply(levels(data$group), function(group) {
    subset <- data[data$group == group, , drop = FALSE]
    data.frame(group = group, n = nrow(subset), events = sum(subset$event),
      censored = sum(subset$event == 0L), max_observed_months = max(subset$time_months))
  }))
  list(fit = fit, data = data, group_summary = group_summary, risk_table = risk_table, test = test)
}
plot_survival <- function(result, directory) {
  open_plot(file.path(directory, "kaplan_meier.png"))
  on.exit(grDevices::dev.off(), add = TRUE)
  colors <- c("#196B8C", "#D0743C")
  plot(result$fit, col = colors, lwd = 2.5, mark.time = TRUE, conf.int = FALSE,
       xlab = "Observed follow-up (months)", ylab = "Estimated event-free probability",
       main = "Kaplan-Meier: simulated follow-up",
       sub = "Synthetic data only; 1 = event, 0 = right-censored; no clinical inference")
  legend("topright",
      legend = sprintf("%s (n = %d)", result$group_summary$group, result$group_summary$n),
      col = colors, lwd = 2.5, bty = "n")
}
