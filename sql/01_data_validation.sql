/* -- 01: Data validation checks on TheLook eCommerce.*/

/*===========================================
01_data_validation.sql
Project: TheLook Growth Analysis
Purpose: Confirm the data is complete before analysis. Checks row counts, date ranges,
         duplicates and status values.
Dataset: bigquery-public-data.thelook_ecommerce
Cutoff: orders created on or before 2026-10-31
============================================ */
/*------------------------------------------
  Check 1: Date range and volume of orders
  Why: Confirms how much history is available and sets
    the cutoff date used in every later query.
  Finding: [124,916 orders from 2019-01-13 to 2026-11-16. The data
            refreshes daily, so Nov 2026 is incomplete; analysis uses
            orders through 2026-10-31. Jan 2019 is also a partial
            month (starts Jan 13) and should be read with caution.]
------------------------------------------*/
SELECT 
  COUNT(*)   AS order_count,
  MIN(created_at) AS first_order,
  MAX(created_at) AS last_order
FROM `bigquery-public-data.thelook_ecommerce.orders`;
/*--------------------------------------------
Check 2:    Duplicate IDs in orders and order_items
   Why:     Duplicate rows would inflate order counts and
            revenue in every later analysis.
   Finding: 2A: 117054 rows, 117054 unique orders, 0 duplicates
            2B: 169886 rows, 169886 unique items, 0 duplicates.
            Both tables are safe to count without de-duplicating.
-----------------------------------------------*/
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT order_id) AS unique_orders,
  COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_rows
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE created_at < '2026-11-01';

SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT id) AS unique_items,
  COUNT(*) - COUNT(DISTINCT id) AS duplicate_rows
FROM `bigquery-public-data.thelook_ecommerce.order_items`
WHERE created_at < '2026-11-01';

/*------------------------------------
Check 3: Orphaned records
Why: Rows that point to a missing parent record would
     make totals differ depending on which tables are joined. 
Finding: 3a - 0 order_items without a matching order.
         3b - 0 orders without a matching user.
         All joins between order_items, orders, and users
         are complete; no rows will be lost when joining.
--------------------------------------*/
SELECT
  COUNT(*) AS orphan_items,
FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
LEFT JOIN `bigquery-public-data.thelook_ecommerce.orders` o 
  ON oi.order_id = o.order_id
WHERE oi.created_at < '2026-11-01'
  AND o.order_id IS NULL;

SELECT 
  COUNT(*) AS orphan_items,
FROM `bigquery-public-data.thelook_ecommerce.orders` o
LEFT JOIN `bigquery-public-data.thelook_ecommerce.users` u
   ON o.user_id = u.id
WHERE o.created_at < '2026-11-01'
AND u.id IS NULL;


/*------------------------------------
Check 4:Order item status values and revenue definition
   Why: Revenue must exclude sales that didn't happen.
         This sets the revenue rule used in every later file.
Finding: 5 statuses across 169,886 items ($10.13M gross).
         Cancelled (15% of value) and Returned (10%) are
         excluded. Revenue rule for all later files:
         status IN ('Shipped', 'Complete', 'Processing').
         Net revenue = $7.58M (74.9% of gross).
         Note: Processing items are booked but not yet
         shipped; some may still be cancelled.
--------------------------------------*/   
SELECT status,
  COUNT(*) AS num_items,
  ROUND(SUM(sale_price), 2) AS total_sale_price
FROM `bigquery-public-data.thelook_ecommerce.order_items`
WHERE created_at < '2026-11-01'
GROUP BY status
ORDER BY num_items DESC;
