USE enterprise_retail_db;

-- ============================================================
-- DAY 1: SQL FOUNDATIONS (Questions 1-12)
-- ============================================================

-- Q1. Select all products from category_id = 1 or 3 with unit_price >= 500,
--     sorted by unit_price in descending order.
SELECT
    product_id,
    product_name,
    category_id,
    unit_price
FROM products
WHERE category_id IN (1, 3)
  AND unit_price >= 500.00
ORDER BY unit_price DESC;


-- Q2. Find all customers in USA whose city has 'e' as the second character.
SELECT
    customer_id,
    customer_name,
    city,
    country
FROM customers
WHERE country = 'USA'
  AND city LIKE '_e%';


-- Q3. Find completed orders placed between 2024-02-01 and 2024-04-30
--     using Express or Same Day shipping.
SELECT
    order_id,
    customer_id,
    order_date,
    ship_mode,
    order_status
FROM orders
WHERE order_date BETWEEN '2024-02-01' AND '2024-04-30'
  AND ship_mode IN ('Express', 'Same Day')
  AND order_status = 'Completed'
ORDER BY order_date ASC;


-- Q4. Show product profit and profit margin, keeping only margin >= 40%.
SELECT
    product_name,
    unit_price,
    cost_price,
    ROUND(unit_price - cost_price, 2) AS unit_profit_usd,
    ROUND(((unit_price - cost_price) / unit_price) * 100, 2) AS profit_margin_pct
FROM products
WHERE ((unit_price - cost_price) / unit_price) * 100 >= 40.00
ORDER BY profit_margin_pct DESC;


-- Q5. Count COMPLETED orders by ship mode.
-- Corrected to match the wording of the task.
SELECT
    ship_mode,
    COUNT(*) AS total_order_count
FROM orders
WHERE order_status = 'Completed'
GROUP BY ship_mode
ORDER BY total_order_count DESC;


-- Q6. Standardize customer email information and extract email domain.
SELECT
    customer_id,
    customer_name,
    LOWER(email) AS clean_email,
    CHAR_LENGTH(customer_name) AS name_char_count,
    SUBSTRING(email, INSTR(email, '@') + 1) AS email_domain
FROM customers;


-- Q7. Calculate employee tenure in full months as of 2026-01-01.
SELECT
    employee_id,
    CONCAT(first_name, ' ', last_name) AS full_name,
    hire_date,
    TIMESTAMPDIFF(MONTH, hire_date, '2026-01-01') AS months_of_service
FROM employees
ORDER BY months_of_service DESC;


-- Q8. Classify orders as Self-Service or Assisted Enterprise and count each.
SELECT
    CASE
        WHEN sales_rep_id IS NULL THEN 'Self-Service'
        ELSE 'Assisted Enterprise'
    END AS sales_channel,
    COUNT(*) AS total_orders
FROM orders
GROUP BY
    CASE
        WHEN sales_rep_id IS NULL THEN 'Self-Service'
        ELSE 'Assisted Enterprise'
    END;


-- Q9. Calculate line-item metrics and net revenue for order_id = 101.
SELECT
    order_id,
    COUNT(order_item_id) AS total_line_items,
    SUM(quantity) AS total_units_sold,
    ROUND(AVG(unit_price), 2) AS avg_unit_price,
    ROUND(SUM(quantity * unit_price * (1 - discount_pct)), 2) AS total_net_revenue
FROM order_items
WHERE order_id = 101
GROUP BY order_id;


-- Q10. Count customers by country and segment; keep groups with at least 2.
SELECT
    country,
    segment,
    COUNT(customer_id) AS customer_count
FROM customers
GROUP BY country, segment
HAVING COUNT(customer_id) >= 2
ORDER BY country ASC, customer_count DESC;


-- Q11. Find customers who used more than one distinct shipping mode.
SELECT
    customer_id,
    COUNT(DISTINCT ship_mode) AS distinct_ship_modes_used
FROM orders
GROUP BY customer_id
HAVING COUNT(DISTINCT ship_mode) > 1;


-- Q12. Analyze order items with quantity >= 5 and return the top 3 products
--      with net revenue >= 10000.
SELECT
    product_id,
    SUM(quantity) AS bulk_volume_sold,
    ROUND(SUM(quantity * unit_price * (1 - discount_pct)), 2) AS bulk_net_revenue,
    CASE
        WHEN AVG(unit_price) > 1000.00 THEN 'High Ticket'
        ELSE 'Standard'
    END AS pricing_category
FROM order_items
WHERE quantity >= 5
GROUP BY product_id
HAVING SUM(quantity * unit_price * (1 - discount_pct)) >= 10000.00
ORDER BY bulk_net_revenue DESC
LIMIT 3;


-- ============================================================
-- DAY 2: JOINS, SUBQUERIES & CTEs (Questions 13-20)
-- ============================================================

-- Q13. Category sales report for Completed orders.
SELECT
    cat.category_name,
    SUM(oi.quantity) AS total_units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)), 2) AS net_revenue
FROM categories cat
INNER JOIN products p
    ON cat.category_id = p.category_id
INNER JOIN order_items oi
    ON p.product_id = oi.product_id
