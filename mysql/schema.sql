-- MySQL Schema with Enum Types Sample

-- Create database (uncomment if needed)
-- CREATE DATABASE IF NOT EXISTS sample_schema;
-- USE sample_schema;

-- Drop existing tables if they exist
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS support_tickets;
DROP TABLE IF EXISTS notification_preferences;
DROP TABLE IF EXISTS users;

-- Create Tables with inline ENUM types (MySQL style)

-- Users table with status enum
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    status ENUM('active', 'inactive', 'suspended', 'pending_verification', 'deleted') 
        DEFAULT 'pending_verification' NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Products table with category enum
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    category ENUM('electronics', 'clothing', 'books', 'food', 'home_garden', 'sports', 'toys', 'health_beauty') NOT NULL,
    stock_quantity INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Orders table with status and payment method enums
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded') 
        DEFAULT 'pending' NOT NULL,
    payment_method ENUM('credit_card', 'debit_card', 'paypal', 'bank_transfer', 'cash_on_delivery', 'cryptocurrency') NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    shipping_address TEXT,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_status (status),
    INDEX idx_user_id (user_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Order items table
CREATE TABLE order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Support tickets with priority and severity enums
CREATE TABLE support_tickets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    priority ENUM('low', 'medium', 'high', 'urgent', 'critical') 
        DEFAULT 'medium' NOT NULL,
    severity ENUM('trivial', 'minor', 'major', 'critical', 'blocker') 
        DEFAULT 'minor' NOT NULL,
    assigned_to INT,
    resolved_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_priority (priority),
    INDEX idx_severity (severity),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Notification preferences with SET type (MySQL's alternative to array of enums)
-- Using SET for multiple enum values and separate columns for weekdays
CREATE TABLE notification_preferences (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    -- SET allows multiple values from the list
    enabled_types SET('email', 'sms', 'push', 'in_app', 'webhook') 
        DEFAULT 'email,in_app',
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    -- Using SET for quiet_days as well
    quiet_days SET('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday') 
        DEFAULT '',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create a view that uses enum types
CREATE OR REPLACE VIEW active_user_orders AS
SELECT 
    u.id as user_id,
    u.username,
    u.email,
    o.id as order_id,
    o.status as order_status,
    o.payment_method,
    o.total_amount,
    o.order_date
FROM users u
JOIN orders o ON u.id = o.user_id
WHERE u.status = 'active';

-- Create stored procedure that uses enum types
DELIMITER //

CREATE PROCEDURE GetOrdersByStatus(
    IN p_status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded')
)
BEGIN
    SELECT 
        id as order_id,
        user_id,
        status,
        payment_method,
        total_amount,
        order_date
    FROM orders
    WHERE status = p_status;
END //

-- Create function to calculate order statistics by status
CREATE FUNCTION GetOrderCountByStatus(
    p_status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded')
) RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE order_count INT;
    SELECT COUNT(*) INTO order_count
    FROM orders
    WHERE status = p_status;
    RETURN order_count;
END //

-- Create trigger to validate enum transitions
CREATE TRIGGER before_order_status_update
BEFORE UPDATE ON orders
FOR EACH ROW
BEGIN
    -- Example validation: cancelled orders cannot be changed to delivered
    IF OLD.status = 'cancelled' AND NEW.status = 'delivered' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot change cancelled order to delivered';
    END IF;
    
    -- Example validation: delivered orders can only be refunded
    IF OLD.status = 'delivered' AND NEW.status NOT IN ('delivered', 'refunded') THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Delivered orders can only be refunded';
    END IF;
END //

DELIMITER ;

-- Insert sample data
INSERT INTO users (email, username, status) VALUES
    ('john.doe@example.com', 'johndoe', 'active'),
    ('jane.smith@example.com', 'janesmith', 'active'),
    ('bob.wilson@example.com', 'bobwilson', 'pending_verification'),
    ('alice.brown@example.com', 'alicebrown', 'suspended');

INSERT INTO products (name, description, price, category, stock_quantity) VALUES
    ('Laptop Pro 15', 'High-performance laptop', 1299.99, 'electronics', 10),
    ('Running Shoes', 'Professional running shoes', 89.99, 'sports', 25),
    ('Organic Shampoo', 'Natural hair care product', 12.99, 'health_beauty', 50),
    ('Programming Book', 'Learn MySQL', 45.99, 'books', 15);

INSERT INTO orders (user_id, status, payment_method, total_amount, shipping_address) VALUES
    (1, 'delivered', 'credit_card', 1299.99, '123 Main St, City, Country'),
    (2, 'processing', 'paypal', 89.99, '456 Oak Ave, Town, Country'),
    (1, 'pending', 'bank_transfer', 58.98, '123 Main St, City, Country');

INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES
    (1, 1, 1, 1299.99, 1299.99),
    (2, 2, 1, 89.99, 89.99),
    (3, 3, 2, 12.99, 25.98),
    (3, 4, 1, 45.99, 45.99);

INSERT INTO support_tickets (user_id, title, description, priority, severity) VALUES
    (1, 'Cannot login', 'Getting error when trying to login', 'high', 'major'),
    (2, 'Shipping delay', 'Order has not arrived yet', 'medium', 'minor'),
    (3, 'Feature request', 'Add dark mode to website', 'low', 'trivial');

-- Using SET type for multiple values
INSERT INTO notification_preferences (user_id, enabled_types, quiet_hours_start, quiet_hours_end, quiet_days) VALUES
    (1, 'email,push,in_app', '22:00', '08:00', 'saturday,sunday'),
    (2, 'email', '23:00', '07:00', ''),
    (3, 'email,sms,push', NULL, NULL, NULL);

-- Example queries demonstrating ENUM usage

-- Query using ENUM value
SELECT * FROM users WHERE status = 'active';

-- Query using SET type with FIND_IN_SET
SELECT * FROM notification_preferences 
WHERE FIND_IN_SET('push', enabled_types) > 0;

-- Query to get all possible enum values for a column
SELECT 
    COLUMN_TYPE 
FROM 
    INFORMATION_SCHEMA.COLUMNS 
WHERE 
    TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'users' 
    AND COLUMN_NAME = 'status';

-- Query to check if specific day is in quiet_days SET
SELECT * FROM notification_preferences 
WHERE FIND_IN_SET('saturday', quiet_days) > 0;