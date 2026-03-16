# =============================================================================
# High-Performance Employee Analysis
# Purpose: Identify factors that define a high-performance employee at BOLT
# =============================================================================

# --- 1. Load and Merge Data ---------------------------------------------------

employees   <- read.csv("BOLT_casefiles2026/BOLT_Employees.csv")
performance <- read.csv("BOLT_casefiles2026/BOLT_Performance.csv")
applicants  <- read.csv("BOLT_casefiles2026/BOLT_Applicants.csv")
changes     <- read.csv("BOLT_casefiles2026/BOLT_EmployeeChanges.csv")

# Compute average performance score per employee
avg_perf <- aggregate(PerformanceScore ~ EmployeeID, data = performance, FUN = mean)
colnames(avg_perf)[2] <- "AvgPerformance"

# Count number of reviews per employee (proxy for tenure/review frequency)
review_count <- aggregate(PerformanceScore ~ EmployeeID, data = performance, FUN = length)
colnames(review_count)[2] <- "NumReviews"

# Count promotions per employee (role changes that are NOT Quit/Dismissed)
promotions <- changes[!(changes$New.Role %in% c("Quit", "Dismissed")), ]
promo_count <- as.data.frame(table(promotions$EmployeeID))
colnames(promo_count) <- c("EmployeeID", "NumPromotions")
promo_count$EmployeeID <- as.integer(as.character(promo_count$EmployeeID))

# Merge all data together
df <- merge(employees, avg_perf, by = "EmployeeID", all.x = TRUE)
df <- merge(df, review_count, by = "EmployeeID", all.x = TRUE)
df <- merge(df, promo_count, by = "EmployeeID", all.x = TRUE)
df <- merge(df, applicants, by.x = "ApplicantID", by.y = "ApplicantID", all.x = TRUE)

# Fill NA promotions with 0
df$NumPromotions[is.na(df$NumPromotions)] <- 0

# Remove employees without performance reviews
df <- df[!is.na(df$AvgPerformance), ]

# Calculate tenure in years (from HiredOn to today or leaving)
df$HiredOn <- as.Date(df$HiredOn)
df$TenureYears <- as.numeric(difftime(Sys.Date(), df$HiredOn, units = "days")) / 365.25

# Define "High Performer": top 25% by average performance score
threshold <- quantile(df$AvgPerformance, 0.75)
df$HighPerformer <- ifelse(df$AvgPerformance >= threshold, 1, 0)

cat("=== Dataset Summary ===\n")
cat("Total employees with reviews:", nrow(df), "\n")
cat("High-performer threshold (75th pct):", round(threshold, 2), "\n")
cat("High performers:", sum(df$HighPerformer), "\n")
cat("Non-high performers:", sum(df$HighPerformer == 0), "\n\n")

# --- 2. Descriptive Comparison ------------------------------------------------

cat("=== Mean Comparison: High vs Non-High Performers ===\n\n")

compare_vars <- c("AvgWorkingHours.Week", "TenureYears",
                   "YearsOfRelevantExperience", "NumPromotions", "NumReviews")

for (v in compare_vars) {
  high_mean <- mean(df[[v]][df$HighPerformer == 1], na.rm = TRUE)
  low_mean  <- mean(df[[v]][df$HighPerformer == 0], na.rm = TRUE)
  cat(sprintf("%-30s  High: %6.2f   Non-High: %6.2f\n", v, high_mean, low_mean))
}

# Wage distribution
cat("\n=== Wage Distribution (%) ===\n")
wage_table <- prop.table(table(df$HighPerformer, df$Wage), margin = 1)
print(round(wage_table * 100, 1))

# Position (full-time vs part-time)
cat("\n=== Position Distribution (%) ===\n")
pos_table <- prop.table(table(df$HighPerformer, df$Position), margin = 1)
print(round(pos_table * 100, 1))

# Role
cat("\n=== Role Distribution (%) ===\n")
role_table <- prop.table(table(df$HighPerformer, df$Role), margin = 1)
print(round(role_table * 100, 1))

# Education
cat("\n=== Education Distribution (%) ===\n")
edu_table <- prop.table(table(df$HighPerformer, df$HighestEducationLevel), margin = 1)
print(round(edu_table * 100, 1))

# Past experience
cat("\n=== Past Relevant Experience (%) ===\n")
exp_table <- prop.table(table(df$HighPerformer, df$PastRelevantExperience), margin = 1)
print(round(exp_table * 100, 1))

# Branch
cat("\n=== Branch Distribution (%) ===\n")
branch_table <- prop.table(table(df$HighPerformer, df$Branch.), margin = 1)
print(round(branch_table * 100, 1))

# --- 3. Statistical Tests (t-tests / chi-squared) ----------------------------

cat("\n=== Statistical Tests ===\n\n")

# t-tests for continuous variables
for (v in compare_vars) {
  tt <- t.test(df[[v]][df$HighPerformer == 1],
               df[[v]][df$HighPerformer == 0])
  cat(sprintf("t-test for %-30s  p-value: %.4f  %s\n",
              v, tt$p.value,
              ifelse(tt$p.value < 0.05, "*significant*", "")))
}

# Chi-squared tests for categorical variables
cat_vars <- c("Wage", "Position", "Role", "HighestEducationLevel",
              "PastRelevantExperience", "Branch.")
