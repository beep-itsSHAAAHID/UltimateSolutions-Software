import 'package:UltimateSolutions/home_v2/homepagev2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:UltimateSolutions/view/products/productselectionpage.dart';
import 'package:UltimateSolutions/view/customer/customerselection.dart';
import 'package:UltimateSolutions/view/salesnav.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Delivery extends StatefulWidget {
  final String userEmail;

  const Delivery({Key? key, required this.userEmail}) : super(key: key);

  @override
  _DeliveryState createState() => _DeliveryState();
}

class _DeliveryState extends State<Delivery> {
  TextEditingController _customerCodeController = TextEditingController();
  TextEditingController _customerNameController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _invoiceController = TextEditingController();
  TextEditingController _deliveryNoteNoController = TextEditingController();
  TextEditingController _poNoController = TextEditingController();
  TextEditingController _refNoController = TextEditingController();
  TextEditingController _vatNoController = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  List<ProductControllerGroup> products = [ProductControllerGroup()];

  List<String> unitDropdownValues = ['Unit', 'Roll', 'Piece','Each','Box'];

  @override
  void initState() {
    super.initState();
    _setNextDeliveryNoteNumber();
    _setCurrentDate();
  }

  void _setCurrentDate() {
    final DateTime now = DateTime.now();
    final String formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _dateController.text = formattedDate;
  }



  Future<void> _setNextDeliveryNoteNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int nextDeliveryNoteNo = prefs.getInt('deliveryNoteNo') ?? 200020; // Start from 10000 if not set

    setState(() {
      _deliveryNoteNoController.text = '$nextDeliveryNoteNo';
    });

    // Increment the delivery note number and save it back to SharedPreferences
    await prefs.setInt('deliveryNoteNo', nextDeliveryNoteNo + 1);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    final double paddingValue = isSmallScreen ? 8.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: AppBar(
          title: Text(
            "Enter Delivery",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 30),
          ),
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
        child: Padding(
          padding: EdgeInsets.all(paddingValue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              buildCustomerField(context),
              buildTextField('Customer Name', _customerNameController, enabled: true),
              buildTextField('Address', _addressController),
              buildTextField('Phone No.', _phoneController),
              buildTextField('Vat No.', _vatNoController),
              buildTextField('Delivery Note No.', _deliveryNoteNoController),
              buildTextField('Invoice No.', _invoiceController),
              buildTextField('PO No.', _poNoController),
              buildTextField('REF No.', _refNoController),
              buildTextField('Date', _dateController),
              SizedBox(height: 16),
              for (int i = 0; i < products.length; i++) buildProductRow(i),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    products.add(ProductControllerGroup());
                  });
                },
                child: Text('Add More Products'),
              ),
              SizedBox(height: 16),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Icon(Icons.check),
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
    return Column(
      children: [
        buildTextField('Product Code', products[index].codeController),
        buildTextFieldWithSearchIcon(
          'Product Name',
          products[index].nameController,
          onTap: () async {
            final selectedProduct = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductSelectionPage(),
              ),
            );

            if (selectedProduct != null) {
              setState(() {
                products[index].nameController.text = selectedProduct['itemName'];
                products[index].codeController.text = selectedProduct['itemCode'];
              });
            }
          },
        ),
        buildTextField('Quantity', products[index].qtyController),
        buildDropdown('Unit', products[index].unitController, unitDropdownValues, products[index].selectedUnit),
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

  Widget buildDropdown(String labelText, TextEditingController controller, List<String> items, String selectedItem) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField(
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
        value: selectedItem,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (value) {
          controller.text = value.toString();
          // Add any additional logic here based on the selected value
        },
      ),
    );
  }


  void submitData() async {
    try {
      CollectionReference deliveryCollection = FirebaseFirestore.instance.collection('delivery');

      await deliveryCollection.add({
        'customerCode': _customerCodeController.text,
        'customerName': _customerNameController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'deliveryNoteNo': _deliveryNoteNoController.text,
        'poNo': _poNoController.text,
        'vatNo': _vatNoController.text,
        'invoiceNo': _invoiceController.text,
        'refNo': _refNoController.text,
        'date':_dateController.text,
        'products': products.map((product) {
          return {
            'code': product.codeController.text,
            'name': product.nameController.text,
            'unit': product.unitController.text,
            'quantity': product.qtyController.text,
          };
        }).toList(),
      });

      print('Data submitted to Firestore successfully');

      // Navigate to SalesNav page after submitting data
      String userEmail = widget.userEmail; // Store userEmail from widget
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );

      final snackBar = SnackBar(content:
      const Text('Delivery Note Created Succesfully!'));

      ScaffoldMessenger.of(context).showSnackBar(snackBar);

    } catch (error) {
      print('Error submitting data to Firestore: $error');
    }
  }
}

class ProductControllerGroup {
  TextEditingController codeController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController qtyController = TextEditingController();
  TextEditingController unitController = TextEditingController();
  String selectedUnit = 'Unit';
}
