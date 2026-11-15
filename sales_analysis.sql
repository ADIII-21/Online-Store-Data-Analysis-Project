-- QUESTION 1: WHAT IS THE TOTAL REVENUE?
-- Business objective: Calculate the store's total revenue.

CREATE OR REPLACE VIEW vw_total_revenue AS
SELECT
    ROUND(SUM(TotalPrice), 2) AS total_revenue
FROM online_store_orders;

SELECT * FROM vw_total_revenue;


-- QUESTION 2: HOW MANY ORDERS WERE PLACED?
-- Business objective: Count unique orders.

CREATE OR REPLACE VIEW vw_total_orders AS
SELECT
    COUNT(DISTINCT OrderID) AS total_orders
FROM online_store_orders;

SELECT * FROM vw_total_orders;


-- QUESTION 3: HOW MANY PRODUCT UNITS WERE SOLD?
-- Business objective: Calculate total quantity sold.

CREATE OR REPLACE VIEW vw_total_quantity_sold AS
SELECT
    SUM(Quantity) AS total_quantity_sold
FROM online_store_orders;

SELECT * FROM vw_total_quantity_sold;


-- QUESTION 4: WHAT IS THE YEARLY REVENUE?
-- Business objective: Compare revenue across years.

CREATE OR REPLACE VIEW vw_yearly_revenue AS
SELECT
    YEAR(Date) AS order_year,
    ROUND(SUM(TotalPrice), 2) AS total_revenue
FROM online_store_orders
WHERE Date IS NOT NULL
GROUP BY YEAR(Date);

SELECT *
FROM vw_yearly_revenue
ORDER BY order_year;


-- QUESTION 5: WHAT IS THE MONTHLY REVENUE?
-- Business objective: Track revenue month by month.


CREATE OR REPLACE VIEW vw_monthly_revenue AS
SELECT
    YEAR(Date) AS order_year,
    MONTH(Date) AS month_number,
    MONTHNAME(Date) AS month_name,

    CAST(
        DATE_FORMAT(Date, '%Y-%m-01') AS DATE
    ) AS month_start,

    ROUND(SUM(TotalPrice), 2) AS monthly_revenue

FROM online_store_orders
WHERE Date IS NOT NULL

GROUP BY
    YEAR(Date),
    MONTH(Date),
    MONTHNAME(Date),
    CAST(DATE_FORMAT(Date, '%Y-%m-01') AS DATE);

SELECT *
FROM vw_monthly_revenue
ORDER BY order_year, month_number;


-- QUESTION 6: WHAT IS THE MONTH-OVER-MONTH GROWTH?
-- Business objective: Measure monthly revenue increase or decrease.


CREATE OR REPLACE VIEW vw_monthly_growth AS

WITH sales_with_previous AS (
    SELECT
        order_year,
        month_number,
        month_name,
        month_start,
        monthly_revenue,

        LAG(monthly_revenue) OVER (
            ORDER BY order_year, month_number
        ) AS previous_month_revenue

    FROM vw_monthly_revenue
)

SELECT
    order_year,
    month_number,
    month_name,
    month_start,
    monthly_revenue,
    previous_month_revenue,

    ROUND(
        (
            (monthly_revenue - previous_month_revenue)
            / NULLIF(previous_month_revenue, 0)
        ) * 100,
        2
    ) AS growth_percentage

FROM sales_with_previous;

SELECT *
FROM vw_monthly_growth
ORDER BY order_year, month_number;


-- QUESTION 7: WHICH MONTHS GENERATED THE MOST REVENUE?
-- Business objective: Rank all year-month periods by revenue.

CREATE OR REPLACE VIEW vw_highest_revenue_months AS
SELECT
    order_year,
    month_number,
    month_name,
    month_start,
    monthly_revenue,

    RANK() OVER (
        ORDER BY monthly_revenue DESC
    ) AS revenue_rank

FROM vw_monthly_revenue;

SELECT *
FROM vw_highest_revenue_months
ORDER BY revenue_rank, month_start;


-- QUESTION 8: WHAT IS THE AVERAGE ORDER VALUE?
-- Business objective: Calculate average revenue per unique order.


CREATE OR REPLACE VIEW vw_average_order_value AS
SELECT
    ROUND(AVG(order_revenue), 2) AS average_order_value

FROM (
    SELECT
        OrderID,
        SUM(TotalPrice) AS order_revenue

    FROM online_store_orders
    WHERE OrderID IS NOT NULL

    GROUP BY OrderID

) AS order_summary;

SELECT * FROM vw_average_order_value;


