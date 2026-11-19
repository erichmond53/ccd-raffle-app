import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../core/models/local_sale.dart';

/// The local proof-of-sale log. A row is written the instant a payment
/// succeeds, before any network call — this table is the source of truth
/// that money was taken; syncing it to WordPress is best-effort on top.
class LocalSalesDb {
  LocalSalesDb._();
  static final LocalSalesDb instance = LocalSalesDb._();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'ccd_raffle_sales.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE local_sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            square_payment_id TEXT UNIQUE NOT NULL,
            event_id INTEGER NOT NULL,
            event_title TEXT NOT NULL,
            sale_type TEXT NOT NULL DEFAULT 'raffle',
            quantity INTEGER NOT NULL,
            buyer_first_name TEXT NOT NULL,
            buyer_last_name TEXT NOT NULL,
            buyer_phone TEXT NOT NULL,
            buyer_email TEXT NOT NULL,
            amount_charged_cents INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            order_id INTEGER,
            ticket_numbers_formatted TEXT,
            pot_value REAL,
            last_error TEXT,
            retry_count INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
    return _db!;
  }

  /// Inserts the sale and returns the row as actually stored (with its real id).
  Future<LocalSale> insert(LocalSale sale) async {
    final db = await _database;
    final id = await db.insert('local_sales', sale.toDb()..remove('id'));
    final rows = await db.query('local_sales', where: 'id = ?', whereArgs: [id]);
    return LocalSale.fromDb(rows.first);
  }

  Future<void> update(LocalSale sale) async {
    final db = await _database;
    await db.update(
      'local_sales',
      sale.toDb()..remove('id'),
      where: 'id = ?',
      whereArgs: [sale.id],
    );
  }

  Future<List<LocalSale>> all() async {
    final db = await _database;
    final rows = await db.query('local_sales', orderBy: 'created_at DESC');
    return rows.map(LocalSale.fromDb).toList();
  }

  Future<List<LocalSale>> pending() async {
    final db = await _database;
    final rows = await db.query('local_sales', where: "sync_status = 'pending'");
    return rows.map(LocalSale.fromDb).toList();
  }

  Future<LocalSale?> findByPaymentId(String squarePaymentId) async {
    final db = await _database;
    final rows = await db.query(
      'local_sales',
      where: 'square_payment_id = ?',
      whereArgs: [squarePaymentId],
    );
    if (rows.isEmpty) return null;
    return LocalSale.fromDb(rows.first);
  }
}
