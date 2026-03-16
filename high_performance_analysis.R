# =============================================================================
# High-Performance Employee Tenure Exit Analysis
# Question: At what point in tenure are high-performing employees most likely
#           to exit? (early tenure vs. after extended time in role)
# =============================================================================

# --- 1. Load Data -------------------------------------------------------------

employees   <- read.csv("BOLT_casefiles2026/BOLT_Employees.csv")
performance <- read.csv("BOLT_casefiles2026/BOLT_Performance.csv")
changes     <- read.csv("BOLT_casefiles2026/BOLT_EmployeeChanges.csv")

# --- 2. Compute Average Performance Per Employee -----------------------------

avg_perf <- aggregate(PerformanceScore ~ EmployeeID, data = performance, FUN = mean)
colnames(avg_perf)[2] <- "AvgPerformance"

df <- merge(employees, avg_perf, by = "EmployeeID", all.x = TRUE)
df <- df[!is.na(df$AvgPerformance), ]

# --- 3. Define High Performers (Top 25%) -------------------------------------

threshold <- quantile(df$AvgPerformance, 0.75)
df$HighPerformer <- ifelse(df$AvgPerformance >= threshold, "High Performer", "Other")

cat("=============================================================\n")
cat("  HIGH PERFORMER DEFINITION (Top 25%)\n")
cat("=============================================================\n\n")
cat(sprintf("  Threshold (75th pct): %.2f\n", threshold))
cat(sprintf("  High Performers: %d  |  Others: %d\n\n",
            sum(df$HighPerformer == "High Performer"),
            sum(df$HighPerformer == "Other")))

# --- 4. Turnover Rate Comparison ----------------------------------------------

df$TurnedOver <- ifelse(df$Current.status %in% c("Left", "Fired"), 1, 0)

cat("=============================================================\n")
cat("  TURNOVER RATE: HIGH PERFORMERS vs OTHERS\n")
cat("=============================================================\n\n")

turnover_table <- table(df$HighPerformer, df$TurnedOver)
colnames(turnover_table) <- c("Retained", "Turned Over")
cat("--- Turnover Counts ---\n\n")
print(turnover_table)

cat("\n--- Turnover Rates ---\n\n")
for (grp in c("High Performer", "Other")) {
  total    <- sum(df$HighPerformer == grp)
  left     <- sum(df$HighPerformer == grp & df$TurnedOver == 1)
  retained <- total - left
  rate     <- 100 * left / total
  cat(sprintf("  %s:\n", grp))
  cat(sprintf("    Total: %d  |  Turned Over: %d  |  Retained: %d\n", total, left, retained))
  cat(sprintf("    Turnover Rate: %.1f%%\n\n", rate))
}

hp_rate    <- 100 * sum(df$HighPerformer == "High Performer" & df$TurnedOver == 1) /
                    sum(df$HighPerformer == "High Performer")
other_rate <- 100 * sum(df$HighPerformer == "Other" & df$TurnedOver == 1) /
                    sum(df$HighPerformer == "Other")
diff_rate  <- hp_rate - other_rate
cat(sprintf("  Difference: High Performers turnover is %.1f pp %s than Others\n\n",
            abs(diff_rate), ifelse(diff_rate > 0, "HIGHER", "LOWER")))

# Chi-squared test
chi_test <- chisq.test(table(df$HighPerformer, df$TurnedOver))
cat(sprintf("  Chi-squared p-value: %.4f  (%s)\n\n",
            chi_test$p.value,
            ifelse(chi_test$p.value < 0.05, "significant", "not significant")))

# Turnover type breakdown (Quit vs Dismissed)
quit_ids      <- unique(changes$EmployeeID[changes$New.Role == "Quit"])
dismissed_ids <- unique(changes$EmployeeID[changes$New.Role == "Dismissed"])

df$TurnoverType <- "Retained"
df$TurnoverType[df$EmployeeID %in% quit_ids & df$TurnedOver == 1]      <- "Quit"
df$TurnoverType[df$EmployeeID %in% dismissed_ids & df$TurnedOver == 1] <- "Dismissed"

cat("--- Turnover Type Breakdown ---\n\n")
type_table <- table(df$HighPerformer, df$TurnoverType)
cat("Counts:\n")
print(type_table)
cat("\nPercentages (row-wise):\n")
print(round(prop.table(type_table, margin = 1) * 100, 1))

