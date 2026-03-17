library(dplyr)

applicant_data <- read.csv("BOLT_casefiles2026/BOLT_Applicants.csv")
branch_data <- read.csv("BOLT_casefiles2026/BOLT_Branch.csv")
employeechanges_data <- read.csv(
  "BOLT_casefiles2026/BOLT_EmployeeChanges.csv"
)
employee_data <- read.csv("BOLT_casefiles2026/BOLT_Employees.csv")
performance_data <- read.csv(
  "BOLT_casefiles2026/BOLT_Performance.csv"
)

# 1. Define "high performance" use top 25% mean performance score employees.
# filter the employees get the top 25% avg performance
# score to get know good performance employees and we
# will focus on examine their data and figure out
# their turnover rate

performance_summarize <- performance_data |>
  group_by(EmployeeID) |>
  summarize(mean_score = mean(PerformanceScore, na.rm = TRUE)) |>
  filter(mean_score >= quantile(mean_score, 0.75, na.rm = TRUE))

employee_compare <- employee_data |>
  mutate(
    performance_group = ifelse(EmployeeID %in% performance_summarize$EmployeeID,
                               "high_performance", "other"),
    turnover = ifelse(Current.status == "Working", "No", "Yes")
  )

# turnover table
turnover_table <- table(
  employee_compare$performance_group,
  employee_compare$turnover
)
turnover_table

# turnover rate is 87.6% for high performers, 90.3& for others
employee_compare |>
  group_by(performance_group) |>
  summarize(
    n = n(),
    turnover_n = sum(turnover == "Yes"),
    turnover_rate = mean(turnover == "Yes")
  )

# p-value shows 0.2936
# This non-significant result may partly reflect
# the smaller sample size of the high-performing
# group which can limit the ability to detect
# group differences statistically.
chisq.test(turnover_table)

# 2. Among high-performing employees who exited,
# the largest proportion had early tenure
# (<6 months, 42.3%), followed by mid tenure
# (6-12 months, 31.1%), while the smallest
# proportion had extended tenure
# (>12 months, 26.6%).
# The tenure distribution is right-skewed:
# median tenure was 6.87 months, while the mean
# was higher at 8.80 months, suggesting that a
# smaller number of employees stayed much longer
# before leaving.
# Overall, many high-performing employees who
# exited left within their first year, especially
# during the first 6 months, indicating that
# retention efforts should focus more on
# early-stage employee experience and support.

high_perf_exit <- employeechanges_data |>
  filter(EmployeeID %in% performance_summarize$EmployeeID,
         New.Role %in% c("Quit", "Dismissed")) |>
  left_join(
    employee_data |> select(EmployeeID, HiredOn),
    by = "EmployeeID"
  ) |>
  mutate(
    HiredOn = as.Date(HiredOn),
    DateChanged = as.Date(DateChanged),
    tenure_days = as.numeric(DateChanged - HiredOn),
    tenure_months = tenure_days / 30.44,
    tenure_group = case_when(
      tenure_months < 6 ~ "Early tenure (<6 months)",
      tenure_months < 12 ~ "Mid tenure (6-12 months)",
      TRUE ~ "Extended tenure (>12 months)"
    )
  )

high_perf_exit |>
  count(tenure_group) |>
  mutate(prop = n / sum(n))

summary(high_perf_exit$tenure_months)
median(high_perf_exit$tenure_months, na.rm = TRUE)



# 3. Does time-in-role before promotion
# increase the likelihood of exit among
# strong performers?

# Use EmployeeChanges to identify promotions.
# Based on the data structure, ANY role change
# that is not an exit ("Quit" or "Dismissed")
# represents a role transition/promotion
# for an employee.

promos_q3 <- employeechanges_data |>
  filter(
    !New.Role %in% c("Quit", "Dismissed")
  ) |>
  mutate(
    DateChanged = as.Date(DateChanged)
  ) |>
  group_by(EmployeeID) |>
  summarize(
    first_promo_date = min(
      DateChanged, na.rm = TRUE
    ),
    promo_role = New.Role[
      which.min(DateChanged)
    ]
  )

