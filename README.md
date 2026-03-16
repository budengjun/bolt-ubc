# BOLT High-Performance Employee Analysis

## 1. How is "High-Performing" Defined?

High-performing employees are defined as those in the **top 25%** by their **average performance review score** across all quarterly reviews.

| Metric | Value |
|---|---|
| Performance threshold (75th percentile) | **85.44 / 100** |
| Total employees with reviews | 1,067 |
| High Performers (≥ 85.44) | 267 (25.0%) |
| Others (< 85.44) | 800 (75.0%) |

**Score ranges:**
- High Performers: 85.45 – 98.20 (mean: 90.03)
- Others: 58.07 – 85.44 (mean: 75.59)

## 2. Turnover Rate: High Performers vs Others

| Group | Total | Turned Over | Retained | Turnover Rate |
|---|---|---|---|---|
| **High Performers** | 267 | 241 | 26 | **90.3%** |
| **Others** | 800 | 701 | 99 | **87.6%** |

> The difference is **2.6 percentage points** and is **not statistically significant** (Chi-squared p = 0.29). Both groups have similarly high turnover.

### Turnover Type Breakdown

| Group | Quit Rate | Dismissal Rate | Retained |
|---|---|---|---|
| High Performers | **79.0%** | 11.2% | 9.7% |
| Others | 74.0% | 13.6% | 12.4% |

High performers **quit more** (79.0% vs 74.0%) but are **dismissed less** (11.2% vs 13.6%).

### Top Reasons High Performers Quit

| Rank | Reason | Count | % |
|---|---|---|---|
| 1 | **Better Offer** | 92 | **43.6%** |
| 2 | **Lack of Growth** | 65 | **30.8%** |
| 3 | Burnout | 18 | 8.5% |
| 4 | Insufficient Wages | 16 | 7.6% |
| 5 | Poor Management | 13 | 6.2% |
| 6 | Relocation | 7 | 3.3% |

### Top Reasons Others Quit

| Rank | Reason | Count | % |
|---|---|---|---|
| 1 | Better Offer | 139 | 23.5% |
| 2 | Burnout | 106 | 17.9% |
| 3 | Lack of Growth | 104 | 17.6% |
| 4 | Insufficient Wages | 103 | 17.4% |
| 5 | Poor Management | 101 | 17.1% |
| 6 | Relocation | 39 | 6.6% |

> **74.4%** of high-performer quits are for "Better Offer" + "Lack of Growth". Others quit for evenly distributed reasons.

## 3. At What Tenure Point Do High Performers Exit?

### Tenure at Exit Summary

| Metric | High Performers | Others |
|---|---|---|
| **Median tenure at exit** | **6.9 months** | **3.2 months** |
| Mean tenure at exit | 8.8 months | 4.7 months |
| Q1 – Q3 range | 2.6 – 12.8 mo | 1.1 – 6.6 mo |
| t-test p-value | **< 0.0001** (significant) | |

> High performers stay **roughly twice as long** before exiting.

### Exit Distribution by Tenure Bucket

| Tenure Bucket | High Performers | Others |
|---|---|---|
| **0–6 months** | **42.3%** | **72.0%** |
| **6–12 months** | **31.1%** | 18.3% |
| 12–18 months | 13.3% | 7.4% |
| 18–24 months | 9.1% | 1.1% |
| 24–36 months | 4.1% | 1.1% |

### Cumulative Exit Timeline

| By... | High Performers Exited | Others Exited |
|---|---|---|
| 6 months | 42.3% | 72.0% |
| 12 months | 73.4% | 90.3% |
| 18 months | 86.7% | 97.7% |
| 24 months | 95.9% | 98.9% |

> By 6 months, 72% of others have left vs only 42% of high performers. The **6–12 month window** is a critical period (31.1% of HP exits).

### Quit Reasons Shift by Tenure (High Performers)

| Tenure | Top Reason | 2nd Reason |
|---|---|---|
| **0–6 mo** | Better Offer (47.1%) | Lack of Growth (33.3%) |
| **6–12 mo** | Better Offer (39.7%) | Lack of Growth (26.5%) |
| **12–18 mo** | Lack of Growth (44.4%) | Better Offer (29.6%) |
| **18–24 mo** | Better Offer (65.0%) | Insufficient Wages (15.0%) |
| **24–36 mo** | Lack of Growth (55.6%) | Better Offer (33.3%) |

> Early exits (< 12 mo) are driven by **Better Offer**. After 12 months, **Lack of Growth** becomes the #1 reason.

## How To Run

```bash
cd /Users/yaolonghu/Desktop/bolt-ubc
Rscript high_performance_analysis.R
```

## Output

- Console: full statistical breakdown
- `tenure_exit_distribution.png`: histograms of tenure at exit
- `tenure_buckets.png`: grouped bar chart by tenure bucket
- `tenure_boxplot.png`: boxplot comparison

## Data Sources

| File | Description |
|---|---|
| `BOLT_Employees.csv` | Employee info (role, wage, branch, hours, status) |
| `BOLT_Performance.csv` | Quarterly performance review scores |
| `BOLT_EmployeeChanges.csv` | Role changes, quits, dismissals with reasons |
