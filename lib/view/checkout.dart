import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


import 'SalesHome.dart';
import 'login.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({Key? key}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  TextEditingController _closingOdometerController = TextEditingController();
  TextEditingController _parkedLocationController = TextEditingController();
  TextEditingController _jobRemarksController = TextEditingController();
  TextEditingController _petrolAmountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Checkout'),
          centerTitle: true,
          backgroundColor: Color(0xff0C88BD),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildTextField(
                'Enter Closing Odometer',
                'Enter closing odometer',
                _closingOdometerController,
              ),
              SizedBox(height: 10),
              buildTextField(
                'Enter Parked Location',
                'Enter parked location',
                _parkedLocationController,
              ),
              SizedBox(height: 10),
              buildTextField(
                'Enter Job Remarks',
                'Enter job remarks',
                _jobRemarksController,
              ),
              SizedBox(height: 10),
              buildTextField(
                'Enter Petrol Amount',
                'Enter petrol amount',
                _petrolAmountController,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  submitData();
                },
                child: Text('Submit'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll(Colors.red)
                ),
                onPressed: () {
                  logout();
                },
                child: Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String labelText, String hintText, TextEditingController controller) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 3,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(35),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(35),
            borderSide: BorderSide(
              color: Colors.blue,
              width: 2.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(35),
            borderSide: BorderSide(
              color: Colors.grey,
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }

  Future<void> submitData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;
        String userName = extractNameFromEmail(user.email ?? 'unknown@example.com');

        // Create a map with the checkout data
        Map<String, dynamic> data = {
          'userId': userId,
          'userName': userName,
          'timestamp': FieldValue.serverTimestamp(),
          'closingOdometer': _closingOdometerController.text,
          'parkedLocation': _parkedLocationController.text,
          'jobRemarks': _jobRemarksController.text,
          'petrolAmount': _petrolAmountController.text,
        };

        // Add data to the 'checkout' collection
        await FirebaseFirestore.instance.collection('checkout').add(data);

        Navigator.push(context, MaterialPageRoute(builder: (context) => SalesHome()));
        print('Data submitted successfully!');
      }
    } catch (e) {
      print('Error submitting data: $e');
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Login()));
  }

  String extractNameFromEmail(String email) {
    List<String> parts = email.split('@');
    if (parts.length == 2) {
      String name = parts[0];
      List<String> nameParts = name.split('.');
      nameParts = nameParts.map((part) => part[0].toUpperCase() + part.substring(1)).toList();
      return nameParts.join(' ');
    }
    return 'Unknown';
  }
}