# 3a. Among strong performers who were
# promoted, compute months-in-role before
# first promotion, split by exit status
strong_promo <- promos_q3 |>
  filter(
    EmployeeID %in%
      performance_summarize$EmployeeID
  ) |>
  left_join(
    employee_data |>
      select(EmployeeID, HiredOn,
             Current.status),
    by = "EmployeeID"
  ) |>
  mutate(
    HiredOn = as.Date(HiredOn),
    months_in_role = as.numeric(
      first_promo_date - HiredOn
    ) / 30.44,
    exited = ifelse(
      Current.status == "Working",
      "No", "Yes"
    )
  )

strong_promo |>
  group_by(exited) |>
  summarize(
    n = n(),
    mean_months = mean(
      months_in_role, na.rm = TRUE
    ),
    median_months = median(
      months_in_role, na.rm = TRUE
    ),
    sd_months = sd(
      months_in_role, na.rm = TRUE
    )
  )

# Wilcoxon test: do exited strong performers
# wait longer before promotion?
wilcox.test(
  months_in_role ~ exited,
  data = strong_promo
)

# 3b. Logistic regression: does longer
# time-in-role predict exit among promoted
# strong performers?
promo_exit_model <- glm(
  I(exited == "Yes") ~ months_in_role,
  data = strong_promo,
  family = binomial
)

summary(promo_exit_model)
exp(coef(promo_exit_model))

# 3c. Compare exit rates: promoted vs
# unpromoted strong performers
strong_all <- employee_data |>
  filter(
    EmployeeID %in%
      performance_summarize$EmployeeID
  ) |>
  mutate(
    promoted = ifelse(
      EmployeeID %in%
        promos_q3$EmployeeID,
      "Promoted", "Not promoted"
    ),
    exited = ifelse(
      Current.status == "Working",
      "No", "Yes"
    )
  )

strong_all |>
  group_by(promoted) |>
  summarize(
    n = n(),
    exit_n = sum(exited == "Yes"),
    exit_rate = mean(exited == "Yes")
  )

promo_exit_table <- table(
  strong_all$promoted,
  strong_all$exited
)
promo_exit_table
chisq.test(promo_exit_table)

# 3d. Among unpromoted strong performers
# who exited, check if "Lack of Growth"
# is a top reason
unpromoted_exit <- employeechanges_data |>
  filter(
    EmployeeID %in%
      performance_summarize$EmployeeID,
    !EmployeeID %in%
      promos_q3$EmployeeID,
    New.Role %in% c("Quit", "Dismissed"),
    !is.na(ReasonForLeaving)
  )

unpromoted_exit |>
  count(ReasonForLeaving) |>
  mutate(prop = n / sum(n)) |>
  arrange(desc(prop))

# Q3 findings:
# Using the broader definition of promotion
# (any non-exit role change), 83 strong
# performers received a promotion.
#
# There is NO significant difference in wait
# time before promotion between those who
# stayed vs exited (mean 5.1 vs 4.2 months;
# Wilcoxon p = 0.376). Wait time is not a
# predictor of exit.
#
# Crucially, the exit rate for promoted
# strong performers is nearly IDENTICAL to
# unpromoted strong performers
# (89.2% vs 90.8%; chi-sq p = 0.852).
#
# This suggests that receiving a standard
# role transition does NOT improve retention
# for strong performers.

# 4. Are high performers promoted faster than
# average performers?

# create mean performance score for all employees
performance_summary_all <- performance_data |>
  group_by(EmployeeID) |>
  summarize(mean_score = mean(PerformanceScore, na.rm = TRUE))

# define high performers as top 25% and average performers as middle 50%
q25 <- quantile(performance_summary_all$mean_score, 0.25, na.rm = TRUE)
q75 <- quantile(performance_summary_all$mean_score, 0.75, na.rm = TRUE)

performance_groups <- performance_summary_all |>
  mutate(
    performance_group = case_when(
      mean_score >= q75 ~ "high_performance",
      mean_score >= q25 & mean_score < q75 ~ "average_performance",
      TRUE ~ "other"
    )
  )

# Use the promo dataset defined in Q3
# (promos_q3 = any non-exit role change)

