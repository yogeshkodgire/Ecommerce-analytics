-- Q1. the total amount spent and the country for the Pending delivery status for each country.

SELECT
   c.country,
    SUM(o.amount) AS Total_Amount_Spent
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
JOIN Shippings s ON o.customer_id = s.customer
WHERE s.status = 'Pending'  -- Filter for pending delivery status
GROUP BY c.country
ORDER BY Total_Amount_Spent DESC; -- Sorting in descending order

-- ###########################################################################################################################	

-- Q2. the total number of transactions, total quantity sold, and total amount spent for each customer, along with the product details.

SELECT
    c.customer_id, c.first_name, c.last_name,
    COUNT(o.order_id) AS Total_Transactions,  -- Total number of transactions for the customer
    COUNT(o.order_id) AS Total_Quantity_Sold,  -- Counting orders as total quantity (each order = one quantity)
    SUM(o.amount) AS Total_Amount_Spent,  -- Total amount spent by the customer
    GROUP_CONCAT(DISTINCT o.item) AS Product_Details  -- List of distinct products purchased
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id  -- Join to get orders placed by the customer
LEFT JOIN Shippings s ON c.customer_id = s.customer  -- Join shipping table based on customer_id
WHERE s.status = 'Pending'  -- Filter by pending shipping status
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY Total_Amount_Spent DESC;

-- ###########################################################################################################################	

-- Q3. the maximum product purchased for each country.
-- This Query will return only one product per country (even if multiple products have the same count

SELECT country, product AS most_purchased_product, total_transactions
FROM (
    SELECT 
        c.country,
        o.item AS product,
        COUNT(o.order_id) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY c.country ORDER BY COUNT(o.order_id) DESC) AS rank
    FROM Orders o
    JOIN Customers c ON o.customer_id = c.customer_id
    GROUP BY c.country, o.item
) ranked
WHERE rank = 1;


--If you want to Keeps multiple products if they have the same max transaction count in a country.

SELECT country, product AS most_purchased_product, total_transactions
FROM (
    SELECT 
        c.country,
        o.item AS product,
        COUNT(o.order_id) AS total_transactions,
        DENSE_RANK() OVER (PARTITION BY c.country ORDER BY COUNT(o.order_id) DESC) AS rank
    FROM Orders o
    JOIN Customers c ON o.customer_id = c.customer_id
    GROUP BY c.country, o.item
) ranked
WHERE rank = 1;

-- ###########################################################################################################################	

-- Q4. the most purchased product based on the age category less than 30 and above 30.

WITH AgeCategory AS ( -- categorizes customers into two groups based on their age: "Under 30" and "30 and Above"
    SELECT
        c.customer_id, c.age,
        CASE
            WHEN c.age < 30 THEN 'Under 30'
            ELSE '30 and Above'
        END AS age_category
    FROM
        Customers c
),
-- calculate the total number of transactions (or total sales) for each product within each age category.
ProductSales AS (
    SELECT
        a.age_category,
        o.item,
        COUNT(o.order_id) AS total_transactions
    FROM
        Orders o
    JOIN
        AgeCategory a ON o.customer_id = a.customer_id
    GROUP BY
        a.age_category, o.item
),
-- rank the products within each age category based on the total number of transactions in descending order
RankedProducts AS (
    SELECT
        age_category, item AS product, total_transactions,
        ROW_NUMBER() OVER (PARTITION BY age_category ORDER BY total_transactions DESC) AS rn
    FROM
        ProductSales
)
SELECT
    age_category,
    product AS most_purchased_product,
    total_transactions
FROM
    RankedProducts
WHERE
    rn = 1; -- filter out the top-ranked product for each age category
	
	
-- ###########################################################################################################################	
	
-- Q5. the country that had minimum transactions and sales amount.

WITH CountrySales AS (
    SELECT
        c.country, COUNT(o.order_id) AS total_transactions,
        SUM(o.amount) AS total_sales
    FROM
        Orders o
    JOIN
        Customers c ON o.customer_id = c.customer_id
    GROUP BY
        c.country
)
SELECT
    country, total_transactions, total_sales
FROM
    CountrySales
ORDER BY
    total_transactions ASC, total_sales ASC
LIMIT 2; -- One can change the limit value ans see number of countries with minimum transaction
