import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// SQLite-based offline cache for products, categories, and pending orders.
/// Allows browsing products and adding to cart when offline.
class OfflineCacheService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'spazasure_cache.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_products (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            sku TEXT,
            price REAL NOT NULL,
            image_url TEXT,
            category_id TEXT,
            category_name TEXT,
            supplier_id TEXT,
            supplier_name TEXT,
            stock_quantity INTEGER,
            min_order_qty INTEGER,
            is_available INTEGER DEFAULT 1,
            cached_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE cached_categories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon_name TEXT,
            product_count INTEGER DEFAULT 0,
            cached_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE pending_orders (
            id TEXT PRIMARY KEY,
            order_json TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            synced INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  // ── Products Cache ─────────────────────────────────────────────────────────

  /// Cache a list of products from the API.
  static Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final p in products) {
      batch.insert(
        'cached_products',
        {
          'id': p['id'],
          'name': p['name'],
          'description': p['description'],
          'sku': p['sku'],
          'price': p['price'],
          'image_url': p['imageUrl'] ?? p['image_url'],
          'category_id': p['categoryId'] ?? p['category_id'],
          'category_name': p['categoryName'] ?? p['category_name'],
          'supplier_id': p['supplierId'] ?? p['supplier_id'],
          'supplier_name': p['supplierName'] ?? p['supplier_name'],
          'stock_quantity': p['stockQuantity'] ?? p['stock_quantity'] ?? 0,
          'min_order_qty': p['minOrderQty'] ?? p['min_order_qty'] ?? 1,
          'is_available': (p['isAvailable'] ?? p['is_available'] ?? true) ? 1 : 0,
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get cached products, optionally filtered by category.
  static Future<List<Map<String, dynamic>>> getCachedProducts({String? categoryId}) async {
    final db = await database;
    final where = categoryId != null ? 'category_id = ?' : null;
    final args = categoryId != null ? [categoryId] : null;

    return db.query('cached_products', where: where, whereArgs: args, orderBy: 'name');
  }

  /// Search cached products by name.
  static Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await database;
    return db.query(
      'cached_products',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
  }

  // ── Categories Cache ───────────────────────────────────────────────────────

  /// Cache categories from the API.
  static Future<void> cacheCategories(List<Map<String, dynamic>> categories) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final c in categories) {
      batch.insert(
        'cached_categories',
        {
          'id': c['id'],
          'name': c['name'],
          'icon_name': c['iconName'] ?? c['icon_name'],
          'product_count': c['productCount'] ?? c['product_count'] ?? 0,
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get cached categories.
  static Future<List<Map<String, dynamic>>> getCachedCategories() async {
    final db = await database;
    return db.query('cached_categories', orderBy: 'name');
  }

  // ── Offline Order Queue ────────────────────────────────────────────────────

  /// Queue an order for later sync when back online.
  static Future<void> queueOrder(Map<String, dynamic> orderData) async {
    final db = await database;
    await db.insert('pending_orders', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'order_json': jsonEncode(orderData),
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'synced': 0,
    });
  }

  /// Get all unsynced orders.
  static Future<List<Map<String, dynamic>>> getPendingOrders() async {
    final db = await database;
    return db.query('pending_orders', where: 'synced = 0', orderBy: 'created_at');
  }

  /// Mark an order as synced.
  static Future<void> markOrderSynced(String id) async {
    final db = await database;
    await db.update('pending_orders', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // ── Cache Management ───────────────────────────────────────────────────────

  /// Clear all cached data (e.g., on logout).
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('cached_products');
    await db.delete('cached_categories');
    await db.delete('pending_orders');
  }

  /// Check if cache is stale (older than given duration).
  static Future<bool> isCacheStale({Duration maxAge = const Duration(hours: 24)}) async {
    final db = await database;
    final result = await db.rawQuery('SELECT MAX(cached_at) as latest FROM cached_products');
    if (result.isEmpty || result.first['latest'] == null) return true;
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(result.first['latest'] as int);
    return DateTime.now().difference(cachedAt) > maxAge;
  }
}
