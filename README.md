# BOLT High-Performance Employee Analysis

## How is "High-Performing" Defined?

High-performing employees are defined as those in the
**top 25%** by their **average performance review score**
across all quarterly reviews
(75th percentile threshold: **85.44 / 100**).

| Metric | Value |
|---|---|
| Total employees with reviews | 1,067 |
| High Performers (≥ 85.44) | 267 (25.0%) |
| Others (< 85.44) | 800 (75.0%) |

---

## Q1. Turnover Rate: High Performers vs Others

| Group | n | Turnover n | Turnover Rate |
|---|---|---|---|
| High Performers | 267 | 241 | **90.3%** |
| Others | 800 | 701 | **87.6%** |

- **Difference:** 2.6 pp higher for high performers
- **Chi-squared p = 0.2936** → Not significant
- The non-significant result may partly reflect the
  smaller sample size of the high-performing group.

---

## Q2. At What Tenure Point Do High Performers Exit?

Among high-performing employees who exited:

| Tenure Group | n | Proportion |
|---|---|---|
| Early tenure (< 6 months) | 102 | **42.3%** |
| Mid tenure (6–12 months) | 75 | **31.1%** |
| Extended tenure (> 12 months) | 64 | **26.6%** |

- **Median tenure at exit:** 6.87 months
- **Mean tenure at exit:** 8.80 months (right-skewed)

> Many high-performing employees who exited left
> within their first year, especially during the
> first 6 months. Retention efforts should focus on
> early-stage employee experience and support.

---

## Q3. Does Time-in-Role Before Promotion Increase the Likelihood of Exit Among Strong Performers?

Using ANY non-exit role change in `EmployeeChanges`
as a promotion. Of 267 strong performers,
**83 were promoted/transitioned** (31%).

### 3a. Wait Time for Promotion by Eventual Exit Status

This looks **only** at the 83 strong performers who **did** receive a promotion. It compares how long they waited (months from hire to promotion date) based on whether they eventually stayed or left the company.

| Later Exit Status | n | Mean Months Waited | Median | SD |
|---|---|---|---|---|
| Stayed | 9 | 5.1 | 4.8 | 3.3 |
| Eventually Exited | 74 | 4.2 | 3.5 | 3.5 |

- **Wilcoxon p = 0.376** → Not significant
- There is no statistical difference in wait time
  before promotion between those who stayed
  and those who left.

### 3b. Logistic Regression

- OR = **0.93** per additional month (p = 0.441)
- Wait time is **not** a predictor of exit
  among promoted strong performers.

### 3c. Promoted vs Unpromoted Exit Rates

| Group | n | Exited | Exit Rate |
|---|---|---|---|
| Promoted | 83 | 74 | **89.2%** |
| Not Promoted | 184 | 167 | **90.8%** |

- **Chi-squared p = 0.852** → Not significant
- The exit rate is virtually **identical** whether
  a strong performer is promoted or not.

### 3d. Exit Reasons (Unpromoted Strong Performers)

| Reason | n | Proportion |
|---|---|---|
| Better Offer | 60 | **35.9%** |
| Lack of Growth | 48 | **28.7%** |
| Performance | 14 | 8.4% |
| Burnout | 12 | 7.2% |
| Insufficient Wages | 10 | 6.0% |

> **Conclusion:** NO — longer time-in-role before
> promotion is NOT associated with higher exit risk.
> Crucially, receiving a standard promotion/role transition
> **does not improve retention** at all for strong
> performers (the exit rate is ~90% regardless).

---

## Q4. Are High Performers Promoted Faster?

Using ANY non-exit role change as a promotion:

| Group | Mean Months to Promotion | Median |
|---|---|---|
| High Performers | **4.28 months** | 3.71 |
| Average Performers | **4.10 months** | 3.45 |

- **Wilcoxon p = 0.838** → Not significant
- High performers are **not** promoted faster
  than average performers.

> **Conclusion:** The restaurant does not
> meaningfully accelerate career progression
> for its top performers.

---

## Q5. Do Promoted Employees Show Higher Retention?

