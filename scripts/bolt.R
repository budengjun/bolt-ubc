library(dplyr)

applicant_data <- read.csv("data/casefiles/BOLT_Applicants.csv")
branch_data <- read.csv("data/casefiles/BOLT_Branch.csv")
employeechanges_data <- read.csv(
  "data/casefiles/BOLT_EmployeeChanges.csv"
)
employee_data <- read.csv("data/casefiles/BOLT_Employees.csv")
performance_data <- read.csv(
  "data/casefiles/BOLT_Performance.csv"
)

# =====================================================================
# BASELINE: Define "high performance"
# =====================================================================
# Define "high performance" use top 25% mean performance score employees.
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
print(turnover_table)

# turnover rate is 87.6% for high performers, 90.3& for others
print(
  employee_compare |>
    group_by(performance_group) |>
    summarize(
      n = n(),
      turnover_n = sum(turnover == "Yes"),
      turnover_rate = mean(turnover == "Yes")
    )
)

# p-value shows 0.2936
# This non-significant result may partly reflect
# the smaller sample size of the high-performing
# group which can limit the ability to detect
# group differences statistically.
print(chisq.test(turnover_table))

# =====================================================================
# HYPOTHESIS 1: HIRING (FAVORED PROFILES)
# =====================================================================
employee_applicant <- employee_data |> 
  left_join(applicant_data, by = "ApplicantID") |>
  mutate(
    turnover = ifelse(Current.status == "Working", "No", "Yes")
  )

# Plot: High performers distribution by the 4 profile groups
library(ggplot2)

# classify ALL employees into 4 groups
all_classified <- employee_applicant |>
  mutate(
    higher_education = ifelse(HighestEducationLevel %in% c("Bachelor", "Master", "PhD"), "Yes", "No"),
    has_experience = ifelse(PastRelevantExperience == "True", "Yes", "No"),
    Group = case_when(
      higher_education == "No" & has_experience == "No" ~ "Neither Trait\n(Baseline)",
      higher_education == "Yes" & has_experience == "No" ~ "Only Higher\nEducation",
      higher_education == "No" & has_experience == "Yes" ~ "Only Relevant\nExperience",
      higher_education == "Yes" & has_experience == "Yes" ~ "BOTH\n(Education + Experience)"
    ),
    is_hp = EmployeeID %in% performance_summarize$EmployeeID
  )

group_levels <- c("Neither Trait\n(Baseline)", "Only Higher\nEducation", "Only Relevant\nExperience", "BOTH\n(Education + Experience)")

hp_dist <- all_classified |>
  group_by(Group) |>
  summarize(
    total = n(),
    hp_count = sum(is_hp),
    hp_pct = mean(is_hp),
    .groups = "drop"
  ) |>
  # ensure all 4 groups appear
  right_join(tibble(Group = group_levels), by = "Group") |>
  mutate(
    total = ifelse(is.na(total), 0L, total),
    hp_count = ifelse(is.na(hp_count), 0L, hp_count),
    hp_pct = ifelse(is.na(hp_pct), 0, hp_pct),
    Group = factor(Group, levels = group_levels)
  )

p_hp_dist <- ggplot(hp_dist, aes(x = Group, y = hp_count, fill = Group)) +
  geom_bar(stat = "identity", width = 0.6) +
  geom_text(aes(label = paste0(hp_count, " / ", total, "\n(", scales::percent(hp_pct, accuracy = 0.1), ")")),
            vjust = -0.5, size = 4, fontface = "bold") +
  scale_fill_manual(values = c("#9DB2B1", "#4C787E", "#2B547E", "#B22222")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.2))) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", hjust = 0.5),
    axis.text.x = element_text(face = "bold", size = 11)
  ) +
  labs(
    title = "High Performers as % of All Employees by Hiring Profile",
    x = NULL,
    y = "High Performer Count"
  )
ggsave("output/figures/hiring/bolt_hp_edu_exp_dist.png", p_hp_dist, width = 8, height = 5, bg = "white")
print("Plot saved as output/figures/hiring/bolt_hp_edu_exp_dist.png")

# Do favored hiring profiles (higher education, relevant experience) exhibit higher turnover?
employee_applicant_profile <- employee_applicant |>
  mutate(
    higher_education = ifelse(HighestEducationLevel %in% c("Bachelor", "Master", "PhD"), "Yes", "No"),
    has_experience = ifelse(PastRelevantExperience == "True", "Yes", "No")
  )