-- QUESTION 9: HOW MANY UNIQUE CUSTOMERS PLACED ORDERS?
-- Business objective: Measure the store's customer reach.

CREATE OR REPLACE VIEW vw_unique_customers AS
SELECT
    COUNT(DISTINCT CustomerID) AS unique_customers
FROM online_store_orders;

SELECT * FROM vw_unique_customers;


-- QUESTION 10: WHAT IS THE YEARLY REVENUE BY PRODUCT?
-- Business objective: Compare product revenue across years.

CREATE OR REPLACE VIEW vw_yearly_product_revenue AS
SELECT
    YEAR(Date) AS order_year,
    Product,
    ROUND(SUM(TotalPrice), 2) AS total_revenue

FROM online_store_orders

WHERE Date IS NOT NULL
  AND Product IS NOT NULL

GROUP BY
    YEAR(Date),
    Product;

SELECT *
FROM vw_yearly_product_revenue
ORDER BY order_year, total_revenue DESC;


USE online_store_analysis;

-- QUESTION 11: WHICH PRODUCTS GENERATE THE MOST REVENUE?
-- Business objective: Identify the highest-revenue products.

CREATE OR REPLACE VIEW vw_product_revenue AS
SELECT
    Product,
    ROUND(SUM(TotalPrice), 2) AS total_revenue

FROM online_store_orders

WHERE Product IS NOT NULL

GROUP BY Product;

SELECT *
FROM vw_product_revenue
ORDER BY total_revenue DESC;


-- QUESTION 12: WHICH PRODUCTS RECEIVE THE MOST ORDERS?
-- Business objective: Find the products appearing in the most
-- distinct customer orders.

CREATE OR REPLACE VIEW vw_product_order_count AS
SELECT
    Product,
    COUNT(DISTINCT OrderID) AS total_orders

FROM online_store_orders

WHERE Product IS NOT NULL
  AND OrderID IS NOT NULL

GROUP BY Product;

SELECT *
FROM vw_product_order_count
ORDER BY total_orders DESC;


-- QUESTION 13: WHICH PRODUCTS SELL THE HIGHEST QUANTITY?
-- Business objective: Identify products with the highest
-- total number of units sold.

CREATE OR REPLACE VIEW vw_product_quantity_sold AS
SELECT
    Product,
    SUM(Quantity) AS total_quantity_sold

FROM online_store_orders

WHERE Product IS NOT NULL

GROUP BY Product;

SELECT *
FROM vw_product_quantity_sold
ORDER BY total_quantity_sold DESC;


-- QUESTION 14: WHICH PRODUCT GENERATES THE MOST REVENUE
-- IN EACH YEAR?
-- Business objective: Identify the leading product annually.


CREATE OR REPLACE VIEW vw_top_product_each_year AS

WITH yearly_product_sales AS (
    SELECT
        YEAR(Date) AS order_year,
        Product,
        ROUND(SUM(TotalPrice), 2) AS total_revenue

    FROM online_store_orders

    WHERE Date IS NOT NULL
      AND Product IS NOT NULL

    GROUP BY
        YEAR(Date),
        Product
),

ranked_products AS (
    SELECT
        order_year,
        Product,
        total_revenue,

        RANK() OVER (
            PARTITION BY order_year
            ORDER BY total_revenue DESC
        ) AS product_rank

    FROM yearly_product_sales
)

SELECT
    order_year,
    Product,
    total_revenue,
    product_rank

FROM ranked_products

WHERE product_rank = 1;

SELECT *
FROM vw_top_product_each_year
ORDER BY order_year;


-- QUESTION 15: HOW DOES PRODUCT REVENUE CHANGE MONTHLY?
-- Business objective: Compare monthly revenue contribution
-- across different products.

CREATE OR REPLACE VIEW vw_monthly_product_revenue AS

SELECT
    YEAR(Date) AS order_year,
    MONTH(Date) AS month_number,
    MONTHNAME(Date) AS month_name,

    CAST(
        DATE_FORMAT(Date, '%Y-%m-01') AS DATE
    ) AS month_start,

    Product,

    ROUND(SUM(TotalPrice), 2) AS monthly_revenue

FROM online_store_orders

WHERE Date IS NOT NULL
  AND Product IS NOT NULL

GROUP BY
    YEAR(Date),
    MONTH(Date),
    MONTHNAME(Date),
    CAST(DATE_FORMAT(Date, '%Y-%m-01') AS DATE),
    Product;

SELECT *
FROM vw_monthly_product_revenue
ORDER BY
    order_year,
    month_number,
    Product;


