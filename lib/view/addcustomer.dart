import 'package:UltimateSolutions/view/salesnav.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:UltimateSolutions/view/salesnav.dart';

class AddCustomer extends StatefulWidget {
  final String userEmail;

  const AddCustomer({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<AddCustomer> createState() => _AddCustomerState();
}

class _AddCustomerState extends State<AddCustomer> {
  late TextEditingController _customerCodeController;
  TextEditingController _customerNameController = TextEditingController();
  TextEditingController _contactPersonController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _mobileNumberController = TextEditingController();
  TextEditingController _telephoneNumberController = TextEditingController();
  TextEditingController _vtNumberController = TextEditingController();
  TextEditingController _deliveryLocationController = TextEditingController();

  List<String> _customerTypeOptions = ['Cash', 'Credit', 'Bank Transfer', 'Performa Invoice'];
  String _selectedCustomerType = 'Cash';

  // Define location options
  List<String> _locationOptions = ['Riyadh', 'Jeddah', 'Dammam'];
  String _selectedLocation = 'Dammam';

  int _currentCustomerCode = 0;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _customerCodeController = TextEditingController();
    _loadLastCustomerCode();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
  }

  Future<void> _loadLastCustomerCode() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String lastCustomerCode = querySnapshot.docs.first['customerCode'];
        setState(() {
          _customerCodeController.text = lastCustomerCode;
        });
      }
    } catch (e) {
      print('Error fetching last customer code: $e');
    }
  }

  Future<void> _submitCustomerData() async {
    try {
      // Retrieve values from controllers
      String customerCode = _customerCodeController.text;
      String customerName = _customerNameController.text;
      String contactPerson = _contactPersonController.text;
      String address = _addressController.text;
      String mobileNumber = _mobileNumberController.text;
      String telephoneNumber = _telephoneNumberController.text;
      String vtNumber = _vtNumberController.text;
      String customerType = _selectedCustomerType;
      String deliveryLocation = _deliveryLocationController.text;

      // Add customer data to Firestore
      await FirebaseFirestore.instance.collection('customers').add({
        'customerCode': customerCode,
        'customerName': customerName,
        'contactPerson': contactPerson,
        'address': address,
        'mobileNumber': mobileNumber,
        'telephoneNumber': telephoneNumber,
        'vtNumber': vtNumber,
        'customerType': customerType,
        'deliveryLocation': deliveryLocation,
        'createdAt': FieldValue.serverTimestamp(),
      });
      Navigator.push(context, MaterialPageRoute(builder: (context) => SalesNav(userEmail: widget.userEmail)));

    } catch (e) {
      print('Error submitting customer data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70.0),
          child: AppBar(
            title: Text("Customer", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 30)),
            centerTitle: true,
            backgroundColor: Color(0xff0C88BD),
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
              buildDropdownMenu(
                labelText: 'Select Location',
                value: _selectedLocation,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLocation = newValue ?? '';
                  });
                },
                items: _locationOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              buildTextField('Customer Code', _customerCodeController),
              buildTextField('Enter Customer Name', _customerNameController),
              buildTextField('Enter Contact Person', _contactPersonController),
              buildTextField('Enter Address', _addressController),
              buildTextField('Enter Mobile No.', _mobileNumberController),
              buildTextField('Enter Telephone No.', _telephoneNumberController),
              buildTextField('Enter Vat No.', _vtNumberController),
              buildDropdownMenu(
                labelText: 'Type of Customer',
                value: _selectedCustomerType,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCustomerType = newValue ?? '';
                  });
                },
                items: _customerTypeOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
              ),
              buildTextField('Enter Delivery Location', _deliveryLocationController),

              SizedBox(height: 10),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll(Colors.blueAccent)
                ),
                onPressed: _submitCustomerData,
                child: Text('Submit',style: TextStyle(color: Colors.white)),
              )
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

  Widget buildDropdownMenu({required String labelText, required String value, required void Function(String?) onChanged, required List<DropdownMenuItem<String>> items}) {
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
