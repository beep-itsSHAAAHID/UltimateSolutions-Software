import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductSelectionPage extends StatefulWidget {
  @override
  _ProductSelectionPageState createState() => _ProductSelectionPageState();
}

class _ProductSelectionPageState extends State<ProductSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  late QuerySnapshot _originalProductList;
  late List<DocumentSnapshot> _filteredProductList = [];

  @override
  void initState() {
    super.initState();
    _loadProductList();
  }

  Future<void> _loadProductList() async {
    _originalProductList = await FirebaseFirestore.instance.collection('products').orderBy('productCode').get();
    setState(() {
      _filteredProductList = List.from(_originalProductList.docs);
    });

    // Log the product data
    for (var productDocument in _filteredProductList) {
      var productData = productDocument.data() as Map<String, dynamic>;
      print('Product Data: $productData');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: filterProducts,
              decoration: InputDecoration(
                labelText: 'Search Product',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredProductList.length,
              itemBuilder: (context, index) {
                var productData = _filteredProductList[index].data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(productData['productName'] ?? ''), // Use null-aware operator to handle potential null values
                  subtitle: Text('Product Code: ${productData['productCode'] ?? ''}'), // Use null-aware operator
                  onTap: () => onSelectProduct(productData),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void filterProducts(String query) {
    setState(() {
      _filteredProductList = _originalProductList.docs.where((doc) {
        var productName = doc['productName'].toString().toLowerCase();
        var productCode = doc['productCode'].toString().toLowerCase();
        return productName.contains(query.toLowerCase()) || productCode.contains(query.toLowerCase());
      }).toList();

      // Log the filtered product data
      for (var productDocument in _filteredProductList) {
        var productData = productDocument.data() as Map<String, dynamic>;
        print('Filtered Product Data: $productData');
      }
    });
  }


  void onSelectProduct(Map<String, dynamic> productData) {
    Navigator.pop(context, {
      'productName': productData['productName'] ?? '',
      'itemCode': productData['productCode'] ?? '',
      'itemName': productData['productName'] ?? '',
      'rate': productData['retailPrice'] ?? 0, // Use default value if the field is null
      'address': productData['address'] ?? '',
      // Add more fields as needed
    });
  }
}