for (v in cat_vars) {
  ct <- chisq.test(table(df$HighPerformer, df[[v]]))
  cat(sprintf("Chi-sq for %-30s  p-value: %.4f  %s\n",
              v, ct$p.value,
              ifelse(ct$p.value < 0.05, "*significant*", "")))
}

# --- 4. Logistic Regression ---------------------------------------------------

cat("\n=== Logistic Regression: Factors Predicting High Performance ===\n\n")

# Prepare factors
df$Wage      <- factor(df$Wage)
df$Position  <- factor(df$Position)
df$Role      <- factor(df$Role)
df$Branch.   <- factor(df$Branch.)
df$HighestEducationLevel <- factor(df$HighestEducationLevel)
df$PastRelevantExperience <- factor(df$PastRelevantExperience)

model <- glm(HighPerformer ~ Wage + Position + Role + Branch. +
               AvgWorkingHours.Week + TenureYears +
               YearsOfRelevantExperience + HighestEducationLevel +
               PastRelevantExperience + NumPromotions,
             data = df, family = binomial)

cat("--- Model Summary ---\n")
print(summary(model))

# Odds ratios with confidence intervals
cat("\n--- Odds Ratios (exp(coef)) ---\n")
or <- exp(coef(model))
ci <- exp(confint.default(model))
or_table <- data.frame(OddsRatio = round(or, 3),
                       CI_Lower  = round(ci[, 1], 3),
                       CI_Upper  = round(ci[, 2], 3))
print(or_table)

# --- 5. Visualizations --------------------------------------------------------

cat("\n=== Generating Plots ===\n")

# Plot 1: Performance Distribution by High vs Non-High
png("performance_distribution.png", width = 800, height = 500)
par(mfrow = c(1, 2), mar = c(5, 4, 3, 1))

hist(df$AvgPerformance[df$HighPerformer == 0],
     main = "Non-High Performers", xlab = "Avg Performance Score",
     col = "lightblue", breaks = 20, xlim = c(55, 100))
abline(v = threshold, col = "red", lwd = 2, lty = 2)

hist(df$AvgPerformance[df$HighPerformer == 1],
     main = "High Performers", xlab = "Avg Performance Score",
     col = "salmon", breaks = 20, xlim = c(55, 100))
abline(v = threshold, col = "red", lwd = 2, lty = 2)
dev.off()

# Plot 2: Boxplots of key continuous factors
png("factor_boxplots.png", width = 1000, height = 600)
par(mfrow = c(2, 3), mar = c(5, 4, 3, 1))

for (v in c(compare_vars, "AvgPerformance")) {
  label <- ifelse(v == "AvgWorkingHours.Week", "Avg Hours/Week", v)
  boxplot(df[[v]] ~ df$HighPerformer,
          names = c("Non-High", "High"),
          main = label,
          col = c("lightblue", "salmon"),
          ylab = label)
}
dev.off()

# Plot 3: Role vs Performance
png("role_performance.png", width = 800, height = 500)
par(mar = c(7, 4, 3, 1))
boxplot(AvgPerformance ~ Role, data = df,
        main = "Average Performance by Role",
        col = rainbow(length(unique(df$Role))),
        ylab = "Avg Performance Score",
        las = 2)
dev.off()

# Plot 4: Wage vs Performance
png("wage_performance.png", width = 800, height = 500)
par(mar = c(5, 4, 3, 1))
boxplot(AvgPerformance ~ Wage, data = df,
        main = "Average Performance by Wage Tier",
        col = c("lightblue", "lightgreen", "salmon"),
        ylab = "Avg Performance Score")
dev.off()

# Plot 5: Promotions vs Performance
png("promotions_performance.png", width = 800, height = 500)
par(mar = c(5, 4, 3, 1))
boxplot(AvgPerformance ~ NumPromotions, data = df,
        main = "Average Performance by Number of Promotions",
        col = heat.colors(length(unique(df$NumPromotions))),
        ylab = "Avg Performance Score",
        xlab = "Number of Promotions")
dev.off()

cat("Plots saved: performance_distribution.png, factor_boxplots.png,\n")
cat("             role_performance.png, wage_performance.png,\n")
cat("             promotions_performance.png\n")

# --- 6. Summary of Key Findings -----------------------------------------------

cat("\n")
cat("=============================================\n")
cat("  KEY FINDINGS: What Defines High Performers\n")
cat("=============================================\n\n")
cat("The logistic regression and descriptive analysis above reveal which\n")
cat("factors significantly predict whether an employee is a high performer\n")
cat("(top 25% by average performance score). Check the model output for:\n\n")
cat("  1. Role        - Do certain roles (Manager, Shift Lead) score higher?\n")
cat("  2. Promotions  - Are promoted employees higher performers?\n")
cat("  3. Wage Tier   - Does Competitive/Premium pay correlate with performance?\n")
cat("  4. Hours/Week  - Do more hours lead to better performance?\n")
cat("  5. Tenure      - Does longer tenure help?\n")
cat("  6. Education   - Does education level matter?\n")
cat("  7. Experience  - Does prior relevant experience predict success?\n")
cat("  8. Branch      - Are some branches producing more high performers?\n")
cat("  9. Position    - Full-time vs part-time performance differences?\n\n")
cat("Look at the p-values and odds ratios in the model output.\n")
cat("Statistically significant factors (p < 0.05) with odds ratio > 1\n")
cat("indicate factors that INCREASE the likelihood of being high-performing.\n")
