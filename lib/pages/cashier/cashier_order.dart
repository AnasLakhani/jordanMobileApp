import 'package:flutter/material.dart';
import 'package:jhs_pop/main.dart';
import 'package:sqflite/sqflite.dart';

class CashierOrder extends StatefulWidget {
  const CashierOrder({super.key});

  @override
  State<CashierOrder> createState() => _CashierOrderState();
}

class _CashierOrderState extends State<CashierOrder> {
  late Database _database;
  late Future<List<Map<String, dynamic>>> _orders;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    _database = await openDatabase('jhs_pop.db');
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _orders = getAllOrders(_database);
    });
  }

  Future<List<Map<String, dynamic>>> getAllOrders(Database db) async {
    return await db.rawQuery('''
      SELECT id AS order_id, cardNumber,cardHolderName, orderDate, orderTime, totalPrice, totalQuantity
      FROM cashier_order ORDER BY id desc
    ''');
  }

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _filterOrders(
      List<Map<String, dynamic>> orders, String query) {
    return orders.where((order) {
      final cardHolderName = order['cardHolderName'].toString().toLowerCase();
      return cardHolderName.contains(query.toLowerCase());
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchFilteredOrders(String query) async {
    final allOrders = await getAllOrders(_database);
    return _filterOrders(allOrders, query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashier Orders'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _fetchOrders();
              });
            },
            icon: Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
              });
            },
            icon: const Icon(Icons.clear),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _orders = _fetchFilteredOrders(value);
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by Card Holder Name',
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _orders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final orders = snapshot.data ?? [];
            return ListView.separated(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final orderId = order['order_id'];
                final orderDate = order['orderDate'];
                final orderTime = order['orderTime'];
                final totalPrice = order['totalPrice'];
                print(order);
                final cardHolderName = order['cardHolderName'];
                final totalQuantity = order['totalQuantity'];

                return ListTile(
                  title: Text('Order # $orderId'),
                  subtitle: Text(
                      'Date: $orderDate, Time: $orderTime\nTotal Price: \$${totalPrice.toString()}\nTotal Quantity: $totalQuantity\nCard HolderName: $cardHolderName'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            OrderDetailsPage(orderId: orderId),
                      ),
                    );
                  },
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return Divider();
              },
            );
          }
        },
      ),
    );
  }
}

class OrderDetailsPage extends StatelessWidget {
  final int orderId;

  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    return await db.rawQuery('''
      SELECT oi.id AS order_item_id, oi.quantity, oi.price AS item_price,
             c.name AS item_name, c.image AS item_image
      FROM order_items AS oi
      INNER JOIN checkouts AS c ON oi.checkout_id = c.id
      WHERE oi.order_id = ?
    ''', [orderId]);
  }

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order $orderId Details'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getOrderItems(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final items = snapshot.data ?? [];
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final itemName = item['item_name'];
                final itemPrice = item['item_price'];

                return ListTile(
                  leading: Image.asset((item['item_image'])),
                  title: Text(itemName),
                  subtitle: Text('Price: \$${itemPrice.toString()}'),
                );
              },
            );
          }
        },
      ),
    );
  }
}