Using ANY non-exit role change as a promotion
across the entire employee base:

| Group | n | Retained | Retention Rate |
|---|---|---|---|
| Promoted | 178 | 35 | **19.7%** |
| Not Promoted | 889 | 90 | **10.1%** |

- **Chi-squared p = 0.00049** → Significant
- **Logistic regression:** OR = **2.16**

> **Conclusion:** Yes, employees who receive a
> role transition have roughly double the retention
> rate (19.7% vs 10.1%). However, the effect is
> relatively weak—even among promoted employees,
> **80.3% still quit**. While promotion helps
> marginally, it is not enough to fix the systemic
> turnover issue.

### 5a. What About High Performers Specifically?

Looking **only** at the 267 high-performing employees:

| Group | n | Retained | Retention Rate |
|---|---|---|---|
| Promoted | 83 | 9 | **10.8%** |
| Not Promoted | 184 | 17 | **9.2%** |

- **Chi-squared p = 0.85** → Not significant
- **Logistic regression:** OR = **1.19** (p = 0.68)

> **Conclusion:** When looking exclusively at the
> restaurant's top talent, **promotion does not
> improve retention at all**. Promoted high performers
> quit at exactly the same staggering rate (~90%)
> as those who are never promoted.

## Q6. Branch-Level Differences in HP Turnover

| Branch | Turnover Rate (HP) |
|---|---|
| Range across branches | 81.8% – 97.2% |

- **Chi-squared:** X² = 8.69, df = 6,
  **p = 0.192** → Not significant
- Observed differences likely reflect random
  variation, not a consistent location effect.

---

## Q7. Is Compensation Aligned with Performance?

Using `ReasonForLeaving == "Insufficient Wages"`
as a proxy for wage dissatisfaction:

- Only **6.6%** of HP exits cited insufficient
  wages, far below better offer (38.2%) and
  lack of growth (27.0%).
- Average performers were more likely to leave
  for insufficient wages (13.0% vs 6.6%;
  Chi-squared p = 0.0137).
- Among HP exits, those leaving for wages had
  somewhat longer tenure (10.2 vs 8.7 months),
  but not significant (Wilcoxon p = 0.2285).
- No significant association between insufficient
  wages and wage tier (Chi-squared p = 0.641).

> Wage stagnation was **not** a primary driver of
> exit among strong performers. Growth
> opportunities and external offers are more
> important.

---

## Q8. Do Working Hours Influence Exit Risk?

| Group (HP only) | Mean Hours/Week |
|---|---|
| Exited | **30.9** |
| Retained | **41.9** |

- **Wilcoxon p < 0.001** → Significant
- **Logistic regression:** OR = **0.838** —
  each additional hour/week reduces exit odds
  by ~16%.
- Part-time vs full-time status alone was
  **not significant** (p = 0.301).

> Actual working-hour intensity matters more
> than the part-time/full-time label. Pay closer
> attention to high performers with lower weekly
> hours — they face higher exit risk.

---

## Q9. Is Turnover Driven by Student Employees?

Using age (≤ 22) and education (High School)
as a proxy for student status:

| Group | Turnover Rate |
|---|---|
| Likely Student | **81.7%** |
| Non-Student Proxy | **89.2%** |

- **Chi-squared p = 0.018** → Significant,
  but in the **opposite** direction.
- Likely students had **lower** turnover.

> The data does **not** support the assumption
> that turnover is primarily driven by student
> employees.

---

## How To Run

```bash
cd /Users/yaolonghu/Desktop/bolt-ubc
Rscript bolt.R
```

## Data Sources

| File | Description |
|---|---|
| `BOLT_Applicants.csv` | Applicant education, experience, hire status |
| `BOLT_Branch.csv` | Branch locations and customer reviews |
| `BOLT_EmployeeChanges.csv` | Role changes, quits, dismissals with reasons |
| `BOLT_Employees.csv` | Employee info (role, wage, branch, hours, status) |
| `BOLT_Performance.csv` | Quarterly performance review scores |
