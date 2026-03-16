library(tidyverse)

applicant_data<-read.csv("~/Desktop/BOLT_casefiles2026/BOLT_Applicants.csv")
branch_data<-read.csv("~/Desktop/BOLT_casefiles2026/BOLT_Branch.csv")
employeechanges_data<-read.csv("~/Desktop/BOLT_casefiles2026/BOLT_EmployeeChanges.csv")
employee_data<-read.csv("~/Desktop/BOLT_casefiles2026/BOLT_Employees.csv")
performance_data<-read.csv("~/Desktop/BOLT_casefiles2026/BOLT_Performance.csv")

# 1. Define "high performance" use top 25% mean performance score employees.
# filter the employees get  the top 25% avg performance score to get know good performance
# employees and we will focus on examine their data and figure out their turnover rate

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
turnover_table <- table(employee_compare$performance_group, employee_compare$turnover)
turnover_table

# turnover rate is 87.6% for high performers, 90.3& for others
employee_compare |>
  group_by(performance_group) |>
  summarize(
    n = n(),
    turnover_n = sum(turnover == "Yes"),
    turnover_rate = mean(turnover == "Yes"))

# p-value shows 0.2936
#This non-significant result may partly reflect the smaller sample size of the high-performing group
#which can limit the ability to detect group differences statistically.
chisq.test(turnover_table)

# 2.# Among high-performing employees who exited, the largest proportion had early tenure (<6 months, 42.3%),
# followed by mid tenure (6–12 months, 31.1%), while the smallest proportion had extended tenure (>12 months, 26.6%).
# The tenure distribution is right-skewed: the median tenure was 6.87 months, while the mean was higher at 8.80 months,
# suggesting that a smaller number of employees stayed much longer before leaving.
# Overall, many high-performing employees who exited left within their first year, especially during the first 6 months,
# indicating that retention efforts should focus more on early-stage employee experience and support.

high_perf_exit <- employeechanges_data |>
  filter(EmployeeID %in% performance_summarize$EmployeeID,
         New.Role %in% c("Quit", "Dismissed")) |>
  left_join(employee_data |> select(EmployeeID, HiredOn), by = "EmployeeID") |>
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



# 3. Does time-in-role before promotion increase the likelihood of exit among high performers?

# The dataset does not contain explicit promotion history or previous role information,
# so it cannot directly test whether time-in-role before promotion increases exit likelihood.
# Instead, use ReasonForLeaving to examine whether high-performing employees with longer tenure
# were more likely to leave because of lack of growth.

high_perf_exit_growth <- high_perf_exit |>
  filter(!is.na(ReasonForLeaving)) |>
  mutate(
    growth_exit = ifelse(ReasonForLeaving == "Lack of Growth",
                         "Lack of Growth", "Other reasons")
  )

# count the two groups
high_perf_exit_growth |>
  count(growth_exit)

# compare tenure between employees who left because of lack of growth vs other reasons
high_perf_exit_growth |>
  group_by(growth_exit) |>
  summarize(
    n = n(),
    mean_tenure = mean(tenure_months, na.rm = TRUE),
    median_tenure = median(tenure_months, na.rm = TRUE),
    sd_tenure = sd(tenure_months, na.rm = TRUE)
  )

# non-parametric test because tenure may be skewed
wilcox.test(tenure_months ~ growth_exit, data = high_perf_exit_growth)

# logistic regression:
# does longer tenure increase the likelihood of leaving due to lack of growth?
growth_model <- glm(
  I(ReasonForLeaving == "Lack of Growth") ~ tenure_months,
  data = high_perf_exit_growth,
  family = binomial
)

summary(growth_model)
exp(coef(growth_model))

# This analysis did not reveal a meaningful relationship between tenure
# and leaving because of lack of growth among high-performing employees.
# The differences in tenure were small and not statistically significant,
# suggesting that tenure alone is not a useful predictor in this proxy analysis.

# 4. Are high performers promoted faster than average performers - and if not, why?

# The dataset does not include explicit promotion events or previous role history.
# Therefore, use the first observed move into Shift Lead or Manager as a proxy for promotion timing.

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

# proxy for promotion:
# first observed move into Shift Lead or Manager
promo_proxy <- employeechanges_data |>
  filter(New.Role %in% c("Shift Lead", "Manager")) |>
  mutate(DateChanged = as.Date(DateChanged)) |>
  group_by(EmployeeID) |>
  summarize(first_higher_role_date = min(DateChanged, na.rm = TRUE))

