import 'package:UltimateSolutions/view/invoice/invoicereceipt.dart';
import 'package:UltimateSolutions/view/login.dart';
import 'package:UltimateSolutions/view/quotation/rfqreceipt.dart';
import 'package:UltimateSolutions/view/salesnav.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize SharedPreferences
  SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    print('Error initializing SharedPreferences: $e');
    return;
  }

  // Retrieve user email and role from SharedPreferences
  String? userEmail = prefs.getString('userEmail');
  String? userRole = prefs.getString('userRole');

  // Debug print statements
  print('User Email from SharedPreferences: $userEmail');
  print('User Role from SharedPreferences: $userRole');

  runApp(MyApp(userEmail: userEmail, userRole: userRole));
}



class MyApp extends StatelessWidget {
  final String? userEmail;
  final String? userRole;

  const MyApp({Key? key, this.userEmail, this.userRole}) : super(key: key);


//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Ultimate Solutions',
//       home: InvoiceReceipt());
//   }
// }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ultimate Solutions',
      home: AuthenticationWrapper(userEmail: userEmail, userRole: userRole),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  final String? userEmail;
  final String? userRole;

  const AuthenticationWrapper({Key? key, this.userEmail, this.userRole}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;

    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Handle loading state
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is authenticated
          if (userRole == 'admin') {
            return SalesNav(userEmail: userEmail ?? "");
          } else {
            return SalesNav(userEmail: userEmail ?? "");
          }
        } else {
          // User is not authenticated
          return Login();
        }
      },
    );
  }
}