# Education vs Turnover
edu_turnover_table <- table(
  employee_applicant_profile$higher_education,
  employee_applicant_profile$turnover
)
print("--- Education vs Turnover ---")
print(edu_turnover_table)
print(prop.table(edu_turnover_table, margin = 1))
print(chisq.test(edu_turnover_table))

# Experience vs Turnover
exp_turnover_table <- table(
  employee_applicant_profile$has_experience,
  employee_applicant_profile$turnover
)
print("--- Experience vs Turnover ---")
print(exp_turnover_table)
print(prop.table(exp_turnover_table, margin = 1))
print(chisq.test(exp_turnover_table))

# Logistic Regression Modeling Both
profile_model <- glm(
  I(turnover == "Yes") ~ higher_education + has_experience,
  data = employee_applicant_profile,
  family = binomial
)
print("--- Logistic Regression ---")
print(summary(profile_model))
print(exp(coef(profile_model)))

# Combined Profile (Both Education and Experience)
employee_applicant_profile <- employee_applicant_profile |>
  mutate(
    combined_favored = ifelse(higher_education == "Yes" & has_experience == "Yes", "Yes", "No")
  )

combined_table <- table(employee_applicant_profile$combined_favored, employee_applicant_profile$turnover)
print("--- Combined Profile vs Turnover ---")
print(combined_table)
print(prop.table(combined_table, margin = 1))
print(chisq.test(combined_table))

print("--- Breakdown of all 4 groups ---")
all_groups_table <- table(interaction(employee_applicant_profile$higher_education, employee_applicant_profile$has_experience), employee_applicant_profile$turnover)
print(prop.table(all_groups_table, margin = 1))

# Generate presentation plot for favored profiles
library(ggplot2)
summary_data <- employee_applicant_profile |>
  mutate(
    Group = case_when(
      higher_education == "No" & has_experience == "No" ~ "Neither Trait\n(Baseline)",
      higher_education == "Yes" & has_experience == "No" ~ "Only Higher\nEducation",
      higher_education == "No" & has_experience == "Yes" ~ "Only Relevant\nExperience",
      higher_education == "Yes" & has_experience == "Yes" ~ "BOTH\n(Education + Experience)"
    )
  ) |>
  group_by(Group) |>
  summarize(
    TurnoverRate = mean(turnover == "Yes"),
    Count = n()
  ) |>
  mutate(
    Group = factor(Group, levels = c("Neither Trait\n(Baseline)", "Only Higher\nEducation", "Only Relevant\nExperience", "BOTH\n(Education + Experience)"))
  )

p <- ggplot(summary_data, aes(x = Group, y = TurnoverRate, fill = Group)) +
  geom_bar(stat = "identity", width = 0.6) +
  geom_text(aes(label = paste0(scales::percent(TurnoverRate, accuracy = 0.1), "\n(n=", Count, ")")), 
            vjust = -0.5, size = 4.5, fontface = "bold") +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1.0)) +
  scale_fill_manual(values = c("#9DB2B1", "#4C787E", "#2B547E", "#B22222")) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30"),
    axis.text.x = element_text(face = "bold", size = 11, vjust = 1)
  ) +
  labs(
    title = "Turnover Rates by Education and Experience",
    x = NULL,
    y = "Turnover Rate"
  )
ggsave("output/figures/hiring/hiring_favored_profiles.png", p, width = 8, height = 6, bg = "white")
print("Plot saved as output/figures/hiring/hiring_favored_profiles.png")


# Controlled Logistic Regression
# To ensure this isn't just a byproduct of other factors (like branch or wage),
# we run a multiple logistic regression controlling for Branch, Wage, 
# Average Working Hours, and Promotion status.
# Note: "Role" is excluded from this control model due to perfect separation 
# (100% of Servers, Hosts, and Server Assistants turned over, meaning Role 
# perfectly predicts exit for those groups and breaks the MLE).

employee_promotions_control <- employeechanges_data |>
  filter(New.Role != "Quit" & New.Role != "Dismissed") |>
  group_by(EmployeeID) |>
  summarize(promoted = "Yes")

