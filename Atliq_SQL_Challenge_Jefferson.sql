-- Q1: Markets where 'Atliq Exclusive' operates in APAC
SELECT DISTINCT c.market
FROM dim_customer c
JOIN fact_sales_monthly f ON c.customer_code = f.customer_code
WHERE c.customer = 'Atliq Exclusive'
  AND c.region = 'APAC';
  
  
-- Q2. Unique product increase in 2021 vs 2020
 WITH products_2020 AS (
  SELECT COUNT(DISTINCT product_code) AS unique_products_2020
  FROM fact_sales_monthly
  WHERE fiscal_year = 2020
),
products_2021 AS (
  SELECT COUNT(DISTINCT product_code) AS unique_products_2021
  FROM fact_sales_monthly
  WHERE fiscal_year = 2021
)
SELECT
  p2020.unique_products_2020,
  p2021.unique_products_2021,
  ROUND(100.0 * (p2021.unique_products_2021 - p2020.unique_products_2020) / p2020.unique_products_2020, 2) AS percentage_chg
FROM products_2020 p2020, products_2021 p2021;        


-- Q3. Unique product counts for each segment (descending order)
SELECT
  segment,
  COUNT(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;


-- Q4. Segment with most increase in unique products in 2021 vs 2020
WITH product_2020 AS (
  SELECT p.segment, COUNT(DISTINCT f.product_code) AS product_count_2020
  FROM fact_sales_monthly f
  JOIN dim_product p ON f.product_code = p.product_code
  WHERE f.fiscal_year = 2020
  GROUP BY p.segment
),
product_2021 AS (
  SELECT p.segment, COUNT(DISTINCT f.product_code) AS product_count_2021
  FROM fact_sales_monthly f
  JOIN dim_product p ON f.product_code = p.product_code
  WHERE f.fiscal_year = 2021
  GROUP BY p.segment
)
SELECT
  p21.segment,
  COALESCE(p20.product_count_2020, 0) AS product_count_2020,
  p21.product_count_2021,
  p21.product_count_2021 - COALESCE(p20.product_count_2020, 0) AS difference
FROM product_2021 p21
LEFT JOIN product_2020 p20 ON p21.segment = p20.segment
ORDER BY difference DESC
LIMIT 1;


-- Q5. Products with the highest and lowest manufacturing costs
SELECT fmc.product_code, dp.product, fmc.manufacturing_cost 
FROM fact_manufacturing_cost fmc
JOIN dim_product dp ON fmc.product_code = dp.product_code
WHERE fmc.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
   OR fmc.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost);

-- Q6. Top 5 customers with highest average pre_invoice_discount_pct in FY 2021 in Indian market
SELECT
  c.customer_code,
  c.customer,
  ROUND(AVG(f.pre_invoice_discount_pct), 2) AS average_discount_percentage
FROM fact_pre_invoice_deductions f
JOIN dim_customer c ON f.customer_code = c.customer_code
WHERE f.fiscal_year = 2021
  AND c.market = 'India'
GROUP BY c.customer_code, c.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;


-- Q7. Gross sales amount for "Atliq Exclusive" per month
SELECT
  MONTH(fsm.date) AS month,
  YEAR(fsm.date) AS year,
  SUM(fsm.sold_quantity * fgp.gross_price) AS gross_sales_amount
FROM fact_sales_monthly fsm
JOIN dim_customer dc ON fsm.customer_code = dc.customer_code
JOIN fact_gross_price fgp ON fsm.product_code = fgp.product_code
    AND fsm.fiscal_year = fgp.fiscal_year
WHERE dc.customer = 'Atliq Exclusive'
GROUP BY YEAR(fsm.date), MONTH(fsm.date)
ORDER BY YEAR(fsm.date), MONTH(fsm.date);


-- Q8. Quarter of 2020 with maximum total_sold_quantity
SELECT 
    QUARTER(date) as quarter, SUM(sold_quantity) as total_sold_quantity
    FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY quarter
ORDER BY total_sold_quantity DESC
LIMIT 1;


-- Q9. Channel with most gross sales in FY 2021 and its percentage contribution
WITH channel_sales AS (
  SELECT dc.channel, 
         SUM(fsm.sold_quantity * fgp.gross_price) AS gross_sales_mln
  FROM fact_sales_monthly fsm
  JOIN dim_customer dc ON fsm.customer_code = dc.customer_code
  JOIN fact_gross_price fgp 
    ON fsm.product_code = fgp.product_code 
   AND fsm.fiscal_year = fgp.fiscal_year
  WHERE fsm.fiscal_year = 2021
  GROUP BY dc.channel
),
total AS (
  SELECT SUM(gross_sales_mln) AS total_sales FROM channel_sales
)
SELECT
  cs.channel,
  ROUND(cs.gross_sales_mln, 2) AS gross_sales_mln,
  ROUND(100 * cs.gross_sales_mln / t.total_sales, 2) AS percentage
FROM channel_sales cs, total t
ORDER BY cs.gross_sales_mln DESC
LIMIT 1;


-- Q10. Top 3 products in each division by total_sold_quantity in FY 2021
WITH ranked_products AS (
  SELECT
    dp.division,
    f.product_code,
    dp.product,
    SUM(f.sold_quantity) AS total_sold_quantity,
    ROW_NUMBER() OVER (PARTITION BY dp.division ORDER BY SUM(f.sold_quantity) DESC) AS rank_order
  FROM fact_sales_monthly f
  JOIN dim_product dp ON f.product_code = dp.product_code
  WHERE f.fiscal_year = 2021
  GROUP BY dp.division, f.product_code, dp.product
)
SELECT
  division,
  product_code,
  product,
  total_sold_quantity,
  rank_order
FROM ranked_products
WHERE rank_order <= 3
ORDER BY division, rank_order;





