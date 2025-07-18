import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:UltimateSolutions/home_v2/homepagev2.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:UltimateSolutions/view/products/productselectionpage.dart';
import 'package:UltimateSolutions/view/salesnav.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../customer/customerselection.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:UltimateSolutions/models/qrgenerator.dart';

class Rfq extends StatefulWidget {
  final String userEmail;

  const Rfq({Key? key, required this.userEmail}) : super(key: key);
  @override
  _RfqState createState() => _RfqState();
}

class _RfqState extends State<Rfq> {
  final TextEditingController quotationDateController = TextEditingController();
  final TextEditingController entryDateController = TextEditingController();
  final TextEditingController quotationNoController = TextEditingController();
  final TextEditingController enquiryReferenceController = TextEditingController();
  final TextEditingController poNoController = TextEditingController();
  final TextEditingController vatNoController = TextEditingController();
  final TextEditingController customerCodeController = TextEditingController();
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController deliveryPlaceController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController netAmountController = TextEditingController();
  final TextEditingController personController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  TextEditingController vatExclusiveController = TextEditingController();
  TextEditingController attentionController = TextEditingController();

  List<ProductControllerGroup> products = [ProductControllerGroup()];
  String? selectedModeOfPayment;
  List<String> unitDropdownValues = ['Unit', 'Roll', 'Piece','Each','Box'];
  List<String> modeOfPaymentValues = ['Cash', 'Cash / Bank Transfer', 'Credit', 'Bank Transfer', 'Proforma Invoice'];

