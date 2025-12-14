-- 销售退货单表
CREATE TABLE IF NOT EXISTS sales_returns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sales_transaction_id INTEGER NOT NULL,
    customer_id INTEGER,
    shop_id INTEGER NOT NULL,
    total_amount REAL NOT NULL,
    status TEXT DEFAULT 'pending',
    reason TEXT,
    remarks TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sales_transaction_id) REFERENCES sales_transactions(id) ON DELETE RESTRICT,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,
    FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE
);

-- 销售退货明细表
CREATE TABLE IF NOT EXISTS sales_return_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sales_return_id INTEGER NOT NULL,
    sales_transaction_item_id INTEGER,
    product_id INTEGER NOT NULL,
    unit_id INTEGER,
    batch_id INTEGER,
    quantity INTEGER NOT NULL,
    price_in_cents INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sales_return_id) REFERENCES sales_returns(id) ON DELETE CASCADE,
    FOREIGN KEY (sales_transaction_item_id) REFERENCES sales_transaction_items(id) ON DELETE SET NULL,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE SET NULL,
    FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE SET NULL
);

-- 更新时间触发器
CREATE TRIGGER IF NOT EXISTS update_sales_returns_updated_at
AFTER UPDATE ON sales_returns
FOR EACH ROW
BEGIN
    UPDATE sales_returns SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;
