# AI-Assisted Credit Card Fraud Detection: Risk Analysis

An end-to-end analytics project that cleans, analyzes, and visualizes credit card transaction data to detect fraud patterns — using an AI-assisted, rule-based risk-scoring system instead of a black-box model.

<img width="2418" height="1356" alt="dashboard photo" src="https://github.com/user-attachments/assets/d41a4685-8fa5-4271-9c6b-6207637cd55a" />


## Problem Statement

Credit card fraud is rare but costly. In this dataset, only **0.167% of transactions were fraudulent** (473 out of 283,726), making it a highly imbalanced detection problem where accuracy alone is a meaningless metric. This project explores *when* and *how much* fraud tends to occur, then builds an interpretable risk-scoring system based on those patterns — prioritizing explainability over raw predictive power, since a rule an analyst can defend in an interview or audit is often more valuable than a model no one can explain.

## Dataset

- **Source:** [Kaggle Credit Card Fraud Detection Dataset](https://www.kaggle.com/datasets/mlg-ulb/creditcardfraud)
- **Original size:** 284,807 transactions
- **After cleaning:** 283,726 transactions (1,081 exact duplicate rows removed)
- **Fraud cases:** 473 (0.167%)
- Features `V1`–`V28` are PCA-anonymized for confidentiality; `Time` (seconds elapsed), `Amount`, and `Class` (0 = legitimate, 1 = fraud) are the only interpretable columns.

## Pipeline

**Excel → SQL (SQLite) → Power BI → GitHub**

### 1. Excel — Cleaning & Inspection
- Checked for nulls and duplicates
- Removed 1,081 exact duplicate rows (284,807 → 283,726)
- Built a pivot table to confirm the class imbalance

### 2. SQL — Analysis
Three queries (full code in [`analysis_queries.sql`](analysis_queries.sql)) uncovered the patterns used later in the risk-scoring logic:

**Finding 1 — Fraud rate rises with transaction amount**
| Amount Bucket | Fraud Rate |
|---|---|
| $0–50 | 0.155% |
| $50–200 | 0.151% |
| $200–500 | 0.243% |
| **$500–1000** | **0.391%** |
| $1000+ | 0.294% |

**Finding 2 — Fraud rate spikes at two specific hours** (Time converted to a 24-hour cycle)
| Hour | Fraud Rate |
|---|---|
| **Hour 2** | **1.45%** |
| **Hour 4** | **1.04%** |
| All other hours | Under 0.5% |

Hours 2 and 4 are roughly 6–10x higher than the dataset's overall fraud rate — the single strongest signal found in this analysis.

**Finding 3 — Fraud transactions average higher amounts**
| | Avg Amount | Max Amount |
|---|---|---|
| Legitimate | $88.41 | $25,691.16 |
| Fraud | $123.87 | $2,125.87 |

Fraud transactions average ~40% higher than legitimate ones, but rarely reach the extreme highs seen in legitimate spending — fraud clusters in a moderate-but-above-average range.

### 3. AI-Assisted Risk Scoring
Rather than training a black-box classifier, the three SQL findings above were given to an LLM with a prompt asking it to propose a simple, interpretable rule set. The resulting logic:

- **High risk:** occurs in hour 2 or 4, **and** amount ≥ $50
- **Medium risk:** occurs in hour 2 or 4 (any amount), **or** amount is $500–1000
- **Low risk:** everything else

This was implemented as two Power BI calculated columns:

```dax
Hour_of_Day = MOD(INT(creditcard_cleaned[Time] / 3600), 24)

Risk_Tier =
VAR IsRiskyHour = OR(creditcard_cleaned[Hour_of_Day] = 2, creditcard_cleaned[Hour_of_Day] = 4)
VAR IsHighAmount = creditcard_cleaned[Amount] >= 50
VAR IsMidAmount = creditcard_cleaned[Amount] >= 500 && creditcard_cleaned[Amount] < 1000
RETURN
SWITCH(
    TRUE(),
    IsRiskyHour && IsHighAmount, "High",
    IsRiskyHour || IsMidAmount, "Medium",
    "Low"
)
```

### 4. Power BI Dashboard
The dashboard includes:
- KPI strip: total transactions, fraud cases, fraud rate %, total fraud amount
- Fraud rate by hour-of-day (line chart) — visually confirms the hour 2/4 spike
- Fraud cases by risk tier (donut chart)
- A sortable table of all High-risk transactions
- Interactive slicers for hour-of-day and amount range

## Results & Honest Limitations

| Risk Tier | Transactions | Fraud Caught | Fraud Rate | Lift vs. Baseline |
|---|---|---|---|---|
| High | 1,372 | 14 | 1.02% | ~6x |
| Medium | 10,426 | 80 | 0.77% | ~4.6x |
| Low | 271,928 | 379 | 0.14% | 0.8x |

The rule set concentrates risk effectively — the High tier has roughly 6x the baseline fraud rate. However, it only catches about **20% of all fraud cases** (94 of 473), meaning 80% of fraud still falls in the Low tier. This is an expected trade-off of a simple, two-variable rule set built for interpretability rather than recall.

**Important caveat:** these rules were derived from and tested on the same dataset — there's no holdout/validation split. A production system would need to validate this logic on unseen data, and would likely combine these interpretable rules with a proper supervised model (e.g., logistic regression or gradient boosting) to improve recall while keeping some rules explainable for audit purposes.

## Tools Used
SQL (SQLite), Microsoft Excel, Power BI (DAX), and an LLM for rule-design assistance.

## Files in This Repository
- `analysis_queries.sql` — all three SQL analysis queries
- `fraud_detection_dashboard.pbix` — the Power BI file
- `dashboard.png` — dashboard screenshot
