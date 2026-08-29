# E-commerce Customer Retention & Cohort Analysis (SQL)

**Tools:** PostgreSQL · SQL (CTEs, Window Functions, Self-Joins, Conditional Aggregation)
**Dataset:** [Online Retail II (UCI Machine Learning Repository)](https://archive.ics.uci.edu/dataset/502/online+retail+ii) — ~1.07M transactions, Dec 2009–Dec 2011, UK-based online gift retailer

## Business Problem

Every repeat-purchase business lives or dies on one question: **do customers who join keep coming back, and how much are they worth over time?**

This project answers four business questions using pure SQL, on a real (messy, unfiltered) transactional dataset:

1. When do customers stop coming back, and how much retention is lost early vs. late?
2. Is customer retention improving or worsening over time?
3. Which cohorts generate the most value — and is that a fair comparison?
4. Which customers should the business prioritize retaining, winning back, or converting?

---

## Data Validation (Part 1)

Before any analysis, the raw ~1.07M rows were audited and cleaned via a non-destructive SQL `VIEW` (`clean_transactions`) — raw data was never deleted, only filtered in a reusable layer:

| Issue Found | Rows Affected |
|---|---|
| Cancelled orders (Invoice starts with "C") | 19,494 |
| Missing Customer ID | 243,007 (22.8%) |
| Negative quantity (returns) | 22,950 |
| Non-product charge rows (postage, bank fees, etc.) | 5,464 |
| Exact duplicate transaction rows | ~26,000 |

**Final clean dataset: 776,724 rows.** The dataset was also found to have an incomplete final month (data ends Dec 9, 2011) — this partial month was excluded from all trend analysis to avoid a misleading artificial "drop."

---

## Key Finding #1: Retention Collapses in Month 1 — Every Cohort, No Exceptions

| Cohort | M0 | M1 | M2 | M3 | M4 | M5 | M6 |
|---|---|---|---|---|---|---|---|
| Dec 2009 | 100% | **35.3%** | 33.3% | 42.5% | 38.0% | 35.9% | 37.8% |
| Jun 2010 | 100% | **17.6%** | 18.7% | 20.6% | 23.2% | 28.5% | 12.7% |
| Nov 2010 | 100% | **17.5%** | 9.5% | 9.5% | 7.7% | 8.9% | 12.9% |

Across virtually every cohort tested, **60–80%+ of customers never return after their first purchase** — but the ones who survive month 1 settle into a relatively stable repeat-purchase pattern.

**Recommendation:** Retention spend is misallocated if spread evenly across a customer's lifetime. The highest-leverage window is the **first 30 days** — a targeted second-purchase incentive or onboarding email sequence here would have more impact than any later-stage campaign.

---

## Key Finding #2: Retention Dipped Through 2010, Recovered Through 2011

Month-1 retention fell from ~20-25% (early 2010) to a low of **9.2%** (Dec 2010 cohort), before recovering to **31.7%** by Oct 2011 — the strongest performance since the dataset's first cohort.

**Caveat:** Later cohorts are much smaller in size (72–190 customers vs. 300–950 in 2010), so month-to-month swings should be read with caution and ideally smoothed over a rolling window.

**Recommendation:** Something changed for the better starting mid-2011 — worth investigating (pricing, product mix, marketing channel) since it reversed a real decline. Track future performance on a rolling basis rather than single-month snapshots, given the smaller recent cohort sizes.

---

## Key Finding #3: Don't Rank Cohorts by Total Revenue — Normalize by Time Active

| Cohort | Total CLV (Naive) | Months Active | CLV / Month (Fair) |
|---|---|---|---|
| Dec 2009 | ₹8,644.98 | 24 | ₹360.21 |
| Oct 2011 | ₹592.94 | 2 | **₹296.47** |
| Nov 2011 | ₹416.16 | 1 | **₹416.16** |

Naive lifetime value made Dec 2009 look overwhelmingly better than every other cohort — but that's mostly because it's had 24 months to accumulate spend. Once corrected for time active, several **late-2011 cohorts spend at a comparable or higher monthly rate** than most of 2010's cohorts — consistent with the retention recovery found in Finding #2.

**Recommendation:** Use CLV-per-month-active (not raw total CLV) for any cohort comparison. By this fairer metric, recent acquisition quality looks strong — a positive signal worth validating with more data as these cohorts mature.

---

## Key Finding #4: 22% of Customers Drive 69% of Revenue

RFM segmentation (Recency, Frequency, Monetary — scored via `NTILE()` and bucketed via `CASE`) split ~5,800 customers into 6 segments:

| Segment | Customers | % of Customers | Revenue | % of Revenue |
|---|---|---|---|---|
| **Champions** | 1,269 | 21.9% | ₹1.14 Cr | **68.8%** |
| Loyal Customers | 1,410 | 24.3% | ₹25.9 L | 15.6% |
| At Risk | 259 | 4.5% | ₹10.4 L | 6.3% |
| Needs Attention | 1,126 | 19.4% | ₹10.1 L | 6.1% |
| Lost / Hibernating | 1,312 | 22.6% | ₹3.2 L | 1.9% |
| New Customers | 460 | 7.9% | ₹2.0 L | 1.2% |

**Recommendations by segment:**
- **Champions (68.8% of revenue):** Highest-priority retention target — a loyalty/VIP program here has the best ROI in the business.
- **At Risk (6.3% of revenue, formerly high-value):** Urgent, personalized win-back outreach — losing this group is a real revenue loss, not just a headcount loss.
- **Lost/Hibernating (22.6% of customers, only 1.9% of revenue):** Low expected ROI for expensive win-back campaigns — keep any outreach cheap and automated.
- **New Customers (1.2% of revenue):** The real lever is early conversion — this connects directly to Finding #1: the first 30 days determine whether a "New Customer" becomes a "Loyal Customer" or churns entirely.

---

## The One-Slide Takeaway

**The single biggest lever for this business is the first purchase-to-second-purchase transition.** Retention data shows the steepest drop happens in month 1 across every cohort; RFM data shows New Customers contribute almost no revenue yet represent real future Champions if converted. A single, well-targeted early-lifecycle retention campaign would have more business impact than any other single change available in this dataset.

---

## Techniques Demonstrated

- Data validation & cleaning via non-destructive SQL Views
- CTEs (multi-stage, readable query logic)
- Self-joins for cohort-to-transaction matching
- Window functions: `ROW_NUMBER()`, `NTILE()`, `SUM() OVER()`
- Date arithmetic across year boundaries
- Conditional aggregation (`CASE WHEN` + `MAX`) to simulate PIVOT
- Query performance optimization via indexing (~40s → ~13s on join-heavy queries)
- RFM customer segmentation
- Translating SQL output into business recommendations
