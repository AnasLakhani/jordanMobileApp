import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:jhs_pop/main.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String money = '';
  String cvvCode = '';
  bool isCvvFocused = false;

  void onCreditCardModelChange(CreditCardModel data) {
    setState(() {
      cardNumber = data.cardNumber;
      expiryDate = data.expiryDate;
      cardHolderName = data.cardHolderName;
      cvvCode = data.cvvCode;
      isCvvFocused = data.isCvvFocused;
    });
  }

  bool isUpdate = false;

  // Create a GlobalKey<FormFieldState<String>>
  final GlobalKey<FormFieldState<String>> cardHolderKey =
      GlobalKey<FormFieldState<String>>();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Credit Card"),
      ),
      body: Column(
        children: <Widget>[
          CreditCardWidget(
            cardNumber: cardNumber,
            expiryDate: expiryDate,
            cardHolderName: cardHolderName,
            cvvCode: cvvCode,
            showBackView: isCvvFocused,
            onCreditCardWidgetChange: (CreditCardBrand creditCardBrand) {},
          ),
          // Text(cardNumber)
          // ,
          Visibility(
            visible: isUpdate,
            child: Column(
              children: [
                CreditCardForm(
                  cardNumber: cardNumber,
                  expiryDate: expiryDate,
                  cardHolderName: cardHolderName,
                  cvvCode: cvvCode,
                  onCreditCardModelChange: onCreditCardModelChange,
                  formKey: formKey,
                ),
                // const SizedBox(
                //   height: 20,
                // ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    initialValue: money,
                    decoration: const InputDecoration(labelText: 'Money'),
                    onChanged: (value) {
                      setState(() {
                        money = value;
                      });
                    },
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (isUpdate == false) {
                isUpdate = true;
                setState(() {});
                return;
              }
              // isUpdate = false;
              setState(() {});

              if (money.isEmpty || cardHolderName.isEmpty) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text("Enter all Fields")));
                return;
              }
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();

                // Save data to SQLite
                Map<String, dynamic> cardData = {
                  'cardNumber': cardNumber,
                  'expiryDate': expiryDate,
                  'cardHolderName': cardHolderName,
                  'cvvCode': cvvCode,
                  'money': money
                };

                await db.insert('credit_cards', cardData);

                print('Card saved to database');
              } else {
                print('Form is invalid');
              }
            },
            child: Text(isUpdate ? 'Submit' : 'Update'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _creditCards = [];

  @override
  void initState() {
    _fetchCreditCardData();
    super.initState();
  }

  Future<void> _fetchCreditCardData() async {
    List<Map<String, dynamic>> cards = await getCreditCards();

    if (cards.isNotEmpty) {
      var card = cards.last;
      cardNumber = card['cardNumber'];
      expiryDate = card['expiryDate'];
      cardHolderName = card['cardHolderName'];
      cvvCode = card['cvvCode'];
      money = card['money'];
    }

    setState(() {});

    onCreditCardModelChange(CreditCardModel(
        cardNumber, expiryDate, cardHolderName, cvvCode, isCvvFocused));
  }

  Future<List<Map<String, dynamic>>> getCreditCards() async {
    return await db.query('credit_cards');
  }

  Future<int> insertCard(Map<String, dynamic> card) async {
    return await db.insert('credit_cards', card);
  }
}
