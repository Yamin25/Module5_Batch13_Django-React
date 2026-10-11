-- ============================================================
-- MULTI-VENDOR SaaS E-COMMERCE DATABASE
-- Module: Database Design & SQL
-- ============================================================

-- ============================================================
-- PART B: DDL — TABLE CREATION
-- ============================================================

-- Creating SubscriptionPlan table (parent of Vendor)
CREATE TABLE SubscriptionPlan (
    plan_id      INT PRIMARY KEY AUTO_INCREMENT,
    plan_name    VARCHAR(100) NOT NULL,
    price        DECIMAL(10,2) NOT NULL,
    duration     INT NOT NULL,
    features     TEXT
);

-- Creating Vendor table with FK to SubscriptionPlan
CREATE TABLE Vendor (
    vendor_id         INT PRIMARY KEY AUTO_INCREMENT,
    business_name     VARCHAR(150) NOT NULL,
    contact_person    VARCHAR(100) NOT NULL,
    email             VARCHAR(150) NOT NULL UNIQUE,
    phone             VARCHAR(20),
    business_address  VARCHAR(255),
    plan_id           INT,
    CONSTRAINT fk_vendor_plan
        FOREIGN KEY (plan_id) REFERENCES SubscriptionPlan(plan_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- Creating Category table
CREATE TABLE Category (
    category_id   INT PRIMARY KEY AUTO_INCREMENT,
    name          VARCHAR(100) NOT NULL UNIQUE,
    description   TEXT
);

-- Creating Product table (FK to Vendor)
CREATE TABLE Product (
    product_id      INT PRIMARY KEY AUTO_INCREMENT,
    product_name    VARCHAR(150) NOT NULL,
    description     TEXT,
    price           DECIMAL(10,2) NOT NULL,
    stock_quantity  INT DEFAULT 0,
    status          ENUM('active','inactive') DEFAULT 'active',
    vendor_id       INT NOT NULL,
    CONSTRAINT fk_product_vendor
        FOREIGN KEY (vendor_id) REFERENCES Vendor(vendor_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Creating ProductCategory junction table (resolves M:N)
CREATE TABLE ProductCategory (
    product_id   INT NOT NULL,
    category_id  INT NOT NULL,
    PRIMARY KEY (product_id, category_id),
    CONSTRAINT fk_pc_product
        FOREIGN KEY (product_id) REFERENCES Product(product_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_pc_category
        FOREIGN KEY (category_id) REFERENCES Category(category_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Creating Customer table
CREATE TABLE Customer (
    customer_id  INT PRIMARY KEY AUTO_INCREMENT,
    name         VARCHAR(100) NOT NULL,
    email        VARCHAR(150) NOT NULL UNIQUE,
    phone        VARCHAR(20),
    address      VARCHAR(255)
);

-- Creating Orders table (FK to Customer)
CREATE TABLE Orders (
    order_id      INT PRIMARY KEY AUTO_INCREMENT,
    order_date    DATE NOT NULL,
    total_amount  DECIMAL(10,2) NOT NULL,
    order_status  VARCHAR(50) DEFAULT 'Pending',
    customer_id   INT NOT NULL,
    CONSTRAINT fk_order_customer
        FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
        ON DELETE CASCADE
);

-- Creating OrderItem table (FK to Orders and Product)
CREATE TABLE OrderItem (
    order_item_id  INT PRIMARY KEY AUTO_INCREMENT,
    order_id       INT NOT NULL,
    product_id     INT NOT NULL,
    quantity       INT NOT NULL,
    unit_price     DECIMAL(10,2) NOT NULL,
    subtotal       DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_oi_order
        FOREIGN KEY (order_id) REFERENCES Orders(order_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_oi_product
        FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

-- Creating Payment table (1:1 with Orders)
CREATE TABLE Payment (
    payment_id      INT PRIMARY KEY AUTO_INCREMENT,
    order_id        INT NOT NULL UNIQUE,
    method          ENUM('Card','Bkash','PayPal','Cash on Delivery') NOT NULL,
    amount          DECIMAL(10,2) NOT NULL,
    payment_date    DATE NOT NULL,
    payment_status  VARCHAR(50) DEFAULT 'Pending',
    CONSTRAINT fk_payment_order
        FOREIGN KEY (order_id) REFERENCES Orders(order_id)
        ON DELETE CASCADE
);

-- ============================================================
-- PART C: DML — INSERT / UPDATE / DELETE
-- ============================================================

-- Insert Basic subscription plan
INSERT INTO SubscriptionPlan (plan_name, price, duration, features)
VALUES ('Basic', 1500.00, 12, 'Up to 50 products, Email support');

-- Q5: Insert vendor "SmartTech Ltd." under Basic plan
INSERT INTO Vendor
    (business_name, contact_person, email, phone, business_address, plan_id)
VALUES
    ('SmartTech Ltd.', 'Rahim Khan', 'rahim@smarttech.com',
     '017XXXXXXXX', 'Dhaka, Bangladesh',
     (SELECT plan_id FROM SubscriptionPlan WHERE plan_name = 'Basic'));

-- Insert Electronics category
INSERT INTO Category (name, description)
VALUES ('Electronics', 'Electronic gadgets and devices');

-- Q6: Insert product "Laptop" under Electronics, belonging to SmartTech Ltd.
INSERT INTO Product
    (product_name, description, price, stock_quantity, status, vendor_id)
VALUES
    ('Laptop', 'High-performance laptop', 75000.00, 10, 'active',
     (SELECT vendor_id FROM Vendor WHERE business_name = 'SmartTech Ltd.'));

-- Link product to Electronics category
INSERT INTO ProductCategory (product_id, category_id)
VALUES
    ((SELECT product_id FROM Product WHERE product_name = 'Laptop' LIMIT 1),
     (SELECT category_id FROM Category WHERE name = 'Electronics'));

-- Q7: Update stock quantity of "Laptop" product to 15
UPDATE Product
SET stock_quantity = 15
WHERE product_name = 'Laptop';

-- Q8: Delete customer with email "oldcustomer@gmail.com"
DELETE FROM Customer
WHERE email = 'oldcustomer@gmail.com';
-- ============================================================
-- SAMPLE DATA (for meaningful Q11–Q13 results)
-- ============================================================

-- Sample customer "Karim Uddin"
INSERT INTO Customer (name, email, phone, address)
VALUES ('Karim Uddin', 'karim@mail.com', '01811111111', 'Chattogram');

-- Sample order by Karim (customer_id = 1)
INSERT INTO Orders (order_date, total_amount, order_status, customer_id)
VALUES ('2024-01-15', 75000.00, 'Pending', 1);

-- Order item (linking the order to the Laptop product)
INSERT INTO OrderItem (order_id, product_id, quantity, unit_price, subtotal)
VALUES (1, 1, 1, 75000.00, 75000.00);

-- Payment for order_id = 1
INSERT INTO Payment (order_id, method, amount, payment_date, payment_status)
VALUES (1, 'Bkash', 75000.00, '2024-01-15', 'Paid');

-- Extra product sales so Q13 (top 5 best-sellers) returns rows
INSERT INTO Orders (order_date, total_amount, order_status, customer_id)
VALUES ('2024-02-10', 150000.00, 'Delivered', 1);

INSERT INTO OrderItem (order_id, product_id, quantity, unit_price, subtotal)
VALUES (2, 1, 2, 75000.00, 150000.00);
-- ============================================================
-- PART D: DQL — SELECT QUERIES
-- ============================================================

-- Q9: Display all vendors with their subscription plan name and price
SELECT v.vendor_id, v.business_name, v.contact_person,
       sp.plan_name, sp.price AS plan_price
FROM Vendor v
LEFT JOIN SubscriptionPlan sp ON v.plan_id = sp.plan_id;

-- Q10: All products under "Electronics" with name, price, stock
SELECT p.product_id, p.product_name, p.price, p.stock_quantity
FROM Product p
JOIN ProductCategory pc ON p.product_id = pc.product_id
JOIN Category c         ON pc.category_id = c.category_id
WHERE c.name = 'Electronics';

-- Q11: All orders placed by customer "Karim Uddin"
SELECT o.order_id, o.order_date, o.total_amount, o.order_status
FROM Orders o
JOIN Customer c ON o.customer_id = c.customer_id
WHERE c.name = 'Karim Uddin';

-- Q12: Payment details (method, amount, status) for order_id = 1
SELECT method, amount, payment_status AS status
FROM Payment
WHERE order_id = 1;

-- Q13: Top 5 best-selling products based on total quantity sold
SELECT p.product_id, p.product_name,
       SUM(oi.quantity) AS total_quantity_sold
FROM OrderItem oi
JOIN Product p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_quantity_sold DESC
LIMIT 5;