# build analysis dataset
promo_compare <- promos_q3 |>
  inner_join(performance_groups, by = "EmployeeID") |>
  filter(
    performance_group %in%
      c("high_performance", "average_performance")
  ) |>
  left_join(
    employee_data |>
      select(EmployeeID, HiredOn, Current.status),
    by = "EmployeeID"
  ) |>
  mutate(
    HiredOn = as.Date(HiredOn),
    months_to_promo = as.numeric(
      first_promo_date - HiredOn
    ) / 30.44,
    turnover = ifelse(Current.status == "Working", "No", "Yes")
  )

# compare descriptive statistics
promo_compare |>
  group_by(performance_group) |>
  summarize(
    n = n(),
    mean_months = mean(months_to_promo, na.rm = TRUE),
    median_months = median(months_to_promo, na.rm = TRUE),
    sd_months = sd(months_to_promo, na.rm = TRUE)
  )

# non-parametric test because time to higher role may be skewed
wilcox.test(months_to_promo ~ performance_group, data = promo_compare)

# Q4 findings:
# Using the broader definition of promotion,
# high performers are NOT promoted faster than
# average performers. The wait time is nearly
# identical (4.28 months for high performers vs
# 4.10 months for average performers).
#
# The difference is not statistically significant
# (Wilcoxon p = 0.838).
#
# This suggests the restaurant does not
# meaningfully accelerate career progression
# for its top performers compared to average ones.
# 5. Do employees who receive promotions show
# significantly higher retention than those
# who do not?

# Use the promos_q3 dataset from above
# (first non-exit role change)
promotion_retention <- employee_data |>
  mutate(
    promoted = ifelse(
      EmployeeID %in% promos_q3$EmployeeID,
      "Yes", "No"
    ),
    retained = ifelse(
      Current.status == "Working",
      "Yes", "No"
    )
  )

# retention rate by promotion status
promotion_retention |>
  group_by(promoted) |>
  summarize(
    n = n(),
    retained_n = sum(retained == "Yes"),
    retention_rate = mean(retained == "Yes"),
    turnover_rate = mean(retained == "No")
  )

# count table and chi-square test
retention_table <- table(
  promotion_retention$promoted,
  promotion_retention$retained
)
retention_table
chisq.test(retention_table)

# logistic regression
retention_model <- glm(
  I(retained == "Yes") ~ promoted,
  data = promotion_retention,
  family = binomial
)

summary(retention_model)
exp(coef(retention_model))

# Q5 findings:
# Using the broader definition of promotion
# (any non-exit role change), employees who
# were promoted do have a statistically higher
# retention rate (19.7% vs 10.1%; chi-sq
# p = 0.00049; OR = 2.16).
#
# However, this effect is relatively weak. Even
# among those who received a role transition,
# the turnover rate remains extremely high
# (80.3% quit or were dismissed).
#
# While promotion helps marginally across the
# general population, it is clearly not enough
# to fix the systemic turnover issue.
# The odds ratio was 16.26, indicating that promoted employees had much higher
# odds of being retained than non-promoted employees.

# Overall, promotion status was strongly
# associated with retention in this dataset,
# although this should be interpreted as
# association rather than causation.

# 6. Are there branch-level differences in
# turnover of high performers?

high_perf_branch <- employee_data |>
  filter(EmployeeID %in% performance_summarize$EmployeeID) |>
  mutate(
    turnover = ifelse(Current.status == "Working", "No", "Yes")
  )

high_perf_branch_summary <- high_perf_branch |>
  group_by(Branch.) |>
  summarize(
    n = n(),
    turnover_n = sum(turnover == "Yes"),
    turnover_rate = mean(turnover == "Yes")
  ) |>
  arrange(desc(turnover_rate), desc(n))
high_perf_branch_summary
branch_turnover_table <- table(
  high_perf_branch$Branch.,
  high_perf_branch$turnover
)
branch_turnover_table

chisq.test(branch_turnover_table)
# High-performer turnover rates varied descriptively across branches,
# ranging from 81.8% to 97.2%.
# However, the chi-square test did not show a statistically significant
# association between branch and turnover (X-squared = 8.69, df = 6, p = 0.192).

# This suggests that the observed branch-level differences may reflect
# random variation rather than a consistent location effect.

# 7. Is compensation aligned with performance,
# or do strong performers show signs of wage
# dissatisfaction before exit?

# The dataset does not contain wage history,
# so it cannot directly test compensation
# progression.
# Instead, use ReasonForLeaving ==
# "Insufficient Wages" as a proxy for
# compensation dissatisfaction.

