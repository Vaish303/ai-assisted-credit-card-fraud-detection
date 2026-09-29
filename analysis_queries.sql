-- ============================================
-- Fraud Detection Analysis Queries
-- Dataset: Kaggle Credit Card Fraud Detection (cleaned, deduplicated)
-- ============================================

-- 1. Fraud rate by transaction amount bucket
SELECT 
  CASE 
    WHEN Amount < 50 THEN '0-50'
    WHEN Amount < 200 THEN '50-200'
    WHEN Amount < 500 THEN '200-500'
    WHEN Amount < 1000 THEN '500-1000'
    ELSE '1000+'
  END AS amount_bucket,
  COUNT(*) AS total_transactions,
  SUM(Class) AS fraud_count,
  ROUND(100.0 * SUM(Class) / COUNT(*), 4) AS fraud_rate_pct
FROM creditcard_cleaned
GROUP BY amount_bucket
ORDER BY MIN(Amount);


-- 2. Fraud rate by hour-of-day (Time is seconds elapsed, wrapped into a 24-hour cycle)
SELECT 
  CAST(Time / 3600 AS INTEGER) % 24 AS hour_of_day,
  COUNT(*) AS total_transactions,
  SUM(Class) AS fraud_count,
  ROUND(100.0 * SUM(Class) / COUNT(*), 4) AS fraud_rate_pct
FROM creditcard_cleaned
GROUP BY hour_of_day
ORDER BY hour_of_day;


-- 3. Average / min / max transaction amount, fraud vs. legitimate
SELECT 
  Class,
  COUNT(*) AS total_transactions,
  ROUND(AVG(Amount), 2) AS avg_amount,
  ROUND(MIN(Amount), 2) AS min_amount,
  ROUND(MAX(Amount), 2) AS max_amount
FROM creditcard_cleaned
GROUP BY Class;