-- Add unit_id column to sales_transaction_items table
ALTER TABLE sales_transaction_items ADD COLUMN unit_id INTEGER REFERENCES units(id);
