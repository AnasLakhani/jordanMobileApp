import 'package:flutter/material.dart';
import 'package:jhs_pop/main.dart';
import 'package:jhs_pop/pages/dialog/user_info_dialog.dart';
import 'package:jhs_pop/util/checkout_order.dart';
import 'package:jhs_pop/util/constants.dart';
import 'package:jhs_pop/util/navigation_service.dart';
import 'package:jhs_pop/widgets/counter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  List<CheckoutOrder> _buttons = [];
  final Map<CheckoutOrder, int> _orders = {};

  var sName = "";
  var sGender = "";

  Future<void> ss(isFirstTime) async {
    var sharedPreferences = await SharedPreferences.getInstance();
    if (isFirstTime) {
      // Show user info dialog
      await showDialog(
        context: NavigationService.navigatorKey.currentContext!,
        builder: (context) {
          return UserInfoDialog(
            onSubmitted: (name, gender) async {
              sharedPreferences.setBool("isFirstTime", false);
              sharedPreferences.setString("name", name);
              sharedPreferences.setString("gender", gender);

              sName = name;
              sGender = gender;

              // Handle user information
              debugPrint('Name: $name, Gender: $gender');
              // Continue with app initialization or navigation

              setState(() {});
            },
          );
        },
      );
    }
  }

  Future<void> init() async {
    final sharedPreferences = await SharedPreferences.getInstance();

    bool isFirstTime = sharedPreferences.getBool("isFirstTime") ?? true;

    if (isFirstTime) {
      await ss(isFirstTime);
      return;
    }

    sName = sharedPreferences.getString("name") ?? "";
    sGender = sharedPreferences.getString("gender") ?? "";

    setState(() {});
  }

  @override
  void initState() {
    init();
    super.initState();

    dbReady.future.then((_) {
      db.query('checkouts').then((rows) {
        setState(() {
          _buttons = rows.map((row) => CheckoutOrder.fromMap(row)).toList();
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Point of Payment'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                children: List.generate(_buttons.length, (index) {
                  final button = _buttons[index];
                  final background = DecorationImage(
                    image: AssetImage(button.image),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(
                          0.3), // Adjust the opacity value here (0.5 for 50% opacity)
                      BlendMode
                          .darken, // You can change the blend mode as needed
                    ),
                  );

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_orders.containsKey(button)) {
                          // If the item exists, increment its quantity
                          _orders[button] = _orders[button]! + 1;
                        } else {
                          // If the item does not exist, add it to the map with a quantity of 1
                          _orders[button] = 1;
                        }

                        // _orders.putIfAbsent(button, () => 1);
                      });
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          image: background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(children: [
                          Container(
                            decoration: BoxDecoration(
                              // borderRadius: BorderRadius.circular(12),
                              gradient: RadialGradient(radius: 1.5, colors: [
                                Colors.black.withOpacity(0.25),
                                Colors.transparent
                              ]),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  button.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.035,
                                  ),
                                ),
                                Text(
                                  '\$${button.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.035,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                  );
                }),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                      onPressed: () async {
                        if (_orders.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Select Item to Continue")));
                          return;
                        }

                        // print(_orders);
                        Navigator.pushNamed(context, '/payment',
                            arguments: _orders);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Complete Order')),
                  const SizedBox(width: 20),
                  TextButton.icon(
                      onPressed: () async {
                        await context.showConfirmationDialog(
                          title: 'Restart Order',
                          message:
                              'Are you sure you want to restart the order?',
                          confirmText: 'Restart',
                          onConfirm: () {
                            setState(() {
                              _orders.clear();
                            });
                          },
                        );
                      },
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Restart Order')),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders.keys.elementAt(index);

                    return Row(
                      children: [
                        Expanded(
                          child: ListTileCounter(
                            order: order,
                            count: _orders,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              context.showConfirmationDialog(
                                title: 'Remove Item',
                                message:
                                    'Are you sure you want to remove this item?',
                                confirmText: 'Remove',
                                onConfirm: () {
                                  setState(() {
                                    _orders.remove(order);
                                  });
                                },
                              );
                            });
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.blue,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Point of Payment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      sName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      sGender,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              // ListTile(
              //   title: const Text('Teacher Orders Screen'),
              //   onTap: () {
              //     Navigator.pushReplacementNamed(context, '/home');
              //   },
              // ),
              ListTile(
                title: const Text('Edit Options'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/edit_options',
                      arguments: _buttons);
                },
              ),
              ListTile(
                title: const Text('Orders'),
                onTap: () async {
                  Navigator.of(context).pushNamed('/cashierOrders');
                },
              ),
              ListTile(
                title: const Text('Credit Card Setup'),
                onTap: () async {
                  Navigator.of(context).pushNamed('/setting');
                },
              ),
              ListTile(
                title: const Text('Change Name'),
                onTap: () async {
                  ss(true);
                },
              ),
              ListTile(
                title: const Text('Make Default Screen'),
                onTap: () {
                  SharedPreferences.getInstance().then((prefs) {
                    prefs.setString('default_screen', '/cashier');
                    context.showSnackBar(
                        message: 'Default screen set to cashier mode');
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          ),
        ));
  }
}