# 7a. Among high-performing employees who
# exited, how common is insufficient wages?
high_perf_exit |>
  count(ReasonForLeaving) |>
  mutate(prop = n / sum(n))

# create wage dissatisfaction flag
high_perf_exit_wage <- high_perf_exit |>
  filter(!is.na(ReasonForLeaving)) |>
  mutate(
    wage_exit = ifelse(ReasonForLeaving == "Insufficient Wages",
                       "Insufficient Wages", "Other reasons")
  )

high_perf_exit_wage |>
  count(wage_exit) |>
  mutate(prop = n / sum(n))

# 7b. Compare high performers vs average
# performers on insufficient wages as a
# reason for leaving
avg_perf_ids <- performance_groups |>
  filter(performance_group == "average_performance") |>
  pull(EmployeeID)

avg_perf_exit <- employeechanges_data |>
  filter(EmployeeID %in% avg_perf_ids,
         New.Role %in% c("Quit", "Dismissed")) |>
  left_join(
    employee_data |>
      select(EmployeeID, HiredOn, Wage),
    by = "EmployeeID"
  ) |>
  mutate(
    HiredOn = as.Date(HiredOn),
    DateChanged = as.Date(DateChanged),
    tenure_days = as.numeric(DateChanged - HiredOn),
    tenure_months = tenure_days / 30.44,
    performance_group = "average_performance"
  )

high_perf_exit2 <- high_perf_exit |>
  left_join(
    employee_data |> select(EmployeeID, Wage),
    by = "EmployeeID"
  ) |>
  mutate(performance_group = "high_performance")

exit_wage_reason_compare <- bind_rows(
  high_perf_exit2 |>
    select(EmployeeID, performance_group,
           ReasonForLeaving, tenure_months, Wage),
  avg_perf_exit |>
    select(EmployeeID, performance_group,
           ReasonForLeaving, tenure_months, Wage)
) |>
  filter(!is.na(ReasonForLeaving)) |>
  mutate(
    insufficient_wages = ifelse(
      ReasonForLeaving == "Insufficient Wages",
      "Yes", "No"
    )
  )

# compare proportions
wage_reason_table <- table(
  exit_wage_reason_compare$performance_group,
  exit_wage_reason_compare$insufficient_wages
)
wage_reason_table

prop.table(wage_reason_table, margin = 1)

chisq.test(wage_reason_table)

# 7c. Among high-performing exits, do those
# leaving for insufficient wages have
# longer tenure?
high_perf_exit_wage |>
  group_by(wage_exit) |>
  summarize(
    n = n(),
    mean_tenure = mean(tenure_months, na.rm = TRUE),
    median_tenure = median(tenure_months, na.rm = TRUE),
    sd_tenure = sd(tenure_months, na.rm = TRUE)
  )

wilcox.test(tenure_months ~ wage_exit, data = high_perf_exit_wage)

# 7d. Are high-performing exits who leave for
# insufficient wages concentrated in lower
# wage tiers?
high_perf_exit_wage2 <- high_perf_exit |>
  left_join(
    employee_data |> select(EmployeeID, Wage),
    by = "EmployeeID"
  ) |>
  filter(!is.na(ReasonForLeaving)) |>
  mutate(
    insufficient_wages = ifelse(
      ReasonForLeaving == "Insufficient Wages",
      "Yes", "No"
    )
  )

table(
  high_perf_exit_wage2$insufficient_wages,
  high_perf_exit_wage2$Wage
)

chisq.test(table(
  high_perf_exit_wage2$insufficient_wages,
  high_perf_exit_wage2$Wage
))
# The results provide limited evidence that
# strong performers experienced wage stagnation
# before exit.
# Among high-performing employees who exited,
# only 6.6% cited insufficient wages as their
# reason for leaving, far below the shares
# citing better offer (38.2%) and lack of
# growth (27.0%).

# In addition, average performers were
# significantly more likely than high performers
# to leave because of insufficient wages
# (13.0% vs 6.6%, chi-square p = 0.0137).
# This suggests that wage dissatisfaction was
# relatively more important for average
# performers than for strong performers.