USE online_store_analysis;

-- QUESTION 16: WHO ARE THE TOP 10 CUSTOMERS BY SPENDING?
-- Business objective: Identify the highest-value customers.

CREATE OR REPLACE VIEW vw_top_customers_by_spending AS

WITH customer_spending AS (
    SELECT
        CustomerID,

        ROUND(SUM(TotalPrice), 2) AS total_spending

    FROM online_store_orders

    WHERE CustomerID IS NOT NULL

    GROUP BY CustomerID
)

SELECT
    CustomerID,
    total_spending,

    RANK() OVER (
        ORDER BY total_spending DESC
    ) AS spending_rank

FROM customer_spending;

SELECT *
FROM vw_top_customers_by_spending
WHERE spending_rank <= 10
ORDER BY spending_rank;


-- QUESTION 17: HOW MANY REPEAT CUSTOMERS DOES THE STORE HAVE?
-- Business objective: Count customers who placed more than
-- one distinct order.


CREATE OR REPLACE VIEW vw_repeat_customers AS

SELECT
    COUNT(*) AS repeat_customers

FROM (
    SELECT
        CustomerID,
        COUNT(DISTINCT OrderID) AS total_orders

    FROM online_store_orders

    WHERE CustomerID IS NOT NULL
      AND OrderID IS NOT NULL

    GROUP BY CustomerID

    HAVING COUNT(DISTINCT OrderID) > 1

) AS customer_orders;

SELECT *
FROM vw_repeat_customers;


-- QUESTION 18: WHAT IS THE AVERAGE SPENDING PER CUSTOMER?
-- Business objective: Calculate average customer lifetime
-- spending across the dataset.


CREATE OR REPLACE VIEW vw_average_customer_spending AS

SELECT
    ROUND(AVG(total_spending), 2) AS average_customer_spending

FROM (
    SELECT
        CustomerID,

        SUM(TotalPrice) AS total_spending

    FROM online_store_orders

    WHERE CustomerID IS NOT NULL

    GROUP BY CustomerID

) AS customer_summary;

SELECT *
FROM vw_average_customer_spending;


-- QUESTION 19: WHICH CUSTOMERS PLACE THE MOST ORDERS?
-- Business objective: Identify customers with the highest
-- purchase frequency.

CREATE OR REPLACE VIEW vw_customer_order_frequency AS

SELECT
    CustomerID,

    COUNT(DISTINCT OrderID) AS total_orders

FROM online_store_orders

WHERE CustomerID IS NOT NULL
  AND OrderID IS NOT NULL

GROUP BY CustomerID;

SELECT *
FROM vw_customer_order_frequency
ORDER BY total_orders DESC, CustomerID
LIMIT 10;


-- QUESTION 20: WHAT IS EACH CUSTOMER'S CONTRIBUTION
-- TO TOTAL STORE REVENUE?
-- Business objective: Understand how much each customer
-- contributes to overall revenue.


CREATE OR REPLACE VIEW vw_customer_revenue_contribution AS

WITH customer_revenue AS (
    SELECT
        CustomerID,

        SUM(TotalPrice) AS total_spending

    FROM online_store_orders

    WHERE CustomerID IS NOT NULL

    GROUP BY CustomerID
)

SELECT
    CustomerID,

    ROUND(total_spending, 2) AS total_spending,

    ROUND(
        total_spending /
        NULLIF(SUM(total_spending) OVER (), 0) * 100,
        2
    ) AS revenue_contribution_percentage

FROM customer_revenue;

SELECT *
FROM vw_customer_revenue_contribution
ORDER BY total_spending DESC;


USE online_store_analysis;

-- QUESTION 21: WHAT IS THE DISTRIBUTION OF ORDER STATUSES?
-- Business objective: Understand how many orders are delivered,
-- pending, cancelled, or in other statuses.

CREATE OR REPLACE VIEW vw_order_status_distribution AS

SELECT
    OrderStatus,

    COUNT(DISTINCT OrderID) AS total_orders

FROM online_store_orders

WHERE OrderStatus IS NOT NULL

GROUP BY OrderStatus;

SELECT *
FROM vw_order_status_distribution
ORDER BY total_orders DESC;


-- QUESTION 22: WHAT IS THE ORDER CANCELLATION RATE?
-- Business objective: Measure the percentage of orders cancelled.


CREATE OR REPLACE VIEW vw_cancellation_rate AS

