# BOLT High-Performance Employee Analysis

## How is "High-Performing" Defined?

High-performing employees are defined as those in the
**top 25%** by their **average performance review score**
across all quarterly reviews
(75th percentile threshold: **85.44 / 100**).

| Metric | Value |
|---|---|
| Total employees with reviews | 1,067 |
| High Performers (≥ 75th pctl) | 267 (25.0%) |
| Average Performers (25th–75th pctl) | ~534 (50.0%) |
| Others (< 25th pctl) | ~266 (25.0%) |

---

## Baseline: Turnover Rate (High Performers vs Others)

| Group | n | Turnover n | Turnover Rate |
|---|---|---|---|
| High Performers | 267 | 241 | **90.3%** |
| Others | 800 | 701 | **87.6%** |

- **Difference:** 2.6 pp higher for high performers
- **Chi-squared p = 0.2936** → Not significant
- The non-significant result may partly reflect the
  smaller sample size of the high-performing group.

---

# HIRING (FAVORED PROFILES)

Managers tend to favor applicants with higher education (Bachelor, Master, PhD) and past relevant experience. Here is how those profiles perform descriptively in reality:

| Profile Trait | Sample Size (n) | Turnover Rate |
|---|---|---|
| **Neither Trait (Baseline)** | 56 | **83.9%** |
| **Only Higher Education** | 63 | **85.7%** |
| **Only Relevant Experience** | 491 | **87.2%** |
| **BOTH (Education + Experience)** | 457 | **90.4%** |

### Statistical Solving Process
To ensure this isn't simply a descriptive illusion driven by confounding factors (like certain branches, wages, or hours), the data was put through a rigorous solving process:

- **Identifying Covariates:** We designed a multiple logistic regression model to hold other variables constant, specifically controlling for `Branch`, `Wage`, `Average Working Hours`, `Promotion` status, and `Role`.
- **Handling Perfect Separation:** During mathematical modeling, the calculation initially failed because `Role` perfectly predicted turnover. Our data exposed a massive structural truth: virtually **100%** of all standard non-management roles (Servers, Hosts, Server Assistants) turned over. Because `Role` perfectly predicts exit for these groups, it breaks the Maximum Likelihood Estimation math. Thus, `Role` had to be excluded from the control variables.
- **Running the Controlled Model:** We re-ran the logistic regression against the favored profile (having *both* traits) while controlling for branch allocation, wage tier, hours worked, and promotions.

### Results
Even when controlling for those factors, having BOTH traits is **statistically significant (p = 0.0465)** and increases the baseline odds of exit by **1.56x**.

> **Conclusion:** The data supports a positive association between "favored" hiring traits and turnover. While the descriptive rate gap is small, the controlled model confirms that hunting for the "most qualified" people on paper recruits individuals who are structurally more likely to leave the restaurant.

---

# BRANCH

## Branch-Level Differences in HP Turnover

| Branch | Turnover Rate (HP) |
|---|---|
| Range across branches | 81.8% – 97.2% |

- **Chi-squared:** X² = 8.69, df = 6,
  **p = 0.192** → Not significant
- Observed differences likely reflect random
  variation, not a consistent location effect.

---

# PROMOTION

## Among Strong Performers, Is a Longer Wait for Promotion Associated With a Higher Chance of Leaving the Company?

Using ANY non-exit role change in `EmployeeChanges`
as a promotion. Of 267 strong performers,
**83 were promoted/transitioned** (31%).

### Wait Time for Promotion by Eventual Exit Status

This looks **only** at the 83 strong performers who **did** receive a promotion. It compares how long they waited (months from hire to promotion date) based on whether they eventually stayed or left the company.

| Later Exit Status | n | Mean Months Waited | Median | SD |
|---|---|---|---|---|
| Stayed | 9 | 5.1 | 4.8 | 3.3 |
| Eventually Exited | 74 | 4.2 | 3.5 | 3.5 |

- **Wilcoxon p = 0.376** → Not significant
- There is no statistical difference in wait time
  before promotion between those who stayed
  and those who left.
- **Logistic Regression:** Wait time is **not** a predictor of exit (p = 0.441).

### Promoted vs Unpromoted Exit Rates

| Group | n | Exited | Exit Rate |
|---|---|---|---|
| Promoted | 83 | 74 | **89.2%** |
| Not Promoted | 184 | 167 | **90.8%** |

- **Chi-squared p = 0.852** → Not significant
- The exit rate is virtually **identical** whether
  a strong performer is promoted or not.

> **Conclusion:** NO — longer time-in-role before
> promotion is NOT associated with higher exit risk.
> Crucially, receiving a standard promotion/role transition
> **does not improve retention** at all for strong
> performers (the exit rate is ~90% regardless).

## Are High Performers Promoted Faster?

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

## Do Promoted Employees Show Higher Retention?

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

### What About High Performers Specifically?

Looking **only** at the 267 high-performing employees:

| Group | n | Retained | Retention Rate |
|---|---|---|---|
| Promoted | 83 | 9 | **10.8%** |
| Not Promoted | 184 | 17 | **9.2%** |

- **Chi-squared p = 0.85** → Not significant

> **Conclusion:** When looking exclusively at the
> restaurant's top talent, **promotion does not
> improve retention at all**. Promoted high performers
> quit at exactly the same staggering rate (~90%)
> as those who are never promoted.


# PROGRESSION

## At What Tenure Point Do High Performers Exit?

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

# ADDITIONAL FINDINGS

## Do Working Hours Influence Exit Risk?

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

## Is Turnover Driven by Student Employees?

Using a strict definition of "current university/school student" based on their highest attained education matching an age-appropriate timeline (`≤18` + High School, `≤22` + Bachelor, `≤25` + Master, `≤29` + PhD):

| Group | Turnover Rate |
|---|---|
| Current Student | **86.6%** |
| Non-Student | **88.5%** |

- **Chi-squared p = 0.6048** → Not significant
- The slight difference (slightly lower turnover for students)
  is not statistically significant.

> The data does **not** support the assumption
> that turnover is primarily driven by student
> employees. Even under the strictest proxy definitions, their turnover behaves identically to the general population.

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