controlled_df <- employee_applicant_profile |>
  left_join(employee_promotions_control, by = "EmployeeID") |>
  mutate(
    promoted = ifelse(is.na(promoted), "No", "Yes"),
    Branch. = as.factor(Branch.),
    Wage = as.factor(Wage)
  )

controlled_model <- glm(
  I(turnover == "Yes") ~ combined_favored + Branch. + Wage + AvgWorkingHours.Week + promoted,
  data = controlled_df,
  family = binomial
)
print("--- Controlled Logistic Regression (Favored Profile) ---")
print(summary(controlled_model))
print(exp(coef(controlled_model)))

# Finding: The controlled model confirms the descriptive pattern. Even after holding branch,
# wage, hours worked, and promotion status constant, employees who match the 
# "favored" profile (both higher education and experience) have significantly 
# higher odds of turning over (Odds Ratio = 1.56, p = 0.0465). 

# =====================================================================
# HYPOTHESIS 2: BRANCH 
# =====================================================================

# Are there branch-level differences in
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
print(high_perf_branch_summary)
branch_turnover_table <- table(
  high_perf_branch$Branch.,
  high_perf_branch$turnover
)
print(branch_turnover_table)

print(chisq.test(branch_turnover_table))
# High-performer turnover rates varied descriptively across branches,
# ranging from 81.8% to 97.2%.
# However, the chi-square test did not show a statistically significant
# association between branch and turnover (X-squared = 8.69, df = 6, p = 0.192).

# This suggests that the observed branch-level differences may reflect
# random variation rather than a consistent location effect.


# =====================================================================
# HYPOTHESIS 3: PROMOTION 
# =====================================================================

# Among strong performers, is a longer wait
# for promotion associated with a higher chance
# of leaving the company?

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

# Among strong performers who were
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

print(
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
)

# Wilcoxon test: do exited strong performers
# wait longer before promotion?
print(
  wilcox.test(
    months_in_role ~ exited,
    data = strong_promo
  )
)

# Logistic regression: does longer
# time-in-role predict exit among promoted
# strong performers?
promo_exit_model <- glm(
  I(exited == "Yes") ~ months_in_role,
  data = strong_promo,
  family = binomial
)

print(summary(promo_exit_model))
print(exp(coef(promo_exit_model)))

# Compare exit rates: promoted vs
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

print(
  strong_all |>
    group_by(promoted) |>
    summarize(
      n = n(),
      exit_n = sum(exited == "Yes"),
      exit_rate = mean(exited == "Yes")
    )
)

promo_exit_table <- table(
  strong_all$promoted,
  strong_all$exited
)
print(promo_exit_table)
print(chisq.test(promo_exit_table))

# Among unpromoted strong performers
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

print(
  unpromoted_exit |>
    count(ReasonForLeaving) |>
    mutate(prop = n / sum(n)) |>
    arrange(desc(prop))
)

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

# Are high performers promoted faster than
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
print(
  promo_compare |>
    group_by(performance_group) |>
    summarize(
      n = n(),
      mean_months = mean(months_to_promo, na.rm = TRUE),
      median_months = median(months_to_promo, na.rm = TRUE),
      sd_months = sd(months_to_promo, na.rm = TRUE)
    )
)

# non-parametric test because time to higher role may be skewed
print(wilcox.test(months_to_promo ~ performance_group, data = promo_compare))

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
# Do employees who receive promotions show
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
print(
  promotion_retention |>
    group_by(promoted) |>
    summarize(
      n = n(),
      retained_n = sum(retained == "Yes"),
      retention_rate = mean(retained == "Yes"),
      turnover_rate = mean(retained == "No")
    )
)

# count table and chi-square test
retention_table <- table(
  promotion_retention$promoted,
  promotion_retention$retained
)
print(retention_table)
print(chisq.test(retention_table))

# logistic regression
retention_model <- glm(
  I(retained == "Yes") ~ promoted,
  data = promotion_retention,
  family = binomial
)

print(summary(retention_model))
print(exp(coef(retention_model)))

# Plot: Retention by Promotion (All Employees)
library(ggplot2)
promo_ret_all_summary <- promotion_retention |>
  group_by(promoted) |>
  summarize(retention_rate = mean(retained == "Yes"), Count = n()) |>
  mutate(promoted = ifelse(promoted == "Yes", "Promoted", "Not Promoted"))