# build analysis dataset
promo_compare <- promo_proxy |>
  inner_join(performance_groups, by = "EmployeeID") |>
  filter(performance_group %in% c("high_performance", "average_performance")) |>
  left_join(employee_data |> select(EmployeeID, HiredOn, Current.status), by = "EmployeeID") |>
  mutate(
    HiredOn = as.Date(HiredOn),
    months_to_higher_role = as.numeric(first_higher_role_date - HiredOn) / 30.44,
    turnover = ifelse(Current.status == "Working", "No", "Yes")
  )

# compare descriptive statistics
promo_compare |>
  group_by(performance_group) |>
  summarize(
    n = n(),
    mean_months = mean(months_to_higher_role, na.rm = TRUE),
    median_months = median(months_to_higher_role, na.rm = TRUE),
    sd_months = sd(months_to_higher_role, na.rm = TRUE)
  )

# non-parametric test because time to higher role may be skewed
wilcox.test(months_to_higher_role ~ performance_group, data = promo_compare)

# simple linear model for the proxy outcome
promo_model <- lm(months_to_higher_role ~ performance_group, data = promo_compare)
summary(promo_model)

# If high performers are not promoted faster, examine possible reasons using available proxies.

# reason 1 proxy: are high performers leaving earlier before reaching higher roles?
employee_compare |>
  group_by(performance_group) |>
  summarize(
    n = n(),
    turnover_n = sum(turnover == "Yes"),
    turnover_rate = mean(turnover == "Yes")
  )

# compare exit tenure for high performers vs average performers
avg_perf_ids <- performance_groups |>
  filter(performance_group == "average_performance") |>
  pull(EmployeeID)

avg_perf_exit <- employeechanges_data |>
  filter(EmployeeID %in% avg_perf_ids,
         New.Role %in% c("Quit", "Dismissed")) |>
  left_join(employee_data |> select(EmployeeID, HiredOn), by = "EmployeeID") |>
  mutate(
    HiredOn = as.Date(HiredOn),
    DateChanged = as.Date(DateChanged),
    tenure_days = as.numeric(DateChanged - HiredOn),
    tenure_months = tenure_days / 30.44
  )

exit_tenure_compare <- bind_rows(
  high_perf_exit |>
    mutate(performance_group = "high_performance") |>
    select(EmployeeID, tenure_months, performance_group, ReasonForLeaving),
  avg_perf_exit |>
    mutate(performance_group = "average_performance") |>
    select(EmployeeID, tenure_months, performance_group, ReasonForLeaving)
)

exit_tenure_compare |>
  group_by(performance_group) |>
  summarize(
    n = n(),
    mean_tenure = mean(tenure_months, na.rm = TRUE),
    median_tenure = median(tenure_months, na.rm = TRUE),
    sd_tenure = sd(tenure_months, na.rm = TRUE)
  )

wilcox.test(tenure_months ~ performance_group, data = exit_tenure_compare)

# reason 2 proxy: among employees who exited, do high performers cite lack of growth more often?
exit_reason_compare <- bind_rows(
  high_perf_exit |>
    mutate(performance_group = "high_performance"),
  avg_perf_exit |>
    mutate(performance_group = "average_performance")
) |>
  filter(!is.na(ReasonForLeaving)) |>
  mutate(
    lack_of_growth = ifelse(ReasonForLeaving == "Lack of Growth", "Yes", "No")
  )

reason_table <- table(exit_reason_compare$performance_group, exit_reason_compare$lack_of_growth)
reason_table

prop.table(reason_table, margin = 1)

chisq.test(reason_table)

#q4:Using the first observed move into Shift Lead or Manager as a proxy for promotion,
# high performers were not promoted faster than average performers.
# Instead, high performers reached a higher role significantly later on average
# (mean: 13.4 vs 8.91 months; Wilcoxon p = 0.025; linear model p = 0.043).

# This slower progression does not appear to be explained by earlier exit.
# Among employees who exited, high performers actually had significantly longer tenure
# than average performers (mean: 8.80 vs 5.24 months; Wilcoxon p = 2.27e-10).

# A more plausible explanation is limited growth opportunity.
# Among exited employees, high performers were significantly more likely than average performers
# to cite lack of growth as a reason for leaving (27.0% vs 16.9%; chi-square p = 0.0022).

# Overall, the results suggest that strong performers were not advancing faster,
# and this may have contributed to higher frustration with growth opportunities.
# These findings suggest that the restaurant may need to strengthen career progression
# for strong performers. Since high-performing employees were not reaching higher
# roles faster, but were more likely to leave because of lack of growth, the company
# should consider earlier career development conversations and clearer promotion criteria.

