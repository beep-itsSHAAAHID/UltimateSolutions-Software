import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../salesnav.dart';
import 'customers.dart';


class AddCustomer extends StatefulWidget {
  final String userEmail;
  final Customers? customer;
  final String? documentId;

  const AddCustomer({Key? key, required this.userEmail, this.customer, this.documentId}) : super(key: key);

  @override
  State<AddCustomer> createState() => _AddCustomerState();
}

class _AddCustomerState extends State<AddCustomer> {
  late TextEditingController _customerCodeController;
  TextEditingController _customerNameController = TextEditingController();
  TextEditingController _arabicNameController = TextEditingController();
  TextEditingController _contactPersonController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _mobileNumberController = TextEditingController();
  TextEditingController _telephoneNumberController = TextEditingController();
  TextEditingController _vtNumberController = TextEditingController();
  TextEditingController _deliveryLocationController = TextEditingController();
  TextEditingController _emailController = TextEditingController();

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

    if (widget.customer != null) {
      _customerCodeController = TextEditingController(text: widget.customer!.customerCode);
      _customerNameController.text = widget.customer!.customerName;
      _arabicNameController.text = widget.customer!.arabicName;
      _addressController.text = widget.customer!.address;
      _mobileNumberController.text = widget.customer!.mobileNumber;
      _telephoneNumberController.text = widget.customer!.telephoneNumber;
      _vtNumberController.text = widget.customer!.vtNumber;
      _deliveryLocationController.text = widget.customer!.deliveryLocation;
      _emailController.text = widget.customer!.email;

      // Ensure the selected value is in the list
      _selectedCustomerType = _customerTypeOptions.contains(widget.customer!.customerType)
          ? widget.customer!.customerType
          : _customerTypeOptions[0];

      _selectedLocation = _locationOptions.contains(widget.customer!.deliveryLocation)
          ? widget.customer!.deliveryLocation
          : _locationOptions[0];
    } else {
      _customerCodeController = TextEditingController();
      _loadLastCustomerCode();
    }
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
      String customerCode = _customerCodeController.text;
      String customerName = _customerNameController.text;
      String arabicName = _arabicNameController.text;
      String contactPerson = _contactPersonController.text;
      String address = _addressController.text;
      String mobileNumber = _mobileNumberController.text;
      String telephoneNumber = _telephoneNumberController.text;
      String vtNumber = _vtNumberController.text;
      String customerType = _selectedCustomerType;
      String deliveryLocation = _deliveryLocationController.text;
      String email = _emailController.text;

      // Check if customer with the same customerCode exists
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .where('customerCode', isEqualTo: customerCode)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // If customer exists, update the document
        DocumentSnapshot existingCustomer = querySnapshot.docs.first;
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(existingCustomer.id)
            .update({
          'customerName': customerName,
          'arabicName': arabicName,
          'address': address,
          'mobileNumber': mobileNumber,
          'telephoneNumber': telephoneNumber,
          'vtNumber': vtNumber,
          'customerType': customerType,
          'deliveryLocation': deliveryLocation,
          'email': email,
          'addedBy': widget.userEmail,
        });
      } else {
        // If customerCode doesn't exist, add a new customer
        await FirebaseFirestore.instance.collection('customers').add({
          'customerCode': customerCode,
          'arabicName': arabicName,
          'customerName': customerName,
          'contactPerson': contactPerson,
          'address': address,
          'mobileNumber': mobileNumber,
          'telephoneNumber': telephoneNumber,
          'vtNumber': vtNumber,
          'customerType': customerType,
          'deliveryLocation': deliveryLocation,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'addedBy': widget.userEmail,
        });
      }

      // Navigate to the next page or screen
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SalesNav(userEmail: widget.userEmail)));
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
              buildTextField('Enter Arabic Name', _arabicNameController),
              buildTextField('Enter Contact Person', _contactPersonController),
              buildTextField('Enter Address', _addressController),
              buildTextField('Enter Email', _emailController),
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
                  backgroundColor: MaterialStateProperty.all(Colors.blueAccent),
                ),
                onPressed: _submitCustomerData,
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
