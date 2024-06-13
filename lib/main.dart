import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jhs_pop/pages/cashier/cashier_order.dart';
import 'package:jhs_pop/pages/cashier_screen.dart';
import 'package:jhs_pop/pages/edit_options_page.dart';
// import 'package:jhs_pop/pages/home_page.dart';
// import 'package:jhs_pop/pages/load_order_page.dart';
// import 'package:jhs_pop/pages/manual_entry.dart';
import 'package:jhs_pop/pages/payment_screen.dart';
import 'package:jhs_pop/pages/setting/setting_page.dart';
import 'package:jhs_pop/pages/splash.dart';
import 'package:jhs_pop/util/checkout_order.dart';
import 'package:jhs_pop/util/navigation_service.dart';
import 'package:jhs_pop/util/teacher_order.dart';
import 'package:sqflite/sqflite.dart';

late final Database db;
final dbReady = Completer<void>();

void main() {
  runApp(const MyApp());

  openDatabase('jhs_pop.db', version: 2).then((database) {
    db = database;

    // setup tables
    initDatabase() async {
      //////// DEBUG ONLY /////////
      // db.execute('''
      //   drop table if exists checkouts;
      // ''');
      ////////////////////////////

      await db.execute('''
        CREATE TABLE IF NOT EXISTS checkouts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          image TEXT,
          price REAL
        )
      ''');

      await db.execute('''
      CREATE TABLE IF NOT EXISTS credit_cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cardNumber TEXT,
        expiryDate TEXT,
        cardHolderName TEXT,
        cvvCode TEXT,
        money TEXT
      )
    ''');

      await db.query('checkouts').then((rows) {
        if (rows.isEmpty) {
          db.transaction((txn) async {
            for (var i = 0; i < 15; i++) {
              await txn.insert('checkouts', {
                'name': 'Item ${i + 1}',
                'image': 'assets/jordan/${i + 1}.jpeg',
                'price': (i + 1) * 1.5,
              });
            }
          });
        }
      });

      // await db.execute(''' TRUNCATE TABLE  orders''');

      // await db.execute('''
      //   CREATE TABLE IF NOT EXISTS orders (
      //     id INTEGER PRIMARY KEY AUTOINCREMENT,
      //     name TEXT,
      //     room TEXT,
      //     additional TEXT,
      //     frequency TEXT,
      //     creamer TEXT,
      //     sweetener TEXT
      //   )
      // ''');

      await db.execute('''
    CREATE TABLE IF NOT EXISTS cashier_order (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cardNumber TEXT,
      cardHolderName TEXT,
      orderDate TEXT,
      orderTime TEXT,
      totalPrice REAL,
      totalQuantity INTEGER
    )
  ''');

      await db.execute('''
    CREATE TABLE IF NOT EXISTS order_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER,
      checkout_id INTEGER,
      quantity INTEGER,
      price REAL,
      FOREIGN KEY(order_id) REFERENCES cashier_order(id),
      FOREIGN KEY(checkout_id) REFERENCES checkouts(id)
    )
  ''');
    }

    initDatabase().then((_) => dbReady.complete());
  });
}

final routes = <String, WidgetBuilder>{
  '/': (context) => const SplashScreen(),
  // '/home': (context) => const HomePage(),
  // '/manual': (context) => const NewItemPage(),
  '/setting': (context) => const SettingPage(),
  '/cashierOrders': (context) => const CashierOrder(),
  '/payment': (context) {
    final args = ModalRoute.of(context)!.settings.arguments;

    if (args is TeacherOrder) {
      return PaymentScreen(teacherOrder: args);
    } else if (args is Map<CheckoutOrder, int>) {
      return PaymentScreen(checkoutOrder: args);
    } else {
      return PaymentScreen();
    }
  },
  // '/load_order': (context) => const LoadOrderPage(),
  '/cashier': (context) => const CashierScreen(),
  '/edit_options': (context) => EditOptionsPage(
      buttons:
          ModalRoute.of(context)!.settings.arguments as List<CheckoutOrder>),
};

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey, // set property
      title: 'Point of Payment',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          prefixIconColor: Colors.grey[400],
          suffixIconColor: Colors.grey[400],
          hintStyle: TextStyle(color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(10),
          ),
        ),
        useMaterial3: true,
      ),
      routes: routes,
    );
  }
}
