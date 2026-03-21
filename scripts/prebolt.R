library(dplyr)
library(ggplot2)

# Load data
applicant_data <- read.csv("data/casefiles/BOLT_Applicants.csv")
branch_data <- read.csv("data/casefiles/BOLT_Branch.csv")
employeechanges_data <- read.csv("data/casefiles/BOLT_EmployeeChanges.csv")
employee_data <- read.csv("data/casefiles/BOLT_Employees.csv")
performance_data <- read.csv("data/casefiles/BOLT_Performance.csv")

# Identify strong performers
performance_summarize <- performance_data |>
  group_by(EmployeeID) |>
  summarize(mean_score = mean(PerformanceScore, na.rm = TRUE)) |>
  filter(mean_score >= quantile(mean_score, 0.75, na.rm = TRUE))

strong_employees <- employee_data |>
  filter(EmployeeID %in% performance_summarize$EmployeeID)

# 1. Hiring: age and education
hiring_data <- strong_employees |>
  left_join(applicant_data, by = "ApplicantID") |>
  mutate(Age = 2026 - YearOfBirth)

# Plot: Age distribution
p_age <- ggplot(hiring_data, aes(x = Age)) +
  geom_histogram(binwidth = 1, fill = "skyblue", color = "black") +
  theme_minimal() +
  labs(title = "Age Distribution Among Strong Performers", x = "Age", y = "Count")
ggsave("output/figures/demographics/prebolt_age.png", p_age, width = 6, height = 4)

# Plot: Education distribution
p_edu <- ggplot(hiring_data, aes(x = HighestEducationLevel)) +
  geom_bar(fill = "lightgreen", color = "black") +
  theme_minimal() +
  labs(title = "Education Level Among Strong Performers", x = "Education", y = "Count") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave("output/figures/demographics/prebolt_edu.png", p_edu, width = 6, height = 4)

# Part-time vs Full-time turnover rate
pt_ft_data <- strong_employees |>
  mutate(
    turnover = ifelse(Current.status == "Working", 0, 1),
    employment_type = Position
  ) |>
  group_by(employment_type) |>
  summarize(
    total = n(),
    turnover_rate = mean(turnover)
  )

print("Part-time vs Full-time Turnover (Strong Performers):")
print(pt_ft_data)