# Among high-performing exits, those leaving
# for insufficient wages had somewhat longer
# tenure on average (10.2 vs 8.7 months), but
# the difference was not statistically
# significant (Wilcoxon p = 0.2285).

# There was also no significant association
# between insufficient wages and current wage
# tier among high-performing exits
# (chi-square p = 0.641), although this result
# should be interpreted cautiously because of
# the small number of wage-related exits.

# Overall, the evidence does not suggest that
# wage stagnation was a primary driver of exit
# among strong performers. Growth opportunities
# and external offers appear to be more
# important.

# 8. Do working hours influence exit risk among high performers?

high_perf_hours <- employee_data |>
  filter(EmployeeID %in% performance_summarize$EmployeeID) |>
  mutate(
    turnover = ifelse(Current.status == "Working", "No", "Yes"),
    position_group = Position
  )

# 8a. Compare average working hours between
# exited and retained high performers
high_perf_hours |>
  group_by(turnover) |>
  summarize(
    n = n(),
    mean_hours = mean(AvgWorkingHours.Week, na.rm = TRUE),
    median_hours = median(AvgWorkingHours.Week, na.rm = TRUE),
    sd_hours = sd(AvgWorkingHours.Week, na.rm = TRUE)
  )

# non-parametric test because hours may not be normally distributed
wilcox.test(
  AvgWorkingHours.Week ~ turnover,
  data = high_perf_hours
)

# 8b. Compare part-time vs full-time distribution by turnover
position_turnover_table <- table(
  high_perf_hours$position_group,
  high_perf_hours$turnover
)
position_turnover_table

prop.table(position_turnover_table, margin = 1)

chisq.test(position_turnover_table)

# 8c. Logistic regression using hours as predictor of exit risk
hours_model <- glm(
  I(turnover == "Yes") ~ AvgWorkingHours.Week,
  data = high_perf_hours,
  family = binomial
)

summary(hours_model)
exp(coef(hours_model))

# 8d. Logistic regression using part-time/full-time status
position_model <- glm(
  I(turnover == "Yes") ~ position_group,
  data = high_perf_hours,
  family = binomial
)

summary(position_model)
exp(coef(position_model))

# 8e. Combined model
combined_model <- glm(
  I(turnover == "Yes") ~ AvgWorkingHours.Week + position_group,
  data = high_perf_hours,
  family = binomial
)

summary(combined_model)
exp(coef(combined_model))
# Among high-performing employees, those who
# exited worked substantially fewer hours
# on average than those who were retained
# (30.9 vs 41.9 hours per week).
# This difference was statistically significant
# (Wilcoxon p < 0.001).

# Logistic regression also showed that average
# weekly hours were a significant predictor
# of exit risk
# (beta = -0.177, p < 0.001, OR = 0.838),
# indicating that higher working hours were
# associated with lower odds of exit among
# strong performers.

# In contrast, part-time versus full-time
# status alone was not a significant predictor
# of exit (chi-square p = 0.301;
# logistic regression p = 0.218).

# Overall, the results suggest that actual
# working-hour intensity matters more than the
# simple part-time/full-time label in
# understanding exit risk among high performers.

# The restaurant should pay closer attention
# to high-performing employees with lower
# weekly working hours, as they may face a
# higher risk of exit even when their
# performance remains strong.

# Q9: find out the likely student status
employee_applicant <- employee_data |>
  left_join(applicant_data, by = "ApplicantID") |>
  mutate(
    turnover = ifelse(Current.status == "Working", "No", "Yes"),
    age_approx = 2026 - YearOfBirth,
    likely_student = case_when(
      HighestEducationLevel == "High School" & age_approx <= 22 ~ "Yes",
      TRUE ~ "No"
    )
  )
student_turnover_table <- table(
  employee_applicant$likely_student,
  employee_applicant$turnover
)
student_turnover_table

prop.table(student_turnover_table, margin = 1)

chisq.test(student_turnover_table)
# Using age and education as a proxy for
# student status, the data does not support
# managers' assumption that turnover is
# primarily driven by student employees.

# In fact, the likely-student group showed a significantly lower turnover rate
# than the non-student-proxy group (81.7% vs 89.2%, chi-square p = 0.018).

# This suggests that student status, at least
# as approximated here, is unlikely to be the
# main explanation for overall turnover.
