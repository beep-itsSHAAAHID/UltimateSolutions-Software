import 'package:UltimateSolutions/view/productselectionpage.dart';
import 'package:UltimateSolutions/view/salesnav.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class Purchase extends StatefulWidget {

  final String userEmail;
  Purchase({Key? key, required this.userEmail}) : super(key: key);


  @override
  State<Purchase> createState() => _PurchaseState();

}

class _PurchaseState extends State<Purchase> {


  List<Map<String, TextEditingController>> products = [
    {'code': TextEditingController(), 'name': TextEditingController()}
  ];
  TextEditingController _productCodeController = TextEditingController();
  TextEditingController _productNameController = TextEditingController();

  TextEditingController _purchaseAmountController = TextEditingController();
  TextEditingController _amountController = TextEditingController();
  TextEditingController _currentStockController = TextEditingController();
  TextEditingController _openingStockController = TextEditingController();
  TextEditingController _averageCostController = TextEditingController();
  TextEditingController _retailPriceController = TextEditingController();
  TextEditingController _wholesaleRateController = TextEditingController();
  TextEditingController _priceAfterVATController = TextEditingController();

  String _selectedVATCategory = '5%'; // Default value

  List<String> _vatCategories = ['5%', '10%', '15%'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Purchase",
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildProductRow(),

            SizedBox(height: 16),
            buildTextField('Enter Purchase Amount', _purchaseAmountController),
            buildTextField('Enter Quantity', _amountController),
            buildTextField('Current Stock', _currentStockController),
            buildTextField('Opening Stock', _openingStockController),
            buildTextField('Average Cost', _averageCostController),
            buildTextField('Retail Price', _retailPriceController),
            buildTextField('Wholesale Rate', _wholesaleRateController),
            SizedBox(height: 16),
            buildVATCategoryDropdown(),
            SizedBox(height: 16),
            buildTextField('Price after VAT', _priceAfterVATController, editable: false),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                addDataToFirestore();Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context)=>SalesNav(userEmail: widget.userEmail)));
                // Call a function or navigate to the next screen
                // based on your requirements.
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProductRow() {
    return Column(
      children: [
        buildTextField('Product Code', _productCodeController),
        buildTextFieldWithSearchIcon(
          'Product Name',
          _productNameController,
          onTap: () async {
            final selectedProduct = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductSelectionPage(),
              ),
            );
          },
        ),
      ],
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

  Widget buildVATCategoryDropdown() {
    return Row(
      children: [
        Text('VAT Category:'),
        SizedBox(width: 10),
        DropdownButton<String>(
          value: _selectedVATCategory,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedVATCategory = newValue;
                calculatePriceAfterVAT();
              });
            }
          },
          items: _vatCategories.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    );
  }

  void calculatePriceAfterVAT() {
    try {
      double retailPrice = double.parse(_retailPriceController.text);
      double vatPercentage = double.parse(_selectedVATCategory.replaceAll('%', ''));
      double priceAfterVAT = retailPrice + (retailPrice * vatPercentage / 100);
      _priceAfterVATController.text = priceAfterVAT.toString();
    } catch (error) {
      print('Error calculating price after VAT: $error');
    }
  }

  void addDataToFirestore() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;



      await firestore.collection('products').add({

        'productName': _productNameController.text,
        'productCode': _productCodeController.text,
        'purchaseAmount': _purchaseAmountController.text,
        'quantity': _amountController.text,
        'currentStock': _currentStockController.text,
        'openingStock': _openingStockController.text,
        'averageCost': _averageCostController.text,
        'retailPrice': _retailPriceController.text,
        'wholesaleRate': _wholesaleRateController.text,
        'vatCategory': _selectedVATCategory,
        'priceAfterVAT': _priceAfterVATController.text,

      });

      print('Data added to Firestore successfully!');
    } catch (error) {
      print('Error adding data to Firestore: $error');
    }
  }
}
