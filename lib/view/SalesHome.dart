import 'package:UltimateSolutions/view/salesnav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class SalesHome extends StatefulWidget {

  const SalesHome({Key? key, this.userEmail=''}) : super(key: key);

  final String userEmail;

  @override
  State<SalesHome> createState() => _SalesHomeState();
}

class _SalesHomeState extends State<SalesHome> {
  bool _checkWheels = false;
  bool _checkOilWater = false;
  bool _checkBrakes = false;

  TextEditingController _startingOdometerController = TextEditingController();
  TextEditingController _startingLocationController = TextEditingController();
  TextEditingController _nameController = TextEditingController();

  DateTime _currentDateTime = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi User!'),
        centerTitle: true,
        backgroundColor: Color(0xff0C88BD),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Daily Check-in!',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 20),
              buildCheckboxTile('Check Wheels', _checkWheels, (value) {
                setState(() {
                  _checkWheels = value!;
                });
              }),
              buildCheckboxTile('Check Oil/Water', _checkOilWater, (value) {
                setState(() {
                  _checkOilWater = value!;
                });
              }),
              buildCheckboxTile('Check Brakes', _checkBrakes, (value) {
                setState(() {
                  _checkBrakes = value!;
                });
              }),
              SizedBox(height: 20),
              buildTextField(
                'Starting Odometer',
                'Enter starting odometer',
                _startingOdometerController,
              ),
              SizedBox(height: 10),
              buildTextField(
                'Starting Location',
                'Enter starting location',
                _startingLocationController,
              ),

              SizedBox(height: 16),
              ElevatedButton(
                onPressed: canSubmit() ? handleSubmit : null,
                child: Text('Submit'),
              ),
              SizedBox(height: 100,),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SalesNav(userEmail:widget.userEmail,)
                  ));
                },
                child: Text('Skip'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCheckboxTile(String title, bool value,
      ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      value: value,
      title: Text(
        title,
        style: TextStyle(fontSize: 20),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: onChanged,
    );
  }

  Widget buildTextField(String labelText, String hintText,
      TextEditingController controller) {
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
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  bool canSubmit() {
    return _checkWheels &&
        _checkOilWater &&
        _checkBrakes &&
        _startingOdometerController.text.isNotEmpty &&
        _startingLocationController.text.isNotEmpty ;
  }

  void handleSubmit() async {
    if (canSubmit()) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Get current user ID
          String userId = user.uid;

          // Extract name from email
          String userEmail = user.email ?? '';
          String userName = extractNameFromEmail(userEmail);

          // Get current date and time
          DateTime now = DateTime.now();
          String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

          // Prepare data for Firestore
          Map<String, dynamic> data = {
            'userId': userId,
            'userName': userName,
            'startingOdometer': _startingOdometerController.text,
            'startingLocation': _startingLocationController.text,
            'timestamp': formattedDate,
          };

          // Add data to Firestore
          await FirebaseFirestore.instance
              .collection('daily_check_ins')
              .add(data);

          // Navigate to SalesNav after submitting
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SalesNav(userEmail: userEmail,)),
          );

          print('Submitted!');
        }
      } catch (e) {
        print('Error submitting data: $e');
      }
    }
  }

  String extractNameFromEmail(String email) {
    List<String> parts = email.split('@');
    if (parts.length == 2) {
      String name = parts[0];
      List<String> nameParts = name.split('.');
      nameParts =
          nameParts.map((part) => part[0].toUpperCase() + part.substring(1)).toList();
      return nameParts.join(' ');
    }
    return '';
  }
}