WITH order_summary AS (

    SELECT
        OrderID,

        MAX(LOWER(TRIM(OrderStatus))) AS order_status

    FROM online_store_orders

    WHERE OrderID IS NOT NULL

    GROUP BY OrderID
)

SELECT
    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN order_status IN ('cancelled', 'canceled')
            THEN 1
            ELSE 0
        END
    ) AS cancelled_orders,

    ROUND(
        SUM(
            CASE
                WHEN order_status IN ('cancelled', 'canceled')
                THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS cancellation_rate_percentage

FROM order_summary;

SELECT *
FROM vw_cancellation_rate;


-- QUESTION 23: WHICH PAYMENT METHODS ARE MOST POPULAR?
-- Business objective: Compare customer payment preferences.

CREATE OR REPLACE VIEW vw_payment_method_popularity AS

SELECT
    PaymentMethod,

    COUNT(DISTINCT OrderID) AS total_orders

FROM online_store_orders

WHERE PaymentMethod IS NOT NULL
  AND OrderID IS NOT NULL

GROUP BY PaymentMethod;

SELECT *
FROM vw_payment_method_popularity
ORDER BY total_orders DESC;


-- QUESTION 24: WHICH PAYMENT METHOD GENERATES
-- THE HIGHEST REVENUE?
-- Business objective: Compare revenue across payment methods.

CREATE OR REPLACE VIEW vw_revenue_by_payment_method AS

SELECT
    PaymentMethod,

    ROUND(SUM(TotalPrice), 2) AS total_revenue

FROM online_store_orders

WHERE PaymentMethod IS NOT NULL

GROUP BY PaymentMethod;

SELECT *
FROM vw_revenue_by_payment_method
ORDER BY total_revenue DESC;


-- QUESTION 25: WHAT IS THE AVERAGE ORDER VALUE
-- FOR EACH PAYMENT METHOD?
-- Business objective: Compare average order value by payment type.


CREATE OR REPLACE VIEW vw_average_order_value_by_payment AS

WITH order_summary AS (

    SELECT
        OrderID,
        PaymentMethod,

        SUM(TotalPrice) AS order_revenue

    FROM online_store_orders

    WHERE OrderID IS NOT NULL
      AND PaymentMethod IS NOT NULL

    GROUP BY
        OrderID,
        PaymentMethod
)

SELECT
    PaymentMethod,

    COUNT(*) AS total_orders,

    ROUND(AVG(order_revenue), 2) AS average_order_value

FROM order_summary

GROUP BY PaymentMethod;

SELECT *
FROM vw_average_order_value_by_payment
ORDER BY average_order_value DESC;


USE online_store_analysis;

-- QUESTION 26: Which referral source brings the most orders?

CREATE OR REPLACE VIEW vw_orders_by_referral_source AS
SELECT
    ReferralSource,
    COUNT(DISTINCT OrderID) AS total_orders
FROM online_store_orders
WHERE ReferralSource IS NOT NULL
  AND TRIM(ReferralSource) <> ''
GROUP BY ReferralSource;

SELECT *
FROM vw_orders_by_referral_source
ORDER BY total_orders DESC;


-- QUESTION 27: Which referral source generates the most revenue?

CREATE OR REPLACE VIEW vw_revenue_by_referral_source AS
SELECT
    ReferralSource,
    ROUND(SUM(TotalPrice), 2) AS total_revenue
FROM online_store_orders
WHERE ReferralSource IS NOT NULL
  AND TRIM(ReferralSource) <> ''
GROUP BY ReferralSource;

SELECT *
FROM vw_revenue_by_referral_source
ORDER BY total_revenue DESC;


-- QUESTION 28: Which referral source brings the most customers?

CREATE OR REPLACE VIEW vw_customers_by_referral_source AS
SELECT
    ReferralSource,
    COUNT(DISTINCT CustomerID) AS total_customers
FROM online_store_orders
WHERE ReferralSource IS NOT NULL
  AND TRIM(ReferralSource) <> ''
GROUP BY ReferralSource;

SELECT *
FROM vw_customers_by_referral_source
ORDER BY total_customers DESC;


-- QUESTION 29: How many orders use coupons?

CREATE OR REPLACE VIEW vw_coupon_usage AS
WITH order_coupon_status AS (
    SELECT
        OrderID,

        MAX(
            CASE
                WHEN CouponCode IS NOT NULL
                 AND TRIM(CouponCode) <> ''
                 AND LOWER(TRIM(CouponCode)) <> 'no coupon'
                THEN 1
                ELSE 0
            END
        ) AS used_coupon

    FROM online_store_orders
    GROUP BY OrderID
)

SELECT
    COUNT(*) AS total_orders,

    SUM(used_coupon) AS coupon_orders,

    SUM(CASE WHEN used_coupon = 0 THEN 1 ELSE 0 END)
        AS no_coupon_orders,

    ROUND(
        SUM(used_coupon) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS coupon_usage_percentage

FROM order_coupon_status;

SELECT *
FROM vw_coupon_usage;


-- QUESTION 30: Which coupon codes generate the most revenue?

CREATE OR REPLACE VIEW vw_revenue_by_coupon_code AS
SELECT
    CASE
        WHEN CouponCode IS NULL
          OR TRIM(CouponCode) = ''
          OR LOWER(TRIM(CouponCode)) = 'no coupon'
        THEN 'No Coupon'
        ELSE TRIM(CouponCode)
    END AS coupon_code,

    COUNT(DISTINCT OrderID) AS total_orders,

    ROUND(SUM(TotalPrice), 2) AS total_revenue

FROM online_store_orders

GROUP BY
    CASE
        WHEN CouponCode IS NULL
          OR TRIM(CouponCode) = ''
          OR LOWER(TRIM(CouponCode)) = 'no coupon'
        THEN 'No Coupon'
        ELSE TRIM(CouponCode)
    END;

SELECT *
FROM vw_revenue_by_coupon_code
ORDER BY total_revenue DESC;


USE online_store_analysis;


-- QUESTION 31: How much revenue comes from delivered orders?

CREATE OR REPLACE VIEW vw_delivered_revenue AS
SELECT
    ROUND(SUM(TotalPrice), 2) AS delivered_revenue
FROM online_store_orders
WHERE LOWER(TRIM(OrderStatus)) = 'delivered';

SELECT *
FROM vw_delivered_revenue;


-- QUESTION 32: How much revenue comes from cancelled orders?

CREATE OR REPLACE VIEW vw_cancelled_revenue AS
SELECT
    ROUND(SUM(TotalPrice), 2) AS cancelled_revenue
FROM online_store_orders
WHERE LOWER(TRIM(OrderStatus)) IN ('cancelled', 'canceled');

SELECT *
FROM vw_cancelled_revenue;


-- QUESTION 33: What is the revenue generated by each order status?

CREATE OR REPLACE VIEW vw_revenue_by_order_status AS
SELECT
    TRIM(OrderStatus) AS order_status,

    COUNT(DISTINCT OrderID) AS total_orders,

    ROUND(SUM(TotalPrice), 2) AS total_revenue

FROM online_store_orders
WHERE OrderStatus IS NOT NULL
  AND TRIM(OrderStatus) <> ''
GROUP BY TRIM(OrderStatus);

SELECT *
FROM vw_revenue_by_order_status
ORDER BY total_revenue DESC;


-- QUESTION 34: What percentage of orders belong to each status?

CREATE OR REPLACE VIEW vw_order_status_percentage AS
WITH status_summary AS (
    SELECT
        LOWER(TRIM(OrderStatus)) AS order_status,

        COUNT(DISTINCT OrderID) AS total_orders

    FROM online_store_orders
    WHERE OrderStatus IS NOT NULL
      AND TRIM(OrderStatus) <> ''
    GROUP BY LOWER(TRIM(OrderStatus))
)

SELECT
    order_status,
    total_orders,

    ROUND(
        total_orders * 100.0 / NULLIF(SUM(total_orders) OVER (), 0),
        2
    ) AS order_percentage

FROM status_summary;

SELECT *
FROM vw_order_status_percentage
ORDER BY order_percentage DESC;


-- QUESTION 35: How many orders are delivered, cancelled,
-- and not yet completed?

CREATE OR REPLACE VIEW vw_order_completion_summary AS
WITH order_summary AS (
    SELECT
        OrderID,

        MAX(LOWER(TRIM(OrderStatus))) AS order_status

    FROM online_store_orders
    GROUP BY OrderID
)

SELECT
    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN order_status = 'delivered' THEN 1
            ELSE 0
        END
    ) AS delivered_orders,

    SUM(
        CASE
            WHEN order_status IN ('cancelled', 'canceled') THEN 1
            ELSE 0
        END
    ) AS cancelled_orders,

    SUM(
        CASE
            WHEN order_status NOT IN (
                'delivered', 'cancelled', 'canceled'
            )
            OR order_status IS NULL
            THEN 1
            ELSE 0
        END
    ) AS other_status_orders

FROM order_summary;

SELECT *
FROM vw_order_completion_summary;