# In practice, managers could identify high-performing employees earlier and provide
# more visible next-step opportunities, such as stretch assignments, leadership training,
# mentoring, or partial supervisory responsibilities before formal promotion.

# If promotion timing cannot be accelerated immediately, providing clearer signals of
# advancement and development may help reduce frustration and improve retention of top talent.

# 5. Do employees who receive promotions show significantly higher retention
# than those who do not?

# Use first observed move into Shift Lead or Manager as a proxy for promotion.
promoted_ids <- employeechanges_data |>
  filter(New.Role %in% c("Shift Lead", "Manager")) |>
  distinct(EmployeeID)

promotion_retention <- employee_data |>
  mutate(
    promoted = ifelse(EmployeeID %in% promoted_ids$EmployeeID, "Yes", "No"),
    retained = ifelse(Current.status == "Working", "Yes", "No")
  )

# count table
retention_table <- table(promotion_retention$promoted, promotion_retention$retained)
retention_table

# retention rate by promotion status
promotion_retention |>
  group_by(promoted) |>
  summarize(
    n = n(),
    retained_n = sum(retained == "Yes"),
    retention_rate = mean(retained == "Yes"),
    turnover_rate = mean(retained == "No")
  )

# chi-square test
chisq.test(retention_table)

# optional: logistic regression
retention_model <- glm(
  I(retained == "Yes") ~ promoted,
  data = promotion_retention,
  family = binomial
)

summary(retention_model)
exp(coef(retention_model))
# Logistic regression showed that employees who received promotions had
# significantly higher retention than those who did not (p < 2e-16).

# The odds ratio was 16.26, indicating that promoted employees had much higher
# odds of being retained than non-promoted employees.

# Overall, promotion status was strongly associated with retention in this dataset,
# although this should be interpreted as association rather than causation.

# 6. Are there branch-level differences in turnover of high performers?

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
branch_turnover_table <- table(high_perf_branch$Branch., high_perf_branch$turnover)
branch_turnover_table

chisq.test(branch_turnover_table)
# High-performer turnover rates varied descriptively across branches,
# ranging from 81.8% to 97.2%.
# However, the chi-square test did not show a statistically significant
# association between branch and turnover (X-squared = 8.69, df = 6, p = 0.192).

# This suggests that the observed branch-level differences may reflect
# random variation rather than a consistent location effect.

# 7. Is compensation aligned with performance, or do strong performers show signs
# of wage dissatisfaction before exit?

# The dataset does not contain wage history, so it cannot directly test compensation progression.
# Instead, use ReasonForLeaving == "Insufficient Wages" as a proxy for compensation dissatisfaction.

# 7a. Among high-performing employees who exited, how common is insufficient wages?
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

# 7b. Compare high performers vs average performers on insufficient wages as a reason for leaving
avg_perf_ids <- performance_groups |>
  filter(performance_group == "average_performance") |>
  pull(EmployeeID)

avg_perf_exit <- employeechanges_data |>
  filter(EmployeeID %in% avg_perf_ids,
         New.Role %in% c("Quit", "Dismissed")) |>
  left_join(employee_data |> select(EmployeeID, HiredOn, Wage), by = "EmployeeID") |>
  mutate(
    HiredOn = as.Date(HiredOn),
    DateChanged = as.Date(DateChanged),
    tenure_days = as.numeric(DateChanged - HiredOn),
    tenure_months = tenure_days / 30.44,
    performance_group = "average_performance"
  )

high_perf_exit2 <- high_perf_exit |>
  left_join(employee_data |> select(EmployeeID, Wage), by = "EmployeeID") |>
  mutate(performance_group = "high_performance")

exit_wage_reason_compare <- bind_rows(
  high_perf_exit2 |> select(EmployeeID, performance_group, ReasonForLeaving, tenure_months, Wage),
  avg_perf_exit |> select(EmployeeID, performance_group, ReasonForLeaving, tenure_months, Wage)
) |>
  filter(!is.na(ReasonForLeaving)) |>
  mutate(
    insufficient_wages = ifelse(ReasonForLeaving == "Insufficient Wages", "Yes", "No")
  )

# compare proportions
wage_reason_table <- table(exit_wage_reason_compare$performance_group,
                           exit_wage_reason_compare$insufficient_wages)
wage_reason_table

prop.table(wage_reason_table, margin = 1)

chisq.test(wage_reason_table)