cat("\n")
for (grp in c("High Performer", "Other")) {
  total   <- sum(df$HighPerformer == grp)
  quit_n  <- sum(df$HighPerformer == grp & df$TurnoverType == "Quit")
  fire_n  <- sum(df$HighPerformer == grp & df$TurnoverType == "Dismissed")
  cat(sprintf("  %s:  Quit rate = %.1f%%  |  Dismissal rate = %.1f%%\n",
              grp, 100 * quit_n / total, 100 * fire_n / total))
}

# Top quit reasons
cat("\n--- Top Reasons High Performers Quit ---\n\n")
hp_ids <- df$EmployeeID[df$HighPerformer == "High Performer"]
hp_quits <- changes[changes$EmployeeID %in% hp_ids & changes$New.Role == "Quit", ]
if (nrow(hp_quits) > 0) {
  reason_table <- sort(table(hp_quits$ReasonForLeaving), decreasing = TRUE)
  for (i in seq_along(reason_table)) {
    cat(sprintf("  %2d. %-25s  %d (%.1f%%)\n",
                i, names(reason_table)[i], reason_table[i],
                100 * reason_table[i] / sum(reason_table)))
  }
}

cat("\n--- Top Reasons Others Quit ---\n\n")
other_ids <- df$EmployeeID[df$HighPerformer == "Other"]
other_quits <- changes[changes$EmployeeID %in% other_ids & changes$New.Role == "Quit", ]
if (nrow(other_quits) > 0) {
  reason_table2 <- sort(table(other_quits$ReasonForLeaving), decreasing = TRUE)
  for (i in seq_along(reason_table2)) {
    cat(sprintf("  %2d. %-25s  %d (%.1f%%)\n",
                i, names(reason_table2)[i], reason_table2[i],
                100 * reason_table2[i] / sum(reason_table2)))
  }
}

cat("\n")

# --- 5. Calculate Tenure for Exited Employees ---------------------------------

df$HiredOn <- as.Date(df$HiredOn)

# Get exit dates from EmployeeChanges (last Quit or Dismissed event)
exits <- changes[changes$New.Role %in% c("Quit", "Dismissed"), ]
# Keep the LAST exit event per employee (some have multiple entries)
exits <- exits[order(exits$EmployeeID, exits$DateChanged), ]
last_exit <- aggregate(DateChanged ~ EmployeeID, data = exits, FUN = max)
colnames(last_exit)[2] <- "ExitDate"
last_exit$ExitDate <- as.Date(last_exit$ExitDate)

# Also get the exit type (Quit vs Dismissed)
exit_type <- exits[!duplicated(exits$EmployeeID, fromLast = TRUE),
                   c("EmployeeID", "New.Role", "ReasonForLeaving")]
colnames(exit_type)[2] <- "ExitType"

# Merge exit info
df <- merge(df, last_exit, by = "EmployeeID", all.x = TRUE)
df <- merge(df, exit_type, by = "EmployeeID", all.x = TRUE)

# Filter to only exited employees
exited <- df[df$Current.status %in% c("Left", "Fired"), ]
exited$TenureMonths <- as.numeric(difftime(exited$ExitDate, exited$HiredOn, units = "days")) / 30.44
# Remove any with missing exit dates
exited <- exited[!is.na(exited$TenureMonths), ]

cat("=============================================================\n")
cat("  TENURE AT EXIT: HIGH PERFORMERS vs OTHERS\n")
cat("=============================================================\n\n")

# --- 5. Tenure Summary Statistics ---------------------------------------------

cat("--- Tenure at Exit (Months) ---\n\n")

for (grp in c("High Performer", "Other")) {
  tenure <- exited$TenureMonths[exited$HighPerformer == grp]
  cat(sprintf("  %s (n = %d):\n", grp, length(tenure)))
  cat(sprintf("    Min: %5.1f  |  Q1: %5.1f  |  Median: %5.1f  |  Q3: %5.1f  |  Max: %5.1f\n",
              min(tenure), quantile(tenure, 0.25), median(tenure),
              quantile(tenure, 0.75), max(tenure)))
  cat(sprintf("    Mean: %.1f months (%.1f years)\n\n", mean(tenure), mean(tenure) / 12))
}

# t-test
tt <- t.test(exited$TenureMonths[exited$HighPerformer == "High Performer"],
             exited$TenureMonths[exited$HighPerformer == "Other"])
cat(sprintf("  t-test p-value: %.4f  %s\n\n",
            tt$p.value, ifelse(tt$p.value < 0.05, "*significant*", "not significant")))

# --- 6. Tenure Buckets -------------------------------------------------------

cat("--- Tenure Bucket Analysis ---\n\n")

