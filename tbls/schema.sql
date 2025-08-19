-- PostgreSQL Schema for tbls Documentation with Enum Types
-- This schema includes comprehensive comments for documentation generation

-- Create custom enum types with comments
CREATE TYPE user_status AS ENUM (
    'active',
    'inactive', 
    'suspended',
    'pending_verification',
    'deleted'
);
COMMENT ON TYPE user_status IS 'Enumeration of possible user account statuses';

CREATE TYPE order_status AS ENUM (
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
    'refunded'
);
COMMENT ON TYPE order_status IS 'Enumeration of order fulfillment statuses';

CREATE TYPE payment_method AS ENUM (
    'credit_card',
    'debit_card',
    'paypal',
    'bank_transfer',
    'cash_on_delivery',
    'cryptocurrency'
);
COMMENT ON TYPE payment_method IS 'Available payment methods for orders';

CREATE TYPE priority_level AS ENUM (
    'low',
    'medium',
    'high',
    'urgent',
    'critical'
);
COMMENT ON TYPE priority_level IS 'Priority levels for support tickets';

CREATE TYPE ticket_severity AS ENUM (
    'trivial',
    'minor',
    'major',
    'critical',
    'blocker'
);
COMMENT ON TYPE ticket_severity IS 'Severity classification for support issues';

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
COMMENT ON TYPE product_category IS 'Product categorization enum';

CREATE TYPE notification_channel AS ENUM (
    'email',
    'sms',
    'push',
    'in_app',
    'webhook'
);
COMMENT ON TYPE notification_channel IS 'Available notification delivery channels';

-- Create tables with comprehensive comments

-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    status user_status DEFAULT 'pending_verification' NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE users IS 'System users with authentication and account status management';
COMMENT ON COLUMN users.id IS 'Unique user identifier';
COMMENT ON COLUMN users.email IS 'User email address for authentication';
COMMENT ON COLUMN users.username IS 'Unique username for display purposes';
COMMENT ON COLUMN users.status IS 'Current account status (enum: active, inactive, suspended, pending_verification, deleted)';
COMMENT ON COLUMN users.created_at IS 'Timestamp of user registration';
COMMENT ON COLUMN users.updated_at IS 'Last modification timestamp';

-- User profiles table
CREATE TABLE user_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    bio TEXT,
    avatar_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE user_profiles IS 'Extended user profile information';
COMMENT ON COLUMN user_profiles.user_id IS 'Reference to users table';
COMMENT ON COLUMN user_profiles.first_name IS 'User first name';
COMMENT ON COLUMN user_profiles.last_name IS 'User last name';
COMMENT ON COLUMN user_profiles.phone IS 'Contact phone number';
COMMENT ON COLUMN user_profiles.bio IS 'User biography or description';
COMMENT ON COLUMN user_profiles.avatar_url IS 'URL to user avatar image';

-- Products table
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    category product_category NOT NULL,
    stock_quantity INTEGER DEFAULT 0,
    sku VARCHAR(100) UNIQUE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE products IS 'Product catalog with inventory tracking';
COMMENT ON COLUMN products.id IS 'Unique product identifier';
COMMENT ON COLUMN products.name IS 'Product display name';
COMMENT ON COLUMN products.description IS 'Detailed product description';
COMMENT ON COLUMN products.price IS 'Current product price';
COMMENT ON COLUMN products.category IS 'Product category classification (enum)';
COMMENT ON COLUMN products.stock_quantity IS 'Available inventory count';
COMMENT ON COLUMN products.sku IS 'Stock keeping unit for inventory management';
COMMENT ON COLUMN products.is_active IS 'Whether product is available for purchase';

-- Orders table
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    status order_status DEFAULT 'pending' NOT NULL,
    payment_method payment_method NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    shipping_address TEXT,
    notes TEXT,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    shipped_date TIMESTAMP,
    delivered_date TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE orders IS 'Customer orders with status and payment tracking';
COMMENT ON COLUMN orders.id IS 'Unique order identifier';
COMMENT ON COLUMN orders.user_id IS 'Customer who placed the order';
COMMENT ON COLUMN orders.order_number IS 'Human-readable order reference number';
COMMENT ON COLUMN orders.status IS 'Current order status (enum: pending, processing, shipped, delivered, cancelled, refunded)';
COMMENT ON COLUMN orders.payment_method IS 'Payment method used (enum)';
COMMENT ON COLUMN orders.total_amount IS 'Total order value including tax and shipping';
COMMENT ON COLUMN orders.shipping_address IS 'Delivery address for the order';
COMMENT ON COLUMN orders.notes IS 'Additional order notes or special instructions';
COMMENT ON COLUMN orders.order_date IS 'When the order was placed';
COMMENT ON COLUMN orders.shipped_date IS 'When the order was shipped';
COMMENT ON COLUMN orders.delivered_date IS 'When the order was delivered';

