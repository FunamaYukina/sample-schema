-- PostgreSQL Schema with Enum Types Sample

-- Drop existing types if they exist (for idempotent execution)
DROP TYPE IF EXISTS user_status CASCADE;
DROP TYPE IF EXISTS order_status CASCADE;
DROP TYPE IF EXISTS payment_method CASCADE;
DROP TYPE IF EXISTS priority_level CASCADE;
DROP TYPE IF EXISTS notification_type CASCADE;
DROP TYPE IF EXISTS weekday CASCADE;
DROP TYPE IF EXISTS ticket_severity CASCADE;
DROP TYPE IF EXISTS product_category CASCADE;

-- Create Enum Types
CREATE TYPE user_status AS ENUM (
    'active',
    'inactive',
    'suspended',
    'pending_verification',
    'deleted'
);
COMMENT ON TYPE user_status IS 'User account status enumeration - tracks the current state of user accounts in the system';

CREATE TYPE order_status AS ENUM (
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
    'refunded'
);
COMMENT ON TYPE order_status IS 'Order fulfillment status - represents the lifecycle stages of customer orders from placement to completion';

CREATE TYPE payment_method AS ENUM (
    'credit_card',
    'debit_card',
    'paypal',
    'bank_transfer',
    'cash_on_delivery',
    'cryptocurrency'
);

CREATE TYPE priority_level AS ENUM (
    'low',
    'medium',
    'high',
    'urgent',
    'critical'
);

CREATE TYPE notification_type AS ENUM (
    'email',
    'sms',
    'push',
    'in_app',
    'webhook'
);

CREATE TYPE weekday AS ENUM (
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
);

CREATE TYPE ticket_severity AS ENUM (
    'trivial',
    'minor',
    'major',
    'critical',
    'blocker'
);

CREATE TYPE product_category AS ENUM (
    'electronics',
    'clothing',
    'books',
    'food',
    'home_garden',
    'sports',
    'toys',
    'health_beauty'
);

-- Drop existing tables if they exist
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS support_tickets CASCADE;
DROP TABLE IF EXISTS notification_preferences CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Create Tables using Enum Types

-- Users table with status enum
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    status user_status DEFAULT 'pending_verification' NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products table with category enum
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    category product_category NOT NULL,
    stock_quantity INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders table with status and payment method enums
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    status order_status DEFAULT 'pending' NOT NULL,
    payment_method payment_method NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    shipping_address TEXT,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Order items table
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL
);

-- Support tickets with priority and severity enums
CREATE TABLE support_tickets (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    priority priority_level DEFAULT 'medium' NOT NULL,
    severity ticket_severity DEFAULT 'minor' NOT NULL,
    assigned_to INTEGER,
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notification preferences with array of enum types
CREATE TABLE notification_preferences (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    enabled_types notification_type[] DEFAULT '{email, in_app}',
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    quiet_days weekday[] DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_tickets_priority ON support_tickets(priority);
CREATE INDEX idx_tickets_severity ON support_tickets(severity);
CREATE INDEX idx_products_category ON products(category);

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

-- Sample function that uses enum types
CREATE OR REPLACE FUNCTION get_orders_by_status(
    p_status order_status
) RETURNS TABLE (
    order_id INTEGER,
    user_id INTEGER,
    total_amount DECIMAL,
    order_date TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT id, user_id, total_amount, order_date
    FROM orders
    WHERE status = p_status;
END;
$$ LANGUAGE plpgsql;

-- Trigger function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at columns
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tickets_updated_at BEFORE UPDATE ON support_tickets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notification_preferences_updated_at BEFORE UPDATE ON notification_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

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
    ('Programming Book', 'Learn PostgreSQL', 45.99, 'books', 15);

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

INSERT INTO notification_preferences (user_id, enabled_types, quiet_hours_start, quiet_hours_end, quiet_days) VALUES
    (1, '{email, push, in_app}', '22:00', '08:00', '{saturday, sunday}'),
    (2, '{email}', '23:00', '07:00', '{}'),
    (3, '{email, sms, push}', NULL, NULL, NULL);