exited$TenureBucket <- cut(exited$TenureMonths,
                           breaks = c(-Inf, 6, 12, 18, 24, 36, Inf),
                           labels = c("0-6 mo", "6-12 mo", "12-18 mo",
                                      "18-24 mo", "24-36 mo", "36+ mo"))

# Counts
bucket_table <- table(exited$HighPerformer, exited$TenureBucket)
cat("Counts:\n")
print(bucket_table)

# Percentages
cat("\nPercentages (row-wise):\n")
bucket_pct <- prop.table(bucket_table, margin = 1) * 100
print(round(bucket_pct, 1))

# Peak exit period
cat("\n--- Peak Exit Period ---\n\n")
for (grp in c("High Performer", "Other")) {
  pcts <- bucket_pct[grp, ]
  peak <- names(which.max(pcts))
  cat(sprintf("  %s: Peak exit at %s (%.1f%% of exits)\n", grp, peak, max(pcts)))
}

# Cumulative exit analysis
cat("\n--- Cumulative Exit by Tenure ---\n\n")
for (grp in c("High Performer", "Other")) {
  pcts <- bucket_pct[grp, ]
  cum_pct <- cumsum(pcts)
  cat(sprintf("  %s:\n", grp))
  for (i in seq_along(cum_pct)) {
    cat(sprintf("    By %-10s: %5.1f%% exited\n", names(cum_pct)[i], cum_pct[i]))
  }
  cat("\n")
}

# --- 7. Reasons by Tenure Bucket for High Performers -------------------------

cat("--- High Performer Quit Reasons by Tenure ---\n\n")

hp_exited <- exited[exited$HighPerformer == "High Performer" & exited$ExitType == "Quit", ]

if (nrow(hp_exited) > 0) {
  reason_by_tenure <- table(hp_exited$TenureBucket, hp_exited$ReasonForLeaving)
  cat("Counts:\n")
  print(reason_by_tenure)

  cat("\nPercentages within each tenure bucket:\n")
  reason_pct <- prop.table(reason_by_tenure, margin = 1) * 100
  print(round(reason_pct, 1))
}

# --- 8. Visualizations --------------------------------------------------------

cat("\n=== Generating Plots ===\n")

# Plot 1: Tenure distribution comparison
png("tenure_exit_distribution.png", width = 1000, height = 600)
par(mfrow = c(1, 2), mar = c(5, 4, 4, 2))

hist(exited$TenureMonths[exited$HighPerformer == "High Performer"],
     breaks = seq(0, max(exited$TenureMonths, na.rm = TRUE) + 6, by = 3),
     main = "High Performers - Tenure at Exit",
     xlab = "Tenure (Months)", col = "salmon", xlim = c(0, 70),
     freq = FALSE, ylab = "Density")
abline(v = median(exited$TenureMonths[exited$HighPerformer == "High Performer"]),
       col = "red", lwd = 2, lty = 2)
legend("topright", "Median", col = "red", lty = 2, lwd = 2)

hist(exited$TenureMonths[exited$HighPerformer == "Other"],
     breaks = seq(0, max(exited$TenureMonths, na.rm = TRUE) + 6, by = 3),
     main = "Others - Tenure at Exit",
     xlab = "Tenure (Months)", col = "lightblue", xlim = c(0, 70),
     freq = FALSE, ylab = "Density")
abline(v = median(exited$TenureMonths[exited$HighPerformer == "Other"]),
       col = "blue", lwd = 2, lty = 2)
legend("topright", "Median", col = "blue", lty = 2, lwd = 2)

dev.off()

# Plot 2: Grouped bar chart of tenure buckets
png("tenure_buckets.png", width = 900, height = 550)
par(mar = c(6, 5, 4, 2))

barplot(bucket_pct, beside = TRUE,
        col = c("salmon", "lightblue"),
        main = "Exit Distribution by Tenure Bucket",
        ylab = "% of Group's Exits", xlab = "",
        legend.text = c("High Performers", "Others"),
        args.legend = list(x = "topright"),
        las = 2, ylim = c(0, max(bucket_pct) + 5))

dev.off()

# Plot 3: Boxplot comparison
png("tenure_boxplot.png", width = 700, height = 500)
par(mar = c(5, 5, 4, 2))

boxplot(TenureMonths ~ HighPerformer, data = exited,
        col = c("salmon", "lightblue"),
        main = "Tenure at Exit: High Performers vs Others",
        ylab = "Tenure (Months)",
        xlab = "")

dev.off()

cat("Plots saved: tenure_exit_distribution.png, tenure_buckets.png, tenure_boxplot.png\n")