-- Order items table
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL,
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    subtotal DECIMAL(10, 2) NOT NULL
);

COMMENT ON TABLE order_items IS 'Individual line items within an order';
COMMENT ON COLUMN order_items.order_id IS 'Parent order reference';
COMMENT ON COLUMN order_items.product_id IS 'Product being ordered';
COMMENT ON COLUMN order_items.quantity IS 'Number of units ordered';
COMMENT ON COLUMN order_items.unit_price IS 'Price per unit at time of order';
COMMENT ON COLUMN order_items.discount_amount IS 'Discount applied to this line item';
COMMENT ON COLUMN order_items.subtotal IS 'Line item total (quantity * unit_price - discount)';

-- Support tickets table
CREATE TABLE support_tickets (
    id SERIAL PRIMARY KEY,
    ticket_number VARCHAR(50) UNIQUE NOT NULL,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    priority priority_level DEFAULT 'medium' NOT NULL,
    severity ticket_severity DEFAULT 'minor' NOT NULL,
    assigned_to INTEGER REFERENCES users(id),
    status VARCHAR(50) DEFAULT 'open',
    resolved_at TIMESTAMP,
    resolution_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE support_tickets IS 'Customer support ticket tracking system';
COMMENT ON COLUMN support_tickets.ticket_number IS 'Human-readable ticket reference';
COMMENT ON COLUMN support_tickets.user_id IS 'Customer who created the ticket';
COMMENT ON COLUMN support_tickets.title IS 'Brief ticket summary';
COMMENT ON COLUMN support_tickets.description IS 'Detailed issue description';
COMMENT ON COLUMN support_tickets.priority IS 'Ticket priority (enum: low, medium, high, urgent, critical)';
COMMENT ON COLUMN support_tickets.severity IS 'Issue severity (enum: trivial, minor, major, critical, blocker)';
COMMENT ON COLUMN support_tickets.assigned_to IS 'Support agent handling the ticket';
COMMENT ON COLUMN support_tickets.status IS 'Current ticket status';
COMMENT ON COLUMN support_tickets.resolved_at IS 'When the ticket was resolved';
COMMENT ON COLUMN support_tickets.resolution_notes IS 'Notes about how the issue was resolved';

-- Notification preferences table
CREATE TABLE notification_preferences (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    channels notification_channel[] DEFAULT '{email, in_app}',
    email_frequency VARCHAR(20) DEFAULT 'instant',
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE notification_preferences IS 'User notification settings and preferences';
COMMENT ON COLUMN notification_preferences.user_id IS 'User these preferences belong to';
COMMENT ON COLUMN notification_preferences.channels IS 'Array of enabled notification channels (enum[])';
COMMENT ON COLUMN notification_preferences.email_frequency IS 'Email batch frequency (instant, daily, weekly)';
COMMENT ON COLUMN notification_preferences.quiet_hours_start IS 'Start of do-not-disturb period';
COMMENT ON COLUMN notification_preferences.quiet_hours_end IS 'End of do-not-disturb period';

-- Audit log table
CREATE TABLE audit_logs (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id INTEGER NOT NULL,
    action VARCHAR(20) NOT NULL,
    user_id INTEGER REFERENCES users(id),
    changes JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE audit_logs IS 'System-wide audit trail for data changes';
COMMENT ON COLUMN audit_logs.table_name IS 'Table where change occurred';
COMMENT ON COLUMN audit_logs.record_id IS 'ID of the affected record';
COMMENT ON COLUMN audit_logs.action IS 'Type of action (INSERT, UPDATE, DELETE)';
COMMENT ON COLUMN audit_logs.user_id IS 'User who made the change';
COMMENT ON COLUMN audit_logs.changes IS 'JSON object containing before/after values';
COMMENT ON COLUMN audit_logs.ip_address IS 'IP address of the user';
COMMENT ON COLUMN audit_logs.user_agent IS 'Browser/client information';

-- Create indexes for better performance
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_order_date ON orders(order_date);
CREATE INDEX idx_tickets_priority ON support_tickets(priority);
CREATE INDEX idx_tickets_severity ON support_tickets(severity);
CREATE INDEX idx_tickets_assigned_to ON support_tickets(assigned_to);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_is_active ON products(is_active);
CREATE INDEX idx_audit_logs_table_record ON audit_logs(table_name, record_id);

-- Add comments to indexes
COMMENT ON INDEX idx_users_status IS 'Index for filtering users by status';
COMMENT ON INDEX idx_orders_status IS 'Index for filtering orders by status';
COMMENT ON INDEX idx_tickets_priority IS 'Index for filtering tickets by priority';
COMMENT ON INDEX idx_products_category IS 'Index for filtering products by category';