import 'package:flutter/material.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:jhs_pop/main.dart';
import 'package:jhs_pop/pages/splash.dart';
import 'package:jhs_pop/util/checkout_order.dart';
import 'package:jhs_pop/util/constants.dart';
import 'package:jhs_pop/util/navigation_service.dart';
import 'package:jhs_pop/util/order_aggregator.dart';
import 'package:jhs_pop/util/teacher_order.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:sqflite/sqflite.dart';

class PaymentScreen extends StatefulWidget {
  PaymentScreen(
      {super.key,
      TeacherOrder? teacherOrder,
      Map<CheckoutOrder, int>? checkoutOrder}) {
    orderAggregator = OrderAggregator(
      teacherOrder: teacherOrder,
      checkoutOrder: checkoutOrder,
    );
  }

  late final OrderAggregator orderAggregator;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isComplete = false;

  void completePayment() {
    setState(() {
      _isComplete = true;
    });

    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();

    NfcManager.instance.isAvailable().then((available) {
      if (!available) {
        return;
      }

      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          tag.data.forEach((key, value) {});
        },
      );
    });
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              widget.orderAggregator.name,
              style: const TextStyle(
                fontSize: 24.0,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              'Total: \$${widget.orderAggregator.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24.0,
              ),
            ),
            const SizedBox(height: 50.0),
            // _isComplete
            //     ? Container()
            //     : const Card(
            //         child: Padding(
            //           padding: EdgeInsets.all(75.0),
            //           child: Text(
            //             'Tap your card to pay',
            //           ),
            //         ),
            //       ),
            const SizedBox(height: 50.0),
            TextButton(
                onPressed: () {
                  showOrderDialog(widget.orderAggregator.fields,
                      widget.orderAggregator.price);
                },
                child: const Text('View Order Details')),
            Container(
              width: 100,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.lightBlue, width: 1)),
              child: TextButton(
                onPressed: () async {
                  await pay();

// if (!mounted) return;
                  // Navigator.of(context).pushNamed('/splash');
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //     SnackBar(content: Text("Order Payment Successfully")));
                },
                child: const Text('Pay'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  // void

  Future<List<Map<String, dynamic>>> getCreditCards() async {
    return await db.query('credit_cards');
  }

  void showOrderDialog(Map<String, dynamic> fields, double price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Total'),
              subtitle: Text('\$${price.toStringAsFixed(2)}'),
            ),
            ...fields.entries.map(
              (e) => ListTile(
                title: Text(e.key.capitalize()),
                subtitle: Text(e.value.toString()),
              ),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<int> insertOrder(
      Database db,
      String cardNumber,
      String cardHolderName,
      String orderDate,
      String orderTime,
      double totalPrice,
      int totalQuantity) async {
    return await db.insert(
      'cashier_order',
      {
        'cardNumber': cardNumber,
        'cardHolderName': cardHolderName,
        'orderDate': orderDate,
        'orderTime': orderTime,
        'totalPrice': totalPrice,
        'totalQuantity': totalQuantity,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertOrderItem(Database db, int orderId, int checkoutId,
      int quantity, double price) async {
    await db.insert(
      'order_items',
      {
        'order_id': orderId,
        'checkout_id': checkoutId,
        'quantity': quantity,
        'price': price,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> createOrder(
      Database db,
      Map<CheckoutOrder, int>? items,
      String cardNumber,
      String cardHolderName,
      String orderDate,
      String orderTime) async {
    // Calculate total price and total quantity
    double totalPrice = items!.entries
        .fold(0, (sum, entry) => sum + (entry.key.price * entry.value));
    int totalQuantity =
        items.entries.fold(0, (sum, entry) => sum + entry.value);

    // Insert the order and get the order ID
    int orderId = await insertOrder(db, cardNumber, cardHolderName, orderDate,
        orderTime, totalPrice, totalQuantity);

    // Insert each item into the order_items table
    for (var entry in items.entries) {
      await insertOrderItem(
          db, orderId, entry.key.id!, entry.value, entry.key.price);
    }
  }

  Future<List<Map<String, dynamic>>> getAllOrderDetails(Database db) async {
    return await db.rawQuery('''
    SELECT co.id AS order_id, co.cardNumber, co.orderDate, co.orderTime, co.totalPrice, co.totalQuantity,
           oi.id AS order_item_id, oi.quantity, oi.price AS item_price,
           c.name AS item_name, c.image AS item_image
    FROM order_items AS oi
    INNER JOIN checkouts AS c ON oi.checkout_id = c.id
    INNER JOIN cashier_order AS co ON oi.order_id = co.id
  ''');
  }

  Future<List<Map<String, dynamic>>> getOrderDetails(
      Database db, int orderId) async {
    return await db.rawQuery('''
    SELECT oi.id AS order_item_id, oi.quantity, oi.price AS item_price,
           c.name AS item_name, c.image AS item_image,
           co.cardNumber, co.orderDate, co.orderTime, co.totalPrice, co.totalQuantity
    FROM order_items AS oi
    INNER JOIN checkouts AS c ON oi.checkout_id = c.id
    INNER JOIN cashier_order AS co ON oi.order_id = co.id
    WHERE co.id = ?
  ''', [orderId]);
  }

  Future<void> showCreditCardNotFoundDialog(BuildContext context,
      {String text = "Credit Card not found",
      String subText = "Are you sure you want to add a credit card?",
      String button = 'Setup Card'}) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(text),
          content: Text(subText),
          actions: <Widget>[
            TextButton(
              child: Text(button),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pushNamed('/setting');
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  pay() async {
    var cards = await getCreditCards();

    if (cards.isEmpty) {
      await showCreditCardNotFoundDialog(context);
      return;
    }

    print(cards);

    if (widget.orderAggregator.price > double.parse(cards.last['money'])) {
      await showCreditCardNotFoundDialog(context,
          text: "Balance Low",
          subText: "Kindly add funds to make payments",
          button: "Add Funds");
      return;
    }

    int id = cards.last['id'];
    int count = await db.update(
      'credit_cards',
      {
        'money':
            double.parse(cards.last['money']) - widget.orderAggregator.price
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count != 0) {
      print("Card Money Update");
    }

    DateTime now = DateTime.now();
    String orderDate = now.toIso8601String().split('T')[0]; // yyyy-MM-dd
    String orderTime =
        now.toIso8601String().split('T')[1].split('.')[0]; // HH:mm:ss

    String cardNumber = cards.last['cardNumber'];
    String cardHolderName = cards.last['cardHolderName'];

    print(cardHolderName);

    // Create the order
    await createOrder(db, widget.orderAggregator.checkout, cardNumber,
        cardHolderName, orderDate, orderTime);

    // Retrieve the order details
    int orderId = 0; // Replace with the actual order ID
    List<Map<String, dynamic>> orderDetails =
        await getOrderDetails(db, orderId);

    // Retrieve all order details
    List<Map<String, dynamic>> allOrderDetails = await getAllOrderDetails(db);

    print(allOrderDetails);

    // Print the order details
    for (var detail in orderDetails) {
      // print(
      //     'Item: ${detail['item_name']}, Quantity: ${detail['quantity']}, Price: ${detail['item_price']}, Total Price: ${detail['totalPrice']}');
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Order Successfully")));

    Navigator.of(NavigationService.navigatorKey.currentContext!)
        .push(MaterialPageRoute(builder: (context) => const SplashScreen()));
  }
}
