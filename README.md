---

# **Amazon USA Sales Analysis Project**

### **Difficulty Level: Intermediate**

---

## **Project Overview**

I have worked on analyzing a dataset of over 20,000 sales records from an Amazon-like e-commerce platform. This project involves extensive querying of customer behavior, product performance, and sales trends using PostgreSQL. Through this project, I have tackled various SQL problems, including revenue analysis, customer segmentation, and inventory management.

The project also focuses on data cleaning, handling null values, and solving real-world business problems using structured queries.

An ERD diagram is included to visually represent the database schema and relationships between tables.

---

![ERD Scratch](https://github.com/Kuvam7/Amazon_sql_project/blob/main/Amazon%20ERD.png)

## **Database Setup & Design**

### **Schema Structure**

```sql
-- CREATING CATEGORY TABLE
CREATE TABLE category
(
category_id INT PRIMARY KEY,
category_name VARCHAR(20)
);

-- CREATING CUSTOMER TABLE
CREATE TABLE customers
(
customer_id INT PRIMARY KEY,
first_name VARCHAR(20),
last_name VARCHAR(30),
state VARCHAR(50),
address VARCHAR(50) DEFAULT ('xxxx')
);

-- CREATING SELLERS TABLE
CREATE TABLE sellers
(
seller_id INT PRIMARY KEY,
seller_name VARCHAR(50),
origin VARCHAR(10)
);

-- CREATING PRODUCTS TABLE
CREATE TABLE products
(
product_id INT PRIMARY KEY,
product_name VARCHAR(100),
price NUMERIC, -- USE NUMERIC INSTEAD OF FLOAT FOR FINANCIAL DATA WHERE ACCURACY IS CRUCIAL
cogs NUMERIC,
category_id INT, -- FK
CONSTRAINT categoryid_fk_in_product FOREIGN KEY(category_id) REFERENCES category(category_id)
);

-- CREATING ORDERS TABLE
CREATE TABLE orders
(
order_id INT PRIMARY KEY,
order_date DATE,
customer_id INT, -- FK
seller_id INT,  -- FK
order_status VARCHAR(20),
CONSTRAINT customerid_fk_in_orders FOREIGN KEY(customer_id) REFERENCES customers(customer_id),
CONSTRAINT sellerid_fk_in_orders FOREIGN KEY(seller_id) REFERENCES sellers(seller_id)
);

-- CREATING ORDER_ITEMS TABLE
CREATE TABLE order_items
(
order_item_id INT PRIMARY KEY,
order_id INT, -- FK
product_id INT, -- FK
quantity INT,
price_per_unit NUMERIC,
CONSTRAINT orderid_fk_in_orderitems FOREIGN KEY(order_id) REFERENCES orders(order_id) ,
CONSTRAINT productid_in_orderitems FOREIGN KEY(product_id) REFERENCES products(product_id)
);

-- CREATING SHIPPING TABLE
CREATE TABLE shipping
(
shipping_id INT PRIMARY KEY,
order_id INT, -- FK
shipping_date DATE,
return_date DATE ,
shipping_providers VARCHAR(20),
delivery_status VARCHAR(20),
CONSTRAINT orderid_fk_in_shipping FOREIGN KEY(order_id) REFERENCES orders(order_id)
);

-- CREATING PAYMENTS TABLE
CREATE TABLE payments
(
payment_id INT PRIMARY KEY,
order_id INT, -- FK
payment_date DATE,
payment_status VARCHAR(20),
CONSTRAINT orderid_fk_in_payments FOREIGN KEY(order_id) REFERENCES orders(order_id)
);

-- CREATING INVENTORY TABLE
CREATE TABLE inventory
(
inventory_id INT PRIMARY KEY,
product_id INT, -- FK
stock_remaining INT,
warehouse_id INT,
last_stock_date DATE,
CONSTRAINT product_id_fk_in_inventory FOREIGN KEY(product_id) REFERENCES products(product_id)
);
```

---

## **Task: Data Cleaning**

I cleaned the dataset by:
- **Removing duplicates**: Duplicates in the customer and order tables were identified and removed.
- **Handling missing values**: Null values in critical fields (e.g., customer address, payment status) were either filled with default values or handled using appropriate methods.

---

## **Handling Null Values**

Null values were handled based on their context:
- **Customer addresses**: Missing addresses were assigned default placeholder values.
- **Payment statuses**: Orders with null payment statuses were categorized as “Pending.”
- **Shipping information**: Null return dates were left as is, as not all shipments are returned.

---

## **Objective**

The primary objective of this project is to showcase SQL proficiency through complex queries that address real-world e-commerce business challenges. The analysis covers various aspects of e-commerce operations, including:
- Customer behavior
- Sales trends
- Inventory management
- Payment and shipping analysis
- Forecasting and product performance
  

## **Identifying Business Problems**

Key business problems identified:
1. Low product availability due to inconsistent restocking.
2. High return rates for specific product categories.
3. Significant delays in shipments and inconsistencies in delivery times.
4. High customer acquisition costs with a low customer retention rate.

---

## **Solving Business Problems**

### Solutions Implemented:
1. Top Selling Products
Query the top 10 products by total sales value.
Challenge: Include product name, total quantity sold, and total sales value.

```sql
-- CREATING NEW COLUMN FOR SALE AMOUNT
ALTER TABLE order_items
ADD COLUMN total_sale NUMERIC;

-- SETTING SALE COLUMN = (QUANTITY * PRICE)
UPDATE order_items
SET total_sale = quantity*price_per_unit;

-- CHECK
SELECT *
FROM order_items;

-- SOLUTION QUERY
SELECT
	p.product_id,
	p.product_name,
	SUM(o.quantity) as total_quantity_sold,
	SUM(o.total_sale) as total_sale_amount
FROM order_items o
JOIN products p
	ON p.product_id = o.product_id
GROUP BY
	p.product_name,
	p.product_id
ORDER BY
	total_sale_amount DESC
LIMIT 10;
```

2. Revenue by Category
Calculate total revenue generated by each product category.
Challenge: Include the percentage contribution of each category to total revenue.

```sql
SELECT
	c.category_id,
	c.category_name,
	SUM(oi.total_sale) as category_sale,
	ROUND(SUM(oi.total_sale)/(SELECT SUM(total_sale) FROM order_items) * 100,2) as total_revenue_perc_contribution
FROM order_items oi
JOIN products p
	ON p.product_id = oi.product_id
LEFT JOIN category c
	ON c.category_id = p.category_id
GROUP BY
	c.category_id,
	c.category_name
ORDER BY
	category_sale DESC;
```

3. Average Order Value (AOV)
Compute the average order value for each customer.
Challenge: Include only customers with more than 5 orders.

```sql
SELECT
	c.customer_id,
	CONCAT(c.first_name,' ',c.last_name) as Customer_name,
	ROUND(AVG(oi.total_sale),2) as Avg_order_value,
	COUNT(oi.order_id) as orders_per_customer
FROM
	order_items oi
JOIN
	orders o
ON
	o.order_id = oi.order_id
JOIN
	customers c
ON
	c.customer_id = o.customer_id
GROUP BY
	c.customer_id,
	Customer_name
HAVING
	COUNT(oi.order_id) > 5
ORDER BY
	3 DESC;
```

4. Monthly Sales Trend
Query monthly total sales over the past year.
Challenge: Display the sales trend, grouping by month, return current_month sale, last month sale!

```sql
SELECT
	year,
	month,
	monthly_sale as current_month_sale,
	LAG(monthly_sale,1) OVER (ORDER BY year,month) as prev_month_sale
FROM
(SELECT
	EXTRACT(MONTH FROM o.order_date) as Month,
	EXTRACT(YEAR FROM o.order_date) as Year,
	SUM(oi.total_sale) as Monthly_Sale
FROM
	orders as o
JOIN
	order_items as oi
ON
	oi.order_id = o.order_id
WHERE
	o.order_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY
	Year, Month
ORDER BY
	Year, Month) t;
```


5. Customers with No Purchases
Find customers who have registered but never placed an order.
Challenge: List customer details and the time since their registration.

```sql
-- Approach 1 (WHERE NOT IN)
SELECT 
	* 
FROM customers c
WHERE customer_id NOT IN (SELECT DISTINCT customer_id from orders) 
```
```sql
-- Approach 2 (LEFT JOIN)
SELECT *
FROM CUSTOMERS C
LEFT JOIN ORDERS O
ON O.CUSTOMER_ID = C.CUSTOMER_ID
WHERE O.CUSTOMER_ID IS NULL;
```

6. Least-Selling Categories by State
Identify the least-selling product category for each state.
Challenge: Include the total sales for that category within each state.

```sql
SELECT
	STATE,
	CATEGORY,
	TOTAL_SALE
FROM 
(SELECT
	*,
	RANK() OVER (PARTITION BY STATE ORDER BY TOTAL_SALE) R
FROM
(SELECT 
	SUM(TOTAL_SALE) AS TOTAL_SALE, 
	C.CATEGORY_NAME AS CATEGORY,
	CU.STATE AS STATE
FROM 
	CATEGORY C
JOIN 
	PRODUCTS P ON C.CATEGORY_ID = P.CATEGORY_ID
JOIN 
	ORDER_ITEMS OI ON OI.PRODUCT_ID = P.PRODUCT_ID
JOIN 
	ORDERS O ON O.ORDER_ID = OI.ORDER_ID
JOIN 
	CUSTOMERS CU ON CU.CUSTOMER_ID = O.CUSTOMER_ID
GROUP BY 
	CU.STATE,
	C.CATEGORY_NAME
ORDER BY STATE) T ) G
WHERE R = 1;
```


7. Customer Lifetime Value (CLTV)
Calculate the total value of orders placed by each customer over their lifetime.
Challenge: Rank customers based on their CLTV.

```sql
SELECT
	*,
	DENSE_RANK() OVER (ORDER BY CLTV DESC)
FROM(SELECT 
	C.CUSTOMER_ID,
	CONCAT(C.FIRST_NAME, ' ', C.LAST_NAME) AS FULL_NAME,
	COUNT(O.ORDER_ID) AS TOTAL_NO_OF_ORDERS,
	SUM(TOTAL_SALE) AS CLTV
FROM CUSTOMERS C
JOIN ORDERS O
ON O.CUSTOMER_ID=C.CUSTOMER_ID
JOIN ORDER_ITEMS OI
ON OI.ORDER_ID = O.ORDER_ID
GROUP BY 
	C.CUSTOMER_ID,
	FULL_NAME) T;
```


8. Inventory Stock Alerts
Query products with stock levels below a certain threshold (e.g., less than 10 units).
Challenge: Include last restock date and warehouse information.

```sql
SELECT 
	I.STOCK_REMAINING,
	I.LAST_STOCK_DATE,
	PRODUCT_NAME,
	I.WAREHOUSE_ID
FROM INVENTORY I
JOIN PRODUCTS P
ON I.PRODUCT_ID = P.PRODUCT_ID
WHERE I.STOCK_REMAINING < 10;
```

9. Shipping Delays
Identify orders where the shipping date is later than 3 days after the order date.
Challenge: Include customer, order details, and delivery provider.

```sql
SELECT
	O.ORDER_ID,
	O.ORDER_DATE,
	S.SHIPPING_DATE,
	(S.SHIPPING_DATE - O.ORDER_DATE) AS DAYS_BEFORE_SHIPPING,
	S.SHIPPING_PROVIDERS AS DELIVERY_PROVIDER,
	CONCAT(C.FIRST_NAME,' ',C.LAST_NAME) AS CUSTOMER,
	C.STATE,
	P.PRODUCT_NAME,
	OI.TOTAL_SALE
FROM SHIPPING S
JOIN ORDERS O
ON O.ORDER_ID = S.ORDER_ID
JOIN CUSTOMERS C
ON C.CUSTOMER_ID = O.CUSTOMER_ID
JOIN ORDER_ITEMS OI
ON OI.ORDER_ID = O.ORDER_ID
JOIN PRODUCTS P
ON P.PRODUCT_ID = OI.PRODUCT_ID
WHERE ORDER_DATE < SHIPPING_DATE - INTERVAL '3 DAYS';
```

10. Payment Success Rate 
Calculate the percentage of successful payments across all orders.
Challenge: Include breakdowns by payment status (e.g., failed, pending).

```sql
SELECT
    PAYMENT_STATUS,
    COUNT(ORDER_ID) AS NO_OF_ORDERS,
    ROUND (COUNT(ORDER_ID) * 100.0 / (SELECT COUNT(PAYMENT_STATUS) FROM PAYMENTS),2)  AS PERCENTAGE
FROM PAYMENTS P
GROUP BY
    PAYMENT_STATUS;
```

11. Top Performing Sellers
Find the top 5 sellers based on total sales value.
Challenge: Include both successful and failed orders, and display their percentage of successful orders.

```sql
WITH top_sellers
AS
(SELECT 
	s.seller_id,
	s.seller_name,
	SUM(oi.total_sale) as total_sale
FROM orders as o
JOIN
sellers as s
ON o.seller_id = s.seller_id
JOIN 
order_items as oi
ON oi.order_id = o.order_id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 5
),

sellers_reports
AS
(SELECT 
	o.seller_id,
	ts.seller_name,
	o.order_status,
	COUNT(*) as total_orders
FROM orders as o
JOIN 
top_sellers as ts
ON ts.seller_id = o.seller_id
WHERE 
	o.order_status NOT IN ('Inprogress', 'Returned')
	
GROUP BY 1, 2, 3
)
SELECT 
	seller_id,
	seller_name,
	SUM(CASE WHEN order_status = 'Completed' THEN total_orders ELSE 0 END) as Completed_orders,
	SUM(CASE WHEN order_status = 'Cancelled' THEN total_orders ELSE 0 END) as Cancelled_orders,
	SUM(total_orders) as total_orders,
	SUM(CASE WHEN order_status = 'Completed' THEN total_orders ELSE 0 END)::numeric/
	SUM(total_orders)::numeric * 100 as successful_orders_percentage
	
FROM sellers_reports
GROUP BY 1, 2
```


12. Product Profit Margin
Calculate the profit margin for each product (difference between price and cost of goods sold).
Challenge: Rank products by their profit margin, showing highest to lowest.
*/


```sql
SELECT 
	product_id,
	product_name,
	profit_margin,
	DENSE_RANK() OVER( ORDER BY profit_margin DESC) as product_ranking
FROM
(SELECT 
	p.product_id,
	p.product_name,
	-- SUM(total_sale - (p.cogs * oi.quantity)) as profit,
	SUM(total_sale - (p.cogs * oi.quantity))/sum(total_sale) * 100 as profit_margin
FROM order_items as oi
JOIN 
products as p
ON oi.product_id = p.product_id
GROUP BY 1, 2
) as t1
```

13. Most Returned Products
Query the top 10 products by the number of returns.
Challenge: Display the return rate as a percentage of total units sold for each product.

```sql
SELECT
	*,
	ROUND(NO_RETURNS::NUMERIC/TOTAL_ORDERS::NUMERIC*100,2) AS RETURN_PERCENTAGE
FROM
(SELECT
    P.PRODUCT_ID,
    P.PRODUCT_NAME,
    SUM(CASE WHEN O.ORDER_STATUS = 'Returned' THEN 1 ELSE 0 END) AS NO_RETURNS,
    COUNT(O.ORDER_ID) AS TOTAL_ORDERS
FROM PRODUCTS P
JOIN ORDER_ITEMS OI
    ON OI.PRODUCT_ID = P.PRODUCT_ID
JOIN ORDERS O
    ON O.ORDER_ID = OI.ORDER_ID
GROUP BY P.PRODUCT_ID, P.PRODUCT_NAME
ORDER BY NO_RETURNS DESC) T
LIMIT 10;
```

14. Inactive Sellers
Identify sellers who haven’t made any sales in the last 6 months. Include sellers who've never made a sale
Challenge: Show the last sale date and total sales from those sellers.

```sql
SELECT
	S.SELLER_ID,
	S.SELLER_NAME,
	MAX(O.ORDER_DATE) AS LAST_ORDER_DATE,
	COUNT(O.ORDER_ID) AS NO_OF_ORDER,
	SUM(OI.TOTAL_SALE) AS SELLER_TOTAL_SALE
FROM orders O
JOIN ORDER_ITEMS OI
ON OI.ORDER_ID = O.ORDER_ID
RIGHT JOIN SELLERS S
ON O.SELLER_ID = S.SELLER_ID
GROUP BY S.SELLER_ID, S.SELLER_NAME
HAVING MAX(O.ORDER_DATE) < CURRENT_DATE - INTERVAL '6 months' OR COUNT(O.ORDER_ID) = 0;
```


15. CATEGORISE customers into returning or occasional
if the customer has done more than 5 returns categorize them as returning otherwise occasional
Challenge: List customers id, name, total orders, total returns

```sql
WITH t AS (
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS full_name,
        SUM(CASE WHEN O.ORDER_STATUS = 'Returned' THEN 1 ELSE 0 END) AS no_of_returns,
		COUNT(O.ORDER_ID) AS TOTAL_ORDERS
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
	ORDER BY TOTAL_ORDERS DESC
)
SELECT 
	*,
	CASE WHEN NO_OF_RETURNS > 5 THEN 'Returning' ELSE 'Occasional' END AS CATEGORY
FROM T
```


16. Top 5 Customers by Orders in Each State
Identify the top 5 customers with the highest number of orders for each state.
Challenge: Include the number of orders and total sales for each customer.
```sql
SELECT *
FROM
(SELECT 
	*,
	RANK() OVER (Partition by state ORDER by total_sale DESC)
FROM
(SELECT
	c.state,
	CONCAT(c.first_name, ' ', c.last_name) AS full_name,
	COUNT(*) as no_of_orders,
	SUM(oi.total_sale) as total_sale
FROM customers c
JOIN orders o
ON o.customer_id = c.customer_id
JOIN order_items oi
ON oi.order_id = o.order_id
GROUP BY
	c.state,full_name
ORDER BY 
	4,1 DESC) t) o
WHERE rank <= 5;
```

17. Revenue by Shipping Provider
Calculate the total revenue handled by each shipping provider.
Challenge: Include the total number of orders handled and the average delivery time for each provider.

```sql
SELECT
	S.SHIPPING_PROVIDERS,
	COUNT(O.ORDER_ID) AS NO_OF_ORDERS,
	SUM(TOTAL_SALE) AS TOTAL_REVENUE,
	ROUND(AVG(S.SHIPPING_DATE - O.ORDER_DATE),2) AS AVG_DELIVERY_DAYS
FROM SHIPPING S
JOIN ORDERS O
ON O.ORDER_ID = S.ORDER_ID
JOIN ORDER_ITEMS OI
ON OI.ORDER_ID = O.ORDER_ID
GROUP BY S.SHIPPING_PROVIDERS;
```

18. Top 10 product with highest decreasing revenue ratio compare to last year(2022) and current_year(2023)
Challenge: Return product_id, product_name, category_name, 2022 revenue and 2023 revenue decrease ratio at end Round the result
Note: Decrease ratio = cr-ls/ls* 100 (cs = current_year ls=last_year)

```sql
SELECT
	product_id,
	product_name,
	category_name,
	y2022_revenue,
	y2023_revenue,
	decrease_ratio
FROM
(SELECT
	*,
	DENSE_RANK() OVER (PARTITION BY PRODUCT_NAME ORDER BY DECREASE_RATIO DESC)
FROM
(SELECT
	*,
	COALESCE((ROUND(((Y2022_REVENUE-Y2023_REVENUE)/Y2022_REVENUE)*100,2)),0) AS DECREASE_RATIO
FROM
(SELECT 
	*,
	LAG(Y2023_REVENUE) OVER (PARTITION BY PRODUCT_NAME ORDER BY YEAR_ORDER) AS Y2022_REVENUE
FROM
(SELECT
	P.PRODUCT_ID,
	P.PRODUCT_NAME,
	C.CATEGORY_NAME,
	EXTRACT(YEAR FROM O.ORDER_DATE) AS YEAR_ORDER,
	SUM(OI.TOTAL_SALE) AS Y2023_REVENUE
FROM PRODUCTS P
JOIN ORDER_ITEMS OI
ON OI.PRODUCT_ID = P.PRODUCT_ID
JOIN ORDERS O
ON O.ORDER_ID = OI.ORDER_ID
JOIN CATEGORY C
ON C.CATEGORY_ID = P.CATEGORY_ID
GROUP BY P.PRODUCT_ID,P.PRODUCT_NAME,C.CATEGORY_NAME, YEAR_ORDER
ORDER BY 1,2,3,4) T) S) G) B
WHERE DENSE_RANK = 1 AND YEAR_ORDER = 2023
ORDER BY DECREASE_RATIO DESC
LIMIT 10;
```


## **Learning Outcomes**

This project enabled me to:
- Design and implement a normalized database schema.
- Clean and preprocess real-world datasets for analysis.
- Use advanced SQL techniques, including window functions, subqueries, and joins.
- Conduct in-depth business analysis using SQL.
- Optimize query performance and handle large datasets efficiently.

---

## **Conclusion**

This advanced SQL project successfully demonstrates my ability to solve real-world e-commerce problems using structured queries. From improving customer retention to optimizing inventory and logistics, the project provides valuable insights into operational challenges and solutions.

By completing this project, I have gained a deeper understanding of how SQL can be used to tackle complex data problems and drive business decision-making.

---

### **Entity Relationship Diagram (ERD)**
![ERD](https://github.com/Kuvam7/Amazon_sql_project/blob/main/Updated%20ERD%20-%20Amazon.png)

---
