# BOLT High-Performance Employee Analysis

## Overview

This project analyzes BOLT employee data to identify **which factors define a high-performance employee**. A high performer is defined as an employee in the **top 25% by average performance score** (threshold: **85.44/100**).

The analysis uses R and merges 5 datasets: Employees, Performance Reviews, Applicants, Employee Changes, and Branch information.

## How To Run

```bash
cd /Users/yaolonghu/Desktop/bolt-ubc
Rscript high_performance_analysis.R
```

## Key Findings

### Statistically Significant Factors (Logistic Regression, p < 0.05)

| Factor | Odds Ratio | p-value | Interpretation |
|---|---|---|---|
| **Past Relevant Experience** | 76.0x | < 0.001 | Strongest predictor — 99.3% of high performers have it vs 85.4% of others |
| **PhD Education** | 15.5x | < 0.001 | PhD holders are ~15x more likely to be high performers |
| **Bachelor's Degree** | 10.7x | < 0.001 | ~11x more likely vs Associate Degree baseline |
| **Master's Degree** | 10.1x | < 0.001 | ~10x more likely vs Associate Degree baseline |
| **Number of Promotions** | 2.1x | < 0.001 | Each promotion doubles the odds of being a high performer |
| **Years of Relevant Experience** | 0.79x | < 0.001 | More years slightly *decreases* odds — possible diminishing returns or burnout effect |

### Non-Significant Factors

The following factors showed **no statistically significant relationship** with high performance:

- **Wage tier** (Minimum / Competitive / Premium) — p > 0.5
- **Branch location** — p > 0.3 across all 7 branches
- **Full-time vs Part-time** — p = 0.57
- **Average working hours/week** — p = 0.42

### Descriptive Highlights

- High performers average **more promotions** (0.40 vs 0.15)
- High performers work slightly **more hours/week** (32.0 vs 29.8, p = 0.002)
- **67%** of high performers hold a Bachelor's degree (vs 31.6% of non-high performers)
- **Bartenders** are overrepresented among high performers (25.1% vs 10.0%)
- Managers and Server Assistants are significantly *less* likely to be classified as high performers (this may reflect the scoring rubric rather than actual capability)

## Methods Used

1. **Descriptive Statistics** — Mean comparisons and distribution tables for high vs non-high performers
2. **t-tests** — For continuous variables (hours/week, tenure, experience, promotions)
3. **Chi-squared Tests** — For categorical variables (wage, position, role, education, branch)
4. **Logistic Regression** — Full model with all predictors, outputting odds ratios and confidence intervals

## Generated Outputs

| File | Description |
|---|---|
| `performance_distribution.png` | Histogram of performance scores for high vs non-high performers |
| `factor_boxplots.png` | Boxplots comparing key continuous variables |
| `role_performance.png` | Performance distribution by employee role |
| `wage_performance.png` | Performance distribution by wage tier |
| `promotions_performance.png` | Performance distribution by number of promotions |

## Dataset Summary

| File | Records | Description |
|---|---|---|
| `BOLT_Employees.csv` | 1,068 | Employee demographics, role, wage, hours, branch |
| `BOLT_Performance.csv` | 2,190 | Quarterly performance review scores (0–100) |
| `BOLT_Applicants.csv` | 10,501 | Applicant education, experience, hire status |
| `BOLT_EmployeeChanges.csv` | 1,166 | Promotions, quits, dismissals with reasons |
| `BOLT_Branch.csv` | 1,050 | Branch locations and customer reviews |
