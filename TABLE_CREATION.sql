-- AMAZON ADVANCED SQL DATABASE PROJECT

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