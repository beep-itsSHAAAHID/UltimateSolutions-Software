import 'package:UltimateSolutions/home_v2/homepagev2.dart';
import 'package:UltimateSolutions/view/products/productselectionpage.dart';
import 'package:UltimateSolutions/view/salesnav.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../supplier/supplier_selection_page.dart';

class Purchase extends StatefulWidget {
  final String userEmail;

  Purchase({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<Purchase> createState() => _PurchaseState();
}

class _PurchaseState extends State<Purchase> {
  List<Map<String, dynamic>> products = [
    {
      'code': TextEditingController(),
      'name': TextEditingController(),
      'retailPrice': TextEditingController(),
      'quantity': TextEditingController(),
      'priceAfterVAT': TextEditingController(),
    }
  ];
  TextEditingController _purchaseInvoiceController = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  TextEditingController _supplierController = TextEditingController();
  TextEditingController _supplierVATController = TextEditingController();
  TextEditingController _totalVATController = TextEditingController();
  TextEditingController _totalAmountPaidController = TextEditingController();

  final String _selectedVATCategory = '15%'; // Default value

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _purchaseInvoiceController.dispose();
    for (var product in products) {
      product['code']?.dispose();
      product['name']?.dispose();
      product['retailPrice']?.dispose();
      product['quantity']?.dispose();
      product['priceAfterVAT']?.dispose();
    }
    _dateController.dispose();
    _supplierController.dispose();
    _supplierVATController.dispose();
    _totalVATController.dispose();
    _totalAmountPaidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Purchase",
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildTextField('Purchase Invoice Code', _purchaseInvoiceController),
            buildProductList(),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                addProductField();
              },
              child: Text('Add Another Product'),
            ),
            SizedBox(height: 16),
            buildTextFieldWithSearchIcon(
              'Supplier Name',
              _supplierController,
              onTap: () async {
                final selectedSupplier = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SupplierSelectionPage(),
                  ),
                );
                // Update state with selected supplier data
                if (selectedSupplier != null && selectedSupplier is Map<String, dynamic>) {
                  setState(() {
                    _supplierController.text = selectedSupplier['supplierName'];
                    _supplierVATController.text = selectedSupplier['vatNumber'];
                  });
                }
              },
            ),
            buildTextField('Supplier VAT', _supplierVATController, editable: true),
            buildTextField('Purchase Date', _dateController),
            buildTextField('Total VAT', _totalVATController, editable: false),
            buildTextField('Total Amount Paid', _totalAmountPaidController, editable: false),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                addDataToFirestore();
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => HomePage()));
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProductList() {
    return Column(
      children: products
          .map((product) => Column(
        children: [
          buildTextField('Product Code', product['code']!, editable: true),
          buildTextFieldWithSearchIcon(
            'Product Name',
            product['name']!,
            onTap: () async {
              final selectedProduct = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductSelectionPage(),
                ),
              );
              // Update state with selected product data
              if (selectedProduct != null && selectedProduct is Map<String, dynamic>) {
                setState(() {
                  product['code']?.text = selectedProduct['itemCode'] ?? '';
                  product['name']?.text = selectedProduct['itemName'] ?? '';
                });
              }
            },
          ),
          buildTextField('Retail Price', product['retailPrice']!),
          buildTextField('Quantity', product['quantity']!),
          buildTextField('Price After VAT', product['priceAfterVAT']!, editable: false),
          SizedBox(height: 16),
        ],
      ))
          .toList(),
    );
  }

  Widget buildTextField(String labelText, TextEditingController controller, {bool editable = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        enabled: editable,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
        onChanged: (value) {
          if (!editable && labelText == 'Price After VAT') return;
          calculatePriceAfterVAT();
        },
      ),
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

  void calculatePriceAfterVAT() {
    double totalVAT = 0.0;
    double totalAmountPaid = 0.0;

    setState(() {
      for (var product in products) {
        try {
          double retailPrice = double.parse(product['retailPrice']?.text ?? '0');
          int quantity = int.parse(product['quantity']?.text ?? '0');
          double vatPercentage = 15.0; // Set to 15% by default
          double totalPrice = retailPrice * quantity;
          double vatAmount = totalPrice * vatPercentage / 100;
          double priceAfterVAT = totalPrice + vatAmount;

          product['priceAfterVAT']?.text = priceAfterVAT.toStringAsFixed(2);

          totalVAT += vatAmount;
          totalAmountPaid += priceAfterVAT;
        } catch (error) {
          print('Error calculating price after VAT: $error');
        }
      }

      _totalVATController.text = totalVAT.toStringAsFixed(2);
      _totalAmountPaidController.text = totalAmountPaid.toStringAsFixed(2);
    });
  }

  void addDataToFirestore() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      for (var product in products) {
        await firestore.collection('purchase').add({
          'purchaseInvoiceCode': _purchaseInvoiceController.text,
          'productName': product['name']?.text ?? '',
          'productCode': product['code']?.text ?? '',
          'retailPrice': product['retailPrice']?.text ?? '',
          'quantity': product['quantity']?.text ?? '',
          'priceAfterVAT': product['priceAfterVAT']?.text ?? '',
          'vatCategory': _selectedVATCategory,
          'purchaseDate': _dateController.text,
          'addedBy': widget.userEmail,
          'supplierName': _supplierController.text,
          'supplierVAT': _supplierVATController.text,
          'createdDate': FieldValue.serverTimestamp(),
        });
      }

      print('Data added to Firestore successfully!');
    } catch (error) {
      print('Error adding data to Firestore: $error');
    }
  }

  void addProductField() {
    setState(() {
      products.add({
        'code': TextEditingController(),
        'name': TextEditingController(),
        'retailPrice': TextEditingController(),
        'quantity': TextEditingController(),
        'priceAfterVAT': TextEditingController(),
      });
    });
  }
}