  double totalLineTotal = 0.0;

  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _setNextQuotationNumber();
    _setCurrentDate();

  }

  void _setCurrentDate() {
    final DateTime now = DateTime.now();
    final String formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    quotationDateController.text = formattedDate;
  }

  Future<void> _setNextQuotationNumber() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('rfq')
        .orderBy('timestamp', descending: true)
        .limit(20) // Get more to filter invalid ones
        .get();

    int nextInvoiceNo = 200060;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final raw = data['quotationNo']?.toString();

      // Extract only numeric parts
      final numericPart = int.tryParse(raw ?? '');

      if (numericPart != null) {
        nextInvoiceNo = numericPart + 1;
        break; // Stop at the first valid one
      }
    }

    setState(() {
      quotationNoController.text = nextInvoiceNo.toString();
    });
  }

  @override
  Widget build(BuildContext context) {

    // Add listeners to controllers
    for (int i = 0; i < products.length; i++) {
      products[i].priceController.addListener(() {
        updateLineTotal(i);
        updateNetAmount();
      });

      products[i].qtyController.addListener(() {
        updateLineTotal(i);
        updateNetAmount();
      });

    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: AppBar(
          title: Text(

            "Enter Quotation Request",
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              buildTextFormField(
                controller: customerCodeController,
                label: 'Customer Code',
                onTap: () async {
                  // Open CustomerSelectionPage and wait for result
                  final selectedCustomer = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerSelectionPage(),
                    ),
                  );

                  // Update state with selected customer data
                  if (selectedCustomer != null && selectedCustomer is Map<String, dynamic>) {
                    setState(() {
                      customerCodeController.text = selectedCustomer['customerCode'] ?? '';
                      customerNameController.text = selectedCustomer['customerName'] ?? '';
                      addressController.text = selectedCustomer['address'] ?? '';
                      vatNoController.text = selectedCustomer['vtNumber'] ?? '';
                      emailController.text = selectedCustomer['email'] ?? '';
                      personController.text = selectedCustomer['contactPerson'] ?? '';
                      // Update other fields as needed
                    });
                  }
                },
              ),
              SizedBox(height: 16),
              buildTextFormField(
                controller: customerNameController,
                label: 'Customer Name',
              ),
              SizedBox(height: 16),
              buildTextFormField(
                controller: addressController,
                label: 'Address',
              ),
              SizedBox(height: 16),
              buildTextFormField(
                controller: emailController,
                label: 'Email',
              ),
              SizedBox(height: 16),
              buildTextFormField(
                controller: personController,
                label: 'Attention',
              ),
              SizedBox(height: 16),
              buildTextFormField(
                controller: vatNoController,
                label: 'Customer Vat Number',
              ),
              SizedBox(height: 16),
              buildDateFormField(
                controller: quotationDateController,
                label: 'Quotation Date',
              ),
              // SizedBox(height: 16),
              // buildDateFormField(
              //   controller: entryDateController,
              //   label: 'Entry Date',
              // ),
              SizedBox(height: 16),
              buildTextFormField(
                controller: quotationNoController,
                label: 'Quotation No',
              ),
              SizedBox(height: 16),
              buildTextFormField(
                controller: enquiryReferenceController,
                label: 'Quotation Reference',
              ),
              // SizedBox(height: 16),
              // buildTextFormField(
              //   controller: poNoController,
              //   label: 'PO No',
              // ),
              SizedBox(height: 16),
              buildTextFormField(
                controller: deliveryPlaceController,
                label: 'Delivery Place',
              ),
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

              buildDropdownButton(
                label: 'Select Payment Terms',
                value: selectedModeOfPayment,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedModeOfPayment = newValue;
                  });
                },
                items: modeOfPaymentValues
                    .map((mode) => DropdownMenuItem<String>(
                  value: mode,
                  child: Text(mode),
                ))
                    .toList(),
              ),
              SizedBox(height: 16),



              Row(
                children: [
                  SizedBox(height: 16),
                  buildTextFormFieldForNetAmount(
                    controller: netAmountController,
                    label: 'Net Amount',
                    readOnly: true,
                  ),

                  SizedBox(height: 16,width: 10,),
                  buildTextFormFieldForNetAmount(
                    controller: vatExclusiveController,
                    label: 'Total Without VAT',
                    readOnly: true,
                    initialValue: getTotalWithoutVat().toString(), // Set the initial value
                  ),

                ],
              ),
              SizedBox(height: 16),
              // buildDropdownButton(
              //   label: 'Select Mode of Payment',
              //   value: selectedModeOfPayment,
              //   onChanged: (String? newValue) {
              //     setState(() {
              //       selectedModeOfPayment = newValue;
              //     });
              //   },
              //   items: ['Cash', 'Credit', 'Bank Transfer', 'Proforma Invoice']
              //       .map((mode) => DropdownMenuItem<String>(
              //     value: mode,
              //     child: Text(mode),
              //   ))
              //       .toList(),
              // ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Icon(Icons.check) ,
              ),
            ],
          ),
        ),
      ),
    );
  }

  double getTotalWithoutVat() {
    double netAmount = double.tryParse(netAmountController.text) ?? 0.0;
    double totalVat = getTotalVat();
    double totalWithoutVat = netAmount - totalVat;

    // Update vatExclusiveController with totalWithoutVat
    vatExclusiveController.text = totalWithoutVat.toString();

    return totalWithoutVat;
  }


  double getTotalVat() {
    double totalVat = 0.0;
    for (int i = 0; i < products.length; i++) {
      double vatAmount = double.tryParse(products[i].taxAmountController.text) ?? 0.0;
      totalVat += vatAmount;
    }
    return totalVat;
  }

  double getNetAmount() {
    double netAmount = 0.0;
    for (int i = 0; i < products.length; i++) {
      double lineTotal = double.tryParse(products[i].lineTotalController.text) ?? 0.0;
      netAmount += lineTotal;
    }
    setState(() {
      netAmountController.text = netAmount.toString();
    });

    return netAmount;
  }



  void updateNetAmount() {
    double netAmount = 0.0;
    for (int i = 0; i < products.length; i++) {
      double lineTotal = double.tryParse(products[i].lineTotalController.text) ?? 0.0;
      netAmount += lineTotal;
    }
    setState(() {
      netAmountController.text = netAmount.toString();
    });
  }

  Future<void> submitData() async {
    try {
      print('Submitting data...');

      // Create a list to store the product data
      List<Map<String, dynamic>> productsData = [];

      // Iterate through the products and add data to the list
      for (int i = 0; i < products.length; i++) {
        productsData.add({
          'code': products[i].codeController.text,
          'name': products[i].nameController.text,
          'unit': products[i].unitController.text,
          'quantity': double.tryParse(products[i].qtyController.text) ?? 0.0,
          'price': double.tryParse(products[i].priceController.text) ?? 0.0,
          'vat': products[i].selectedVAT,
          'taxAmount': double.tryParse(products[i].taxAmountController.text) ?? 0.0,
          'lineTotal': double.tryParse(products[i].lineTotalController.text) ?? 0.0,
        });
      }

      // Capture and save the QR code image, and get the image URL



      await FirebaseFirestore.instance.collection('rfq').add({
        'timestamp': FieldValue.serverTimestamp(),
        'quotationDate': quotationDateController.text,
        'entryDate': entryDateController.text,
        'quotationNo': quotationNoController.text,
        'enquiryReference': enquiryReferenceController.text,
        'poNo': poNoController.text,
        'vatNo': vatNoController.text,
        'totalWithoutVat': vatExclusiveController.text,
        'customerCode': customerCodeController.text,
        'customerName': customerNameController.text,
        'address': addressController.text,
        'deliveryPlace': deliveryPlaceController.text,
        'modeOfPayment': selectedModeOfPayment,
        'netAmount': netAmountController.text,
        'attention' : personController.text,

        'products': productsData, // Add the list of products
      });

      Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
      print('Data submitted successfully!');
      final snackBar = SnackBar(content: const Text('Quotation Created Successfully!'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);


    } catch (error) {
      print('Error submitting data: $error');

      // Display an error snackbar
      final snackBar = SnackBar(content: Text('Error submitting data: $error'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }


  Widget buildTextFormField({
    required TextEditingController controller,
    required String label,
    void Function()? onTap,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(fontSize: 16),
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.blue),
        ),
        labelText: label,
      ),
      onTap: onTap,
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

  Widget buildTextField(String labelText, TextEditingController controller,
      {bool enabled = true, bool showCalendarIcon = false, VoidCallback? onTap, ValueChanged<String>? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        enabled: enabled,
        onTap: onTap,
        onChanged: onChanged,  // Add this onChanged callback
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

  Widget buildDropdown(String labelText, TextEditingController controller, List<String> items, List<String> selectedItems) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField(
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
        value: selectedItems.isNotEmpty ? selectedItems.first : null,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (value) {
          controller.text = value.toString();
          // Update other logic based on the selected value
        },
      ),
    );
  }


  Widget buildVATRadioButtons(int index, List<String> vatValues) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('VAT'),
        Row(
          children: vatValues
              .map(
                (vat) => Row(
              children: [
                Radio(
                  value: vat,
                  groupValue: products[index].selectedVAT,
                  onChanged: (value) {
                    setState(() {
                      products[index].selectedVAT = value.toString();
                    });
                    updateTaxAmount(index); // Update tax amount when VAT changes
                  },
                ),
                Text(vat),
              ],
            ),
          )
              .toList(),
        ),
      ],
    );
  }

  Widget buildProductRow(int index) {
    List<String> vatValues = ['5%', '10%', '15%'];

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
        buildDropdown('Unit', products[index].unitController, unitDropdownValues, products[index].selectedUnit),
        buildTextField('Quantity', products[index].qtyController,onChanged: (_) { updateLineTotal(index);
        updateNetAmount();
        }
        ),
        // Price Field
        buildTextField('Price', products[index].priceController,
            onChanged: (value) {
              updateTaxAmount(index);
              updateLineTotal(index);
              updateNetAmount();
            }
        ),


        // VAT Radio Buttons
        buildVATRadioButtons(index, vatValues),

        // Tax Amount Field
        buildTextField('Tax Amount', products[index].taxAmountController, onChanged: (value) {
          updateLineTotal(index);
          updateTotalLineTotal(); // Update the totalLineTotal when the tax amount changes
        }),

        // Line Total Field
        buildTextField('Line Total', products[index].lineTotalController,
            onChanged: (value) {
              updateLineTotal(index);
              updateTotalLineTotal(); // Update the totalLineTotal when the line total changes
            }),

      ],
    );
  }

  void updateTotalLineTotal() {
    totalLineTotal = 0.0;

    for (int i = 0; i < products.length; i++) {
      totalLineTotal += double.tryParse(products[i].lineTotalController.text) ?? 0.0;
    }

    // Update the netAmountController with the total line total
    netAmountController.text = totalLineTotal.toString();
  }


  void updateTaxAmount(int index) {
    double lineTotal = double.tryParse(products[index].lineTotalController.text) ?? 0.0;
    double vatPercentage = double.tryParse(products[index].selectedVAT.replaceAll('%', '')) ?? 0.0;
    double price = double.tryParse(products[index].priceController.text) ?? 0.0;
    double quantity = double.tryParse(products[index].qtyController.text) ?? 0.0;

    print('Line Total: $lineTotal');
    print('VAT Percentage: $vatPercentage');

    // Calculate tax amount (line total * vat percentage / 100)
    double taxAmount = price*quantity*0.15;

    // Format tax amount to display only the first two digits after the decimal point
    String formattedTaxAmount = taxAmount.toStringAsFixed(2);

    print('Calculated Tax Amount: $formattedTaxAmount');

    // Update tax amount controller
    setState(() {
      products[index].taxAmountController.text = formattedTaxAmount;
    });

    // Update line total
    updateLineTotal(index);
  }



  void updateLineTotal(int index) {
    double price = double.tryParse(products[index].priceController.text) ?? 0.0;
    double quantity = double.tryParse(products[index].qtyController.text) ?? 0.0;
    double vatPercentage = double.tryParse(products[index].selectedVAT.replaceAll('%', '')) ?? 0.0;

    // Calculate tax amount
    double taxAmount = (price * vatPercentage / 100) * quantity;

    // Calculate line total (price * quantity + tax amount)
    double lineTotal = (price * quantity) + taxAmount;

    // Update tax amount controller
    products[index].taxAmountController.text = taxAmount.toString();

    // Update line total controller
    products[index].lineTotalController.text = lineTotal.toString();

    // Update the total line total
    updateTotalLineTotal();
  }

  Widget buildDateFormField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(fontSize: 16),
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.blue),
        ),
        labelText: label,
        suffixIcon: Icon(Icons.calendar_today),
      ),
      onTap: () async {
        DateTime? selectedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );

        if (selectedDate != null && selectedDate != controller.text) {
          controller.text = selectedDate.toLocal().toString().split(' ')[0];
        }
      },
    );
  }

  Widget buildTextFormFieldForNetAmount({
    required TextEditingController controller,
    required String label,
    String? initialValue,
    bool readOnly = false,  // Add a flag for read-only
  }) {
    return Container(
      width: 150,  // Make the container take the full width
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red),  // Add a border to make it look like a square
        borderRadius: BorderRadius.circular(10.0),  // Add border radius for a rounded look
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,  // Set it as read-only
        style: TextStyle(fontSize: 20,fontWeight: FontWeight.w900),
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,  // Remove the default input border
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0),  // Add padding for better appearance
        ),
      ),
    );
  }

  DropdownButtonFormField<String> buildDropdownButton({
    required String label,
    required String? value,
    required void Function(String?) onChanged,
    required List<DropdownMenuItem<String>> items,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
      ),
      value: value,
      onChanged: onChanged,
      items: items,
    );
  }

}

class ProductControllerGroup {


  TextEditingController codeController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController qtyController = TextEditingController();
  TextEditingController taxAmountController = TextEditingController();
  TextEditingController unitController = TextEditingController();
  List<String> selectedUnit = ['Unit'];
  TextEditingController priceController = TextEditingController();
  String selectedVAT = '';
  TextEditingController lineTotalController = TextEditingController();
  String selectedModeOfPayment = '';
}
