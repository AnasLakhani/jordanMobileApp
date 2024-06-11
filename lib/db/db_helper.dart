import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  static Database? _database;

  DBHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'jhs_pop.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS credit_cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cardNumber TEXT,
        expiryDate TEXT,
        cardHolderName TEXT,
        cvvCode TEXT
      )
    ''');

    await db.execute('''
        CREATE TABLE IF NOT EXISTS checkouts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          image TEXT,
          price REAL
        )
      ''');

    await db.query('checkouts').then((rows) {
      if (rows.isEmpty) {
        db.transaction((txn) async {
          for (var i = 0; i < 9; i++) {
            await txn.insert('checkouts', {
              'name': 'Item ${i + 1}',
              'image': 'assets/images/solid_blue.jpeg',
              'price': (i + 1) * 1.5,
            });
          }
        });
      }
    });

    await db.execute('''
        CREATE TABLE IF NOT EXISTS orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          room TEXT,
          additional TEXT,
          frequency TEXT,
          creamer TEXT,
          sweetener TEXT
        )
      ''');
  }

  Future<List<Map<String, dynamic>>> getCreditCards() async {
    Database db = await database;
    return await db.query('credit_cards');
  }

  Future<int> insertCard(Map<String, dynamic> card) async {
    Database db = await database;
    return await db.insert('credit_cards', card);
  }
}
