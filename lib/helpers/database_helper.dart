// lib/helpers/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'katpos_offline.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    // Products table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        imageUrl TEXT,
        barcode TEXT,
        purchasePrice REAL,
        salePrice REAL,
        stock INTEGER,
        categoryId TEXT,
        categoryName TEXT,
        createdAt TEXT,
        userId TEXT,
        syncStatus INTEGER DEFAULT 0
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        iconName TEXT,
        color TEXT,
        createdAt TEXT,
        userId TEXT,
        syncStatus INTEGER DEFAULT 0
      )
    ''');

    // Vendors table
    await db.execute('''
      CREATE TABLE vendors (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phoneNumber TEXT,
        address TEXT,
        createdAt TEXT,
        userId TEXT,
        syncStatus INTEGER DEFAULT 0
      )
    ''');

    // Sales table (offline sales)
    await db.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        invoiceNumber TEXT NOT NULL,
        items TEXT NOT NULL,
        subtotal REAL,
        discount REAL,
        totalAmount REAL,
        paymentMethod TEXT,
        createdAt TEXT,
        userId TEXT,
        createdBy TEXT,
        syncStatus INTEGER DEFAULT 0
      )
    ''');

    // GRNs table (offline GRNs)
    await db.execute('''
      CREATE TABLE grns (
        id TEXT PRIMARY KEY,
        grnNumber TEXT NOT NULL,
        vendorId TEXT,
        vendorName TEXT,
        vendorPhone TEXT,
        items TEXT NOT NULL,
        totalAmount REAL,
        createdAt TEXT,
        userId TEXT,
        createdBy TEXT,
        syncStatus INTEGER DEFAULT 0
      )
    ''');

    // Sync queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation TEXT NOT NULL,
        tableName TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        retryCount INTEGER DEFAULT 0
      )
    ''');

    print('✅ Local database created successfully');
  }

  // ==================== PRODUCTS ====================
  
  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    return await db.insert('products', product, 
      conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getProducts(String userId) async {
    final db = await database;
    return await db.query('products', 
      where: 'userId = ?', 
      whereArgs: [userId],
      orderBy: 'createdAt DESC'
    );
  }

  Future<int> updateProduct(String id, Map<String, dynamic> product) async {
    final db = await database;
    return await db.update('products', product,
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  Future<int> deleteProduct(String id) async {
    final db = await database;
    return await db.delete('products',
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  // ==================== CATEGORIES ====================
  
  Future<int> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    return await db.insert('categories', category,
      conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getCategories(String userId) async {
    final db = await database;
    return await db.query('categories',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC'
    );
  }

  Future<int> updateCategory(String id, Map<String, dynamic> category) async {
    final db = await database;
    return await db.update('categories', category,
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    return await db.delete('categories',
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  // ==================== VENDORS ====================
  
  Future<int> insertVendor(Map<String, dynamic> vendor) async {
    final db = await database;
    return await db.insert('vendors', vendor,
      conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getVendors(String userId) async {
    final db = await database;
    return await db.query('vendors',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC'
    );
  }

  Future<int> updateVendor(String id, Map<String, dynamic> vendor) async {
    final db = await database;
    return await db.update('vendors', vendor,
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  Future<int> deleteVendor(String id) async {
    final db = await database;
    return await db.delete('vendors',
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  // ==================== SALES ====================
  
  Future<int> insertSale(Map<String, dynamic> sale) async {
    final db = await database;
    return await db.insert('sales', sale,
      conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getSales(String userId) async {
    final db = await database;
    return await db.query('sales',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC'
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedSales() async {
    final db = await database;
    return await db.query('sales',
      where: 'syncStatus = ?',
      whereArgs: [0]
    );
  }

  Future<int> updateSaleSyncStatus(String id, int status) async {
    final db = await database;
    return await db.update('sales', {'syncStatus': status},
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  // ==================== GRNS ====================
  
  Future<int> insertGRN(Map<String, dynamic> grn) async {
    final db = await database;
    return await db.insert('grns', grn,
      conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getGRNs(String userId) async {
    final db = await database;
    return await db.query('grns',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC'
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedGRNs() async {
    final db = await database;
    return await db.query('grns',
      where: 'syncStatus = ?',
      whereArgs: [0]
    );
  }

  Future<int> updateGRNSyncStatus(String id, int status) async {
    final db = await database;
    return await db.update('grns', {'syncStatus': status},
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  // ==================== SYNC QUEUE ====================
  
  Future<int> addToSyncQueue(Map<String, dynamic> operation) async {
    final db = await database;
    return await db.insert('sync_queue', operation);
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query('sync_queue',
      orderBy: 'timestamp ASC'
    );
  }

  Future<int> removeSyncQueueItem(int id) async {
    final db = await database;
    return await db.delete('sync_queue',
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  Future<int> updateSyncQueueRetry(int id, int retryCount) async {
    final db = await database;
    return await db.update('sync_queue', {'retryCount': retryCount},
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  // ==================== UTILITY ====================
  
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('products');
    await db.delete('categories');
    await db.delete('vendors');
    await db.delete('sales');
    await db.delete('grns');
    await db.delete('sync_queue');
    print('✅ Local database cleared');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}