p_pt_ft <- ggplot(pt_ft_data, aes(x = employment_type, y = turnover_rate, fill = employment_type)) +
  geom_bar(stat = "identity", width = 0.5) +
  geom_text(aes(label = paste0(scales::percent(turnover_rate, accuracy = 0.1), "\n(n=", total, ")")),
            vjust = -0.5, size = 4.5, fontface = "bold") +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1.0)) +
  scale_fill_manual(values = c("full-time" = "#4C787E", "part-time" = "#B22222")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none", plot.title = element_text(face = "bold", hjust = 0.5)) +
  labs(title = "Turnover Rate: Part-time vs Full-time (Strong Performers)", x = "", y = "Turnover Rate")
ggsave("output/figures/demographics/prebolt_pt_ft.png", p_pt_ft, width = 6, height = 5)

# 2. Branch: turnover rate and poor management rate
branch_analysis <- strong_employees |>
  mutate(turnover = ifelse(Current.status == "Working", 0, 1)) |>
  left_join(
    employeechanges_data |> 
      filter(New.Role %in% c("Quit", "Dismissed"), ReasonForLeaving == "Poor Management") |> 
      select(EmployeeID) |> 
      mutate(poor_mgmt = 1) |> 
      distinct(EmployeeID, .keep_all = TRUE),
    by = "EmployeeID"
  ) |>
  mutate(poor_mgmt = ifelse(is.na(poor_mgmt), 0, poor_mgmt)) |>
  group_by(Branch.) |>
  summarize(
    total = n(),
    turnover_rate = mean(turnover),
    poor_mgmt_rate = sum(poor_mgmt) / total
  )

print("Branch Analysis:")
print(branch_analysis)

# Plot: Turnover rate by branch
p_turnover_branch <- ggplot(branch_analysis, aes(x = Branch., y = turnover_rate)) +
  geom_bar(stat = "identity", fill = "salmon", color = "black") +
  theme_minimal() +
  labs(title = "Turnover Rate by Branch (Strong Performers)", x = "Branch", y = "Turnover Rate") +
  scale_y_continuous(labels = scales::percent)
ggsave("output/figures/branch/prebolt_turnover_branch.png", p_turnover_branch, width = 6, height = 4)

# Plot: Poor management rate by branch
p_mgmt_branch <- ggplot(branch_analysis, aes(x = Branch., y = poor_mgmt_rate)) +
  geom_bar(stat = "identity", fill = "orange", color = "black") +
  theme_minimal() +
  labs(title = "Poor Management Exit Rate by Branch (Strong Performers)", x = "Branch", y = "Poor Management Rate") +
  scale_y_continuous(labels = scales::percent)
ggsave("output/figures/branch/prebolt_mgmt_branch.png", p_mgmt_branch, width = 6, height = 4)

# Insufficient wages by branch
branch_wage_analysis <- strong_employees |>
  mutate(turnover = ifelse(Current.status == "Working", 0, 1)) |>
  left_join(
    employeechanges_data |> 
      filter(New.Role %in% c("Quit", "Dismissed"), ReasonForLeaving == "Insufficient Wages") |> 
      select(EmployeeID) |> 
      mutate(wage_exit = 1) |> 
      distinct(EmployeeID, .keep_all = TRUE),
    by = "EmployeeID"
  ) |>
  mutate(wage_exit = ifelse(is.na(wage_exit), 0, wage_exit)) |>
  group_by(Branch.) |>
  summarize(
    total = n(),
    wage_exit_rate = sum(wage_exit) / total
  )

print("Branch Wage Analysis:")
print(branch_wage_analysis)

p_wage_branch <- ggplot(branch_wage_analysis, aes(x = Branch., y = wage_exit_rate)) +
  geom_bar(stat = "identity", fill = "purple", color = "black") +
  theme_minimal() +
  labs(title = "Insufficient Wages Exit Rate by Branch (Strong Performers)", x = "Branch", y = "Insufficient Wages Rate") +
  scale_y_continuous(labels = scales::percent)
ggsave("output/figures/branch/prebolt_wage_branch.png", p_wage_branch, width = 6, height = 4)

# 3. Promotion: avg turnover time and avg promotion time
turnover_time_data <- employeechanges_data |>
  filter(EmployeeID %in% strong_employees$EmployeeID, New.Role %in% c("Quit", "Dismissed")) |>
  left_join(strong_employees |> select(EmployeeID, HiredOn), by = "EmployeeID") |>
  mutate(
    HiredOn = as.Date(HiredOn),
    DateChanged = as.Date(DateChanged),
    turnover_months = as.numeric(DateChanged - HiredOn) / 30.44
  )

promo_time_data <- employeechanges_data |>
  filter(EmployeeID %in% strong_employees$EmployeeID, !New.Role %in% c("Quit", "Dismissed")) |>
  group_by(EmployeeID) |>
  summarize(first_promo = min(as.Date(DateChanged), na.rm = TRUE)) |>
  left_join(strong_employees |> select(EmployeeID, HiredOn), by = "EmployeeID") |>
  mutate(
    HiredOn = as.Date(HiredOn),
    promo_months = as.numeric(first_promo - HiredOn) / 30.44
  )

time_dist_data <- bind_rows(
  turnover_time_data |> select(months = turnover_months) |> mutate(Type = "Turnover Time"),
  promo_time_data |> select(months = promo_months) |> mutate(Type = "Promotion Time")
)

print("Time Distribution Summary:")
print(summary(time_dist_data))

p_time <- ggplot(time_dist_data, aes(x = Type, y = months, fill = Type)) +
  geom_boxplot(color = "black", show.legend = FALSE) +
  theme_minimal() +
  labs(title = "Turnover Time vs Promotion Time Distribution", x = "", y = "Months")
ggsave("output/figures/turnover/prebolt_time.png", p_time, width = 6, height = 4)

# 4. Progression: Exit Reasons Distribution
progression_data <- employeechanges_data |>
  filter(EmployeeID %in% strong_employees$EmployeeID, New.Role %in% c("Quit", "Dismissed"), !is.na(ReasonForLeaving)) |>
  group_by(ReasonForLeaving) |>
  summarize(Count = n()) |>
  mutate(
    Rate = Count / sum(Count),
    LegendLabel = ReasonForLeaving
  )

print("Progression Exit Reasons:")
print(progression_data)

p_growth <- ggplot(progression_data, aes(x = "", y = Rate, fill = LegendLabel)) +
  geom_bar(stat = "identity", width = 1, color = "white") +
  coord_polar(theta = "y", start = 0) +
  theme_void() +
  labs(fill = "Reason for Leaving") +
  theme(
    legend.title = element_text(size = 12),
    legend.text = element_text(size = 10)
  )
ggsave("output/figures/turnover/prebolt_growth.png", p_growth, width = 7, height = 5)

# Exit Reasons Distribution for Average Performers (25th-75th percentile)
avg_perf_ids <- performance_data |>
  group_by(EmployeeID) |>
  summarize(mean_score = mean(PerformanceScore, na.rm = TRUE)) |>
  filter(
    mean_score >= quantile(mean_score, 0.25, na.rm = TRUE),
    mean_score < quantile(mean_score, 0.75, na.rm = TRUE)
  )

average_employees <- employee_data |>
  filter(EmployeeID %in% avg_perf_ids$EmployeeID)

progression_data_avg <- employeechanges_data |>
  filter(EmployeeID %in% average_employees$EmployeeID, New.Role %in% c("Quit", "Dismissed"), !is.na(ReasonForLeaving)) |>
  group_by(ReasonForLeaving) |>
  summarize(Count = n()) |>
  mutate(
    Rate = Count / sum(Count),
    LegendLabel = ReasonForLeaving
  )

print("Average Performers Exit Reasons:")
print(progression_data_avg)

p_growth_avg <- ggplot(progression_data_avg, aes(x = "", y = Rate, fill = LegendLabel)) +
  geom_bar(stat = "identity", width = 1, color = "white") +
  coord_polar(theta = "y", start = 0) +
  theme_void() +
  labs(fill = "Reason for Leaving", title = "Average Performers Exit Reasons") +
  theme(
    legend.title = element_text(size = 12),
    legend.text = element_text(size = 10),
    plot.title = element_text(hjust = 0.5, face = "bold")
  )
ggsave("output/figures/turnover/prebolt_growth_avg.png", p_growth_avg, width = 7, height = 5)

# 5. Branch-Specific Exit Reasons (High Performers)
hp_exits_by_branch <- employeechanges_data |>
  filter(EmployeeID %in% strong_employees$EmployeeID, New.Role %in% c("Quit", "Dismissed"), !is.na(ReasonForLeaving)) |>
  left_join(strong_employees |> select(EmployeeID, Branch.), by = "EmployeeID")

branch_top_reasons <- hp_exits_by_branch |>
  group_by(Branch., ReasonForLeaving) |>
  summarize(Count = n(), .groups = "drop") |>
  group_by(Branch.) |>
  mutate(TotalBranchExits = sum(Count)) |>
  slice_max(Count, n = 1, with_ties = FALSE) |>
  mutate(
    Percentage = Count / TotalBranchExits,
    Label = paste0(ReasonForLeaving, "\n", scales::percent(Percentage, accuracy = 0.1), " (n=", Count, ")")
  )

print("Branch-Level Top Exit Reasons:")
print(branch_top_reasons)

p_branch_top <- ggplot(branch_top_reasons, aes(x = factor(Branch.), y = Count, fill = ReasonForLeaving)) +
  geom_bar(stat = "identity", width = 0.7) +
  geom_text(aes(label = Label), vjust = -0.3, size = 3, fontface = "bold", lineheight = 0.8) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.2))) +
  theme_minimal() +
  labs(
    title = "Primary Exit Reason for High Performers by Branch",
    subtitle = "Calculated as % of all High Performer exits at that location",
    x = "Branch",
    y = "Number of Exits",
    fill = "Reason"
  ) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5, size = 10, face = "italic"),
    axis.text.x = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave("output/figures/branch/prebolt_branch_top_reasons.png", p_branch_top, width = 8, height = 5)
print("Saved top reasons bar chart with percentages as output/figures/branch/prebolt_branch_top_reasons.png")
