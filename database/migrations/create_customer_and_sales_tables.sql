-- This migration creates the initial tables for customer and sales management.

-- Table for storing customer information
CREATE TABLE customers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    address TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Trigger to update the updated_at timestamp on customer record changes
CREATE TRIGGER update_customers_updated_at
AFTER UPDATE ON customers
FOR EACH ROW
BEGIN
    UPDATE customers SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;

-- Table for sales transactions
CREATE TABLE sales_transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id INTEGER,
    shop_id INTEGER NOT NULL,
    transaction_date TEXT NOT NULL,
    total_amount REAL NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,
    FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE
);

-- Trigger to update the updated_at timestamp on sales transaction changes
CREATE TRIGGER update_sales_transactions_updated_at
AFTER UPDATE ON sales_transactions
FOR EACH ROW
BEGIN
    UPDATE sales_transactions SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;

-- Table for items included in a sales transaction
CREATE TABLE sales_transaction_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sales_transaction_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    batch_id INTEGER,
    quantity REAL NOT NULL,
    unit_price REAL NOT NULL,
    total_price REAL NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sales_transaction_id) REFERENCES sales_transactions(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE SET NULL
);

-- Trigger to update the updated_at timestamp on sales transaction item changes
CREATE TRIGGER update_sales_transaction_items_updated_at
AFTER UPDATE ON sales_transaction_items
FOR EACH ROW
BEGIN
    UPDATE sales_transaction_items SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;