import 'package:UltimateSolutions/home_v2/homepagev2.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../salesnav.dart';

class AddSupplier extends StatefulWidget {
  final String userEmail;

  const AddSupplier({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<AddSupplier> createState() => _AddSupplierState();
}

class _AddSupplierState extends State<AddSupplier> {
  late TextEditingController _supplierCodeController;
  TextEditingController _supplierNameController = TextEditingController();
  TextEditingController _contactPersonController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _mobileNumberController = TextEditingController();
  TextEditingController _telephoneNumberController = TextEditingController();
  TextEditingController _vatNumberController = TextEditingController();
  TextEditingController _emailController = TextEditingController();

  List<String> _supplierTypeOptions = ['Local', 'International'];
  String _selectedSupplierType = 'Local';

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _supplierCodeController = TextEditingController();
    _loadLastSupplierCode();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
  }

  Future<void> _loadLastSupplierCode() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('suppliers')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String lastSupplierCode = querySnapshot.docs.first['supplierCode'];
        setState(() {
          _supplierCodeController.text = lastSupplierCode;
        });
      }
    } catch (e) {
      print('Error fetching last supplier code: $e');
    }
  }

  Future<void> _submitSupplierData() async {
    try {
      // Retrieve values from controllers
      String supplierCode = _supplierCodeController.text;
      String supplierName = _supplierNameController.text;
      String contactPerson = _contactPersonController.text;
      String address = _addressController.text;
      String mobileNumber = _mobileNumberController.text;
      String telephoneNumber = _telephoneNumberController.text;
      String vatNumber = _vatNumberController.text;
      String supplierType = _selectedSupplierType;
      String email = _emailController.text;

      // Add supplier data to Firestore, including the userEmail of the person who added the supplier
      await FirebaseFirestore.instance.collection('suppliers').add({
        'supplierCode': supplierCode,
        'supplierName': supplierName,
        'contactPerson': contactPerson,
        'address': address,
        'mobileNumber': mobileNumber,
        'telephoneNumber': telephoneNumber,
        'vatNumber': vatNumber,
        'supplierType': supplierType,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'addedBy': widget.userEmail,  // Include the user email of the person adding the supplier
      });

      Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));

    } catch (e) {
      print('Error submitting supplier data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70.0),
          child: AppBar(
            title: Text("Supplier", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 30)),
            centerTitle: true,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(40),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildTextField('Supplier Code', _supplierCodeController),
              buildTextField('Enter Supplier Name', _supplierNameController),
              buildTextField('Enter Contact Person', _contactPersonController),
              buildTextField('Enter Address', _addressController),
              buildTextField('Enter Email', _emailController),
              buildTextField('Enter Mobile No.', _mobileNumberController),
              buildTextField('Enter Telephone No.', _telephoneNumberController),
              buildTextField('Enter VAT No.', _vatNumberController),
              buildDropdownMenu(
                labelText: 'Type of Supplier',
                value: _selectedSupplierType,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSupplierType = newValue ?? '';
                  });
                },
                items: _supplierTypeOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.blueAccent),
                ),
                onPressed: _submitSupplierData,
                child: Text('Submit', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String labelText, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
      ),
    );
  }

  Widget buildDropdownMenu({
    required String labelText,
    required String value,
    required void Function(String?) onChanged,
    required List<DropdownMenuItem<String>> items,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        items: items,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
      ),
    );
  }
}
