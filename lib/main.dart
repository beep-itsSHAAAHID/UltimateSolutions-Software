import 'package:UltimateSolutions/view/SalesHome.dart';
import 'package:UltimateSolutions/view/invoice.dart';
import 'package:UltimateSolutions/view/invoicereceipt.dart';
import 'package:UltimateSolutions/view/login.dart';
import 'package:UltimateSolutions/view/salesnav.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? userEmail = prefs.getString('userEmail');
  String? userRole = prefs.getString('userRole');


  print('userEmail: $userEmail');
  print('userRole: $userRole');

  runApp(MyApp(userEmail: userEmail, userRole: userRole));
}

class MyApp extends StatefulWidget {
  final String? userEmail;
  final String? userRole;

  const MyApp({Key? key, this.userEmail, this.userRole}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var auth = FirebaseAuth.instance;

  var isLogin = false;

  checkIfLogin() async {
    auth.authStateChanges().listen((User? user) {
      if (user != null && mounted) {
        print('User is logged in');
        setState(() {
          isLogin = true;
        });
      } else {
        print('User is not logged in');
        setState(() {
          isLogin = false;
        });
      }
    });
  }


  @override
  void initState() {
    checkIfLogin();
    if (widget.userEmail == false || widget.userRole == false) {
      // Redirect to login page or handle appropriately
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => Login()));
    }
    super.initState();
  }


  @override
  Widget build(BuildContext context) {

   // return MaterialApp(
    //  home: InvoiceReceipt(),

    if (isLogin) {
      // User is authenticated
      // You may also check the user role and navigate accordingly
      if (widget.userRole == 'admin') {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Ultimate Solutions',
          home: Invoice (userEmail: widget.userEmail ?? ""),
         // home: SalesNav(userEmail: widget.userEmail ?? ""),
        );
      } else {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Ultimate Solutions',
          home: SalesNav(userEmail: widget.userEmail ?? ""),
        );
      }
    } else {
      // User is not authenticated
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ultimate Solutions',
        home: Login(),
      );
    }
  }
}
