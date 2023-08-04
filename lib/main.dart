import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey =
  "pk_test_51Nb5XJFfCVzCyW7fLv23btcz3DRZmB9yyk5IxB3KiVVuHi1FDttU3feLJ3LAcYXiWEQ2M9EmWK8JAy1eZFH6Tpkg00lOEbXjmh";
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<String, dynamic>? paymentIntent;

  Future<void> makePayment() async {
    try {
      paymentIntent = await createPaymentIntent('100', 'USD');

      await Stripe.instance
          .initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            customFlow: true,
              paymentIntentClientSecret: paymentIntent![
              'client_secret'],
              style: ThemeMode.light,
              merchantDisplayName: 'Ikay'))
          .then((value) {
      });

      displayPaymentSheet();
    } catch (err) {
      throw Exception(err);
    }
  }

  calculateAmount(String amount) {
    final calculatedAmout = (int.parse(amount)) * 100;
    return calculatedAmout.toString();
  }

  createPaymentIntent(String amount, String currency) async {
    try {
      //Request body
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currency,
      };

      //Make post request to Stripe
      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer sk_test_51Nb5XJFfCVzCyW7fZNEGABaMZXZVB2aQQ6cfqhE3WgcbquTULhDEbck2CZ6xLHr0U8yliGr3FhUFE8W6hXyz2UN500YKSybepN',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      print(response.body);
      return json.decode(response.body);
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) async {

        await Stripe.instance.confirmPaymentSheetPayment();

        var paymentIntentResult = await Stripe.instance.retrievePaymentIntent(paymentIntent!['client_secret']);
        print(paymentIntentResult.status);
     if(paymentIntentResult.status==PaymentIntentsStatus.Succeeded){
       showDialog(
           context: context,
           builder: (_) =>
           const AlertDialog(
             content: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Icon(
                   Icons.check_circle,
                   color: Colors.green,
                   size: 100.0,
                 ),
                 SizedBox(height: 10.0),
                 Text("Payment Successful!"),
               ],
             ),
           ));

       setState(() {
         paymentIntent = null;
       });

     }else if(paymentIntentResult.status==PaymentIntentsStatus.Canceled){
       const AlertDialog(
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Row(
               children: [
                 Icon(
                   Icons.cancel,
                   color: Colors.red,
                 ),
                 Text("Payment canceled"),
               ],
             ),
           ],
         ),
       );
     }


      }).onError((error, stackTrace) {
        print("onerror $error $stackTrace");
      });
    } on StripeException catch (e) {
      print('Error is:---> $e');
      const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cancel,
                  color: Colors.red,
                ),
                Text("Payment Failed"),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      print('stripe $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await makePayment();
          },
          child: const Text("Make Payment"),
        ),
      ),
    );
  }
}