# 7c. Among high-performing exits, do those leaving for insufficient wages have longer tenure?
high_perf_exit_wage |>
  group_by(wage_exit) |>
  summarize(
    n = n(),
    mean_tenure = mean(tenure_months, na.rm = TRUE),
    median_tenure = median(tenure_months, na.rm = TRUE),
    sd_tenure = sd(tenure_months, na.rm = TRUE)
  )

wilcox.test(tenure_months ~ wage_exit, data = high_perf_exit_wage)

# 7d. Are high-performing exits who leave for insufficient wages concentrated in lower wage tiers?
high_perf_exit_wage2 <- high_perf_exit |>
  left_join(employee_data |> select(EmployeeID, Wage), by = "EmployeeID") |>
  filter(!is.na(ReasonForLeaving)) |>
  mutate(
    insufficient_wages = ifelse(ReasonForLeaving == "Insufficient Wages", "Yes", "No")
  )

table(high_perf_exit_wage2$insufficient_wages, high_perf_exit_wage2$Wage)

chisq.test(table(high_perf_exit_wage2$insufficient_wages, high_perf_exit_wage2$Wage))
# The results provide limited evidence that strong performers experienced wage stagnation before exit.
# Among high-performing employees who exited, only 6.6% cited insufficient wages as their reason for leaving,
# far below the shares citing better offer (38.2%) and lack of growth (27.0%).

# In addition, average performers were significantly more likely than high performers
# to leave because of insufficient wages (13.0% vs 6.6%, chi-square p = 0.0137).
# This suggests that wage dissatisfaction was relatively more important for average performers
# than for strong performers.

# Among high-performing exits, those leaving for insufficient wages had somewhat longer tenure
# on average (10.2 vs 8.7 months), but the difference was not statistically significant
# (Wilcoxon p = 0.2285).

# There was also no significant association between insufficient wages and current wage tier
# among high-performing exits (chi-square p = 0.641), although this result should be interpreted
# cautiously because of the small number of wage-related exits.

# Overall, the evidence does not suggest that wage stagnation was a primary driver of exit
# among strong performers. Growth opportunities and external offers appear to be more important.

# 8. Do working hours influence exit risk among high performers?

high_perf_hours <- employee_data |>
  filter(EmployeeID %in% performance_summarize$EmployeeID) |>
  mutate(
    turnover = ifelse(Current.status == "Working", "No", "Yes"),
    position_group = Position
  )

# 8a. Compare average working hours between exited and retained high performers
high_perf_hours |>
  group_by(turnover) |>
  summarize(
    n = n(),
    mean_hours = mean(AvgWorkingHours.Week, na.rm = TRUE),
    median_hours = median(AvgWorkingHours.Week, na.rm = TRUE),
    sd_hours = sd(AvgWorkingHours.Week, na.rm = TRUE)
  )

# non-parametric test because hours may not be normally distributed
wilcox.test(AvgWorkingHours.Week ~ turnover, data = high_perf_hours)

# 8b. Compare part-time vs full-time distribution by turnover
position_turnover_table <- table(high_perf_hours$position_group, high_perf_hours$turnover)
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
# Among high-performing employees, those who exited worked substantially fewer hours
# on average than those who were retained (30.9 vs 41.9 hours per week).
# This difference was statistically significant (Wilcoxon p < 0.001).

# Logistic regression also showed that average weekly hours were a significant predictor
# of exit risk (beta = -0.177, p < 0.001, OR = 0.838), indicating that higher working hours
# were associated with lower odds of exit among strong performers.

# In contrast, part-time versus full-time status alone was not a significant predictor
# of exit (chi-square p = 0.301; logistic regression p = 0.218).

# Overall, the results suggest that actual working-hour intensity matters more than the
# simple part-time/full-time label in understanding exit risk among high performers.

#The restaurant should pay closer attention to high-performing employees
# with lower weekly working hours, as they may face a higher risk of exit even when
# their performance remains strong.

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
student_turnover_table <- table(employee_applicant$likely_student, employee_applicant$turnover)
student_turnover_table

prop.table(student_turnover_table, margin = 1)

chisq.test(student_turnover_table)
# Using age and education as a proxy for student status, the data does not support
# managers' assumption that turnover is primarily driven by student employees.

# In fact, the likely-student group showed a significantly lower turnover rate
# than the non-student-proxy group (81.7% vs 89.2%, chi-square p = 0.018).

# This suggests that student status, at least as approximated here, is unlikely to be
# the main explanation for overall turnover.
