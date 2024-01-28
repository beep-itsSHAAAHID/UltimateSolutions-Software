import 'package:UltimateSolutions/view/productselectionpage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customerselection.dart';
import 'salesnav.dart';

class Rfq extends StatefulWidget {
  final String userEmail;

  const Rfq({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<Rfq> createState() => _RfqState();
}

class _RfqState extends State<Rfq> {
  TextEditingController _customerCodeController = TextEditingController();
  TextEditingController _customerNameController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _vatNoController = TextEditingController();
  TextEditingController _entryDateController = TextEditingController();
  TextEditingController _quotationNoController = TextEditingController();
  TextEditingController _salesmanController = TextEditingController();
  TextEditingController _enquiryReferenceController = TextEditingController();
  TextEditingController _remarksController = TextEditingController();

  List<Map<String, TextEditingController>> products = [
    {'code': TextEditingController(), 'name': TextEditingController()},
  ];

  TextEditingController _validityController = TextEditingController();
  TextEditingController _deliveryTimeController = TextEditingController();
  TextEditingController _placeOfDeliveryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70.0),
          child: AppBar(
            title: Text(
              "QUOTATION",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 30),
            ),
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
              SizedBox(height: 10),
              buildCustomerField(context),
              buildTextField('Customer Name', _customerNameController, enabled: false),
              buildTextField('Address', _addressController),
              buildTextField('Phone', _phoneController),
              buildTextField('VAT No.', _vatNoController),
              buildTextField('Entry Date', _entryDateController, showCalendarIcon: true),
              buildTextField('Quotation No.', _quotationNoController),
              buildTextField('Salesman', _salesmanController),
              buildTextField('Enquiry Reference', _enquiryReferenceController),
              buildTextField('Remarks', _remarksController),

              // Products Fields
              for (int i = 0; i < products.length; i++) buildProductRow(i),

              ElevatedButton(
                onPressed: () {
                  setState(() {
                    // Check if the last product has non-empty code and name
                    if (products.isNotEmpty &&
                        (products.last['code']?.text?.isNotEmpty == true ||
                            products.last['name']?.text?.isNotEmpty == true)) {
                      // Add a new product with empty code and name fields
                      products.add({'code': TextEditingController(), 'name': TextEditingController()});
                    }
                  });
                },
                child: Text('Add More Products'),
              ),

              // Remaining Fields
              buildTextField('Validity', _validityController),
              buildTextField('Delivery Time', _deliveryTimeController),
              buildTextField('Place of Delivery', _placeOfDeliveryController),

              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // Submit logic here
                  // Access entered values using controllers
                  // Call your custom function to submit data
                  submitDataToFirestore();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SalesNav(userEmail: widget.userEmail)));
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String labelText, TextEditingController controller,
      {bool enabled = true, bool showCalendarIcon = false, VoidCallback? onTap, ValueChanged<String>? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        enabled: enabled,
        onTap: onTap,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: labelText,
          suffixIcon: showCalendarIcon
              ? IconButton(
            onPressed: () async {
              DateTime? selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );

              if (selectedDate != null) {
                controller.text = selectedDate.toLocal().toString().split(' ')[0];
              }
            },
            icon: Icon(Icons.calendar_today),
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
      ),
    );
  }

  Widget buildCustomerField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () async {
          final selectedCustomer = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerSelectionPage(),
            ),
          );

          if (selectedCustomer != null && selectedCustomer is Map<String, dynamic>) {
            setState(() {
              _customerCodeController.text = selectedCustomer['customerCode'] ?? '';
              _customerNameController.text = selectedCustomer['customerName'] ?? '';
              _addressController.text = selectedCustomer['address'] ?? '';
              _phoneController.text = selectedCustomer['mobileNumber'] ?? '';
              _vatNoController.text = selectedCustomer['vtNumber'] ?? '';
            });
          }
        },
        child: AbsorbPointer(
          child: TextField(
            controller: _customerCodeController,
            decoration: InputDecoration(
              labelText: 'Customer Code',
              suffixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildProductRow(int index) {
    TextEditingController codeController = products[index]['code'] ?? TextEditingController();
    TextEditingController nameController = products[index]['name'] ?? TextEditingController();

    return Column(
      children: [
        buildTextField('Product Code', codeController),
        buildTextFieldWithSearchIcon(
          'Product Name',
          nameController,
          onTap: () async {
            final selectedProduct = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductSelectionPage(),
              ),
            );

            if (selectedProduct != null) {
              setState(() {
                products[index]['name'] ??= TextEditingController();
                products[index]['code'] ??= TextEditingController();
                products[index]['name']!.text = selectedProduct['itemName'];
                products[index]['code']!.text = selectedProduct['itemCode'];
              });
            }
          },
        ),
      ],
    );
  }

  Widget buildTextFieldWithSearchIcon(String labelText, TextEditingController controller, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: labelText,
          suffixIcon: onTap != null
              ? IconButton(
            icon: Icon(Icons.search),
            onPressed: onTap,
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
      ),
    );
  }

  void submitDataToFirestore() async {
    try {
      await FirebaseFirestore.instance.collection('rfq').add({
        'customerName': _customerNameController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'vatNo': _vatNoController.text,
        'entryDate': _entryDateController.text,
        'quotationNo': _quotationNoController.text,
        'salesman': _salesmanController.text,
        'enquiryReference': _enquiryReferenceController.text,
        'remarks': _remarksController.text,
        'products': List.generate(
          products.length,
              (index) => {
            'code': products[index]['code']?.text,
            'name': products[index]['name']?.text,
          },
        ),
        'validity': _validityController.text,
        'deliveryTime': _deliveryTimeController.text,
        'placeOfDelivery': _placeOfDeliveryController.text,
      });

      print('Data submitted to Firestore successfully');
    } catch (error) {
      print('Error submitting data to Firestore: $error');
    }
  }
}
