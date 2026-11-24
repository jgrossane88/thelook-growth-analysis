/* ============================================================
   02_kpi_trends.sql
   Project:  TheLook Growth Analysis
   Purpose:  Track monthly revenue, orders, customers, and AOV
             to find when and where growth slowed.
   Rules:    Cutoff: created_at < '2026-11-01'
             Revenue: status IN ('Shipped','Complete','Processing')
             (both defined in 01_data_validation.sql)
   ============================================================ */
WITH monthly AS (
  SELECT
    DATE_TRUNC(DATE(created_at), MONTH) AS order_month,
    SUM(sale_price) AS revenue,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT user_id) AS customers
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE status IN ('Shipped', 'Complete', 'Processing')
    AND created_at < '2026-11-01'
  GROUP BY order_month
)
SELECT
  order_month,
  ROUND(revenue, 2) AS revenue,
  orders,
  customers,
  ROUND(revenue / orders, 2) AS aov
FROM monthly
ORDER BY order_month;
/* ------------------------------------------------------------
   Query 1: Monthly KPIs (revenue, orders, customers, AOV)
   Why:     Establishes the baseline trend for the growth question.
   Finding: 94 months (Jan 2019 - Oct 2026). Revenue grew from
            $869 (partial Jan 2019) to $374K in Oct 2026, a record
            month (+25.6% MoM). AOV is stable at roughly $80-86, so
            growth is driven by order volume, not basket size.
            Growth does not look slower in absolute terms; Query 2
            tests whether the growth RATE is slowing.
   ------------------------------------------------------------ */
WITH monthly AS (
  SELECT
    DATE_TRUNC(DATE(created_at), MONTH) AS order_month,
    SUM(sale_price) AS revenue,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT user_id) AS customers
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE status IN ('Shipped', 'Complete', 'Processing')
    AND created_at < '2026-11-01'
  GROUP BY order_month
)
SELECT
  order_month,
  ROUND(revenue, 2) AS revenue,
  ROUND(LAG(revenue, 12) OVER (ORDER BY order_month), 2) AS revenue_last_year,
  ROUND(
    SAFE_DIVIDE(
      revenue - LAG(revenue, 12) OVER (ORDER BY order_month),
      LAG(revenue, 12) OVER (ORDER BY order_month)
    ) * 100, 1
  ) AS yoy_growth_pct
FROM monthly
ORDER BY order_month;

/*----------------------------------------------------
Query 2: Year-over-year revenue growth
   Why:     Tests the brief's premise that growth has slowed.
            YoY comparison removes seasonality.
   Finding: Premise not supported. October YoY growth accelerated
            each year: +33.6% (2023), +42.9% (2024), +50.8% (2025),
            +129.8% (2026). The 2026 jump needs verification
            (see last-12-months check). Project question reframed:
            what is driving the acceleration, and is it healthy?
----------------------------------------------------------------*/
