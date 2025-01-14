import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController _productCodeController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();

  @override
  void dispose() {
    _productCodeController.dispose();
    _productNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add Product",
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
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildTextField('Product Code', _productCodeController),
            buildTextField('Product Name', _productNameController),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Add product to Firestore or handle as needed
                addProductToFirestore();
                Navigator.pop(context, {
                  'itemCode': _productCodeController.text,
                  'itemName': _productNameController.text,
                });
              },
              child: Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String labelText, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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

  void addProductToFirestore() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      await firestore.collection('products').add({
        'productName': _productNameController.text,
        'productCode': _productCodeController.text,
        'createdDate': FieldValue.serverTimestamp(),
      });

      print('Product added to Firestore successfully!');
    } catch (error) {
      print('Error adding product to Firestore: $error');
    }
  }
}
