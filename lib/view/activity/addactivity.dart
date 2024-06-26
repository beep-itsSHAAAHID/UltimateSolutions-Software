import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:UltimateSolutions/view/products/productselectionpage.dart';
import 'package:UltimateSolutions/view/customer/customerselection.dart';
import 'package:UltimateSolutions/view/salesnav.dart';

class AddActivity extends StatefulWidget {
  final String userEmail;

  const AddActivity({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<AddActivity> createState() => _AddActivityState();
}

class _AddActivityState extends State<AddActivity> {
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _customerRemarksController = TextEditingController();
  final TextEditingController _salesmanRemarksController = TextEditingController();
  final TextEditingController _activityController = TextEditingController();
  bool _sampleCollection = false;
  bool _sampleDelivery = false;
  bool _sales = false;
  bool _followUp = false;
  bool _delivery = false;
  bool _newCustomer = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Activity'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            buildCheckbox("Sample Collection", _sampleCollection, 'Sample Collection'),
            buildCheckbox("Sample Delivery", _sampleDelivery, 'Sample Delivery'),
            buildCheckbox("Delivery", _delivery, 'Delivery'),
            buildCheckbox("New Customer", _newCustomer, 'New Customer'),
            buildCheckbox("Sales", _sales, 'Sales'),
            buildCheckbox("Follow-up", _followUp, 'Follow-up'),
            buildTextField('Activity', _activityController, editable: !_sampleCollection && !_sampleDelivery && !_sales && !_followUp
                && !_delivery && !_newCustomer) ,
            buildTextField('Customer Name', _customerNameController),
            buildTextField('Customer Remarks', _customerRemarksController),
            buildTextField('Salesman Remarks', _salesmanRemarksController),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await addActivityToFirestore();
                navigateToSalesNav();
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String labelText, TextEditingController controller, {VoidCallback? onTap, bool editable = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        onTap: onTap,
        enabled: editable,
        decoration: InputDecoration(
          labelText: labelText,
          suffixIcon: onTap != null ? Icon(Icons.search) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
      ),
    );
  }

  Widget buildCheckbox(String label, bool value, String checkboxValue) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (bool? newValue) {
            setState(() {
              // Ensure only one checkbox is selected
              _sampleCollection = false;
              _sampleDelivery = false;
              _sales = false;
              _followUp = false;
              _delivery = false;
              _newCustomer = false;

              // Update the selected checkbox
              if (newValue != null) {
                if (label == "Sample Collection") {
                  _sampleCollection = newValue;
                } else if (label == "Sample Delivery") {
                  _sampleDelivery = newValue;
                } else if (label == "Sales") {
                  _sales = newValue;
                } else if (label == "Follow-up") {
                  _followUp = newValue;
                }
                else if (label == "Delivery") {
                  _delivery = newValue;
                }
                else if (label == "New Customer") {
                  _newCustomer = newValue;
                }
              }

              // Update the "Activity" text field based on the selected checkbox
              if (newValue == true) {
                _activityController.text = checkboxValue;
              } else {
                _activityController.text = '';
              }
            });
          },
        ),
        Text(label),
      ],
    );
  }


  void navigateToSalesNav() {
    String userEmail = widget.userEmail; // Store userEmail from widget
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SalesNav(userEmail: userEmail),
      ),
    );
  }


  Future<void> addActivityToFirestore() async {
    try {
      // Extract the username from the email
      String username = extractNameFromEmail(widget.userEmail);

      print('Username: $username');

      // Create a Firestore reference
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Create a new document in the 'activities' collection
      await firestore.collection('activities').add({
        'customerName': _customerNameController.text,
        'activity': _activityController.text,
        'customerRemarks': _customerRemarksController.text,
        'salesmanRemarks': _salesmanRemarksController.text,
        'username': username,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Activity added to Firestore');
    } catch (e) {
      print('Error adding activity to Firestore: $e');
    }
  }

  // Function to extract user name from email
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


