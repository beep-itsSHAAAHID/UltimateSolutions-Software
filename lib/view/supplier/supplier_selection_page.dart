import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierSelectionPage extends StatefulWidget {
  @override
  _SupplierSelectionPageState createState() => _SupplierSelectionPageState();
}

class _SupplierSelectionPageState extends State<SupplierSelectionPage> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _filteredSuppliers = [];

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  Future<void> _fetchSuppliers() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('suppliers').get();
      setState(() {
        _suppliers = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        _filteredSuppliers = _suppliers;
      });
    } catch (error) {
      print('Error fetching suppliers: $error');
    }
  }

  void _filterSuppliers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSuppliers = _suppliers;
      } else {
        _filteredSuppliers = _suppliers.where((supplier) {
          return supplier['supplierName'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Supplier'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Supplier',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              onChanged: _filterSuppliers,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredSuppliers.length,
              itemBuilder: (context, index) {
                final supplier = _filteredSuppliers[index];
                return ListTile(
                  title: Text(supplier['supplierName']),
                  subtitle: Text('VAT: ${supplier['vatNumber']}'),
                  onTap: () {
                    Navigator.pop(context, supplier);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
