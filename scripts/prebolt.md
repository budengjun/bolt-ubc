# Strong Performers Analysis (prebolt)

This document provides a focused analysis on the **strong performers** (employees in the top 25% by average performance score) across four key areas: Hiring, Branch, Promotion, and Progression. By zooming in on this critical cohort, we can better understand their profiles and the factors influencing their retention.

## 1. Hiring Profiles
![Age Distribution](prebolt_age.png)
![Education Distribution](prebolt_edu.png)

We visualized the **age** and **education** distributions among the strong performers to understand the profile of successful hires. The plots show the demographic breakdown of our highest performing employees, helping to inform future recruitment targeting.

## 2. Branch-Level Metrics
![Turnover Rate by Branch](prebolt_turnover_branch.png)
![Poor Management Rate by Branch](prebolt_mgmt_branch.png)
![Insufficient Wages Rate by Branch](prebolt_wage_branch.png)

When analyzing by branch, we see variation in how strong performers fare depending on their location:

### Turnover Rate by Branch

| Branch | Turnover Rate (HP) |
|---|---|
| Range across branches | 81.8% – 97.2% |

- **Chi-squared:** X² = 8.69, df = 6, **p = 0.192** → Not significant

### Poor Management Exit Rate by Branch

| Branch | Poor Mgmt Exit Rate (HP) |
|---|---|
| Range across branches | 2.5% – 9.1% |

- **Chi-squared:** X² = 2.88, df = 6, **p = 0.824** → Not significant
- Branch 1 had the highest rate (**9.1%**), roughly 3–4× higher than the lowest branches (2, 3, 6 at ~2.5–3.0%). Branch 7 was second highest at **7.3%**.
- However, the difference is **not statistically significant**, meaning the observed variation could be due to chance given the small sample sizes per branch.

### Insufficient Wages Exit Rate by Branch

| Branch | Insufficient Wages Exit Rate (HP) |
|---|---|
| Range across branches | 0% – 13.9% |

- **Chi-squared:** X² = 8.00, df = 6, **p = 0.238** → Not significant
- Branch 3 stands out at **13.9%**, far above all other branches. Branches 2 and 4 tie at **7.5%**, while Branch 7 had **0%** wage-related exits.
- Despite the wide spread, the difference is **not statistically significant**, likely due to small counts per branch.

### Primary Exit Reason by Branch (HP)

We identified the #1 reason for leaving for each branch to highlight the most volume-heavy pain points:

![Primary Exit Reason by Branch](prebolt_branch_top_reasons.png)

- **Branches 1 & 2**: Primarily driven by **Lack of Growth** (~33%+ of their exits).
- **Branches 3, 4, 5, 6, 7**: Primarily driven by **Better Offers**.

While "Better Offer" is the most frequent top reason company-wide, the prominence of **Lack of Growth** in Branches 1 and 2 suggests these specific locations may have more significant internal career pathing constraints for high performers.

## 3. Promotion vs. Turnover Timelines
![Turnover Time vs Promotion Time Distribution](prebolt_time.png)

We compared the distribution of time a strong performer waits for a promotion versus the distribution of time until they leave the company:
- **Promotion Time Distribution**: Promotions tend to happen relatively early for strong performers, predominantly clustered in the first 4-5 months of tenure.
- **Turnover Time Distribution**: In contrast, the time until exit for strong performers has a much wider spread and a higher median. The median time-to-exit is roughly 6.1 months, with many staying upwards of 10+ months before eventually churning.

This distribution confirms that receiving an early role change (promotion) happens long before the typical exit window, yet it is still not sufficient to prevent these strong performers from eventually leaving.

## 4. Progression: Exit Reasons
### High Performers
![Exit Reasons Distribution](prebolt_growth.png)

We investigated the distribution of all stated primary reasons why strong performers chose to exit the company:
- **Better Offer (38.2%)**: Exploring external opportunities remains the leading cause.
- **Lack of Growth (27.0%)**: A staggering 27% of exited top talent leave explicitly because their progression feels blocked or insufficient.
- **Performance (7.9%) & Burntout (7.5%)**: Some leave due to exhaustion or failing to sustain that high performance.
- **Insufficient Wages (6.6%)**: Pay dissatisfaction makes up a surprisingly small slice.
- **Poor Management (5.4%)**: Only about 1 in 20 exited for management-specific issues.

### Average Performers
![Average Performers Exit Reasons](prebolt_growth_avg.png)

For comparison, **Average Performers** (25th–75th percentile) show a different profile:
- They are significantly more likely to leave for **Insufficient Wages (13.0% vs 6.6%)** and **Poor Management (13.2% vs 5.4%)** compared to high performers.
- However, **Better Offer (22.9%)** and **Lack of Growth (16.9%)** are still major factors, though less dominant than they are for top talent.

This highlights that for the company's best employees, external recruitment and internal growth ceilings are by far the biggest drivers of turnover, whereas for average performers, base hygiene factors (pay, management) play a larger role.