INNER JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY cat.category_id, cat.category_name
ORDER BY net_revenue DESC;


-- Q14. Show all sales reps (department_id = 2), including those with zero
--      completed orders and zero booked revenue.
SELECT
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS sales_rep_name,
    COUNT(DISTINCT o.order_id) AS orders_closed,
    COALESCE(
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)), 2),
        0.00
    ) AS total_booked_revenue
FROM employees e
LEFT JOIN orders o
    ON e.employee_id = o.sales_rep_id
   AND o.order_status = 'Completed'
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE e.department_id = 2
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY total_booked_revenue DESC;


-- Q15. Find employees who earn more than their direct manager.
SELECT
    CONCAT(emp.first_name, ' ', emp.last_name) AS employee_name,
    emp.salary AS employee_salary,
    CONCAT(mgr.first_name, ' ', mgr.last_name) AS manager_name,
    mgr.salary AS manager_salary,
    emp.salary - mgr.salary AS salary_difference
FROM employees emp
INNER JOIN employees mgr
    ON emp.manager_id = mgr.employee_id
WHERE emp.salary > mgr.salary
ORDER BY salary_difference DESC;


-- Q16. Emulate FULL OUTER JOIN between customers and sales reps,
--      matching customer city with department office_location.
SELECT
    c.customer_name,
    c.city AS customer_city,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.office_location AS department_city
FROM customers c
LEFT JOIN departments d
    ON c.city = d.office_location
LEFT JOIN employees e
    ON d.department_id = e.department_id
   AND e.department_id = 2

UNION

SELECT
    c.customer_name,
    c.city AS customer_city,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.office_location AS department_city
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id
LEFT JOIN customers c
    ON c.city = d.office_location
WHERE e.department_id = 2;


-- Q17. Find products priced strictly above their category average.
SELECT
    p.product_id,
    p.product_name,
    p.category_id,
    p.unit_price,
    ROUND(
        (
            SELECT AVG(p2.unit_price)
            FROM products p2
            WHERE p2.category_id = p.category_id
        ),
        2
    ) AS category_avg_price
FROM products p
WHERE p.unit_price > (
    SELECT AVG(p2.unit_price)
    FROM products p2
    WHERE p2.category_id = p.category_id
)
ORDER BY p.category_id, p.unit_price DESC;


-- Q18. Find Corporate customers who placed at least one order in 2024
--      but have never ordered a Furniture product (category_id = 3).
-- Corrected to include the required 2024 condition.
SELECT
    c.customer_id,
    c.customer_name,
    c.segment
FROM customers c
WHERE c.segment = 'Corporate'
  AND EXISTS (
      SELECT 1
      FROM orders o
      WHERE o.customer_id = c.customer_id
        AND o.order_date >= '2024-01-01'
        AND o.order_date < '2025-01-01'
  )
  AND NOT EXISTS (
      SELECT 1
      FROM orders o
      INNER JOIN order_items oi
          ON o.order_id = oi.order_id
      INNER JOIN products p
          ON oi.product_id = p.product_id
      WHERE o.customer_id = c.customer_id
        AND p.category_id = 3
  );


-- Q19. Use chained CTEs to calculate completed-order customer metrics,
--      assign Platinum/Gold/Silver tiers, then summarize each tier.
WITH CustomerMetrics AS (
    SELECT
        c.customer_id,
        c.customer_name,
        COUNT(DISTINCT o.order_id) AS completed_orders,
        COALESCE(
            SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)),
            0
        ) AS total_net_spend
    FROM customers c
    LEFT JOIN orders o
        ON c.customer_id = o.customer_id
       AND o.order_status = 'Completed'
    LEFT JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_id, c.customer_name
),
CustomerTiers AS (
    SELECT
        customer_id,
        customer_name,
        completed_orders,
        total_net_spend,
        CASE
            WHEN total_net_spend >= 30000 THEN 'Platinum'
            WHEN total_net_spend >= 10000 THEN 'Gold'
            ELSE 'Silver'
        END AS customer_tier
    FROM CustomerMetrics
)
SELECT
    customer_tier,
    COUNT(customer_id) AS total_customers,
    ROUND(SUM(total_net_spend), 2) AS total_revenue
FROM CustomerTiers
GROUP BY customer_tier
ORDER BY total_revenue DESC;


-- Q20. Generate a date spine from 2024-01-01 through 2024-01-07 and show
--      daily order count and revenue, including dates with zero orders.
-- Corrected to match the exact date range stated in the task.
WITH RECURSIVE DateSpine AS (
    SELECT CAST('2024-01-01' AS DATE) AS calendar_date

    UNION ALL

    SELECT DATE_ADD(calendar_date, INTERVAL 1 DAY)
    FROM DateSpine
    WHERE calendar_date < '2024-01-07'
)
SELECT
    ds.calendar_date,
    COUNT(DISTINCT o.order_id) AS daily_order_count,
    COALESCE(
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)), 2),
        0.00
    ) AS daily_revenue
FROM DateSpine ds
LEFT JOIN orders o
    ON ds.calendar_date = o.order_date
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY ds.calendar_date
ORDER BY ds.calendar_date ASC;

-- ============================================================
-- END OF SQL ASSESSMENT
-- ============================================================
