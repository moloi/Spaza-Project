-- Fix the existing supplier
UPDATE suppliers SET 
  company_name = 'Fresh Foods SA (Pty) Ltd',
  contact_person = 'Thabo Nkosi',
  status = 'verified',
  tier = 'silver',
  commission_rate = 3.00,
  city = 'Johannesburg',
  province = 'Gauteng',
  address = '12 Industrial Road, Johannesburg'
WHERE id = '00000000-0000-0000-0003-000000000001';

-- Also approve the existing product
UPDATE products SET is_approved = true, is_available = true WHERE supplier_id = '00000000-0000-0000-0003-000000000001';

-- Insert products using first available category
INSERT INTO products (id, supplier_id, category_id, name, description, sku, price, stock_qty, min_order_qty, unit, images, is_available, is_approved, is_food_item, created_at, updated_at)
SELECT gen_random_uuid(), '00000000-0000-0000-0003-000000000001', (SELECT id FROM categories LIMIT 1), 'White Star Maize Meal 10kg', 'Premium super maize meal', 'WS-MM-10', 89.99, 500, 10, 'bag', '[]', true, true, true, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'WS-MM-10');

INSERT INTO products (id, supplier_id, category_id, name, description, sku, price, stock_qty, min_order_qty, unit, images, is_available, is_approved, is_food_item, created_at, updated_at)
SELECT gen_random_uuid(), '00000000-0000-0000-0003-000000000001', (SELECT id FROM categories LIMIT 1), 'Tastic Rice 2kg', 'Long grain parboiled rice', 'TR-2K', 42.99, 300, 12, 'pack', '[]', true, true, true, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'TR-2K');

INSERT INTO products (id, supplier_id, category_id, name, description, sku, price, stock_qty, min_order_qty, unit, images, is_available, is_approved, is_food_item, created_at, updated_at)
SELECT gen_random_uuid(), '00000000-0000-0000-0003-000000000001', (SELECT id FROM categories LIMIT 1), 'Sunfoil Cooking Oil 2L', 'Pure sunflower cooking oil', 'SF-CO-2L', 54.99, 200, 6, 'bottle', '[]', true, true, true, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'SF-CO-2L');

INSERT INTO products (id, supplier_id, category_id, name, description, sku, price, stock_qty, min_order_qty, unit, images, is_available, is_approved, is_food_item, created_at, updated_at)
SELECT gen_random_uuid(), '00000000-0000-0000-0003-000000000001', (SELECT id FROM categories LIMIT 1), 'Coca-Cola 2L (6-Pack)', 'Original taste. 6 bottles', 'CC-2L-6', 89.99, 150, 4, 'pack', '[]', true, true, false, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'CC-2L-6');

INSERT INTO products (id, supplier_id, category_id, name, description, sku, price, stock_qty, min_order_qty, unit, images, is_available, is_approved, is_food_item, created_at, updated_at)
SELECT gen_random_uuid(), '00000000-0000-0000-0003-000000000001', (SELECT id FROM categories LIMIT 1), 'Simba Chips Assorted 36s', 'Mixed flavour chips', 'SC-36', 149.99, 100, 2, 'box', '[]', true, true, true, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'SC-36');

INSERT INTO products (id, supplier_id, category_id, name, description, sku, price, stock_qty, min_order_qty, unit, images, is_available, is_approved, is_food_item, created_at, updated_at)
SELECT gen_random_uuid(), '00000000-0000-0000-0003-000000000001', (SELECT id FROM categories LIMIT 1), 'Lucky Star Pilchards 400g (24-Pack)', 'Pilchards in tomato sauce', 'LS-400-24', 299.99, 60, 1, 'box', '[]', true, true, true, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'LS-400-24');

INSERT INTO products (id, supplier_id, category_id, name, description, sku, price, stock_qty, min_order_qty, unit, images, is_available, is_approved, is_food_item, created_at, updated_at)
SELECT gen_random_uuid(), '00000000-0000-0000-0003-000000000001', (SELECT id FROM categories LIMIT 1), 'Sunlight Dishwashing 750ml (12-Pack)', 'Grease-cutting formula', 'SDL-750-12', 179.99, 120, 2, 'box', '[]', true, true, false, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'SDL-750-12');

INSERT INTO products (id, supplier_id, category_id, name, description, sku, price, stock_qty, min_order_qty, unit, images, is_available, is_approved, is_food_item, created_at, updated_at)
SELECT gen_random_uuid(), '00000000-0000-0000-0003-000000000001', (SELECT id FROM categories LIMIT 1), 'Albany Bread (20 Loaves)', 'White sliced bread bulk', 'AB-WB-20', 259.99, 30, 1, 'case', '[]', true, true, true, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'AB-WB-20');

INSERT INTO products (id, supplier_id, category_id, name, description, sku, price, stock_qty, min_order_qty, unit, images, is_available, is_approved, is_food_item, created_at, updated_at)
SELECT gen_random_uuid(), '00000000-0000-0000-0003-000000000001', (SELECT id FROM categories LIMIT 1), 'KOO Baked Beans 410g (12-Pack)', 'Rich tomato sauce beans', 'KOO-BB-12', 129.99, 200, 2, 'case', '[]', true, true, true, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'KOO-BB-12');

INSERT INTO products (id, supplier_id, category_id, name, description, sku, price, stock_qty, min_order_qty, unit, images, is_available, is_approved, is_food_item, created_at, updated_at)
SELECT gen_random_uuid(), '00000000-0000-0000-0003-000000000001', (SELECT id FROM categories LIMIT 1), 'Clover Fresh Milk 2L (6-Pack)', 'Full cream fresh milk', 'CM-2L-6', 119.99, 80, 2, 'pack', '[]', true, true, true, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM products WHERE sku = 'CM-2L-6');
