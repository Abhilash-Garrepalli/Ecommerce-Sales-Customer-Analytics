



----Monthly Revenue & Order Volume Growth


SELECT 
    FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS total_customers,
    ROUND(SUM(i.total_item_value), 2) AS total_revenue
FROM orders o
JOIN order_items i ON o.order_id = i.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
ORDER BY order_month

----------Top 3 Product Categories per State (Using CTEs & Window Functions)

WITH CategorySales AS (
    SELECT 
        c.customer_state,
        p.category_name,
        ROUND(SUM(i.total_item_value), 2) AS category_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.customer_state ORDER BY SUM(i.total_item_value) DESC) as revenue_rank
    FROM orders o
    JOIN order_items i ON o.order_id = i.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN products p ON i.product_id = p.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state, p.category_name
)
SELECT 
    customer_state,
    category_name,
    category_revenue,
    revenue_rank
FROM CategorySales
WHERE revenue_rank <= 3
ORDER BY customer_state, revenue_rank

---------------Month-over-Month (MoM) Revenue Growth (Using LAG Window Function)

WITH MonthlyRevenue AS (
    SELECT 
        FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS order_month,
        ROUND(SUM(i.total_item_value), 2) AS current_month_revenue
    FROM orders o
    JOIN order_items i ON o.order_id = i.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
)
SELECT 
    order_month,
    current_month_revenue,
    LAG(current_month_revenue, 1) OVER (ORDER BY order_month) AS previous_month_revenue,
    ROUND(
        ((current_month_revenue - LAG(current_month_revenue, 1) OVER (ORDER BY order_month)) 
        / NULLIF(LAG(current_month_revenue, 1) OVER (ORDER BY order_month), 0)) * 100, 2
    ) AS mom_growth_percentage
FROM MonthlyRevenue
ORDER BY order_month