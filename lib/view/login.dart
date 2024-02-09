import 'package:UltimateSolutions/view/salesnav.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String selectedRole = '';
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xff0C88BD),
          title: Text(
            'LOGIN TO CONTINUE',
            style: TextStyle(fontSize: 30),
          ),
          centerTitle: true,
          toolbarHeight: 100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(40),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildRoleOption('admin', 'Admin', 'lib/assets/admin.png'),
                  SizedBox(width: 50),
                  buildRoleOption('user', 'Salesman', 'lib/assets/salesman.png'),
                ],
              ),
              SizedBox(height: 50),
              Card(
                margin: EdgeInsets.symmetric(horizontal: 20),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          labelText: selectedRole == 'admin' ? 'Admin Username' : 'Salesman Username',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await _handleLogin();
                        },
                        child: Text('Login'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blue,
                          onPrimary: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: usernameController.text.trim(),
        password: passwordController.text,
      );

      // Authentication successful
      print('User ID: ${userCredential.user?.uid}');
      print('Email: ${userCredential.user?.email}');

      // Get SharedPreferences instance
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userEmail = prefs.getString('userEmail');
      String? userRole = prefs.getString('userRole');
      print('User email from SharedPreferences: $userEmail');
      print('User role from SharedPreferences: $userRole');

      // Check if the selected role matches the role associated with the user's email
      if (!isRoleMatching(selectedRole, userCredential.user?.email)) {
        // Role mismatch, log out the user and show an error message
        await _auth.signOut();
        print('Role mismatch: User does not have the selected role');
        // Show an error message to the user
        showSnackbar('Role mismatch: User does not have the selected role');
        return;
      }

      // Navigate based on the role
      navigateToHomePage(userCredential.user?.email ?? '');

      // Show a success message
      showSnackbar('Login successful');

    } catch (e) {
      // Authentication failed
      print('Authentication failed: $e');
      // Show an error message to the user
      showSnackbar('Authentication failed: $e');
    }
  }

  Widget buildRoleOption(String role, String title, String imagePath) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = role;
        });
      },
      child: Card(
        elevation: selectedRole == role ? 10 : 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          height: 150,
          width: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                imagePath,
                height: 80,
                width: 80,
              ),
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void navigateToHomePage(String? userEmail) {
    if (userEmail != null) {
      if (isRoleMatching('admin', userEmail)) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SalesNav(userEmail: userEmail,)));
      } else if (isRoleMatching('user', userEmail)) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SalesNav(userEmail: userEmail,)));
      }
    }
  }


  void showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

bool isRoleMatching(String selectedRole, String? userEmail) {
  // Check if the selected role matches the role in the user's email domain
  if (selectedRole == 'admin' && userEmail?.contains('@admin.ultimategcc.com') == true) {
    return true;
  } else if (selectedRole == 'user' && userEmail?.contains('@salesman.ultimategcc.com') == true) {
    return true;
  }
  return false;
}
