import 'package:UltimateSolutions/view/customer/customers.dart';
import 'package:UltimateSolutions/view/login.dart';
import 'package:UltimateSolutions/view/salesnav.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:UltimateSolutions/api/google_sheets_api.dart';

import 'home_v2/homepagev2.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppInitializer());
}

class AppInitializer extends StatefulWidget {
  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitializing = true;
  String? userEmail;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('Initializing Firebase...');
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      print('Firebase initialized successfully.');

      print('Initializing SharedPreferences...');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      print('SharedPreferences initialized successfully.');

      userEmail = prefs.getString('userEmail');
      userRole = prefs.getString('userRole');

      // Debug print statements
      print('User Email from SharedPreferences: $userEmail');
      print('User Role from SharedPreferences: $userRole');

      await init();
    } catch (e) {
      print('Error during initialization: $e');
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return MaterialApp(
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MyApp(userEmail: userEmail, userRole: userRole);
  }
}

class MyApp extends StatelessWidget {
  final String? userEmail;
  final String? userRole;

  const MyApp({Key? key, this.userEmail, this.userRole}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      debugShowCheckedModeBanner: false,
      title: 'Ultimate Solutions',

      // home: HomePage(),
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
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ); // Handle loading state
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is authenticated
          if (userRole == 'admin') {
            return HomePage();
          } else {
            return HomePage();
          }
        } else {
          // User is not authenticated
          if (userEmail != null && userRole != null) {
            // User information retrieved from SharedPreferences
            return Login();
          } else {
            // Both userEmail and userRole are null, indicating the user has not logged in
            return Login();
          }
        }
      },
    );
  }
}
