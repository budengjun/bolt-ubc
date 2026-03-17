# BOLT High-Performance Employee Analysis

## How is "High-Performing" Defined?

High-performing employees are defined as those in the **top 25%** by their **average performance review score** across all quarterly reviews (75th percentile threshold: **85.44 / 100**).

| Metric | Value |
|---|---|
| Total employees with reviews | 1,067 |
| High Performers (≥ 85.44) | 267 (25.0%) |
| Others (< 85.44) | 800 (75.0%) |

---

## Q1. Turnover Rate of High Performers vs Others

| Group | n | Turnover n | Turnover Rate |
|---|---|---|---|
| High Performers | 267 | 241 | **90.3%** |
| Others | 800 | 701 | **87.6%** |

- **Difference:** 2.6 pp higher for high performers
- **Chi-squared p = 0.2936** → Not statistically significant
- The non-significant result may partly reflect the smaller sample size of the high-performing group, which limits the ability to detect group differences statistically.

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

> Many high-performing employees who exited left within their first year, especially during the first 6 months. Retention efforts should focus on early-stage employee experience and support.

---

## Q3. Does Time-in-Role Before Promotion Increase Exit Likelihood?

The dataset lacks explicit promotion history, so `ReasonForLeaving == "Lack of Growth"` was used as a proxy.

| Exit Reason Group | n | Mean Tenure (mo) | Median Tenure (mo) |
|---|---|---|---|
| Lack of Growth | 65 | ~similar | ~similar |
| Other Reasons | 176 | ~similar | ~similar |

- **Wilcoxon test:** Not significant
- **Logistic regression** (tenure → lack of growth exit): Not significant

> This analysis did not reveal a meaningful relationship between tenure and leaving due to lack of growth. Tenure alone is not a useful predictor in this proxy analysis.

---

## Q4. Are High Performers Promoted Faster Than Average Performers?

Using first observed move into Shift Lead or Manager as a promotion proxy:

| Group | Mean Months to Higher Role | Median |
|---|---|---|
| High Performers | **13.4 months** | — |
| Average Performers | **8.91 months** | — |

- **Wilcoxon p = 0.025** → Significant
- **Linear model p = 0.043** → Significant
- High performers were promoted **slower**, not faster.

### Why Are They Not Promoted Faster?

1. **Not because they leave earlier.** High performers who exited actually had *longer* tenure than average performers (mean 8.80 vs 5.24 months; Wilcoxon p = 2.27e-10).
2. **Limited growth opportunity.** High performers were significantly more likely to cite **"Lack of Growth"** as their exit reason (27.0% vs 16.9%; Chi-squared p = 0.0022).

> **Recommendation:** Strengthen career progression for strong performers. Managers should identify high performers earlier and provide visible next-step opportunities (stretch assignments, leadership training, mentoring). If promotion timing cannot be accelerated, clearer signals of advancement may reduce frustration and improve retention.

---

## Q5. Do Promoted Employees Show Higher Retention?

Using first move into Shift Lead or Manager as promotion proxy:

| Group | n | Retained | Retention Rate | Turnover Rate |
|---|---|---|---|---|
| Promoted | — | — | **much higher** | — |
| Not Promoted | — | — | **much lower** | — |

- **Chi-squared:** Significant (p < 2e-16)
- **Logistic regression:** Odds ratio = **16.26** (p < 2e-16)

> Promoted employees had **16x higher odds** of being retained. Promotion is strongly associated with retention, though this should be interpreted as association rather than causation.

---

## Q6. Branch-Level Differences in High-Performer Turnover

| Branch | Turnover Rate (HP) |
|---|---|
| Range across branches | 81.8% – 97.2% |

- **Chi-squared:** X² = 8.69, df = 6, **p = 0.192** → Not significant
- Observed differences likely reflect random variation, not a consistent location effect.

---

## Q7. Is Compensation Aligned with Performance?

Using `ReasonForLeaving == "Insufficient Wages"` as a proxy for wage dissatisfaction:

### Key Findings

- Only **6.6%** of high-performer exits cited insufficient wages, far below better offer (38.2%) and lack of growth (27.0%).
- Average performers were **significantly more likely** to leave for insufficient wages (13.0% vs 6.6%; Chi-squared p = 0.0137).
- Among HP exits, those leaving for wages had somewhat longer tenure (10.2 vs 8.7 months), but the difference was **not significant** (Wilcoxon p = 0.2285).
- No significant association between insufficient wages and wage tier (Chi-squared p = 0.641).

> **Conclusion:** Wage stagnation was **not** a primary driver of exit among strong performers. Growth opportunities and external offers are more important.

---

## Q8. Do Working Hours Influence Exit Risk Among High Performers?

| Group (HP only) | Mean Hours/Week | Median |
|---|---|---|
| Exited | **30.9** | — |
| Retained | **41.9** | — |

- **Wilcoxon p < 0.001** → Significant
- **Logistic regression:** β = -0.177, p < 0.001, OR = **0.838** — each additional hour/week reduces exit odds by ~16%.
- Part-time vs full-time status alone was **not significant** (Chi-squared p = 0.301; logistic p = 0.218).

> Actual working-hour intensity matters more than the part-time/full-time label. The restaurant should pay closer attention to high-performing employees with lower weekly hours, as they face higher exit risk even when performance remains strong.

---

## Q9. Is Turnover Driven by Student Employees?

Using age (≤ 22) and education (High School) as a proxy for student status:

| Group | Turnover Rate |
|---|---|
| Likely Student | **81.7%** |
| Non-Student Proxy | **89.2%** |

- **Chi-squared p = 0.018** → Significant, but in the **opposite** direction.
- Likely students had **lower** turnover than non-students.

> The data does **not** support the assumption that turnover is primarily driven by student employees. Student status is unlikely to be the main explanation for overall turnover.

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