p_promo_all <- ggplot(promo_ret_all_summary, aes(x = promoted, y = retention_rate, fill = promoted)) +
  geom_bar(stat = "identity", width = 0.5) +
  geom_text(aes(label = paste0(scales::percent(retention_rate, accuracy = 0.1), "\n(n=", Count, ")")), 
            vjust = -0.5, size = 4.5, fontface = "bold") +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1.0)) +
  scale_fill_manual(values = c("Not Promoted" = "#F8766D", "Promoted" = "#00BFC4")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none", plot.title = element_text(face = "bold", hjust = 0.5)) +
  labs(title = "Retention Rate by Promotion Status (All Employees)", x = "", y = "Retention Rate")
ggsave("output/figures/promotion/bolt_promo_ret_all.png", p_promo_all, width = 6, height = 5)
print("Plot saved as output/figures/promotion/bolt_promo_ret_all.png")

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

# Subpart: Do HIGH-PERFORMING employees who receive
# promotions show significantly higher retention?
promotion_retention_hp <- promotion_retention |>
  filter(EmployeeID %in% performance_summarize$EmployeeID)

# retention rate for high performers by promotion status
print(
  promotion_retention_hp |>
    group_by(promoted) |>
    summarize(
      n = n(),
      retained_n = sum(retained == "Yes"),
      retention_rate = mean(retained == "Yes"),
      turnover_rate = mean(retained == "No")
    )
)

# count table and chi-square test for high performers
retention_table_hp <- table(
  promotion_retention_hp$promoted,
  promotion_retention_hp$retained
)
print(retention_table_hp)
print(chisq.test(retention_table_hp))

# logistic regression for high performers
retention_model_hp <- glm(
  I(retained == "Yes") ~ promoted,
  data = promotion_retention_hp,
  family = binomial
)
print(summary(retention_model_hp))
print(exp(coef(retention_model_hp)))

# Plot: Retention by Promotion (High Performers)
promo_ret_hp_summary <- promotion_retention_hp |>
  group_by(promoted) |>
  summarize(retention_rate = mean(retained == "Yes"), Count = n()) |>
  mutate(promoted = ifelse(promoted == "Yes", "Promoted", "Not Promoted"))

p_promo_hp <- ggplot(promo_ret_hp_summary, aes(x = promoted, y = retention_rate, fill = promoted)) +
  geom_bar(stat = "identity", width = 0.5) +
  geom_text(aes(label = paste0(scales::percent(retention_rate, accuracy = 0.1), "\n(n=", Count, ")")), 
            vjust = -0.5, size = 4.5, fontface = "bold") +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1.0)) +
  scale_fill_manual(values = c("Not Promoted" = "#F8766D", "Promoted" = "#00BFC4")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none", plot.title = element_text(face = "bold", hjust = 0.5)) +
  labs(title = "Retention Rate by Promotion Status (High Performers)", x = "", y = "Retention Rate")
ggsave("output/figures/promotion/bolt_promo_ret_hp.png", p_promo_hp, width = 6, height = 5)
print("Plot saved as output/figures/promotion/bolt_promo_ret_hp.png")

# Q5a findings:
# When looking EXCLUSIVELY at high-performing employees,
# promotion does NOT improve retention at all.
#
# High performers who were promoted had nearly the exact
# same retention rate (10.8%) as high performers who were
# never promoted (9.2%). This difference is not statistically
# significant (chi-sq p = 0.85).
#
# This perfectly aligns with the Q3c findings and confirms
# that while promotions provide a minor retention boost for
# the general employee population, they are entirely
# ineffective at retaining the restaurant's top talent.


# =====================================================================
# HYPOTHESIS 4: PROGRESSION 
# =====================================================================

# Among high-performing employees who exited,
# what point in their tenure did they leave?
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

print(
  high_perf_exit |>
    count(tenure_group) |>
    mutate(prop = n / sum(n))
)

print(summary(high_perf_exit$tenure_months))
print(median(high_perf_exit$tenure_months, na.rm = TRUE))




# =====================================================================
# ADDITIONAL FINDINGS
# =====================================================================

# Do working hours influence exit risk among high performers?

high_perf_hours <- employee_data |>
  filter(EmployeeID %in% performance_summarize$EmployeeID) |>
  mutate(
    turnover = ifelse(Current.status == "Working", "No", "Yes"),
    position_group = Position
  )

# Compare average working hours between
# exited and retained high performers
print(
  high_perf_hours |>
    group_by(turnover) |>
    summarize(
      n = n(),
      mean_hours = mean(AvgWorkingHours.Week, na.rm = TRUE),
      median_hours = median(AvgWorkingHours.Week, na.rm = TRUE),
      sd_hours = sd(AvgWorkingHours.Week, na.rm = TRUE)
    )
)

# non-parametric test because hours may not be normally distributed
print(wilcox.test(
  AvgWorkingHours.Week ~ turnover,
  data = high_perf_hours
))

# Compare part-time vs full-time distribution by turnover
position_turnover_table <- table(
  high_perf_hours$position_group,
  high_perf_hours$turnover
)
print(position_turnover_table)

print(prop.table(position_turnover_table, margin = 1))

print(chisq.test(position_turnover_table))

# Logistic regression using hours as predictor of exit risk
hours_model <- glm(
  I(turnover == "Yes") ~ AvgWorkingHours.Week,
  data = high_perf_hours,
  family = binomial
)

print(summary(hours_model))
print(exp(coef(hours_model)))

# Logistic regression using part-time/full-time status
position_model <- glm(
  I(turnover == "Yes") ~ position_group,
  data = high_perf_hours,
  family = binomial
)

print(summary(position_model))
print(exp(coef(position_model)))

# Combined model
combined_model <- glm(
  I(turnover == "Yes") ~ AvgWorkingHours.Week + position_group,
  data = high_perf_hours,
  family = binomial
)

print(summary(combined_model))
print(exp(coef(combined_model)))
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

# Find out the likely student status
employee_applicant <- employee_data |>
  left_join(applicant_data, by = "ApplicantID") |>
  mutate(
    turnover = ifelse(Current.status == "Working", "No", "Yes"),
    age_approx = 2026 - YearOfBirth,
    likely_student = ifelse(
      (age_approx <= 18 & HighestEducationLevel %in% c("High School", "None")) |
      (age_approx <= 22 & HighestEducationLevel == "Bachelor") |
      (age_approx <= 25 & HighestEducationLevel == "Master") |
      (age_approx <= 29 & HighestEducationLevel == "PhD"), 
      "Yes", "No"
    )
  )
student_turnover_table <- table(
  employee_applicant$likely_student,
  employee_applicant$turnover
)
print(student_turnover_table)

print(prop.table(student_turnover_table, margin = 1))

print(chisq.test(student_turnover_table))

library(ggplot2)
student_summary_data <- employee_applicant |>
  group_by(likely_student) |>
  summarize(
    TurnoverRate = mean(turnover == "Yes"),
    Count = n()
  ) |>
  mutate(
    Group = ifelse(likely_student == "Yes", "Current Student", "Non-Student"),
    Group = factor(Group, levels = c("Current Student", "Non-Student"))
  )

p2 <- ggplot(student_summary_data, aes(x = Group, y = TurnoverRate, fill = Group)) +
  geom_bar(stat = "identity", width = 0.5) +
  geom_text(aes(label = paste0(scales::percent(TurnoverRate, accuracy = 0.1), "\n(n=", Count, ")")), 
            vjust = -0.5, size = 5, fontface = "bold") +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1.0)) +
  scale_fill_manual(values = c("#4C787E", "#B22222")) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30"),
    axis.text.x = element_text(face = "bold", size = 12, vjust = 1)
  ) +
  labs(
    title = "Does Student Status Drive Turnover?",
    subtitle = "Comparing strict education proxies to the general population",
    x = NULL,
    y = "Turnover Rate"
  )
ggsave("output/figures/turnover/student_turnover.png", p2, width = 7, height = 6, bg = "white")
print("Plot saved as student_turnover.png")
# Using age as a proxy for student status
# (reflecting that education level may be their current university study),
# the data does not support managers' assumption
# that turnover is primarily driven by student employees.

# The likely-student group actually showed a slightly lower turnover rate
# than the non-student group (86.1% vs 89.2%).
# However, this difference was not statistically significant
# (chi-square p = 0.1948).

# This suggests that student status, at least
# as approximated here, is unlikely to be the
# main explanation for overall turnover.
