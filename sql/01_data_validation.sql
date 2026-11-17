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
  Finding: [fill in after running */]
------------------------------------------*/
SELECT 
  COUNT(*)   AS order_count,
  MIN(created_at) AS first_order,
  MAX(created_at) AS last_order
FROM `bigquery-public-data.thelook_ecommerce.orders`;
